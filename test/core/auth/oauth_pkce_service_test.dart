import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/core/auth/oauth_client_store.dart';
import 'package:pocketcrm/core/auth/oauth_pkce_service.dart';

import 'auth_service_test.mocks.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<void> loginWithDirectTokens({
    required String instanceUrl,
    required String accessToken,
    required String refreshToken,
    required String authMethod,
    String? expiresAt,
  }) =>
      (super.noSuchMethod(
        Invocation.method(#loginWithDirectTokens, [], {
          #instanceUrl: instanceUrl,
          #accessToken: accessToken,
          #refreshToken: refreshToken,
          #authMethod: authMethod,
          #expiresAt: expiresAt,
        }),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);
}

void main() {
  late MockStorageService mockStorage;
  late MockAuthService mockAuthService;

  setUp(() {
    mockStorage = MockStorageService();
    mockAuthService = MockAuthService();
    // The discovery cache is static: without resetting it, one test's metadata
    // leaks into the next one.
    OAuthPkceService.clearMetadataCache();
  });

  group('PkcePair', () {
    test('generates valid code_verifier and code_challenge', () {
      final pkce = PkcePair.generate();

      expect(pkce.codeVerifier.length, greaterThanOrEqualTo(43));
      expect(pkce.codeChallenge.length, greaterThanOrEqualTo(43));
      expect(pkce.state.length, greaterThanOrEqualTo(16));

      // Verifier and challenge must not contain URL-unsafe characters or padding
      expect(pkce.codeVerifier.contains('='), isFalse);
      expect(pkce.codeChallenge.contains('='), isFalse);
      expect(pkce.codeVerifier.contains('+'), isFalse);
      expect(pkce.codeChallenge.contains('+'), isFalse);
      expect(pkce.codeVerifier.contains('/'), isFalse);
      expect(pkce.codeChallenge.contains('/'), isFalse);
    });
  });

  group('OAuthPkceService', () {
    test('buildAuthorizationUri creates expected Twenty CRM authorize URL', () {
      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
      );

      final pkce = PkcePair.generate();
      final uri = service.buildAuthorizationUri(
        instanceUrl: 'https://twentycrm.example.com/',
        clientId: 'test-client-id-123',
        pkce: pkce,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'twentycrm.example.com');
      expect(uri.path, '/authorize');
      expect(uri.queryParameters['client_id'], 'test-client-id-123');
      expect(uri.queryParameters['redirect_uri'],
          'https://luciosoft-twentymobilecrm.web.app/oauth/callback');
      expect(uri.queryParameters['response_type'], 'code');
      expect(uri.queryParameters['code_challenge'], pkce.codeChallenge);
      expect(uri.queryParameters['code_challenge_method'], 'S256');
      expect(uri.queryParameters['state'], pkce.state);
      expect(uri.queryParameters['scope'], 'api profile');
    });

    test('tryAutoRegisterClient registers when the instance advertises it', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/.well-known/oauth-authorization-server') {
          return http.Response(
            jsonEncode({
              'authorization_endpoint': 'https://twentycrm.example.com/authorize',
              'token_endpoint': 'https://twentycrm.example.com/oauth/token',
              'registration_endpoint': 'https://twentycrm.example.com/oauth/register',
            }),
            200,
          );
        }
        if (request.url.path == '/oauth/register') {
          return http.Response(
            jsonEncode({'client_id': 'auto-generated-id-456'}),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
      );

      final credentials =
          await service.tryAutoRegisterClient('https://twentycrm.example.com');

      expect(credentials?.clientId, 'auto-generated-id-456');
      // Registration stays side-effect free: the caller decides what to persist.
      verifyNever(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')));
    });

    test('tryAutoRegisterClient returns null without even calling /oauth/register when the discovery document has no registration_endpoint (Twenty v1.19)', () async {
      var registerCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/.well-known/oauth-authorization-server') {
          return http.Response(
            jsonEncode({
              'authorization_endpoint': 'https://twentycrm.example.com/authorize',
              'token_endpoint': 'https://twentycrm.example.com/oauth/token',
              'grant_types_supported': ['authorization_code', 'refresh_token'],
              'code_challenge_methods_supported': ['S256'],
            }),
            200,
          );
        }
        if (request.url.path == '/oauth/register') {
          registerCalls++;
          return http.Response('Cannot POST /oauth/register', 404);
        }
        return http.Response('Not Found', 404);
      });

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
      );

      expect(
        await service.tryAutoRegisterClient('https://twentycrm.example.com'),
        isNull,
      );
      expect(registerCalls, 0);
    });

    test('resolveRedirectMode uses the instance propagator when multi-workspace is disabled', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/.well-known/oauth-authorization-server') {
          return http.Response(
            jsonEncode({
              'authorization_endpoint': 'https://twentycrm.example.com/authorize',
              'token_endpoint': 'https://twentycrm.example.com/oauth/token',
            }),
            200,
          );
        }
        if (request.url.path == '/client-config') {
          return http.Response(jsonEncode({'isMultiWorkspaceEnabled': false}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
      );

      expect(
        await service.resolveRedirectMode('https://twentycrm.example.com'),
        OAuthRedirectMode.instancePropagator,
      );
      expect(
        await service.effectiveRedirectUri('https://twentycrm.example.com'),
        'https://twentycrm.example.com/auth/oauth-propagator/callback',
      );
    });

    test('resolveRedirectMode falls back to the https bouncer when capabilities are unknown', () async {
      final mockClient = MockClient((_) async => http.Response('Not Found', 404));

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
      );

      expect(
        await service.resolveRedirectMode('https://twentycrm.example.com'),
        OAuthRedirectMode.httpsBouncer,
      );
      expect(
        await service.effectiveRedirectUri('https://twentycrm.example.com'),
        OAuthPkceService.defaultRedirectUri,
      );
    });

    test('exchangeCode succeeds on 200 response from /oauth/token', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/oauth/token') {
          final body = jsonDecode(request.body);
          expect(body['grant_type'], 'authorization_code');
          expect(body['client_id'], 'test-client');
          expect(body['code'], 'test-code');
          expect(body['code_verifier'], 'test-verifier');
          return http.Response(
            jsonEncode({
              'access_token': 'mock-access-token',
              'refresh_token': 'mock-refresh-token',
              'expires_in': 7200,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
      );

      final tokens = await service.exchangeCode(
        instanceUrl: 'https://twentycrm.example.com',
        clientId: 'test-client',
        code: 'test-code',
        codeVerifier: 'test-verifier',
      );

      expect(tokens.accessToken, 'mock-access-token');
      expect(tokens.refreshToken, 'mock-refresh-token');
      expect(tokens.expiresIn, 7200);
    });

    test('loginWithOAuth completes the end-to-end flow with state validation', () async {
      late String capturedAuthUrl;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/oauth/token') {
          return http.Response(
            jsonEncode({
              'access_token': 'flow-access-token',
              'refresh_token': 'flow-refresh-token',
              'expires_in': 3600,
            }),
            200,
          );
        }
        return http.Response('Error', 500);
      });

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
        webAuthLauncher: ({required url, required callbackUrlScheme}) async {
          capturedAuthUrl = url;
          final uri = Uri.parse(url);
          final state = uri.queryParameters['state']!;
          return '$callbackUrlScheme://oauth/callback?code=mock_auth_code_123&state=$state';
        },
      );

      await service.loginWithOAuth(
        instanceUrl: 'https://twentycrm.example.com',
        clientId: 'my-custom-client-id',
      );

      expect(capturedAuthUrl, contains('https://twentycrm.example.com/authorize'));
      // The client id is stored per instance, not in one global slot.
      verify(mockStorage.write(
        key: 'oauth_client_id_twentycrm_example_com',
        value: 'my-custom-client-id',
      )).called(1);
      verify(mockAuthService.loginWithDirectTokens(
        instanceUrl: 'https://twentycrm.example.com',
        accessToken: 'flow-access-token',
        refreshToken: 'flow-refresh-token',
        authMethod: 'sso',
        expiresAt: anyNamed('expiresAt'),
      )).called(1);
    });

    test('loginWithOAuth throws on state mismatch (CSRF prevention)', () async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
        webAuthLauncher: ({required url, required callbackUrlScheme}) async {
          return '$callbackUrlScheme://oauth/callback?code=code123&state=tampered_state';
        },
      );

      expect(
        () => service.loginWithOAuth(
          instanceUrl: 'https://twentycrm.example.com',
          clientId: 'client-123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('State mismatch'),
        )),
      );
    });

    test('loginWithOAuth uses the instance propagator when multi-workspace is disabled', () async {
      late Uri capturedAuthUri;

      final mockClient = MockClient((request) async {
        switch (request.url.path) {
          case '/.well-known/oauth-authorization-server':
            return http.Response(
              jsonEncode({
                'authorization_endpoint': 'https://twentycrm.example.com/authorize',
                'token_endpoint': 'https://twentycrm.example.com/oauth/token',
              }),
              200,
            );
          case '/client-config':
            return http.Response(
              jsonEncode({'isMultiWorkspaceEnabled': false}),
              200,
            );
          case '/oauth/token':
            return http.Response(
              jsonEncode({
                'access_token': 'prop-access',
                'refresh_token': 'prop-refresh',
                'expires_in': 3600,
              }),
              200,
            );
          default:
            return http.Response('Not Found', 404);
        }
      });

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
        webAuthLauncher: ({required url, required callbackUrlScheme}) async {
          capturedAuthUri = Uri.parse(url);
          // Replays what Twenty's propagator answers (verified against v1.19):
          // a 302 to the custom scheme carrying the nonce *and* the state.
          final state = capturedAuthUri.queryParameters['state']!;
          final nonce = Uri.parse(state).queryParameters['nonce']!;
          return '$callbackUrlScheme://oauth/callback?nonce=$nonce&code=prop_code'
              '&state=${Uri.encodeComponent(state)}';
        },
      );

      await service.loginWithOAuth(
        instanceUrl: 'https://twentycrm.example.com',
        clientId: 'client-1',
      );

      expect(
        capturedAuthUri.queryParameters['redirect_uri'],
        'https://twentycrm.example.com/auth/oauth-propagator/callback',
      );
      expect(
        capturedAuthUri.queryParameters['state'],
        startsWith('pocketcrm://oauth/callback?nonce='),
      );
      verify(mockAuthService.loginWithDirectTokens(
        instanceUrl: 'https://twentycrm.example.com',
        accessToken: 'prop-access',
        refreshToken: 'prop-refresh',
        authMethod: 'sso',
        expiresAt: anyNamed('expiresAt'),
      )).called(1);
    });

    test('propagator callbacks with a forged nonce are rejected', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/.well-known/oauth-authorization-server') {
          return http.Response(
            jsonEncode({
              'authorization_endpoint': 'https://twentycrm.example.com/authorize',
              'token_endpoint': 'https://twentycrm.example.com/oauth/token',
            }),
            200,
          );
        }
        if (request.url.path == '/client-config') {
          return http.Response(jsonEncode({'isMultiWorkspaceEnabled': false}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
        webAuthLauncher: ({required url, required callbackUrlScheme}) async =>
            '$callbackUrlScheme://oauth/callback?nonce=forged&code=code123',
      );

      expect(
        () => service.loginWithOAuth(
          instanceUrl: 'https://twentycrm.example.com',
          clientId: 'client-1',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('State mismatch'),
        )),
      );
    });

    test('a denied consent surfaces the provider error_description', () async {
      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: MockClient((_) async => http.Response('Not Found', 404)),
        webAuthLauncher: ({required url, required callbackUrlScheme}) async =>
            '$callbackUrlScheme://oauth/callback?error=access_denied'
            '&error_description=The%20user%20denied%20access',
      );

      expect(
        () => service.loginWithOAuth(
          instanceUrl: 'https://twentycrm.example.com',
          clientId: 'client-1',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          'The user denied access',
        )),
      );
    });

    test('a callback without an authorization code is rejected', () async {
      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: MockClient((_) async => http.Response('Not Found', 404)),
        webAuthLauncher: ({required url, required callbackUrlScheme}) async {
          final state = Uri.parse(url).queryParameters['state']!;
          return '$callbackUrlScheme://oauth/callback?state=$state';
        },
      );

      expect(
        () => service.loginWithOAuth(
          instanceUrl: 'https://twentycrm.example.com',
          clientId: 'client-1',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Authorization code missing'),
        )),
      );
    });
  });

  group('shared registry', () {
    test('publishes the client id once per instance', () async {
      var posts = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/oauth-client')) {
          posts++;
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Not Found', 404);
      });
      when(mockStorage.read(
        key: OAuthClientStore.publishedClientIdKey('https://crm.example.com'),
      )).thenAnswer((_) async => null);

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: mockClient,
      );

      expect(
        await service.publishSharedClientId('https://crm.example.com', 'client-1'),
        isTrue,
      );
      expect(posts, 1);
      verify(mockStorage.write(
        key: OAuthClientStore.publishedClientIdKey('https://crm.example.com'),
        value: 'client-1',
      )).called(1);

      // Already published: the second call must not hit the registry again.
      when(mockStorage.read(
        key: OAuthClientStore.publishedClientIdKey('https://crm.example.com'),
      )).thenAnswer((_) async => 'client-1');

      expect(
        await service.publishSharedClientId('https://crm.example.com', 'client-1'),
        isTrue,
      );
      expect(posts, 1);
    });

    test('does not remember a failed publication', () async {
      when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
        httpClient: MockClient((_) async => http.Response('Error', 500)),
      );

      expect(
        await service.publishSharedClientId('https://crm.example.com', 'client-1'),
        isFalse,
      );
      verifyNever(mockStorage.write(
        key: OAuthClientStore.publishedClientIdKey('https://crm.example.com'),
        value: anyNamed('value'),
      ));
    });

    test('exposes and records the rejected shared client id', () async {
      when(mockStorage.read(
        key: OAuthClientStore.rejectedClientIdKey('https://crm.example.com'),
      )).thenAnswer((_) async => 'rejected-id');

      final service = OAuthPkceService(
        storageService: mockStorage,
        authService: mockAuthService,
      );

      expect(
        await service.rejectedSharedClientId('https://crm.example.com'),
        'rejected-id',
      );

      await service.markSharedClientIdRejected(
        'https://crm.example.com',
        'rejected-id',
      );
      verify(mockStorage.write(
        key: OAuthClientStore.rejectedClientIdKey('https://crm.example.com'),
        value: 'rejected-id',
      )).called(1);
    });
  });
}
