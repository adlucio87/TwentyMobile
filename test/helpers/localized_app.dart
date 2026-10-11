import 'package:flutter/material.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

/// Localization setup shared by widget tests.
///
/// Screens read their strings through `context.l10n`, which requires the app
/// localization delegates to be installed in the widget tree under test.
const List<LocalizationsDelegate<dynamic>> testLocalizationsDelegates =
    AppLocalizations.localizationsDelegates;

const List<Locale> testSupportedLocales = AppLocalizations.supportedLocales;

const Locale testLocale = Locale('en');

/// A [MaterialApp] with the app localizations installed, used to pump screens
/// that depend on `context.l10n`.
MaterialApp localizedTestApp({
  required Widget home,
  Locale locale = testLocale,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: home,
  );
}
