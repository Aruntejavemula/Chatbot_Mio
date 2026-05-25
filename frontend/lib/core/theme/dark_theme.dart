import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class DarkTheme {
  DarkTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.persian,
        onPrimary: Colors.white,
        secondary: AppColors.darkBgSecondary,
        onSecondary: AppColors.darkTextPrimary,
        surface: AppColors.darkBgPrimary,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.darkError,
        onError: Colors.white,
        outline: AppColors.darkBorderDefault,
      ),
      scaffoldBackgroundColor: AppColors.darkBgPrimary,
      textTheme: _buildTextTheme(),
      cardTheme: const CardThemeData(
        color: AppColors.darkCardBg,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputBg,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.darkInputFocusBorder),
          borderRadius: BorderRadius.circular(28),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.darkInputBorder),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.persian,
      ),
      dividerColor: AppColors.darkBorderDefault,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBgPrimary,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    const Color primaryTextColor = AppColors.darkTextPrimary;

    final bodyTheme = GoogleFonts.dmSansTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: primaryTextColor),
        bodyMedium: TextStyle(color: primaryTextColor),
        bodySmall: TextStyle(color: primaryTextColor),
        labelLarge: TextStyle(color: primaryTextColor),
        labelMedium: TextStyle(color: primaryTextColor),
        labelSmall: TextStyle(color: primaryTextColor),
        titleLarge: TextStyle(color: primaryTextColor),
        titleMedium: TextStyle(color: primaryTextColor),
        titleSmall: TextStyle(color: primaryTextColor),
      ),
    );

    final displayTheme = GoogleFonts.dmSerifDisplayTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: primaryTextColor),
        displayMedium: TextStyle(color: primaryTextColor),
        displaySmall: TextStyle(color: primaryTextColor),
        headlineLarge: TextStyle(color: primaryTextColor),
        headlineMedium: TextStyle(color: primaryTextColor),
        headlineSmall: TextStyle(color: primaryTextColor),
      ),
    );

    return bodyTheme.copyWith(
      displayLarge: displayTheme.displayLarge,
      displayMedium: displayTheme.displayMedium,
      displaySmall: displayTheme.displaySmall,
      headlineLarge: displayTheme.headlineLarge,
      headlineMedium: displayTheme.headlineMedium,
      headlineSmall: displayTheme.headlineSmall,
    );
  }
}
