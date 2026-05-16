import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  // Light theme configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.medicalBlue,
      secondary: AppColors.lightBlue,
      tertiary: AppColors.warningOrange,
      error: AppColors.emergencyRed,
      surface: AppColors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkGray,
      onError: Colors.white,
    ),
    fontFamily: 'Poppins',
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      color: AppColors.white,
      shadowColor: Colors.black.withValues(alpha: 0.1),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.medicalBlue,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.medicalBlue,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.medicalBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.medicalBlue,
        side: const BorderSide(color: AppColors.medicalBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.medicalBlue,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.medicalBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.emergencyRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.darkGray),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.medicalBlue,
      foregroundColor: Colors.white,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      selectedLabelTextStyle: TextStyle(color: AppColors.medicalBlue),
      unselectedLabelTextStyle: TextStyle(color: AppColors.darkGray),
      selectedIconTheme: IconThemeData(color: AppColors.medicalBlue),
      unselectedIconTheme: IconThemeData(color: AppColors.darkGray),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.medicalBlue,
      unselectedItemColor: AppColors.darkGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkGray),
      headlineMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkGray),
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkGray),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkGray),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkGray),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    scaffoldBackgroundColor: AppColors.lightGray,
    dividerTheme: const DividerThemeData(
      color: Colors.grey,
      thickness: 0.5,
      space: 1,
    ),
  );

  // Dark theme configuration
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.medicalBlue,
      secondary: AppColors.lightBlue,
      tertiary: AppColors.warningOrange,
      error: AppColors.emergencyRed,
      surface: Color(0xFF1E1E2E),
      onPrimary: Colors.white,
      onSurface: Colors.white70,
      onError: Colors.white,
    ),
    fontFamily: 'Poppins',
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF1E1E2E),
      shadowColor: Colors.black.withValues(alpha: 0.3),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.lightBlue,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightBlue,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.medicalBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightBlue,
        side: const BorderSide(color: AppColors.lightBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lightBlue,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.emergencyRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.medicalBlue,
      foregroundColor: Colors.white,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      selectedLabelTextStyle: TextStyle(color: AppColors.lightBlue),
      unselectedLabelTextStyle: TextStyle(color: Colors.grey),
      selectedIconTheme: IconThemeData(color: AppColors.lightBlue),
      unselectedIconTheme: IconThemeData(color: Colors.grey),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E2E),
      selectedItemColor: AppColors.lightBlue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    dividerTheme: const DividerThemeData(
      color: Colors.grey,
      thickness: 0.5,
      space: 1,
    ),
  );
}