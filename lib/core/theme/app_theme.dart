import 'package:flutter/material.dart';

class AppTheme {
  static const Color seedGreen = Color(0xFF18D47A);
  static const Color primaryBlue = Color(0xFF1F45D6);
  static const Color darkBg = Color(0xFF0F1115);

  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scaffoldBg: const Color(0xFFF7F8FA),
    surface: Colors.white,
    onSurface: const Color(0xFF121826),
    outline: const Color(0xFFE5E7EB),
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scaffoldBg: darkBg,
    surface: const Color(0xFF171B22),
    onSurface: const Color(0xFFF3F4F6),
    outline: const Color(0xFF2A3140),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color onSurface,
    required Color outline,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seedGreen,
          brightness: brightness,
        ).copyWith(
          primary: seedGreen,
          secondary: primaryBlue,
          surface: surface,
          onSurface: onSurface,
          outline: outline,
          outlineVariant: outline,
          surfaceContainerHighest: brightness == Brightness.light
              ? const Color(0xFFF1F5F9)
              : const Color(0xFF232A36),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outline),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF1D2330),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: seedGreen, width: 1.5),
        ),
        labelStyle: TextStyle(color: onSurface.withOpacity(0.75)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: seedGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface,
        indicatorColor: seedGreen.withOpacity(0.14),
        labelTextStyle: MaterialStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, color: onSurface),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected ? seedGreen : onSurface.withOpacity(0.65),
          );
        }),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: onSurface),
        bodyLarge: TextStyle(color: onSurface),
        titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: onSurface, fontWeight: FontWeight.w800),
      ),
    );
  }
}
