import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('Benchmark storage.read multiple times', () async {
    WidgetsFlutterBinding.ensureInitialized();

    Hive.init('/tmp/hive_benchmark');
    final box = await Hive.openBox<String>('benchmark_storage');
    await box.put('instance_url', 'https://example.com');
    await box.put('api_token', 'test_token');

    const secure = FlutterSecureStorage();
    final storage = StorageService(secure, box);

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      await storage.read(key: 'instance_url');
      await storage.read(key: 'api_token');
    }
    stopwatch.stop();
    print('100 reads took ${stopwatch.elapsedMilliseconds} ms');

    await box.close();
  });
}
