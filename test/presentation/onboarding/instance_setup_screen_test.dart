import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';
import 'package:pocketcrm/presentation/onboarding/instance_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/localized_app.dart';

class _MockStorageService extends Fake implements StorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('InstanceSetupScreen renders input and action buttons', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(_MockStorageService()),
        ],
        child: localizedTestApp(home: const InstanceSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Try the demo'), findsOneWidget);
  });

  testWidgets('InstanceSetupScreen validates empty URL input', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(_MockStorageService()),
        ],
        child: localizedTestApp(home: const InstanceSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final nextButton = find.widgetWithText(ElevatedButton, 'Next');
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid URL'), findsOneWidget);
  });
}
