import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';
import 'package:pocketcrm/presentation/shared/clipboard_paste.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/localized_app.dart';

/// Installs a fake clipboard returning [text] (or nothing when `null`).
void _mockClipboard(String? text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return text == null ? null : <String, dynamic>{'text': text};
        }
        return null;
      });
}

Future<TextEditingController> _pumpPasteHost(
  WidgetTester tester, {
  required bool otpMode,
}) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    localizedTestApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              TextField(controller: controller),
              ElevatedButton(
                onPressed: () => pasteFromClipboard(
                  context,
                  controller,
                  successMessage: context.l10n.codePasted,
                  emptyMessage: context.l10n.clipboardEmpty,
                  otpMode: otpMode,
                ),
                child: const Text('paste'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('extractOtpCode', () {
    test('returns null when the payload has no digits', () {
      expect(extractOtpCode(null), isNull);
      expect(extractOtpCode(''), isNull);
      expect(extractOtpCode('nessun codice qui'), isNull);
    });

    test('keeps short numeric payloads untouched', () {
      expect(extractOtpCode('1234'), '1234');
    });

    test('strips non digits and spaces', () {
      expect(extractOtpCode(' 12 34 56 '), '123456');
      expect(extractOtpCode('abc-12-34'), '1234');
    });

    test('returns exactly 6 digits when present', () {
      expect(extractOtpCode('Your code is 123456'), '123456');
      expect(extractOtpCode('123456 è il tuo codice'), '123456');
    });

    test('returns the last 6 digits for longer payloads', () {
      expect(extractOtpCode('Order 123456789'), '456789');
    });

    test('honours a custom length', () {
      expect(extractOtpCode('123456789', length: 4), '6789');
    });
  });

  group('pasteFromClipboard', () {
    testWidgets('inserts the clipboard payload as-is', (tester) async {
      _mockClipboard('  my-secret-token  ');
      final controller = await _pumpPasteHost(tester, otpMode: false);

      await tester.tap(find.text('paste'));
      await tester.pumpAndSettle();

      expect(controller.text, 'my-secret-token');
      expect(controller.selection.baseOffset, controller.text.length);
      expect(find.text('Code pasted from clipboard'), findsOneWidget);
    });

    testWidgets('sanitizes the payload in otp mode', (tester) async {
      _mockClipboard('Il tuo codice è 12 34 56. Non condividerlo.');
      final controller = await _pumpPasteHost(tester, otpMode: true);

      await tester.tap(find.text('paste'));
      await tester.pumpAndSettle();

      expect(controller.text, '123456');
      expect(find.text('Code pasted from clipboard'), findsOneWidget);
    });

    testWidgets('informs the user when the clipboard is empty', (tester) async {
      _mockClipboard(null);
      final controller = await _pumpPasteHost(tester, otpMode: false);

      await tester.tap(find.text('paste'));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(find.text('Clipboard is empty'), findsOneWidget);
    });

    testWidgets('informs the user when the clipboard has no digits', (
      tester,
    ) async {
      _mockClipboard('no digits here');
      final controller = await _pumpPasteHost(tester, otpMode: true);

      await tester.tap(find.text('paste'));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(find.text('Clipboard is empty'), findsOneWidget);
    });
  });
}
