import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.persian,
        onPrimary: Colors.white,
        secondary: AppColors.bgSecondary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.bgPrimary,
        onSurface: AppColors.textPrimary,
        error: AppColors.lightError,
        onError: Colors.white,
        outline: AppColors.borderDefault,
      ),
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: _buildTextTheme(Brightness.light),
      cardTheme: const CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.inputFocusBorder),
          borderRadius: BorderRadius.circular(28),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.persian,
      ),
      dividerColor: AppColors.borderDefault,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
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
      textTheme: _buildTextTheme(Brightness.dark),
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

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color primaryTextColor = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.darkTextPrimary;

    final bodyTheme = GoogleFonts.dmSansTextTheme(
      TextTheme(
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
      TextTheme(
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
