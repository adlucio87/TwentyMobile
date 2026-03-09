import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;
    late SharedPreferences fallback;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fallback = await SharedPreferences.getInstance();

      // We can use a real instance or a mocked one. Since flutter_secure_storage
      // might not work in regular unit test without proper mocking, we'll
      // mock it to ensure it doesn't throw or we can just ignore errors it throws
      // because our focus is testing SharedPreferences fallback behavior.
      const secureStorage = FlutterSecureStorage();
      storageService = StorageService(secureStorage, fallback);
    });

    test('writes non-sensitive keys to fallback', () async {
      await storageService.write(key: 'instance_url', value: 'https://example.com');

      expect(fallback.getString('instance_url'), 'https://example.com');
    });

    test('does NOT write sensitive keys to fallback', () async {
      await storageService.write(key: 'api_token', value: 'secret123');

      // Should be null in the fallback SharedPreferences
      expect(fallback.getString('api_token'), null);
    });

    test('removes sensitive key from fallback when value is null', () async {
      // Simulate leaked key manually
      await fallback.setString('api_token', 'old_leaked_token');
      expect(fallback.getString('api_token'), 'old_leaked_token');

      // Writing null should remove it
      await storageService.write(key: 'api_token', value: null);

      expect(fallback.getString('api_token'), null);
    });

    test('does NOT read sensitive keys from fallback', () async {
      // Manually insert into fallback
      await fallback.setString('api_token', 'leaked_token');

      // Read should ignore fallback
      final result = await storageService.read(key: 'api_token');
      expect(result, null);
    });
  });
}
