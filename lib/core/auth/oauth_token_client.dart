import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketcrm/core/config/app_config.dart';

/// Raised when an OAuth endpoint answers with an error payload.
///
/// [toString] returns the bare message so screens can surface it directly
/// (no `Exception: ` prefix to strip).
class OAuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  OAuthException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => message;
}

/// True when [error] says the *client credentials* were refused, i.e. the
/// application was deleted on the instance or the id belongs to another one.
///
/// Deliberately narrow: an earlier `message.contains('client')` check wiped
/// stored credentials for unrelated failures (timeouts, server errors).
bool isClientRejection(OAuthException error) {
  const rejectionCodes = {
    'invalid_client',
    'invalid_client_id',
    'unauthorized_client',
    'invalid_client_metadata',
  };

  final code = error.errorCode?.toLowerCase();
  if (code != null && rejectionCodes.contains(code)) return true;

  final message = error.message.toLowerCase();
  return message.contains('invalid_client') ||
      message.contains('unknown client') ||
      message.contains('client not found') ||
      (message.contains('client_id') && message.contains('invalid'));
}

/// Token pair returned by `/oauth/token`, whatever the grant type.
typedef OAuthTokens = ({String accessToken, String refreshToken, int expiresIn});

/// Credentials issued by dynamic client registration (RFC 7591).
typedef OAuthClientCredentials = ({String clientId, String? clientSecret});

/// Capabilities of a Twenty instance, read from the standard discovery document
/// plus the public `/client-config` endpoint.
///
/// Reading the endpoints from `/.well-known/oauth-authorization-server` instead
/// of hardcoding them removes a whole class of "wrong endpoint" bugs, and the
/// absence of `registration_endpoint` is the compatibility signal the UI uses
/// to explain why no client can be created automatically.
class OAuthServerMetadata {
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;

  /// Present only on instances that support dynamic client registration.
  final Uri? registrationEndpoint;

  final bool supportsRefreshTokenGrant;
  final bool supportsPkceS256;

  /// `appVersion` reported by the instance (empty when unknown).
  final String appVersion;

  /// `isMultiWorkspaceEnabled` from `/client-config`; null when unknown.
  ///
  /// The instance propagator only forwards to an arbitrary callback URL (custom
  /// schemes included) while multi-workspace is disabled.
  final bool? isMultiWorkspaceEnabled;

  const OAuthServerMetadata({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.registrationEndpoint,
    this.supportsRefreshTokenGrant = false,
    this.supportsPkceS256 = true,
    this.appVersion = '',
    this.isMultiWorkspaceEnabled,
  });

  bool get supportsDynamicRegistration => registrationEndpoint != null;
}

/// Thin, stateless HTTP client for Twenty's OAuth endpoints.
///
/// It deliberately knows nothing about storage or Riverpod: both
/// [OAuthPkceService] (authorization code flow) and the auth service (refresh
/// grant) share it, which is also what keeps it unit-testable with a
/// `MockClient`.
class OAuthTokenClient {
  static const String discoveryPath = '/.well-known/oauth-authorization-server';
  static const String clientConfigPath = '/client-config';
  static const String authorizationPath = '/authorize';
  static const String tokenPath = '/oauth/token';
  static const String registrationPath = '/oauth/register';

  /// Budget for the shared registry calls.
  ///
  /// The registry itself spends up to 3s verifying the client id against the
  /// instance (plus cold-start overhead), so a 5s client timeout could abandon
  /// a write that actually succeeded.
  static const Duration registryTimeout = Duration(seconds: 8);

  final http.Client _httpClient;
  final Duration _timeout;

  OAuthTokenClient({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 15);

  /// Removes trailing slashes so instance URLs always concatenate cleanly.
  static String normalizeBaseUrl(String instanceUrl) =>
      instanceUrl.trim().replaceAll(RegExp(r'/+$'), '');

  /// Reads the discovery document, enriched with `/client-config` when the
  /// instance exposes it.
  ///
  /// Returns null when the instance does not publish a usable discovery
  /// document: callers then fall back to the legacy hardcoded paths instead of
  /// failing the sign-in.
  Future<OAuthServerMetadata?> fetchMetadata(String instanceUrl) async {
    final baseUrl = normalizeBaseUrl(instanceUrl);
    final discovery = await _getJson(Uri.parse('$baseUrl$discoveryPath'));

    if (discovery == null) return null;

    final authorizationEndpoint = discovery['authorization_endpoint'] as String?;
    final tokenEndpoint = discovery['token_endpoint'] as String?;
    if (authorizationEndpoint == null || tokenEndpoint == null) return null;

    final registrationEndpoint = discovery['registration_endpoint'] as String?;
    final grants = _stringList(discovery['grant_types_supported']);
    final challengeMethods =
        _stringList(discovery['code_challenge_methods_supported']);

    final clientConfig = await _getJson(Uri.parse('$baseUrl$clientConfigPath'));

    return OAuthServerMetadata(
      authorizationEndpoint: Uri.parse(authorizationEndpoint),
      tokenEndpoint: Uri.parse(tokenEndpoint),
      registrationEndpoint:
          (registrationEndpoint == null || registrationEndpoint.isEmpty)
              ? null
              : Uri.parse(registrationEndpoint),
      supportsRefreshTokenGrant: grants.contains('refresh_token'),
      supportsPkceS256:
          challengeMethods.isEmpty || challengeMethods.contains('S256'),
      appVersion: clientConfig?['appVersion'] as String? ?? '',
      isMultiWorkspaceEnabled: clientConfig?['isMultiWorkspaceEnabled'] as bool?,
    );
  }

  /// Exchanges an authorization code (with its PKCE verifier) for tokens.
  Future<OAuthTokens> exchangeAuthorizationCode({
    required String instanceUrl,
    required String clientId,
    required String code,
    required String codeVerifier,
    required String redirectUri,
    String? clientSecret,
    Uri? tokenEndpoint,
  }) {
    final body = <String, dynamic>{
      'grant_type': 'authorization_code',
      'client_id': clientId,
      'code': code,
      'redirect_uri': redirectUri,
      'code_verifier': codeVerifier,
    };
    _addClientSecret(body, clientSecret);

    return _postTokens(
      instanceUrl: instanceUrl,
      body: body,
      tokenEndpoint: tokenEndpoint,
    );
  }

  /// Renews an OAuth session with the standard refresh grant.
  ///
  /// Twenty rotates the refresh token: callers must persist the value returned
  /// here, otherwise the next refresh replays a consumed token.
  Future<OAuthTokens> refreshTokens({
    required String instanceUrl,
    required String clientId,
    required String refreshToken,
    String? clientSecret,
    Uri? tokenEndpoint,
  }) {
    final body = <String, dynamic>{
      'grant_type': 'refresh_token',
      'client_id': clientId,
      'refresh_token': refreshToken,
    };
    _addClientSecret(body, clientSecret);

    return _postTokens(
      instanceUrl: instanceUrl,
      body: body,
      tokenEndpoint: tokenEndpoint,
    );
  }

  /// Dynamic client registration (RFC 7591).
  ///
  /// Returns null when the instance does not implement it — the common case for
  /// self-hosted Twenty, where `POST /oauth/register` answers 404.
  ///
  /// Registration is side-effect free: the caller decides when/if to persist the
  /// credentials via [OAuthClientStore].
  Future<OAuthClientCredentials?> registerClient({
    required String instanceUrl,
    required String redirectUri,
    String clientName = 'TwentyMobile',
  }) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse('${normalizeBaseUrl(instanceUrl)}$registrationPath'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_name': clientName,
              'redirect_uris': [redirectUri],
              'grant_types': ['authorization_code', 'refresh_token'],
              'response_types': ['code'],
              'token_endpoint_auth_method': 'none',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 && response.statusCode != 201) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final clientId = data['client_id'] as String?;
      if (clientId == null || clientId.isEmpty) return null;

      final secret = data['client_secret'] as String?;
      return (
        clientId: clientId,
        clientSecret: (secret == null || secret.isEmpty) ? null : secret,
      );
    } catch (e) {
      debugPrint('OAuth dynamic registration not available on $instanceUrl: $e');
      return null;
    }
  }

  /// Looks up a registered OAuth client ID for [instanceUrl] from the shared
  /// public registry. Returns null if not registered, unverified, or on error.
  Future<String?> fetchSharedClientId({
    required String instanceUrl,
    String? registryUrl,
  }) async {
    final endpoint = registryUrl ?? AppConfig.oauthRegistryUrl;
    if (endpoint.isEmpty) return null;

    try {
      final uri = Uri.parse(endpoint).replace(
        queryParameters: {'instance': instanceUrl},
      );
      final response =
          await _httpClient.get(uri).timeout(registryTimeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['exists'] == true) {
        final id = data['clientId'] as String?;
        if (id != null && id.isNotEmpty) return id;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to query shared OAuth client registry: $e');
      return null;
    }
  }

  /// Publishes a newly created or validated OAuth client ID for [instanceUrl]
  /// to the shared public registry.
  Future<bool> registerSharedClientId({
    required String instanceUrl,
    required String clientId,
    String? registryUrl,
  }) async {
    final endpoint = registryUrl ?? AppConfig.oauthRegistryUrl;
    if (endpoint.isEmpty) return false;

    try {
      final uri = Uri.parse(endpoint);
      final response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'instance': instanceUrl,
              'clientId': clientId,
            }),
          )
          .timeout(registryTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to register OAuth client with shared registry: $e');
      return false;
    }
  }

  Future<OAuthTokens> _postTokens({
    required String instanceUrl,
    required Map<String, dynamic> body,
    Uri? tokenEndpoint,
  }) async {
    final endpoint =
        tokenEndpoint ?? Uri.parse('${normalizeBaseUrl(instanceUrl)}$tokenPath');

    late final http.Response response;
    try {
      response = await _httpClient
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw OAuthException('Token request timed out');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _errorFrom(response);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw OAuthException(
        'Missing access_token in OAuth response',
        statusCode: response.statusCode,
      );
    }

    final refreshToken = data['refresh_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;

    return (
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      expiresIn: expiresIn,
    );
  }


  /// Turns an error response into a message a user can act on.
  ///
  /// NestJS answers with `{"message": [...]}`, the OAuth spec with
  /// `{"error": ..., "error_description": ...}`; both are handled.
  OAuthException _errorFrom(http.Response response) {
    var message = 'OAuth request failed (HTTP ${response.statusCode})';
    String? errorCode;

    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      errorCode = errorJson['error'] as String?;
      final raw =
          errorJson['message'] ?? errorJson['error_description'] ?? errorJson['error'];

      if (raw is List) {
        message = raw.join(', ');
      } else if (raw != null && raw.toString().isNotEmpty) {
        message = raw.toString();
      }
    } catch (_) {
      if (response.body.isNotEmpty) message = response.body;
    }

    return OAuthException(
      message,
      statusCode: response.statusCode,
      errorCode: errorCode,
    );
  }

  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    try {
      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('OAuth metadata request failed for $uri: $e');
      return null;
    }
  }

  static void _addClientSecret(Map<String, dynamic> body, String? clientSecret) {
    if (clientSecret != null && clientSecret.isNotEmpty) {
      body['client_secret'] = clientSecret;
    }
  }

  static List<String> _stringList(Object? value) =>
      value is List ? value.map((e) => e.toString()).toList() : const <String>[];
}

