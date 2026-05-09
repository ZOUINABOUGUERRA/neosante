import 'package:flutter/material.dart';

/// Centralized color definitions for the NéoSanté medical platform.
/// All colors are based on the medical alert system and modern UI guidelines.
class AppColors {
  // Primary medical palette
  static const Color medicalBlue = Color(0xFF2B7A78);   // Main brand color
  static const Color lightBlue = Color(0xFF3AAFA9);     // Secondary / accent

  // Alert severity colors (following medical standards)
  static const Color emergencyRed = Color(0xFFFF3B3B);  // Critical alert
  static const Color warningOrange = Color(0xFFFFA500); // High surveillance
  static const Color mediumYellow = Color(0xFFFFD700);  // Moderate warning
  static const Color stableGreen = Color(0xFF4CAF50);   // Stable patient

  // Neutral / background shades
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);    // Background for web
  static const Color darkGray = Color(0xFF333333);     // Text on light backgrounds

  // Glassmorphism / overlay
  static const Color glassWhite = Color(0xCCFFFFFF);    // 80% white for frosted cards

  // Functional colors (optional, derived from above)
  static const Color success = stableGreen;
  static const Color error = emergencyRed;
  static const Color warning = warningOrange;
  static const Color info = medicalBlue;
}