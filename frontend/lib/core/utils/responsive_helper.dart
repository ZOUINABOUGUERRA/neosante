import 'package:flutter/material.dart';

/// Helper class for responsive design
class ResponsiveHelper {
  /// Returns true if screen width is less than 600 (Mobile)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Returns true if screen width is between 600 and 1200 (Tablet)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Returns true if screen width is greater than or equal to 1200 (Desktop)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Returns responsive value based on screen size
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Returns responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(32);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  /// Returns responsive spacing
  static double responsiveSpacing(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 16;
    return 12;
  }

  /// Returns responsive font size
  static double responsiveFontSize(BuildContext context) {
    if (isDesktop(context)) return 16;
    if (isTablet(context)) return 14;
    return 12;
  }

  /// Returns responsive heading size
  static double responsiveHeadingSize(BuildContext context) {
    if (isDesktop(context)) return 28;
    if (isTablet(context)) return 24;
    return 20;
  }

  /// Returns responsive grid cross axis count
  static int gridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  /// Returns responsive card height
  static double cardHeight(BuildContext context) {
    if (isDesktop(context)) return 200;
    if (isTablet(context)) return 180;
    return 160;
  }
}