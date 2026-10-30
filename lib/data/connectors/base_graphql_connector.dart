import 'dart:convert';
import 'dart:ui' show VoidCallback;
import 'package:flutter/foundation.dart';
import 'package:gql/language.dart' show parseString;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/core/network/custom_http_client.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';

enum InstanceValidationError {
  unreachable,
  notTwentyInstance,
  invalidUrl,
}

class InstanceValidationException implements Exception {
  final InstanceValidationError error;
  final String? details;

  const InstanceValidationException(this.error, [this.details]);

  @override
  String toString() => 'InstanceValidationException($error, $details)';
}

class BaseGraphQLConnector {
  final GraphQLClient client;
  final AuthService? authService;
  final StorageService storageService;
  final VoidCallback? onTokenRefreshed;
  final Map<String, List<String>> customFields;
  String? _currentMemberId;

  /// Mutex for token refresh — prevents concurrent refresh attempts
  Future<bool>? _refreshFuture;

  BaseGraphQLConnector({
    required this.client,
    required this.storageService,
    this.authService,
    this.onTokenRefreshed,
    this.customFields = const {},
  });

  /// Storage key of the workspace member an API-key user picked under Settings → "I am".
  static const apiKeyMemberIdKey = 'api_key_member_id';

  /// Storage key of that member's display name.
  static const apiKeyMemberNameKey = 'api_key_member_name';

  /// Returns the current workspace member's ID, caching it for the session.
  ///
  /// An API key has no user behind it. For API key auth this returns the member the person picked
  /// under Settings → "I am" (read on every call, so a change applies at once), or null if none was
  /// picked — then all tasks are shown, as before.
  Future<String?> getCurrentMemberId() async {
    final authMethod = await storageService.read(key: 'auth_method') ?? 'api_key';
    if (authMethod != 'email' && authMethod != 'sso') {
      return storageService.read(key: apiKeyMemberIdKey);
    }

    if (_currentMemberId != null) return _currentMemberId;

    final storedId = await storageService.read(key: 'user_member_id');
    if (storedId != null && storedId.isNotEmpty) {
      _currentMemberId = storedId;
      return _currentMemberId;
    }

    // Fallback for existing sessions: fetch from metadata endpoint
    final instanceUrl = await storageService.read(key: 'instance_url');
    final apiToken = await storageService.read(key: 'api_token');
    
    if (instanceUrl != null && apiToken != null) {
      try {
        final customHttpClient = TimeoutHttpClient(
          timeoutDuration: const Duration(seconds: 30),
        );
        final link = HttpLink(
          '$instanceUrl/metadata',
          defaultHeaders: {'Authorization': 'Bearer $apiToken'},
          httpClient: customHttpClient,
        );
        final metadataClient = GraphQLClient(
          link: link,
          cache: GraphQLCache(),
          queryRequestTimeout: const Duration(seconds: 30),
        );

        const String query = r'''
          query Me {
            currentUser {
              workspaceMember {
                id
              }
            }
          }
        ''';
        final result = await metadataClient.query(
          QueryOptions(
            document: parseString(query),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );

        final memberId = result.data?['currentUser']?['workspaceMember']?['id'] as String?;
        if (memberId != null && memberId.isNotEmpty) {
          _currentMemberId = memberId;
          await storageService.write(key: 'user_member_id', value: memberId);
          return _currentMemberId;
        }
      } catch (_) {
        // Ignore errors and fallback
      }
    }

    // If we can't resolve the identity, return a non-existent ID so it doesn't broaden
    // the query to all readable tasks.
    return 'unresolved_identity';
  }

  /// Checks whether the exception is a network timeout.
  bool isTimeout(OperationException exception) {
    final linkException = exception.linkException;
    if (linkException == null) return false;
    return linkException.toString().contains('TimeoutException');
  }

  Future<QueryResult> queryWithRefresh(QueryOptions options) async {
    // Proactively refresh if we know the token is expired
    if (authService != null && await authService!.isTokenExpired()) {
      await tryRefresh();
    }

    QueryResult result = await client.query(options);

    // Retry once on timeout (covers flaky network after foreground resume)
    if (result.hasException && isTimeout(result.exception!)) {
      result = await client.query(options);
    }

    if (result.hasException && isUnauthenticated(result.exception!)) {
      final isRefreshed = await tryRefresh();
      if (isRefreshed) {
        result = await client.query(options);
      }
    }
    return result;
  }

  Future<QueryResult> mutateWithRefresh(MutationOptions options) async {
    // Proactively refresh if we know the token is expired
    if (authService != null && await authService!.isTokenExpired()) {
      await tryRefresh();
    }

    QueryResult result = await client.mutate(options);

    // Retry once on timeout (covers flaky network after foreground resume)
    if (result.hasException && isTimeout(result.exception!)) {
      result = await client.mutate(options);
    }

    if (result.hasException && isUnauthenticated(result.exception!)) {
      final isRefreshed = await tryRefresh();
      if (isRefreshed) {
        result = await client.mutate(options);
      }
    }
    return result;
  }

  bool isUnauthenticated(OperationException exception) {
    // Check GraphQL error codes and messages
    if (exception.graphqlErrors.any((e) {
      final code = e.extensions?['code']?.toString().toUpperCase() ?? '';
      final msg = e.message.toLowerCase();
      return code == 'UNAUTHENTICATED' ||
          msg.contains('unauthenticated') ||
          msg.contains('token has expired') ||
          msg.contains('token expired') ||
          msg.contains('expired token') ||
          msg.contains('jwt expired') ||
          msg.contains('invalid token');
    })) {
      return true;
    }
    // Check link-level exceptions (HTTP 401)
    final linkException = exception.linkException;
    if (linkException is ServerException &&
        linkException.parsedResponse?.response['status'] == 401) {
      return true;
    }
    // Fallback: check raw exception string
    final exStr = exception.toString().toLowerCase();
    if (exStr.contains('401') ||
        exStr.contains('unauthenticated') ||
        exStr.contains('token has expired') ||
        exStr.contains('token expired') ||
        exStr.contains('jwt expired')) {
      return true;
    }
    return false;
  }

  /// Attempts to refresh the auth token. Uses a mutex so only one refresh
  /// runs at a time — concurrent callers wait for the same result.
  Future<bool> tryRefresh() async {
    if (authService == null) return false;

    // If a refresh is already in progress, wait for that one's result
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefresh() async {
    final authMethod = await storageService.read(key: 'auth_method') ?? 'api_key';

    if (authMethod != 'email' && authMethod != 'sso') return false; // API keys don't need refresh

    final isSuccess = await authService!.refreshAccessToken();
    if (isSuccess) {
      onTokenRefreshed?.call();
    }
    return isSuccess;
  }

  void handleResultException(QueryResult result) {
    if (!result.hasException) return;

    final exception = result.exception!;
    final linkException = exception.linkException;

    // Log to Sentry (fire and forget). Only error codes and the link error
    // type are sent: server messages can echo field values of CRM records
    // (e.g. duplicate or validation errors), and those must not leave the
    // user's own server.
    try {
      final codes = exception.graphqlErrors
          .map((e) => e.extensions?['code']?.toString() ?? 'UNKNOWN')
          .toSet()
          .join(',');
      Sentry.captureException(
        GraphQLFailure(
          'graphql=[$codes] link=${linkException?.runtimeType ?? 'none'}',
        ),
        stackTrace: StackTrace.current,
      );
    } catch (_) {}

    // Check if this is an auth error that survived the refresh attempt
    if (isUnauthenticated(exception)) {
      throw Exception('Token has expired.');
    }

    if (linkException != null) {
      final errorStr = linkException.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('NetworkError') ||
          errorStr.contains('Connection closed')) {
        throw Exception(
          'It seems there\'s no internet connection. Please check your settings.',
        );
      }
      if (errorStr.contains('Connection refused') ||
          errorStr.contains('404') ||
          errorStr.contains('Network unreachable')) {
        throw Exception(
          'The CRM endpoint is unreachable. Please verify the URL in settings.',
        );
      }
      if (errorStr.contains('TimeoutException')) {
        throw Exception(
          'The server took too long to respond. Please try again later.',
        );
      }
      throw Exception('Connection error: $errorStr');
    }

    if (exception.graphqlErrors.isNotEmpty) {
      final error = exception.graphqlErrors.first;
      final msg = error.message.toLowerCase();
      if (msg.contains('unauthorized') || msg.contains('forbidden')) {
        throw Exception(
          'Session expired or invalid token. Please reconnect in settings.',
        );
      }
      if (msg.contains('cannot be executed as a single request') ||
          msg.contains('query is too complex') ||
          msg.contains('complexity limit')) {
        throw Exception(
          'Your Twenty instance has restrictive query limits. '
          'Please update Twenty to the latest version, or contact your server administrator '
          'to increase the GraphQL query complexity limit.',
        );
      }
      throw Exception(error.message);
    }

    throw Exception(
      'An unexpected error occurred while communicating with the server.',
    );
  }

  static Future<bool> testConnection(String baseUrl, String apiToken) async {
    const String query = r'''
      query Me {
        workspaceMembers(first: 1) {
          edges {
            node {
              name { firstName lastName }
            }
          }
        }
      }
    ''';

    final customHttpClient = TimeoutHttpClient(
      timeoutDuration: const Duration(seconds: 30),
    );

    final tempLink = HttpLink(
      '$baseUrl/graphql',
      defaultHeaders: {'Authorization': 'Bearer $apiToken'},
      httpClient: customHttpClient,
    );

    final tempClient = GraphQLClient(
      link: tempLink,
      cache: GraphQLCache(),
      queryRequestTimeout: const Duration(seconds: 30),
    );

    final QueryResult result = await tempClient.query(
      QueryOptions(
        document: parseString(query),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      final exception = result.exception!;
      if (exception.graphqlErrors.isNotEmpty) {
        final error = exception.graphqlErrors.first;
        final msg = error.message.toLowerCase();

        if (msg.contains('unauthorized') || msg.contains('forbidden')) {
          throw Exception('Invalid API Token');
        }

        if (msg.contains('cannot be executed as a single request') ||
            msg.contains('query is too complex') ||
            msg.contains('complexity limit')) {
          return true;
        }

        throw Exception(error.message);
      }

      if (exception.linkException != null) {
        final linkError = exception.linkException.toString();
        if (linkError.contains('404')) {
          throw Exception('URL not found. Verify your Instance URL.');
        }
        if (linkError.contains('Connection refused') ||
            linkError.contains('SocketException')) {
          throw Exception('Server unreachable. Check your internet or URL.');
        }
        throw Exception('Network error: $linkError');
      }

      throw Exception('Something went wrong: ${exception.toString()}');
    }

    final edges = result.data?['workspaceMembers']?['edges'] as List?;
    if (edges == null || edges.isEmpty) {
      throw Exception('Connected, but no access to workspace.');
    }

    return true;
  }

  static bool _isConnectionRefusalOrUnreachable(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('failed host lookup') ||
        s.contains('nodename nor servname provided') ||
        s.contains('connection refused') ||
        s.contains('network is unreachable');
  }

  /// Validates that [rawUrl] points to a reachable, responsive Twenty CRM instance.
  /// Normalizes the URL (auto-prepends https:// if needed, strips trailing slashes).
  /// Returns the normalized URL if valid, or throws [InstanceValidationException].
  static Future<String> validateInstance(
    String rawUrl, {
    http.Client? httpClient,
  }) async {
    var url = rawUrl.trim();
    if (url.isEmpty) {
      throw const InstanceValidationException(
        InstanceValidationError.invalidUrl,
        'URL cannot be empty',
      );
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    url = url.replaceAll(RegExp(r'/+$'), '');

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw const InstanceValidationException(
        InstanceValidationError.invalidUrl,
        'Invalid URL format',
      );
    }

    final client = httpClient ?? TimeoutHttpClient(timeoutDuration: const Duration(seconds: 10));
    try {
      // 1. Try /healthz (NestJS Terminus endpoint)
      try {
        final res = await client
            .get(Uri.parse('$url/healthz'))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          try {
            final json = jsonDecode(res.body);
            if (json is Map && (json['status'] == 'ok' || json.containsKey('status'))) {
              return url;
            }
          } catch (_) {}
        }
      } catch (e) {
        if (_isConnectionRefusalOrUnreachable(e)) {
          throw InstanceValidationException(
            InstanceValidationError.unreachable,
            e.toString(),
          );
        }
      }

      // 2. Try /client-config (Twenty frontend config)
      try {
        final res = await client
            .get(Uri.parse('$url/client-config'))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          try {
            final json = jsonDecode(res.body);
            if (json is Map &&
                (json.containsKey('appVersion') ||
                    json.containsKey('authProviders') ||
                    json.containsKey('billing') ||
                    json.containsKey('captcha') ||
                    json.containsKey('isMultiWorkspaceEnabled'))) {
              return url;
            }
          } catch (_) {}
        }
      } catch (e) {
        if (_isConnectionRefusalOrUnreachable(e)) {
          throw InstanceValidationException(
            InstanceValidationError.unreachable,
            e.toString(),
          );
        }
      }

      // 3. Try /metadata (Twenty unauthenticated GraphQL metadata endpoint)
      try {
        final res = await client
            .post(
              Uri.parse('$url/metadata'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'query': '{ __typename }'}),
            )
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          try {
            final json = jsonDecode(res.body);
            if (json is Map && json.containsKey('data')) {
              return url;
            }
          } catch (_) {}
        }
      } catch (e) {
        if (_isConnectionRefusalOrUnreachable(e)) {
          throw InstanceValidationException(
            InstanceValidationError.unreachable,
            e.toString(),
          );
        }
      }

      throw const InstanceValidationException(
        InstanceValidationError.notTwentyInstance,
        'Server did not respond with expected Twenty CRM signatures',
      );
    } on InstanceValidationException {
      rethrow;
    } catch (e) {
      throw InstanceValidationException(
        InstanceValidationError.unreachable,
        e.toString(),
      );
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}

/// Content-free stand-in for an [OperationException] in error reports.
class GraphQLFailure implements Exception {
  final String summary;
  GraphQLFailure(this.summary);

  @override
  String toString() => 'GraphQLFailure($summary)';
}
