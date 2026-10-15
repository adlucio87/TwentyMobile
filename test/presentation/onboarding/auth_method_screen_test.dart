import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/presentation/onboarding/auth_method_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/localized_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('AuthMethodScreen renders all three connection methods including Google / SSO', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: localizedTestApp(home: const AuthMethodScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_method_sso_card')), findsOneWidget);
    expect(find.byKey(const Key('auth_method_email_card')), findsOneWidget);
    expect(find.byKey(const Key('auth_method_token_card')), findsOneWidget);

    expect(find.text('Login with Google / SSO'), findsOneWidget);
    expect(find.text('Login with your account'), findsOneWidget);
    expect(find.text('Login with API Key'), findsOneWidget);
    expect(find.text('Google / SSO'), findsOneWidget);
  });

  testWidgets('AuthMethodScreen renders Italian copy correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: localizedTestApp(
          locale: const Locale('it'),
          home: const AuthMethodScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accedi con Google / SSO'), findsOneWidget);
    expect(find.text('Accedi con il tuo account'), findsOneWidget);
    expect(find.text('Accedi con Chiave API'), findsOneWidget);
  });
}
