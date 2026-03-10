import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('Benchmark CRM Repository', () async {
    WidgetsFlutterBinding.ensureInitialized();

    Hive.init('/tmp/hive_benchmark_crm_repo');
    final box = await Hive.openBox<String>('crm_repo_bench');
    await box.put('instance_url', 'https://example.com');
    await box.put('api_token', 'test_token');

    final container = ProviderContainer(
      overrides: [
        hiveStorageBoxProvider.overrideWithValue(box),
      ],
    );

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      final storage = container.read(storageServiceProvider);
      await storage.read(key: 'instance_url');
      await storage.read(key: 'api_token');
    }
    stopwatch.stop();
    print('100 reads took ${stopwatch.elapsedMilliseconds} ms');

    await box.close();
    container.dispose();
  });
}
