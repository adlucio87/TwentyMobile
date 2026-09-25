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
    locale: Locale('en'),
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

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
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
