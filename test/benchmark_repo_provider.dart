import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('Check if crmRepository is rebuilt', () async {
    WidgetsFlutterBinding.ensureInitialized();

    Hive.init('/tmp/hive_benchmark_repo_provider');
    final box = await Hive.openBox<String>('repo_provider_bench');
    await box.put('instance_url', 'https://example.com');
    await box.put('api_token', 'test_token');

    final container = ProviderContainer(
      overrides: [
        hiveStorageBoxProvider.overrideWithValue(box),
      ],
    );

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      await container.read(crmRepositoryProvider.future);
    }
    stopwatch.stop();
    print('1000 repo reads (no invalidation) took ${stopwatch.elapsedMilliseconds} ms');

    await box.close();
    container.dispose();
  });
}
