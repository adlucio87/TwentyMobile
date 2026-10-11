import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';
import 'package:pocketcrm/core/localization/locale_provider.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/localized_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('localeOptionLabel', () {
    testWidgets('localizes the system entry and keeps language endonyms', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        localizedTestApp(
          home: Builder(
            builder: (context) {
              l10n = context.l10n;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(localeOptionLabel(l10n, appLocaleOptions.first), 'System default');
      expect(
        localeOptionLabel(
          l10n,
          appLocaleOptions.firstWhere((o) => o.code == 'it'),
        ),
        'Italiano',
      );
    });

    testWidgets('translates the system entry', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        localizedTestApp(
          locale: const Locale('it'),
          home: Builder(
            builder: (context) {
              l10n = context.l10n;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        localeOptionLabel(l10n, appLocaleOptions.first),
        'Predefinita di sistema',
      );
    });
  });

  group('LanguageSelectorButton', () {
    Future<ProviderContainer> pumpSelector(
      WidgetTester tester, {
      bool compact = true,
    }) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: localizedTestApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [LanguageSelectorButton(isCompact: compact)],
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('compact variant renders the current flag', (tester) async {
      await pumpSelector(tester);

      expect(find.text('📱'), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('extended variant renders the current option label', (
      tester,
    ) async {
      await pumpSelector(tester, compact: false);

      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);
    });

    testWidgets('selecting a language updates the provider and persists it', (
      tester,
    ) async {
      final container = await pumpSelector(tester, compact: false);

      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      // The current option is marked and the sheet lists the system entry with
      // its localized label.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('System default'), findsWidgets);

      await tester.tap(find.text('Italiano'));
      await tester.pumpAndSettle();

      expect(container.read(localeProvider), const Locale('it'));
      expect(container.read(selectedLocaleOptionProvider).code, 'it');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'it');
      // The sheet is closed after a selection.
      expect(find.text('Select Language'), findsNothing);
    });
  });
}
