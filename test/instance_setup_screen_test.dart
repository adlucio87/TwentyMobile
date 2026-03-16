import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/presentation/onboarding/instance_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('InstanceSetupScreen URL validator test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const MaterialApp(
          home: InstanceSetupScreen(),
        ),
      ),
    );

    final urlField = find.byType(TextFormField);
    final nextButton = find.byType(ElevatedButton);

    // Test empty URL
    await tester.enterText(urlField, '');
    await tester.tap(nextButton);
    await tester.pump();
    expect(find.text('Inserisci un URL valido'), findsOneWidget);

    // Test invalid URL (not absolute)
    await tester.enterText(urlField, 'invalid-url');
    await tester.tap(nextButton);
    await tester.pump();
    expect(find.text('L\'URL deve iniziare con https://'), findsOneWidget);

    // Test http URL (now rejected)
    await tester.enterText(urlField, 'http://example.com');
    await tester.tap(nextButton);
    await tester.pump();
    expect(find.text('L\'URL deve iniziare con https://'), findsOneWidget);

    // Test https URL (accepted)
    await tester.enterText(urlField, 'https://example.com');
    await tester.tap(nextButton);
    await tester.pump();
    expect(find.text('L\'URL deve iniziare con https://'), findsNothing);
    expect(find.text('Inserisci un URL valido'), findsNothing);
  });
}
