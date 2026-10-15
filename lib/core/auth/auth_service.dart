import 'package:flutter/foundation.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/auth/oauth_client_store.dart';
import 'package:pocketcrm/core/auth/oauth_token_client.dart';
import 'package:pocketcrm/core/auth/two_factor_exception.dart';
import 'package:pocketcrm/core/network/custom_http_client.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketcrm/data/graphql/auth_mutations.dart';
import 'package:pocketcrm/domain/services/ios_contacts_provider_service.dart';

class AuthService {
  final StorageService _storage;

  /// OAuth endpoints (discovery, token, registration) shared with the PKCE login.
  final OAuthTokenClient _oauthTokenClient;

  /// Per-instance OAuth client credentials, required by the refresh grant.
  final OAuthClientStore _oauthClientStore;

  /// Mutex for refresh — prevents concurrent refresh attempts from
  /// different callers (lifecycle handler, connector, router).
  Future<bool>? _refreshFuture;

  AuthService(
    StorageService storage, {
    OAuthTokenClient? oauthTokenClient,
    OAuthClientStore? oauthClientStore,
  })  : _storage = storage,
        _oauthTokenClient = oauthTokenClient ?? OAuthTokenClient(),
        _oauthClientStore = oauthClientStore ?? OAuthClientStore(storage);

  Future<void> loginWithCredentials(
    String instanceUrl,
    String email,
    String password, {
    String? captchaToken,
  }) async {
    final client = _createUnauthenticatedClient(instanceUrl);

    // Step 1: Get a temporary login token from credentials
    final variables = <String, dynamic>{
      'email': email,
      'password': password,
      'origin': instanceUrl,
    };
    if (captchaToken != null) {
      variables['captchaToken'] = captchaToken;
    }

    final loginOptions = MutationOptions(
      document: gql(getLoginTokenFromCredentialsMutation),
      variables: variables,
    );

    final loginResult = await client.mutate(loginOptions);

    if (loginResult.hasException) {
      final exStr = loginResult.exception.toString().toLowerCase();
      if (exStr.contains('unauthenticated') ||
          exStr.contains('wrong credentials') ||
          exStr.contains('invalid credentials') ||
          exStr.contains('wrong password') ||
          exStr.contains('wrong-credentials') ||
          exStr.contains('invalid password') ||
          exStr.contains('incorrect password')) {
        throw Exception('Invalid email or password.');
      }
      if (exStr.contains('user not found') ||
          exStr.contains('no account')) {
        throw Exception('No account found with this email.');
      }
      if (exStr.contains('password login is disabled') ||
          exStr.contains('password-login-disabled')) {
        throw Exception(
          'Password login is disabled on this Twenty instance.',
        );
      }
      if (exStr.contains('captcha')) {
        throw Exception(
          'Captcha verification failed. Please try again.',
        );
      }
      throw Exception(loginResult.exception.toString());
    }

    final loginData = loginResult.data?['getLoginTokenFromCredentials'];
    if (loginData == null) {
      throw Exception('Invalid response from server');
    }

    final loginToken = loginData['loginToken']['token'] as String;

    // Step 2: Exchange login token for access + refresh tokens
    await loginWithLoginToken(
      instanceUrl: instanceUrl,
      loginToken: loginToken,
      authMethod: 'email',
    );

    await _storage.write(key: 'auth_email', value: email);
    await _storage.write(key: 'auth_password', value: password);
  }

  /// Exchanges a loginToken (obtained via Google OAuth, SSO, or email credentials)
  /// for access and refresh tokens, fetches user profile info, and persists the session.
  Future<void> loginWithLoginToken({
    required String instanceUrl,
    required String loginToken,
    required String authMethod,
  }) async {
    final client = _createUnauthenticatedClient(instanceUrl);

    final tokenOptions = MutationOptions(
      document: gql(getAuthTokensFromLoginTokenMutation),
      variables: {
        'loginToken': loginToken,
        'origin': instanceUrl,
      },
    );

    final tokenResult = await client.mutate(tokenOptions);

    if (tokenResult.hasException) {
      final exception = tokenResult.exception;
      if (exception != null) {
        final graphqlErrors = exception.graphqlErrors;
        final requires2FA = graphqlErrors.any((e) =>
          e.extensions?['subCode'] == 'TWO_FACTOR_AUTHENTICATION_VERIFICATION_REQUIRED' ||
          e.message.contains('TWO_FACTOR_AUTHENTICATION_VERIFICATION_REQUIRED'),
        );
        if (requires2FA) {
          throw TwoFactorRequiredException(
            loginToken: loginToken,
            instanceUrl: instanceUrl,
            authMethod: authMethod,
          );
        }
      }
      throw Exception(tokenResult.exception.toString());
    }

    final tokenData = tokenResult.data?['getAuthTokensFromLoginToken'];
    if (tokenData == null) {
      throw Exception('Failed to exchange login token for access tokens');
    }

    final tokens = tokenData['tokens'];
    final accessToken = tokens['accessOrWorkspaceAgnosticToken']['token'] as String;
    final refreshToken = tokens['refreshToken']['token'] as String;
    final expiresAt = tokens['accessOrWorkspaceAgnosticToken']['expiresAt'] as String;

    await loginWithDirectTokens(
      instanceUrl: instanceUrl,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      authMethod: authMethod,
    );
  }

  /// Stores direct access & refresh tokens (e.g. from cookies or token exchange)
  /// and fetches the user's workspace member info.
  ///
  /// [authMethod] must be explicit (`sso`, `email`, …) so a caller that forgets
  /// it cannot silently mislabel the session.
  Future<void> loginWithDirectTokens({
    required String instanceUrl,
    required String accessToken,
    required String refreshToken,
    required String authMethod,
    String? expiresAt,
  }) async {
    final effectiveExpiresAt = expiresAt ??
        DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String();

    final member = await _fetchWorkspaceMember(instanceUrl, accessToken);

    await _storage.write(key: 'api_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'token_expires_at', value: effectiveExpiresAt);
    await _storage.write(key: 'auth_method', value: authMethod);
    await _storage.write(key: 'user_member_id', value: member.id);
    await _storage.write(key: 'user_first_name', value: member.firstName);
    await _storage.write(key: 'user_last_name', value: member.lastName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_expires_at', effectiveExpiresAt);
  }

  /// Reads the signed-in workspace member (id + name) through an authenticated
  /// metadata client.
  ///
  /// The profile is non-critical: any failure yields empty values so the caller
  /// still keeps a valid session instead of aborting the login.
  Future<({String id, String firstName, String lastName})> _fetchWorkspaceMember(
    String instanceUrl,
    String accessToken,
  ) async {
    try {
      final client = _createAuthenticatedMetadataClient(instanceUrl, accessToken);
      const meQuery = r'''
        query Me {
          currentUser {
            workspaceMember {
              id
              name { firstName lastName }
            }
          }
        }
      ''';
      final result = await client.query(QueryOptions(document: gql(meQuery)));
      final member = result.data?['currentUser']?['workspaceMember'];
      if (member == null) return (id: '', firstName: '', lastName: '');
      final name = member['name'];
      return (
        id: member['id'] as String? ?? '',
        firstName: name?['firstName'] as String? ?? '',
        lastName: name?['lastName'] as String? ?? '',
      );
    } catch (_) {
      return (id: '', firstName: '', lastName: '');
    }
  }

  /// Complete 2FA login by sending the OTP code alongside the loginToken.
  ///
  /// [authMethod] is the method that started the flow (`email` or `sso`) and is
  /// persisted as-is, so an SSO login that requires 2FA is not relabelled as
  /// an email login.
  Future<void> loginWithOTP({
    required String instanceUrl,
    required String loginToken,
    required String otp,
    required String authMethod,
  }) async {
    final client = _createUnauthenticatedClient(instanceUrl);

    final otpOptions = MutationOptions(
      document: gql(getAuthTokensFromOTPMutation),
      variables: {
        'loginToken': loginToken,
        'otp': otp,
        'origin': instanceUrl,
      },
    );

    final otpResult = await client.mutate(otpOptions);

    if (otpResult.hasException) {
      final exStr = otpResult.exception.toString().toLowerCase();
      if (exStr.contains('invalid') || exStr.contains('wrong') || exStr.contains('incorrect')) {
        throw Exception('Invalid verification code. Please try again.');
      }
      throw Exception(otpResult.exception.toString());
    }

    final otpData = otpResult.data?['getAuthTokensFromOTP'];
    if (otpData == null) {
      throw Exception('Failed to verify OTP code');
    }

    final tokens = otpData['tokens'];
    final accessToken = tokens['accessOrWorkspaceAgnosticToken']['token'] as String;
    final refreshToken = tokens['refreshToken']['token'] as String;
    final expiresAt = tokens['accessOrWorkspaceAgnosticToken']['expiresAt'] as String;

    final member = await _fetchWorkspaceMember(instanceUrl, accessToken);

    await _storage.write(key: 'api_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'token_expires_at', value: expiresAt);
    await _storage.write(key: 'auth_method', value: authMethod);
    await _storage.write(key: 'user_member_id', value: member.id);
    await _storage.write(key: 'user_first_name', value: member.firstName);
    await _storage.write(key: 'user_last_name', value: member.lastName);
    await _storage.delete(key: 'pending_2fa_login_token');
    await _storage.delete(key: 'pending_2fa_auth_method');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_expires_at', expiresAt);
  }

  Future<void> loginWithApiKey(String instanceUrl, String apiKey) async {
    await _storage.write(key: 'api_token', value: apiKey);
    await _storage.write(key: 'auth_method', value: 'api_key');
  }

  Future<bool> refreshAccessToken() async {
    // If a refresh is already in progress, wait for that one's result
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _doRefreshAccessToken();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefreshAccessToken() async {
    final instanceUrl = await _storage.read(key: 'instance_url');
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (instanceUrl == null || refreshToken == null) {
      await logout();
      return false;
    }

    final authMethod = await _storage.read(key: 'auth_method');

    // OAuth sessions (SSO/PKCE) are renewed with the standard
    // `grant_type=refresh_token` grant declared in the discovery document.
    // `renewToken` only understands the login tokens minted by /metadata, so
    // using it here made every OAuth session die after ~1h and fall back to a
    // silent logout (no email/password is stored for SSO).
    if (authMethod == 'sso') {
      return _refreshOAuthSession(
        instanceUrl: instanceUrl,
        refreshToken: refreshToken,
      );
    }

    final client = _createUnauthenticatedClient(instanceUrl);

    final options = MutationOptions(
      document: gql(renewTokenMutation),
      variables: {
        'appToken': refreshToken,
      },
    );

    final result = await client.mutate(options);

    bool fallbackRequired = result.hasException || result.data?['renewToken'] == null;

    if (fallbackRequired) {
      final email = await _storage.read(key: 'auth_email');
      final password = await _storage.read(key: 'auth_password');
      if (email != null && password != null) {
        try {
          await loginWithCredentials(instanceUrl, email, password);
          return true;
        } on TwoFactorRequiredException catch (e) {
          await _storage.write(key: 'pending_2fa_login_token', value: e.loginToken);
          await _storage.write(key: 'pending_2fa_auth_method', value: e.authMethod);
          return false;
        } catch (_) {
          await logout();
          return false;
        }
      } else {
        await logout();
        return false;
      }
    }

    final data = result.data?['renewToken'];

    final tokens = data['tokens'];
    final newAccessToken = tokens['accessOrWorkspaceAgnosticToken']['token'] as String;
    final newRefreshToken = tokens['refreshToken']['token'] as String;
    final expiresAt = tokens['accessOrWorkspaceAgnosticToken']['expiresAt'] as String;

    await _storage.write(key: 'api_token', value: newAccessToken);
    await _storage.write(key: 'refresh_token', value: newRefreshToken);
    await _storage.write(key: 'token_expires_at', value: expiresAt);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_expires_at', expiresAt);

    return true;
  }

  /// Renews an OAuth session with `POST /oauth/token` +
  /// `grant_type=refresh_token`.
  ///
  /// The refresh token is rotated by Twenty, so the value returned here is
  /// always persisted: replaying a consumed token would end the session.
  Future<bool> _refreshOAuthSession({
    required String instanceUrl,
    required String refreshToken,
  }) async {
    final clientId = await _oauthClientStore.readClientId(instanceUrl);

    if (clientId == null || clientId.isEmpty) {
      debugPrint(
        '[AuthService] OAuth refresh skipped: no client id stored for $instanceUrl',
      );
      await logout();
      return false;
    }

    try {
      final tokens = await _oauthTokenClient.refreshTokens(
        instanceUrl: instanceUrl,
        clientId: clientId,
        refreshToken: refreshToken,
        clientSecret: await _oauthClientStore.readClientSecret(instanceUrl),
      );

      final expiresAt = DateTime.now()
          .toUtc()
          .add(Duration(seconds: tokens.expiresIn))
          .toIso8601String();

      await _storage.write(key: 'api_token', value: tokens.accessToken);
      await _storage.write(
        key: 'refresh_token',
        value: tokens.refreshToken.isNotEmpty ? tokens.refreshToken : refreshToken,
      );
      await _storage.write(key: 'token_expires_at', value: expiresAt);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token_expires_at', expiresAt);

      return true;
    } catch (e) {
      debugPrint('[AuthService] OAuth refresh failed: $e');
      await logout();
      return false;
    }
  }

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAtStr = prefs.getString('token_expires_at');

    if (expiresAtStr == null) return false;

    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return false;

    // Se scade entro 5 minuti, consideralo scaduto
    return DateTime.now().toUtc().add(const Duration(minutes: 5)).isAfter(expiresAt);
  }

  Future<void> clearPending2FA() async {
    await _storage.delete(key: 'pending_2fa_login_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'api_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'token_expires_at');
    await _storage.delete(key: 'auth_method');
    await _storage.delete(key: 'auth_email');
    await _storage.delete(key: 'auth_password');
    await _storage.delete(key: 'user_member_id');
    await _storage.delete(key: 'user_first_name');
    await _storage.delete(key: 'user_last_name');
    // The member an API-key user picked under Settings → "I am" belongs to this login only.
    await _storage.delete(key: BaseGraphQLConnector.apiKeyMemberIdKey);
    await _storage.delete(key: BaseGraphQLConnector.apiKeyMemberNameKey);
    await _storage.delete(key: 'is_demo_mode');
    await _storage.delete(key: 'pending_2fa_login_token');
    await _storage.delete(key: 'pending_2fa_auth_method');
    // Client credentials live per instance now; only the global key written by
    // older versions is dropped here (see OAuthClientStore).
    await _storage.delete(key: OAuthClientStore.legacyClientIdKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token_expires_at');
    await IosContactsProviderService.instance.disableAndClear();
  }

  GraphQLClient _createUnauthenticatedClient(String baseUrl) {
    final customHttpClient = TimeoutHttpClient(
      timeoutDuration: const Duration(seconds: 30),
    );
    final link = HttpLink(
      '$baseUrl/metadata',
      httpClient: customHttpClient,
    );
    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
      queryRequestTimeout: const Duration(seconds: 30),
    );
  }

  GraphQLClient _createAuthenticatedMetadataClient(String baseUrl, String token) {
    final customHttpClient = TimeoutHttpClient(
      timeoutDuration: const Duration(seconds: 30),
    );
    final link = HttpLink(
      '$baseUrl/metadata',
      defaultHeaders: {'Authorization': 'Bearer $token'},
      httpClient: customHttpClient,
    );
    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
      queryRequestTimeout: const Duration(seconds: 30),
    );
  }
}
