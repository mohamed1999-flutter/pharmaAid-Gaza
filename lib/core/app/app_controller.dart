import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores app-level settings like language, theme, and system mode.
class AppController extends ChangeNotifier {
  static const _localeKey = 'locale_key';
  static const _themeKey = 'theme_key';
  static const _systemModeKey = 'system_mode_key';

  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;
  bool _isPharmacyMode = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isPharmacyMode => _isPharmacyMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLocale = prefs.getString(_localeKey);
    final savedTheme = prefs.getString(_themeKey);
    final savedSystemMode = prefs.getBool(_systemModeKey);

    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    }

    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedTheme,
        orElse: () => ThemeMode.light,
      );
    }

    if (savedSystemMode != null) {
      _isPharmacyMode = savedSystemMode;
    }

    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> toggleLocale() async {
    await setLocale(
      _locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar'),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> toggleSystemMode() async {
    _isPharmacyMode = !_isPharmacyMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemModeKey, _isPharmacyMode);
  }
}
