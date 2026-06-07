import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { customer, pharmacy }

/// Stores app-level settings like language, theme, and system mode.
class AppController extends ChangeNotifier {
  static const _localeKey = 'locale_key';
  static const _themeKey = 'theme_key';
  static const _systemModeKey = 'system_mode_key';

  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;
  AppMode _appMode = AppMode.customer;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  AppMode get appMode => _appMode;
  bool get isPharmacyMode => _appMode == AppMode.pharmacy;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLocale = prefs.getString(_localeKey);
    final savedTheme = prefs.getString(_themeKey);
    final savedSystemMode = prefs.getString(_systemModeKey);

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
      _appMode = AppMode.values.firstWhere(
        (mode) => mode.name == savedSystemMode,
        orElse: () => AppMode.customer,
      );
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

  Future<void> setAppMode(AppMode mode) async {
    _appMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_systemModeKey, mode.name);
  }

  Future<void> toggleSystemMode() async {
    final newMode = isPharmacyMode ? AppMode.customer : AppMode.pharmacy;
    await setAppMode(newMode);
  }
}
