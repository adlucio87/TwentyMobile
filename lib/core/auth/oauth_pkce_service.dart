import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/core/auth/oauth_client_store.dart';
import 'package:pocketcrm/core/auth/oauth_token_client.dart';
import 'package:pocketcrm/core/config/app_config.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';

/// PKCE cryptographic parameters for OAuth 2.0 Authorization Code Flow (RFC 7636).
class PkcePair {
  final String codeVerifier;
  final String codeChallenge;
  final String state;

  const PkcePair({
    required this.codeVerifier,
    required this.codeChallenge,
    required this.state,
  });

  /// Generates a cryptographically secure PKCE pair with S256 challenge.
  factory PkcePair.generate([Random? secureRandom]) {
    final random = secureRandom ?? Random.secure();

    // 32 random bytes -> 43 base64url characters without padding
    final verifierBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final codeVerifier = base64UrlEncode(verifierBytes).replaceAll('=', '');

    // SHA-256 of ASCII codeVerifier
    final challengeHash = sha256.convert(ascii.encode(codeVerifier));
    final codeChallenge = base64UrlEncode(challengeHash.bytes).replaceAll('=', '');

    // 16 random bytes for the CSRF state/nonce parameter
    final stateBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final state = base64UrlEncode(stateBytes).replaceAll('=', '');

    return PkcePair(
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
      state: state,
    );
  }
}

/// How the authorization code travels back to the app.
enum OAuthRedirectMode {
  /// Through the instance's own `/auth/oauth-propagator/callback`: no third
  /// party sees the code, and the redirect URI is already a trusted domain.
  instancePropagator,

  /// Through the HTTPS bouncer page that forwards to the custom scheme.
  /// Required when the instance cannot redirect to a custom scheme.
  httpsBouncer,
}

/// Everything that must survive between [OAuthPkceService.beginAuthorization]
/// and [OAuthPkceService.completeAuthorization].
@immutable
class OAuthAuthorizationRequest {
  final String instanceUrl;
  final String clientId;
  final Uri url;
  final String redirectUri;
  final PkcePair pkce;
  final OAuthRedirectMode mode;

  /// Exact `state` value the provider is expected to echo back.
  final String expectedState;

  /// Set in [OAuthRedirectMode.instancePropagator]: the propagator forwards the
  /// nonce it received inside the state URL to the custom-scheme callback.
  final String? expectedNonce;

  const OAuthAuthorizationRequest({
    required this.instanceUrl,
    required this.clientId,
    required this.url,
    required this.redirectUri,
    required this.pkce,
    required this.mode,
    required this.expectedState,
    this.expectedNonce,
  });

  bool get usesInstancePropagator =>
      mode == OAuthRedirectMode.instancePropagator;
}

typedef WebAuthLauncher = Future<String> Function({
  required String url,
  required String callbackUrlScheme,
});

/// Service managing the OAuth 2.0 PKCE flow with the system browser.
///
/// Two redirect strategies are supported, chosen from what the instance
/// advertises (see [resolveRedirectMode]):
///
/// * [OAuthRedirectMode.instancePropagator] — Twenty's own propagator turns the
///   redirect into a 302 to `pocketcrm://oauth/callback`.
/// * [OAuthRedirectMode.httpsBouncer] — an HTTPS bouncer page configured on the
///   OAuth application forwards to the same custom scheme.
///
/// The flow is split so the authorization step and the code exchange can be
/// driven (and tested) independently.
class OAuthPkceService {
  static const String defaultCallbackScheme = AppConfig.oauthCallbackScheme;

  /// HTTPS fallback callback; must be registered on the OAuth application when
  /// the instance propagator cannot be used.
  static const String defaultRedirectUri = AppConfig.oauthBouncerRedirectUri;

  /// Metadata is fetched once per instance per process: the screen reads it on
  /// open, the flow reuses it.
  static final Map<String, OAuthServerMetadata> _metadataCache = {};

  final AuthService _authService;
  final OAuthTokenClient _tokenClient;
  final OAuthClientStore _clientStore;
  final WebAuthLauncher _webAuthLauncher;

  OAuthPkceService({
    required StorageService storageService,
    required AuthService authService,
    http.Client? httpClient,
    OAuthTokenClient? tokenClient,
    OAuthClientStore? clientStore,
    WebAuthLauncher? webAuthLauncher,
  })  : _authService = authService,
        _tokenClient = tokenClient ?? OAuthTokenClient(httpClient: httpClient),
        _clientStore = clientStore ?? OAuthClientStore(storageService),
        _webAuthLauncher = webAuthLauncher ?? _openSystemBrowser;

  /// Opens the authorization page in the system browser.
  ///
  /// `preferEphemeral: false` shares existing browser sessions (such as active
  /// Google accounts or an already logged-in Twenty CRM web session), enabling
  /// true Single Sign-On and allowing returning users to immediately see the
  /// consent screen without repeating credentials or landing on the workspace
  /// dashboard.
  static Future<String> _openSystemBrowser({
    required String url,
    required String callbackUrlScheme,
  }) =>
      FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: callbackUrlScheme,
        options: const FlutterWebAuth2Options(preferEphemeral: false),
      );

  // ---------------------------------------------------------------------------
  // Client credentials (per instance)
  // ---------------------------------------------------------------------------

  /// Returns the client id previously stored for [instanceUrl], migrating the
  /// legacy global slot when found.
  Future<String?> getSavedClientId(String instanceUrl) =>
      _clientStore.readClientId(instanceUrl);

  Future<String?> getSavedClientSecret(String instanceUrl) =>
      _clientStore.readClientSecret(instanceUrl);

  /// Persists the credentials the flow should reuse for [instanceUrl].
  Future<void> saveClientCredentials(
    String instanceUrl, {
    required String clientId,
    String? clientSecret,
  }) =>
      _clientStore.saveClient(
        instanceUrl,
        clientId: clientId,
        clientSecret: clientSecret,
      );

  /// Clears stored client credentials for [instanceUrl].
  Future<void> clearSavedClient(String instanceUrl) =>
      _clientStore.clearClient(instanceUrl);

  /// Looks up a shared client ID from the public registry for [instanceUrl].
  ///
  /// Returns null when nothing is registered, when the registry is unreachable
  /// or when the feature is disabled (`--dart-define=OAUTH_REGISTRY_URL=`).
  Future<String?> fetchSharedClientId(String instanceUrl) =>
      _tokenClient.fetchSharedClientId(instanceUrl: instanceUrl);

  /// Client id the registry served but this instance refused, if any.
  ///
  /// Without this marker a stale registry entry would be re-offered on every
  /// attempt and the sign-in would loop through the same error.
  Future<String?> rejectedSharedClientId(String instanceUrl) =>
      _clientStore.readRejectedClientId(instanceUrl);

  /// Remembers that a registry-served [clientId] does not work on the instance.
  Future<void> markSharedClientIdRejected(
    String instanceUrl,
    String clientId,
  ) =>
      _clientStore.saveRejectedClientId(instanceUrl, clientId);

  /// Publishes [clientId] to the shared registry, at most once per instance.
  ///
  /// Sharing an OAuth client id is a convenience for teammates, never a
  /// requirement for signing in: callers fire-and-forget the result.
  Future<bool> publishSharedClientId(
    String instanceUrl,
    String clientId,
  ) async {
    if (await _clientStore.readPublishedClientId(instanceUrl) == clientId) {
      return true;
    }

    final published = await _tokenClient.registerSharedClientId(
      instanceUrl: instanceUrl,
      clientId: clientId,
    );
    if (published) {
      await _clientStore.savePublishedClientId(instanceUrl, clientId);
    }
    return published;
  }


  // ---------------------------------------------------------------------------
  // Instance capabilities
  // ---------------------------------------------------------------------------

  /// Drops the cached discovery results.
  ///
  /// Needed by tests (the cache is static) and after an instance change.
  @visibleForTesting
  static void clearMetadataCache() => _metadataCache.clear();

  static String normalizeBaseUrl(String instanceUrl) =>
      OAuthTokenClient.normalizeBaseUrl(instanceUrl);

  /// Reads (and caches) the instance capabilities.
  ///
  /// A null result means "unknown": the instance did not answer with a usable
  /// discovery document, so callers must fall back to the legacy defaults.
  Future<OAuthServerMetadata?> fetchServerMetadata(
    String instanceUrl, {
    bool forceRefresh = false,
  }) async {
    final key = normalizeBaseUrl(instanceUrl);

    if (!forceRefresh) {
      final cached = _metadataCache[key];
      if (cached != null) return cached;
    }

    final metadata = await _tokenClient.fetchMetadata(key);
    if (metadata != null) _metadataCache[key] = metadata;
    return metadata;
  }

  /// Picks the callback strategy for [instanceUrl].
  ///
  /// The propagator only forwards to an arbitrary callback URL (custom schemes
  /// included) while multi-workspace is disabled, so anything else — including
  /// an unknown capability — falls back to the HTTPS bouncer.
  Future<OAuthRedirectMode> resolveRedirectMode(
    String instanceUrl, {
    OAuthServerMetadata? metadata,
  }) async {
    final meta = metadata ?? await fetchServerMetadata(instanceUrl);
    if (meta == null || meta.isMultiWorkspaceEnabled != false) {
      return OAuthRedirectMode.httpsBouncer;
    }
    return OAuthRedirectMode.instancePropagator;
  }

  /// Redirect URI served by the instance itself (propagator mode).
  String propagatorRedirectUri(String instanceUrl) =>
      '${normalizeBaseUrl(instanceUrl)}${AppConfig.oauthPropagatorPath}';

  /// The redirect URI the OAuth application must be configured with.
  Future<String> effectiveRedirectUri(
    String instanceUrl, {
    OAuthRedirectMode? mode,
  }) async {
    final effectiveMode = mode ?? await resolveRedirectMode(instanceUrl);
    return effectiveMode == OAuthRedirectMode.instancePropagator
        ? propagatorRedirectUri(instanceUrl)
        : defaultRedirectUri;
  }

  Future<bool> supportsDynamicRegistration(String instanceUrl) async =>
      (await fetchServerMetadata(instanceUrl))?.supportsDynamicRegistration ??
      false;

  /// Attempts Dynamic Client Registration (RFC 7591) when the instance
  /// advertises a `registration_endpoint`.
  ///
  /// Returns null on instances without it — for example self-hosted Twenty,
  /// where `POST /oauth/register` answers 404. The credentials are *not*
  /// persisted here: the caller decides what to store.
  Future<OAuthClientCredentials?> tryAutoRegisterClient(
    String instanceUrl, {
    String redirectUri = defaultRedirectUri,
  }) async {
    final metadata = await fetchServerMetadata(instanceUrl);
    if (metadata == null || !metadata.supportsDynamicRegistration) return null;

    return _tokenClient.registerClient(
      instanceUrl: instanceUrl,
      redirectUri: redirectUri,
    );
  }

  // ---------------------------------------------------------------------------
  // Authorization
  // ---------------------------------------------------------------------------

  /// Builds the authorization URL plus the state the callback must echo.
  OAuthAuthorizationRequest beginAuthorization({
    required String instanceUrl,
    required String clientId,
    OAuthRedirectMode mode = OAuthRedirectMode.httpsBouncer,
    String? redirectUri,
    List<String> scopes = AppConfig.oauthScopes,
  }) {
    final pkce = PkcePair.generate();
    final usesPropagator = mode == OAuthRedirectMode.instancePropagator;
    final effectiveRedirect = redirectUri ??
        (usesPropagator
            ? propagatorRedirectUri(instanceUrl)
            : defaultRedirectUri);

    // With the propagator the `state` carries the custom-scheme callback, so the
    // nonce it embeds (and that Twenty forwards back) proves the callback
    // belongs to this request. Otherwise the raw state is echoed.
    final expectedState = usesPropagator
        ? '$defaultCallbackScheme://oauth/callback?nonce=${pkce.state}'
        : pkce.state;

    return OAuthAuthorizationRequest(
      instanceUrl: instanceUrl,
      clientId: clientId,
      url: buildAuthorizationUri(
        instanceUrl: instanceUrl,
        clientId: clientId,
        pkce: pkce,
        redirectUri: effectiveRedirect,
        scopes: scopes,
        state: expectedState,
      ),
      redirectUri: effectiveRedirect,
      pkce: pkce,
      mode: mode,
      expectedState: expectedState,
      expectedNonce: usesPropagator ? pkce.state : null,
    );
  }

  /// Builds the authorization URL, using the discovered endpoint when known.
  Uri buildAuthorizationUri({
    required String instanceUrl,
    required String clientId,
    required PkcePair pkce,
    String redirectUri = defaultRedirectUri,
    List<String> scopes = AppConfig.oauthScopes,
    String? state,
    Uri? authorizationEndpoint,
  }) {
    final endpoint = authorizationEndpoint ??
        Uri.parse(
          '${normalizeBaseUrl(instanceUrl)}${OAuthTokenClient.authorizationPath}',
        );

    return endpoint.replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'code_challenge': pkce.codeChallenge,
        'code_challenge_method': 'S256',
        'state': state ?? pkce.state,
        'scope': scopes.join(' '),
      },
    );
  }

  /// Validates the callback and exchanges the code for tokens, persisting the
  /// session through [AuthService].
  Future<void> completeAuthorization({
    required OAuthAuthorizationRequest request,
    required String callbackResultUrl,
    String? clientSecret,
    Uri? tokenEndpoint,
  }) async {
    final code = _authorizationCodeFrom(request, callbackResultUrl);
    final secret = clientSecret ??
        await _clientStore.readClientSecret(request.instanceUrl);

    final tokens = await _tokenClient.exchangeAuthorizationCode(
      instanceUrl: request.instanceUrl,
      clientId: request.clientId,
      code: code,
      codeVerifier: request.pkce.codeVerifier,
      redirectUri: request.redirectUri,
      clientSecret: secret,
      tokenEndpoint: tokenEndpoint,
    );

    await _persistSession(request.instanceUrl, tokens);
    await _clientStore.saveClient(
      request.instanceUrl,
      clientId: request.clientId,
      clientSecret: secret,
    );
    // The credentials work: forget any earlier rejection of a registry entry.
    await _clientStore.clearRejectedClientId(request.instanceUrl);
    // Asynchronously publish the validated client ID to the shared registry
    // so team members connecting to the same instance can share it.
    unawaited(
      publishSharedClientId(request.instanceUrl, request.clientId),
    );
  }

  /// Runs the whole flow: resolve the redirect strategy, open the browser,
  /// exchange the code and persist the session.
  Future<void> loginWithOAuth({
    required String instanceUrl,
    required String clientId,
    String? clientSecret,
    String? redirectUri,
    OAuthRedirectMode? mode,
  }) async {
    final metadata = await fetchServerMetadata(instanceUrl);
    final effectiveMode =
        mode ?? await resolveRedirectMode(instanceUrl, metadata: metadata);

    final request = beginAuthorization(
      instanceUrl: instanceUrl,
      clientId: clientId,
      mode: effectiveMode,
      redirectUri: redirectUri,
    );

    final callbackResultUrl = await _webAuthLauncher(
      url: request.url.toString(),
      callbackUrlScheme: defaultCallbackScheme,
    );

    await completeAuthorization(
      request: request,
      callbackResultUrl: callbackResultUrl,
      clientSecret: clientSecret,
      tokenEndpoint: metadata?.tokenEndpoint,
    );
  }

  /// Exchanges an authorization code for tokens at `/oauth/token`.
  ///
  /// Kept as a single-purpose entry point (the UI drives the browser itself when
  /// it needs the authorization URL).
  Future<OAuthTokens> exchangeCode({
    required String instanceUrl,
    required String clientId,
    required String code,
    required String codeVerifier,
    String redirectUri = defaultRedirectUri,
    String? clientSecret,
    Uri? tokenEndpoint,
  }) =>
      _tokenClient.exchangeAuthorizationCode(
        instanceUrl: instanceUrl,
        clientId: clientId,
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
        clientSecret: clientSecret,
        tokenEndpoint: tokenEndpoint,
      );

  /// Validates the callback URL and returns the authorization code.
  ///
  /// Rejects `?error=` payloads (denied consent, expired request) and enforces
  /// the CSRF check: the provider must echo either the state we sent, or — in
  /// propagator mode — the nonce embedded in it.
  String _authorizationCodeFrom(
    OAuthAuthorizationRequest request,
    String callbackResultUrl,
  ) {
    final callbackUri = Uri.parse(callbackResultUrl);

    final error = callbackUri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      final description = callbackUri.queryParameters['error_description'];
      throw OAuthException(
        (description == null || description.isEmpty) ? error : description,
        errorCode: error,
      );
    }

    final stateMatches =
        callbackUri.queryParameters['state'] == request.expectedState;
    final nonceMatches = request.expectedNonce != null &&
        callbackUri.queryParameters['nonce'] == request.expectedNonce;

    if (!stateMatches && !nonceMatches) {
      throw OAuthException('State mismatch in OAuth callback (CSRF detected)');
    }

    final code = callbackUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw OAuthException('Authorization code missing from callback');
    }

    return code;
  }

  Future<void> _persistSession(String instanceUrl, OAuthTokens tokens) async {
    final expiresAt = DateTime.now()
        .toUtc()
        .add(Duration(seconds: tokens.expiresIn))
        .toIso8601String();

    await _authService.loginWithDirectTokens(
      instanceUrl: instanceUrl,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      authMethod: 'sso',
      expiresAt: expiresAt,
    );
  }
}

