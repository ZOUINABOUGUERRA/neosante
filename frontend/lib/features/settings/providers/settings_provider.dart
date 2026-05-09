import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/colors.dart';

/// Settings state class
class SettingsState {
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool medicalAlertsEnabled;
  final bool autoBackupEnabled;
  final int autoBackupFrequency; // in days
  final String fontSize; // 'small', 'medium', 'large'
  final bool offlineModeEnabled;
  final bool syncOnlyOnWifi;

  const SettingsState({
    this.isDarkMode = false,
    this.language = 'fr',
    this.notificationsEnabled = true,
    this.medicalAlertsEnabled = true,
    this.autoBackupEnabled = false,
    this.autoBackupFrequency = 7,
    this.fontSize = 'medium',
    this.offlineModeEnabled = true,
    this.syncOnlyOnWifi = true,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? medicalAlertsEnabled,
    bool? autoBackupEnabled,
    int? autoBackupFrequency,
    String? fontSize,
    bool? offlineModeEnabled,
    bool? syncOnlyOnWifi,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      medicalAlertsEnabled: medicalAlertsEnabled ?? this.medicalAlertsEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupFrequency: autoBackupFrequency ?? this.autoBackupFrequency,
      fontSize: fontSize ?? this.fontSize,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
      syncOnlyOnWifi: syncOnlyOnWifi ?? this.syncOnlyOnWifi,
    );
  }

  double get fontSizeValue {
    switch (fontSize) {
      case 'small':
        return 12;
      case 'large':
        return 18;
      default:
        return 14;
    }
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Settings notifier for managing app settings
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLanguage = 'language';
  static const String _keyNotifications = 'notifications';
  static const String _keyMedicalAlerts = 'medical_alerts';
  static const String _keyAutoBackup = 'auto_backup';
  static const String _keyBackupFrequency = 'backup_frequency';
  static const String _keyFontSize = 'font_size';
  static const String _keyOfflineMode = 'offline_mode';
  static const String _keySyncOnlyWifi = 'sync_only_wifi';

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // ✅ إضافة import shared_preferences
    final prefs = await SharedPreferences.getInstance();
    
    state = state.copyWith(
      isDarkMode: prefs.getBool(_keyDarkMode) ?? false,
      language: prefs.getString(_keyLanguage) ?? 'fr',
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
      medicalAlertsEnabled: prefs.getBool(_keyMedicalAlerts) ?? true,
      autoBackupEnabled: prefs.getBool(_keyAutoBackup) ?? false,
      autoBackupFrequency: prefs.getInt(_keyBackupFrequency) ?? 7,
      fontSize: prefs.getString(_keyFontSize) ?? 'medium',
      offlineModeEnabled: prefs.getBool(_keyOfflineMode) ?? true,
      syncOnlyOnWifi: prefs.getBool(_keySyncOnlyWifi) ?? true,
    );
  }

  Future<void> toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
    state = state.copyWith(language: language);
  }

  Future<void> toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> toggleMedicalAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMedicalAlerts, value);
    state = state.copyWith(medicalAlertsEnabled: value);
  }

  Future<void> toggleAutoBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoBackup, value);
    state = state.copyWith(autoBackupEnabled: value);
  }

  Future<void> setAutoBackupFrequency(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBackupFrequency, days);
    state = state.copyWith(autoBackupFrequency: days);
  }

  Future<void> setFontSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFontSize, size);
    state = state.copyWith(fontSize: size);
  }

  Future<void> toggleOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, value);
    state = state.copyWith(offlineModeEnabled: value);
  }

  Future<void> toggleSyncOnlyOnWifi(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySyncOnlyWifi, value);
    state = state.copyWith(syncOnlyOnWifi: value);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const SettingsState();
  }
}