import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/presentation/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsScreen Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'reminder_advance_minutes': 30,
        'theme_mode': 'system',
      });
    });

    Widget createWidgetUnderTest({
      String authMethod = 'email',
      String userName = 'Test User',
    }) {
      return ProviderScope(
        overrides: [
          authMethodProvider.overrideWith((ref) => Future.value(authMethod)),
          currentUserNameProvider.overrideWith((ref) => Future.value(userName)),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('it'),
          ],
          locale: Locale('en'),
          home: SettingsScreen(),
        ),
      );
    }

    testWidgets('Renders Account section and user information', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        authMethod: 'email',
        userName: 'Mario Rossi',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Personal Account'), findsOneWidget);
      expect(find.text('Mario Rossi'), findsOneWidget);
      expect(find.text('Change login method'), findsOneWidget);
    });

    testWidgets('Renders API Key Admin badge when auth method is api_key', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        authMethod: 'api_key',
        userName: '',
      ));
      await tester.pumpAndSettle();

      expect(find.text('API Key Admin'), findsOneWidget);
    });

    testWidgets('Renders Theme section and Logout option', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Application Theme'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Logout'), 300);
      expect(find.text('Logout'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Privacy Policy'), 300);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });
  });
}
