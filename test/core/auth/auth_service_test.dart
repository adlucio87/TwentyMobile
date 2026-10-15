import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/core/auth/oauth_token_client.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<StorageService>()])
void main() {
  late MockStorageService mockStorage;
  late AuthService authService;

  setUp(() {
    mockStorage = MockStorageService();
    authService = AuthService(mockStorage);
    SharedPreferences.setMockInitialValues({});
  });

  group('loginWithApiKey', () {
    test('writes api_token and auth_method to storage', () async {
      await authService.loginWithApiKey('https://example.com', 'test_api_key');

      verify(mockStorage.write(key: 'api_token', value: 'test_api_key')).called(1);
      verify(mockStorage.write(key: 'auth_method', value: 'api_key')).called(1);
    });
  });

  group('logout', () {
    test('deletes all expected keys from storage and clears shared preferences', () async {
      SharedPreferences.setMockInitialValues({'token_expires_at': '2025-01-01T00:00:00Z'});
      
      await authService.logout();

      verify(mockStorage.delete(key: 'api_token')).called(1);
      verify(mockStorage.delete(key: 'refresh_token')).called(1);
      verify(mockStorage.delete(key: 'token_expires_at')).called(1);
      verify(mockStorage.delete(key: 'auth_method')).called(1);
      verify(mockStorage.delete(key: 'auth_email')).called(1);
      verify(mockStorage.delete(key: 'auth_password')).called(1);
      verify(mockStorage.delete(key: 'user_first_name')).called(1);
      verify(mockStorage.delete(key: 'user_last_name')).called(1);
      verify(mockStorage.delete(key: 'api_key_member_id')).called(1);
      verify(mockStorage.delete(key: 'api_key_member_name')).called(1);
      verify(mockStorage.delete(key: 'is_demo_mode')).called(1);
      verify(mockStorage.delete(key: 'pending_2fa_login_token')).called(1);
      // Legacy global OAuth client id (now stored per instance).
      verify(mockStorage.delete(key: 'oauth_client_id')).called(1);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('token_expires_at'), isFalse);
    });
  });

  group('isTokenExpired', () {
    test('returns false when token expires in 1 hour', () async {
      final futureTime = DateTime.now().toUtc().add(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({'token_expires_at': futureTime.toIso8601String()});

      final isExpired = await authService.isTokenExpired();
      expect(isExpired, isFalse);
    });

    test('returns true when token expires in 2 minutes', () async {
      final futureTime = DateTime.now().toUtc().add(const Duration(minutes: 2));
      SharedPreferences.setMockInitialValues({'token_expires_at': futureTime.toIso8601String()});

      final isExpired = await authService.isTokenExpired();
      expect(isExpired, isTrue);
    });

    test('returns true when token expired 1 hour ago', () async {
      final pastTime = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({'token_expires_at': pastTime.toIso8601String()});

      final isExpired = await authService.isTokenExpired();
      expect(isExpired, isTrue);
    });

    test('returns false when no token is stored', () async {
      SharedPreferences.setMockInitialValues({});

      final isExpired = await authService.isTokenExpired();
      expect(isExpired, isFalse);
    });
  });

  group('clearPending2FA', () {
    test('deletes pending_2fa_login_token from storage', () async {
      await authService.clearPending2FA();

      verify(mockStorage.delete(key: 'pending_2fa_login_token')).called(1);
    });
  });

  group('refreshAccessToken mutex', () {
    test('concurrent calls to refreshAccessToken execute the underlying logic only once', () async {
      // Setup mock to return null for instanceUrl/refreshToken to hit the logout fallback (returns false)
      when(mockStorage.read(key: 'instance_url')).thenAnswer((_) async => null);
      when(mockStorage.read(key: 'refresh_token')).thenAnswer((_) async => null);

      // Call refreshAccessToken concurrently
      final future1 = authService.refreshAccessToken();
      final future2 = authService.refreshAccessToken();
      
      final results = await Future.wait([future1, future2]);

      // Both should return false as per logout fallback
      expect(results[0], isFalse);
      expect(results[1], isFalse);

      // Verify that underlying storage calls only happened once because the second call awaited the first future
      verify(mockStorage.read(key: 'instance_url')).called(1);
      verify(mockStorage.read(key: 'refresh_token')).called(1);
    });
  });

  group('loginWithDirectTokens', () {
    test('writes tokens, auth_method and expires_at to storage and shared preferences', () async {
      await authService.loginWithDirectTokens(
        instanceUrl: 'https://example.com',
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        expiresAt: '2026-12-31T23:59:59Z',
        authMethod: 'sso',
      );

      verify(mockStorage.write(key: 'api_token', value: 'test_access_token')).called(1);
      verify(mockStorage.write(key: 'refresh_token', value: 'test_refresh_token')).called(1);
      verify(mockStorage.write(key: 'token_expires_at', value: '2026-12-31T23:59:59Z')).called(1);
      verify(mockStorage.write(key: 'auth_method', value: 'sso')).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token_expires_at'), '2026-12-31T23:59:59Z');
    });
  });

  // Regression tests for the OAuth (SSO/PKCE) session renewal: it used to go
  // through the `renewToken` mutation, which cannot renew an OAuth access token,
  // so every OAuth session was silently logged out after ~1h.
  group('refreshAccessToken for OAuth sessions', () {
    AuthService buildService(http.Client httpClient) => AuthService(
          mockStorage,
          oauthTokenClient: OAuthTokenClient(httpClient: httpClient),
        );

    void givenOAuthSession({
      String instanceUrl = 'https://crm.example.com',
      String? clientId = 'client-1',
      String? clientSecret,
      String refreshToken = 'old-refresh',
    }) {
      when(mockStorage.read(key: 'instance_url'))
          .thenAnswer((_) async => instanceUrl);
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => refreshToken);
      when(mockStorage.read(key: 'auth_method')).thenAnswer((_) async => 'sso');
      when(mockStorage.read(key: 'oauth_client_id_crm_example_com'))
          .thenAnswer((_) async => clientId);
      when(mockStorage.read(key: 'oauth_client_secret_crm_example_com'))
          .thenAnswer((_) async => clientSecret);
    }

    test('renews the session with grant_type=refresh_token and stores the rotated tokens',
        () async {
      givenOAuthSession();

      late Map<String, dynamic> sentBody;
      final service = buildService(
        MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          expect(request.url.path, '/oauth/token');
          return http.Response(
            jsonEncode({
              'access_token': 'fresh-access',
              'refresh_token': 'rotated-refresh',
              'expires_in': 3600,
            }),
            200,
          );
        }),
      );

      expect(await service.refreshAccessToken(), isTrue);

      expect(sentBody['grant_type'], 'refresh_token');
      expect(sentBody['client_id'], 'client-1');
      expect(sentBody['refresh_token'], 'old-refresh');
      verify(mockStorage.write(key: 'api_token', value: 'fresh-access')).called(1);
      verify(mockStorage.write(key: 'refresh_token', value: 'rotated-refresh'))
          .called(1);
      verify(mockStorage.write(
        key: 'token_expires_at',
        value: anyNamed('value'),
      )).called(1);
      // SSO never falls back to stored email/password credentials.
      verifyNever(mockStorage.read(key: 'auth_email'));
    });

    test('keeps the current refresh token when the server does not rotate it',
        () async {
      givenOAuthSession();

      final service = buildService(
        MockClient(
          (_) async => http.Response(
            jsonEncode({'access_token': 'fresh-access'}),
            200,
          ),
        ),
      );

      expect(await service.refreshAccessToken(), isTrue);

      verify(mockStorage.write(key: 'refresh_token', value: 'old-refresh'))
          .called(1);
    });

    test('sends the stored client secret when the instance issued one',
        () async {
      givenOAuthSession(clientSecret: 'stored-secret');

      late Map<String, dynamic> sentBody;
      final service = buildService(
        MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'access_token': 'a', 'refresh_token': 'r'}),
            200,
          );
        }),
      );

      expect(await service.refreshAccessToken(), isTrue);
      expect(sentBody['client_secret'], 'stored-secret');
    });

    test('logs out when the token endpoint rejects the refresh token', () async {
      givenOAuthSession();

      final service = buildService(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': 'invalid_grant',
              'error_description': 'Refresh token expired',
            }),
            400,
          ),
        ),
      );

      expect(await service.refreshAccessToken(), isFalse);
      verify(mockStorage.delete(key: 'api_token')).called(1);
    });

    test('logs out when no client id is stored for the instance', () async {
      givenOAuthSession(clientId: null);

      var oauthCalls = 0;
      final service = buildService(
        MockClient((_) async {
          oauthCalls++;
          return http.Response('{}', 200);
        }),
      );

      expect(await service.refreshAccessToken(), isFalse);
      expect(oauthCalls, 0);
      verify(mockStorage.delete(key: 'api_token')).called(1);
    });

    test('non-sso sessions never touch the OAuth token endpoint', () async {
      // 127.0.0.1:1 refuses the connection immediately, so the `renewToken`
      // GraphQL path fails fast and deterministically.
      when(mockStorage.read(key: 'instance_url'))
          .thenAnswer((_) async => 'http://127.0.0.1:1');
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refresh-token');
      when(mockStorage.read(key: 'auth_method')).thenAnswer((_) async => 'email');
      when(mockStorage.read(key: 'auth_email')).thenAnswer((_) async => null);
      when(mockStorage.read(key: 'auth_password')).thenAnswer((_) async => null);

      var oauthCalls = 0;
      final service = buildService(
        MockClient((_) async {
          oauthCalls++;
          return http.Response('{}', 200);
        }),
      );

      expect(await service.refreshAccessToken(), isFalse);
      expect(oauthCalls, 0);
    });
  });
}
