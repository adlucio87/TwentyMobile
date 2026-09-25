import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
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
      verify(mockStorage.delete(key: 'is_demo_mode')).called(1);
      verify(mockStorage.delete(key: 'pending_2fa_login_token')).called(1);
      
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
}
