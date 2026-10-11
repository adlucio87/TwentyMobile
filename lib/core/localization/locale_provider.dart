import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleOption {
  final String code;
  final String name;
  final String flag;
  final Locale? locale;

  const AppLocaleOption({
    required this.code,
    required this.name,
    required this.flag,
    this.locale,
  });
}

const List<AppLocaleOption> appLocaleOptions = [
  AppLocaleOption(
    code: 'system',
    name: 'System default',
    flag: '📱',
    locale: null,
  ),
  AppLocaleOption(
    code: 'it',
    name: 'Italiano',
    flag: '🇮🇹',
    locale: Locale('it'),
  ),
  AppLocaleOption(
    code: 'en_US',
    name: 'English (US)',
    flag: '🇺🇸',
    locale: Locale('en', 'US'),
  ),
  AppLocaleOption(
    code: 'en_GB',
    name: 'English (UK)',
    flag: '🇬🇧',
    locale: Locale('en', 'GB'),
  ),
  AppLocaleOption(
    code: 'fr',
    name: 'Français',
    flag: '🇫🇷',
    locale: Locale('fr'),
  ),
  AppLocaleOption(
    code: 'de',
    name: 'Deutsch',
    flag: '🇩🇪',
    locale: Locale('de'),
  ),
  AppLocaleOption(
    code: 'hi',
    name: 'हिन्दी',
    flag: '🇮🇳',
    locale: Locale('hi'),
  ),
];

/// Resolves the [AppLocaleOption] that matches [locale].
///
/// A `null` locale (or an unsupported one) maps to the "system default" option,
/// which is always the first entry of [appLocaleOptions]. Language-only
/// fallback (same language, different region) keeps the picker consistent with
/// locales coming from the OS (e.g. `it_CH` → `it`).
AppLocaleOption optionForLocale(Locale? locale) {
  if (locale == null) return appLocaleOptions.first;

  for (final option in appLocaleOptions) {
    if (option.locale == locale) return option;
  }
  for (final option in appLocaleOptions) {
    if (option.locale?.languageCode == locale.languageCode) return option;
  }
  return appLocaleOptions.first;
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

/// Currently selected [AppLocaleOption], derived from [localeProvider].
///
/// UI code uses this to render the selected language label/flag while keeping
/// the resolution logic in a single place.
final selectedLocaleOptionProvider = Provider<AppLocaleOption>((ref) {
  return optionForLocale(ref.watch(localeProvider));
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('app_locale');
    if (savedCode == null || savedCode == 'system') {
      state = null;
    } else {
      final option = appLocaleOptions.firstWhere(
        (o) => o.code == savedCode,
        orElse: () => appLocaleOptions[0],
      );
      state = option.locale;
    }
  }

  Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', code);
    if (code == 'system') {
      state = null;
    } else {
      final option = appLocaleOptions.firstWhere(
        (o) => o.code == code,
        orElse: () => appLocaleOptions[0],
      );
      state = option.locale;
    }
  }
}
