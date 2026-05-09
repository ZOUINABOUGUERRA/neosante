import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Extension methods for BuildContext to simplify common UI operations.
extension ContextExtension on BuildContext {
  /// Returns the current theme data
  ThemeData get theme => Theme.of(this);
  
  /// Returns the text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Returns the color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Returns the current media query data
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Returns the screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Returns the screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Returns true if the screen width is greater than 800 (desktop/tablet landscape)
  bool get isDesktop => screenWidth > 800;
  
  /// Returns true if the screen width is between 480 and 800 (tablet)
  bool get isTablet => screenWidth >= 480 && screenWidth <= 800;
  
  /// Returns true if the screen width is less than 480 (mobile)
  bool get isMobile => screenWidth < 480;
  
  /// Returns the current orientation
  Orientation get orientation => MediaQuery.of(this).orientation;
  
  /// Returns true if the keyboard is open
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;
  
  /// Returns the status bar height
  double get statusBarHeight => MediaQuery.of(this).padding.top;
  
  /// Returns the bottom navigation bar height (if visible)
  double get bottomNavBarHeight => MediaQuery.of(this).padding.bottom;
  
  /// Returns the safe area top padding
  double get safeAreaTop => MediaQuery.of(this).padding.top;
  
  /// Returns the safe area bottom padding
  double get safeAreaBottom => MediaQuery.of(this).padding.bottom;
  
  /// Shows a snack bar with a message
  void showSnackBar(String message, {Color? backgroundColor, Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Shows a success snack bar (green)
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.stableGreen);
  }
  
  /// Shows an error snack bar (red)
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.emergencyRed);
  }
  
  /// Shows a warning snack bar (orange)
  void showWarningSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.warningOrange);
  }
  
  /// Shows an info snack bar (blue)
  void showInfoSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.medicalBlue);
  }
  
  /// Navigates to a named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }
  
  /// Navigates to a named route and replaces the current route
  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
  return Navigator.of(this).pushReplacementNamed(
    routeName,
    arguments: arguments,
  );
}
  
  /// Navigates to a named route and removes all previous routes
  Future<T?> pushNamedAndRemoveUntil<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  /// Pops the current route
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
  
  /// Returns true if the current route can be popped
  bool get canPop => Navigator.of(this).canPop();
  
  /// Shows a loading dialog
  void showLoadingDialog({String message = 'Chargement...'}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Hides the loading dialog
  void hideLoadingDialog() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }
  
  /// Shows a confirmation dialog
  Future<bool?> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color? confirmColor,
  }) async {
    return showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
  
  /// Shows an error dialog
  void showErrorDialog({required String title, required String message}) {
    showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.emergencyRed),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Hides the keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
  
  /// Returns the current locale's language code
  String get localeLanguageCode => Localizations.localeOf(this).languageCode;
  
  /// Returns true if the locale is French
  bool get isFrench => localeLanguageCode == 'fr';
  
  /// Returns true if the locale is English
  bool get isEnglish => localeLanguageCode == 'en';
  
  /// Returns the responsive value based on screen size
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
  
  /// Returns padding that adapts to screen size
  EdgeInsets get responsivePadding {
    if (isDesktop) {
      return const EdgeInsets.all(32);
    } else if (isTablet) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(16);
    }
  }
  
  /// Returns spacing that adapts to screen size
  double get responsiveSpacing {
    if (isDesktop) return 24;
    if (isTablet) return 16;
    return 12;
  }
  
  /// Returns font size that adapts to screen size
  double get responsiveFontSize {
    if (isDesktop) return 16;
    if (isTablet) return 14;
    return 12;
  }
  
  /// Returns heading font size that adapts to screen size
  double get responsiveHeadingSize {
    if (isDesktop) return 28;
    if (isTablet) return 24;
    return 20;
  }
  
  /// Returns the width percentage of the screen
  double widthPercentage(double percentage) {
    return screenWidth * (percentage / 100);
  }
  
  /// Returns the height percentage of the screen
  double heightPercentage(double percentage) {
    return screenHeight * (percentage / 100);
  }
}