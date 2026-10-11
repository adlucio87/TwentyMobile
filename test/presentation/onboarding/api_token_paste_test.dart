import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';
import 'package:pocketcrm/presentation/onboarding/api_token_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/localized_app.dart';

class _MockStorageService extends Mock implements StorageService {
  @override
  Future<String?> read({required String key}) async => null;
}

/// Installs a fake clipboard returning [text].
void _mockClipboard(String? text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return text == null ? null : <String, dynamic>{'text': text};
        }
        return null;
      });
}

Future<void> _pumpApiTokenScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(_MockStorageService()),
      ],
      child: localizedTestApp(home: const ApiTokenScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

String _tokenFieldText(WidgetTester tester) =>
    tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('ApiTokenScreen clipboard behaviour', () {
    testWidgets('the paste button fills the field with the trimmed token', (
      tester,
    ) async {
      _mockClipboard('  my-api-token  ');
      await _pumpApiTokenScreen(tester);

      await tester.tap(find.byTooltip('Paste from clipboard'));
      await tester.pumpAndSettle();

      expect(_tokenFieldText(tester), 'my-api-token');
      expect(find.text('Pasted from clipboard'), findsOneWidget);
    });

    testWidgets('long press only shows the menu, it does not paste', (
      tester,
    ) async {
      _mockClipboard('token-from-clipboard');
      await _pumpApiTokenScreen(tester);

      await tester.longPress(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('Paste'), findsOneWidget);
      expect(_tokenFieldText(tester), isEmpty);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(_tokenFieldText(tester), 'token-from-clipboard');
    });

    testWidgets('an empty clipboard shows an information message', (
      tester,
    ) async {
      _mockClipboard(null);
      await _pumpApiTokenScreen(tester);

      await tester.tap(find.byTooltip('Paste from clipboard'));
      await tester.pumpAndSettle();

      expect(_tokenFieldText(tester), isEmpty);
      expect(find.text('Clipboard is empty'), findsOneWidget);
    });
  });
}
