import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';
import 'package:pocketcrm/presentation/onboarding/otp_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/localized_app.dart';

class _MockStorageService extends Mock implements StorageService {}

/// Auth service that always rejects the code, so the OTP verification flow can
/// be exercised without touching the network.
class _RejectingAuthService extends AuthService {
  _RejectingAuthService() : super(_MockStorageService());

  @override
  Future<void> loginWithOTP({
    required String instanceUrl,
    required String loginToken,
    required String otp,
  }) async {
    throw Exception('Invalid code');
  }
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

Future<void> _pumpOtpScreen(
  WidgetTester tester, {
  AuthService? authService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (authService != null)
          authServiceProvider.overrideWithValue(authService),
      ],
      child: localizedTestApp(
        home: const OtpScreen(
          instanceUrl: 'https://crm.example.com',
          loginToken: 'login-token',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _otpFieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('OtpScreen clipboard behaviour', () {
    testWidgets('long press opens the menu without pasting automatically', (
      tester,
    ) async {
      _mockClipboard('12 34');
      await _pumpOtpScreen(tester);

      await tester.longPress(find.byType(TextField));
      await tester.pumpAndSettle();

      // The toolbar is shown with the localized paste entry...
      expect(find.text('Paste'), findsOneWidget);
      // ...and nothing has been pasted yet (no clipboard read on build).
      expect(_otpFieldText(tester), isEmpty);
    });

    testWidgets('tapping the toolbar paste entry inserts the sanitized code', (
      tester,
    ) async {
      _mockClipboard('Il tuo codice è 12 34.');
      await _pumpOtpScreen(tester);

      await tester.longPress(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(_otpFieldText(tester), '1234');
      expect(find.text('Code pasted from clipboard'), findsOneWidget);
    });

    testWidgets('the explicit paste button works as well', (tester) async {
      _mockClipboard('98765');
      await _pumpOtpScreen(tester);

      await tester.tap(find.text('Paste from clipboard'));
      await tester.pump();

      expect(_otpFieldText(tester), '98765');
    });

    testWidgets('pasting a full code triggers the verification flow', (
      tester,
    ) async {
      _mockClipboard('987654');
      await _pumpOtpScreen(tester, authService: _RejectingAuthService());

      await tester.tap(find.text('Paste from clipboard'));
      await tester.pumpAndSettle();

      // The verification ran with the pasted code and surfaced the failure.
      expect(find.text('Invalid code'), findsOneWidget);
      expect(_otpFieldText(tester), isEmpty);
    });

    testWidgets('an empty clipboard shows an information message', (
      tester,
    ) async {
      _mockClipboard(null);
      await _pumpOtpScreen(tester);

      await tester.tap(find.text('Paste from clipboard'));
      await tester.pumpAndSettle();

      expect(_otpFieldText(tester), isEmpty);
      expect(find.text('Clipboard is empty'), findsOneWidget);
    });
  });
}
