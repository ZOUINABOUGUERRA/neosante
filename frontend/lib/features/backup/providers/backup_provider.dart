import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/backup_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/auth_service.dart';

/// Backup state class
class BackupState {
  final List<Map<String, dynamic>> backups;
  final bool isLoading;
  final String? error;
  final double exportProgress;
  final String? lastBackupDate;
  final int totalBackups;
  final double totalSizeMB;

  const BackupState({
    this.backups = const [],
    this.isLoading = false,
    this.error = null,
    this.exportProgress = 0,
    this.lastBackupDate = null,
    this.totalBackups = 0,
    this.totalSizeMB = 0,
  });

  BackupState copyWith({
    List<Map<String, dynamic>>? backups,
    bool? isLoading,
    String? error,
    double? exportProgress,
    String? lastBackupDate,
    int? totalBackups,
    double? totalSizeMB,
  }) {
    return BackupState(
      backups: backups ?? this.backups,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      exportProgress: exportProgress ?? this.exportProgress,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      totalBackups: totalBackups ?? this.totalBackups,
      totalSizeMB: totalSizeMB ?? this.totalSizeMB,
    );
  }
}

/// Backup provider
final backupProvider =
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  return BackupNotifier();
});

/// Backup notifier for managing backup operations
class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService = BackupService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  BackupNotifier() : super(const BackupState()) {
    loadBackupHistory();
  }

  /// Load backup history from Firestore
  Future<void> loadBackupHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final backups = await _backupService.getBackupHistory();

      // Calculate totals
      int totalBackups = backups.length;
      double totalSizeMB =
          backups.fold(0, (sum, b) => sum + (b['fileSizeMB'] as double? ?? 0));
      String? lastBackupDate = backups.isNotEmpty
          ? (backups.first['createdAt'] as Timestamp?)?.toDate().toString()
          : null;

      state = state.copyWith(
        backups: backups,
        isLoading: false,
        totalBackups: totalBackups,
        totalSizeMB: totalSizeMB,
        lastBackupDate: lastBackupDate,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Export all data to JSON file
  Future<File?> exportAllData() async {
    state = state.copyWith(isLoading: true, error: null, exportProgress: 0);
    try {
      final file = await _backupService.exportAllData();
      state = state.copyWith(exportProgress: 0.5);

      // Save to device
      state = state.copyWith(exportProgress: 1.0);
      state = state.copyWith(isLoading: false, exportProgress: 0);
      return file;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تصدير البيانات: $e',
        exportProgress: 0,
      );
      return null;
    }
  }

  /// Import data from JSON file
  Future<Map<String, int>?> importData(File file) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _backupService.importData(file);
      await loadBackupHistory(); // Refresh history
      state = state.copyWith(isLoading: false);
      return stats;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في استيراد البيانات: $e',
      );
      return null;
    }
  }

  /// Upload backup to cloud
  Future<String?> uploadBackupToCloud(File file) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUser = _authService.currentFirebaseUser;
      if (currentUser == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final url =
          await _backupService.uploadBackupToCloud(file, currentUser.uid);
      await loadBackupHistory(); // Refresh history
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في رفع النسخة الاحتياطية: $e',
      );
      return null;
    }
  }

  /// Restore from cloud backup
  Future<Map<String, int>?> restoreFromCloud(String backupId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _backupService.restoreFromCloud(backupId);
      state = state.copyWith(isLoading: false);
      return stats;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في استعادة النسخة الاحتياطية: $e',
      );
      return null;
    }
  }

  /// Delete old backups
  Future<int> deleteOldBackups() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _backupService.deleteOldBackups();
      await loadBackupHistory();
      state = state.copyWith(isLoading: false);
      return state.totalBackups;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في حذف النسخ القديمة: $e',
      );
      return 0;
    }
  }

  /// Export dossiers only (partial backup)
  Future<File?> exportDossiersOnly() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final file = await _backupService.exportDossiersOnly();
      state = state.copyWith(isLoading: false);
      return file;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تصدير الملفات: $e',
      );
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Format file size
  String formatFileSize(double sizeMB) {
    if (sizeMB < 1) {
      return '${(sizeMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeMB.toStringAsFixed(2)} MB';
  }

  /// Format date
  String formatDate(String? dateString) {
    if (dateString == null) return 'لا يوجد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
