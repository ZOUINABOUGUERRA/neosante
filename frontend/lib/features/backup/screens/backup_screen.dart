import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/backup_service.dart';
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
    this.error,
    this.exportProgress = 0,
    this.lastBackupDate,
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
final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>((
  ref,
) {
  return BackupNotifier();
});

/// Backup notifier for managing backup operations
class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService = BackupService();
  final AuthService _authService = AuthService();

  BackupNotifier() : super(const BackupState()) {
    loadBackupHistory();
  }

  /// ✅ دالة مساعدة لقراءة التاريخ من Firestore
  DateTime? _parseDateFromFirestore(dynamic value) {
    if (value == null) return null;

    // إذا كان من النوع Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // إذا كان من النوع String (ISO format)
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('Error parsing date: $e');
        return null;
      }
    }

    return null;
  }

  /// Load backup history from Firestore
  Future<void> loadBackupHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final backups = await _backupService.getBackupHistory();

      int totalBackups = backups.length;
      double totalSizeMB = backups.fold(
        0.0,
        (total, b) => total + (b['fileSizeMB'] as double? ?? 0),
      );

      // ✅ قراءة التاريخ بشكل آمن
      String? lastBackupDate;
      if (backups.isNotEmpty) {
        final createdAt = backups.first['createdAt'];
        final date = _parseDateFromFirestore(createdAt);
        lastBackupDate = date?.toIso8601String();
      }

      state = state.copyWith(
        backups: backups,
        isLoading: false,
        totalBackups: totalBackups,
        totalSizeMB: totalSizeMB,
        lastBackupDate: lastBackupDate,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading backup history: $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: '❌ Erreur lors du chargement: ${e.toString()}',
      );
    }
  }

  /// Export all data to JSON file
  Future<File?> exportAllData() async {
    state = state.copyWith(isLoading: true, error: null, exportProgress: 0.1);
    try {
      final file = await _backupService.exportAllData();
      state = state.copyWith(exportProgress: 0.8);

      await Future.delayed(const Duration(milliseconds: 200));
      state = state.copyWith(isLoading: false, exportProgress: 0);
      return file;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '❌ Erreur d\'exportation: ${e.toString()}',
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
      await loadBackupHistory();
      state = state.copyWith(isLoading: false);
      return stats;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '❌ Erreur d\'importation: ${e.toString()}',
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
        throw Exception('🔐 Veuillez vous connecter');
      }

      final url = await _backupService.uploadBackupToCloud(
        file,
        currentUser.uid,
      );
      await loadBackupHistory();
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '☁️ Erreur d\'upload: ${e.toString()}',
      );
      return null;
    }
  }

  /// Restore from cloud backup
  Future<Map<String, int>?> restoreFromCloud(String backupId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _backupService.restoreFromCloud(backupId);
      await loadBackupHistory();
      state = state.copyWith(isLoading: false);
      return stats;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '❌ Erreur de restauration: ${e.toString()}',
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
        error: '🗑️ Erreur de suppression: ${e.toString()}',
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
        error: '📁 Erreur d\'exportation: ${e.toString()}',
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
    if (sizeMB < 0.001) return '0 KB';
    if (sizeMB < 1) {
      return '${(sizeMB * 1024).toStringAsFixed(1)} KB';
    }
    return '${sizeMB.toStringAsFixed(2)} MB';
  }

  /// ✅ Format date - يدعم كلاً من String و Timestamp
  String formatDate(String? dateString) {
    if (dateString == null) return '📅 Aucune';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

/// Backup Screen Widget
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupProvider);
    final backupNotifier = ref.read(backupProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💾 Sauvegarde'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Statistiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('Total', '${backupState.totalBackups}'),
                        _buildStatItem(
                          'Taille',
                          backupNotifier.formatFileSize(
                            backupState.totalSizeMB,
                          ),
                        ),
                        _buildStatItem(
                          'Dernière',
                          backupNotifier.formatDate(backupState.lastBackupDate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Export Section
            const Text(
              '📤 Exportation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: backupState.isLoading
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final file = await backupNotifier.exportAllData();
                            if (!mounted || file == null) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('✅ Exporté: ${file.path}'),
                              ),
                            );
                          },
                    icon: const Icon(Icons.download),
                    label: const Text('Exporter Tout'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: backupState.isLoading
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final file = await backupNotifier
                                .exportDossiersOnly();
                            if (!mounted || file == null) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Dossiers exportés: ${file.path}',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.folder),
                    label: const Text('Dossiers Seulement'),
                  ),
                ),
              ],
            ),

            // Progress Indicator
            if (backupState.isLoading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: backupState.exportProgress),
              const SizedBox(height: 8),
              Text('${(backupState.exportProgress * 100).toInt()}%'),
            ],

            const SizedBox(height: 24),

            // Error Display
            if (backupState.error != null) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          backupState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        onPressed: backupNotifier.clearError,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Backup History
            const Text(
              '📚 Historique',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (backupState.backups.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Aucune sauvegarde trouvée'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: backupState.backups.length,
                itemBuilder: (context, index) {
                  final backup = backupState.backups[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.backup),
                      title: Text('Sauvegarde ${index + 1}'),
                      subtitle: Text(
  '📅 ${backupNotifier.formatDate(
    backup['createdAt'] == null
        ? null
        : backup['createdAt'].toString(),
  )}\n'
  '📏 ${backupNotifier.formatFileSize(
    (backup['fileSizeMB'] as num?)?.toDouble() ?? 0,
  )}',
),
                      trailing: IconButton(
                        icon: const Icon(Icons.cloud_upload),
                        onPressed: () {
                          // TODO: Implement cloud upload
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
