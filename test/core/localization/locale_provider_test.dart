import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketcrm/core/localization/locale_provider.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

void main() {
  group('LocaleProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to null (System default)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale, isNull);
    });

    test('can set locale to Italian (it)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale('it');
      expect(container.read(localeProvider), const Locale('it'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'it');
    });

    test('can set locale to US English (en)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale('en_US');
      expect(container.read(localeProvider), const Locale('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'en_US');
    });

    test('can set locale to UK English (en_GB)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale('en_GB');
      expect(container.read(localeProvider), const Locale('en', 'GB'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'en_GB');
    });

    test('can set locale to French (fr)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale('fr');
      expect(container.read(localeProvider), const Locale('fr'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'fr');
    });

    test('can set locale to German (de)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale('de');
      expect(container.read(localeProvider), const Locale('de'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'de');
    });

    test('can set locale to Hindi (hi)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale('hi');
      expect(container.read(localeProvider), const Locale('hi'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'hi');
    });

    test('resetting to system sets locale back to null', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale('it');
      expect(container.read(localeProvider), const Locale('it'));

      await container.read(localeProvider.notifier).setLocale('system');
      expect(container.read(localeProvider), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'system');
    });

    test('appLocaleOptions contains all 6 required languages plus system', () {
      final codes = appLocaleOptions.map((o) => o.code).toList();
      expect(codes, containsAll(['system', 'it', 'en_US', 'en_GB', 'fr', 'de', 'hi']));
    });
  });

  group('AppLocalizations Translations Test', () {
    testWidgets('loads Italian translations correctly', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.navHome, 'Home');
      expect(l10n.navContacts, 'Contatti');
      expect(l10n.navCompanies, 'Aziende');
      expect(l10n.navTasks, 'Attività');
      expect(l10n.greetingMorning, 'Buongiorno 👋');
      expect(l10n.searchContacts, 'Cerca contatti...');
    });

    testWidgets('loads French translations correctly', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.navHome, 'Accueil');
      expect(l10n.navContacts, 'Contacts');
      expect(l10n.navCompanies, 'Entreprises');
      expect(l10n.navTasks, 'Tâches');
      expect(l10n.greetingMorning, 'Bonjour 👋');
      expect(l10n.searchContacts, 'Rechercher des contacts...');
    });

    testWidgets('loads German translations correctly', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.navHome, 'Start');
      expect(l10n.navContacts, 'Kontakte');
      expect(l10n.navCompanies, 'Unternehmen');
      expect(l10n.navTasks, 'Aufgaben');
      expect(l10n.greetingMorning, 'Guten Morgen 👋');
      expect(l10n.searchContacts, 'Kontakte suchen...');
    });

    testWidgets('loads Hindi translations correctly', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('hi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.navHome, 'होम');
      expect(l10n.navContacts, 'संपर्क');
      expect(l10n.navCompanies, 'कंपनियां');
      expect(l10n.navTasks, 'कार्य');
      expect(l10n.greetingMorning, 'सुप्रभात 👋');
      expect(l10n.searchContacts, 'संपर्क खोजें...');
    });

    testWidgets('loads English translations correctly', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.navHome, 'Home');
      expect(l10n.navContacts, 'Contacts');
      expect(l10n.navCompanies, 'Companies');
      expect(l10n.navTasks, 'Tasks');
      expect(l10n.greetingMorning, 'Good morning 👋');
      expect(l10n.searchContacts, 'Search contacts...');
    });
  });
}
