import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/presentation/onboarding/welcome_screen.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/localized_app.dart';

Future<void> _pumpWelcome(
  WidgetTester tester,
  Size size, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: localizedTestApp(locale: locale, home: const WelcomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('WelcomeScreen layout', () {
    // Regression test: the language chip in the header row used to overflow on
    // every phone-width viewport.
    for (final size in const [Size(412, 915), Size(320, 640), Size(280, 653)]) {
      testWidgets(
        'lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await _pumpWelcome(tester, size);

          expect(tester.takeException(), isNull);
          expect(find.byType(LanguageSelectorButton), findsOneWidget);
        },
      );
    }

    testWidgets('renders the localized copy and the connect action', (
      tester,
    ) async {
      await _pumpWelcome(tester, const Size(412, 915));

      expect(find.text('TwentyMobile'), findsOneWidget);
      expect(find.text('Connect your CRM'), findsOneWidget);
      expect(find.textContaining('Your portable CRM'), findsOneWidget);
    });

    testWidgets('renders the Italian copy when the locale is Italian', (
      tester,
    ) async {
      await _pumpWelcome(
        tester,
        const Size(412, 915),
        locale: const Locale('it'),
      );

      expect(find.text('Collega il tuo CRM'), findsOneWidget);
      expect(find.textContaining('Il tuo CRM portatile'), findsOneWidget);
    });

    testWidgets('the language chip opens the picker', (tester) async {
      await _pumpWelcome(tester, const Size(412, 915));

      await tester.tap(find.byType(LanguageSelectorButton));
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
    });
  });
}
