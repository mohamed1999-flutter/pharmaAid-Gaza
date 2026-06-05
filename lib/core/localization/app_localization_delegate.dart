import 'package:flutter/material.dart';

class AppLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    throw UnimplementedError();
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) => false;
}
