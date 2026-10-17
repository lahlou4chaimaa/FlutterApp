import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> appThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.light);

const Color skillUpPrimary = Color(0xFF4F46E5);
const Color skillUpBackground = Color(0xFFF8FAFC);

ThemeData buildSkillUpTheme({required bool isDark}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: skillUpPrimary,
    brightness: isDark ? Brightness.dark : Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF101525)
        : skillUpBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark
          ? const Color(0xFF101525)
          : skillUpBackground,
      foregroundColor: isDark
          ? Colors.white
          : const Color(0xFF172033),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF1C2438) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? const Color(0xFF252E43)
          : const Color(0xFFF7F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: isDark
              ? const Color(0xFF374151)
              : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: skillUpPrimary,
          width: 1.5,
        ),
      ),
    ),
  );
}