import 'package:flutter/material.dart';

class AppTheme {
  static const Color seedGreen = Color(0xFF18D47A);
  static const Color primaryBlue = Color(0xFF1F45D6);
  static const Color darkBg = Color(0xFF111111);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedGreen,
      brightness: Brightness.light,
    ).copyWith(primary: seedGreen, secondary: primaryBlue),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedGreen,
      brightness: Brightness.dark,
    ).copyWith(primary: seedGreen, secondary: primaryBlue),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
  );
}
