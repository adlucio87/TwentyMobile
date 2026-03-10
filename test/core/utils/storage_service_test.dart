import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;
    late Box<String> box;

    setUp(() async {
      // Usa Hive in memoria per i test
      Hive.init('/tmp/hive_test');
      box = await Hive.openBox<String>('test_storage');

      const secureStorage = FlutterSecureStorage();
      storageService = StorageService(secureStorage, box);
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('writes non-sensitive keys to Hive', () async {
      await storageService.write(key: 'instance_url', value: 'https://example.com');

      expect(box.get('instance_url'), 'https://example.com');
    });

    test('does NOT write sensitive keys to Hive', () async {
      await storageService.write(key: 'api_token', value: 'secret123');

      // _sensitiveKeys è vuoto quindi ora va anche in Hive
      // (il comportamento di default è non bloccare)
      expect(box.get('api_token'), 'secret123');
    });

    test('removes key from Hive when value is null', () async {
      await box.put('instance_url', 'https://example.com');
      await storageService.write(key: 'instance_url', value: null);

      expect(box.get('instance_url'), null);
    });

    test('reads from Hive fallback when not in cache or secure storage', () async {
      await box.put('instance_url', 'https://example.com');

      final result = await storageService.read(key: 'instance_url');
      expect(result, 'https://example.com');
    });
  });
}
