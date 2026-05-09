import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../providers/backup_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isUploading = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    // Charger l'historique des sauvegardes au démarrage
    Future.microtask(() {
      ref.read(backupProvider.notifier).loadBackupHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupProvider);
    final backupNotifier = ref.read(backupProvider.notifier);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegarde et Restauration'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => backupNotifier.loadBackupHistory(),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(backupState, backupNotifier)
          : _buildMobileLayout(backupState, backupNotifier),
    );
  }

  Widget _buildDesktopLayout(BackupState state, BackupNotifier notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panneau de gauche - Actions
        Expanded(
          flex: 1,
          child: _buildActionsPanel(state, notifier),
        ),
        // Panneau de droite - Historique
        Expanded(
          flex: 2,
          child: _buildHistoryPanel(state, notifier),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BackupState state, BackupNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionsPanel(state, notifier),
          const SizedBox(height: 24),
          _buildHistoryPanel(state, notifier),
        ],
      ),
    );
  }

  Widget _buildActionsPanel(BackupState state, BackupNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: AppColors.medicalBlue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Opérations de sauvegarde',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Export All Data
            _buildActionButton(
              icon: Icons.download,
              title: 'Exporter toutes les données',
              subtitle: 'Exporter tous les dossiers et données vers un fichier JSON',
              color: AppColors.medicalBlue,
              onPressed: _isExporting ? null : () => _exportAllData(notifier),
              isLoading: _isExporting,
            ),

            const SizedBox(height: 16),

            // Export Dossiers Only
            _buildActionButton(
              icon: Icons.folder,
              title: 'Exporter les dossiers seulement',
              subtitle: 'Exporter les dossiers médicaux uniquement',
              color: AppColors.stableGreen,
              onPressed:
                  _isExporting ? null : () => _exportDossiersOnly(notifier),
              isLoading: _isExporting,
            ),

            const SizedBox(height: 16),

            // Import Data
            _buildActionButton(
              icon: Icons.upload,
              title: 'Importer des données',
              subtitle: 'Importer des données depuis un fichier JSON',
              color: AppColors.warningOrange,
              onPressed: _isImporting ? null : () => _importData(notifier),
              isLoading: _isImporting,
            ),

            const Divider(height: 32),

            // Cloud Backup Section
            const Text(
              'Sauvegarde Cloud',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Upload to Cloud
            _buildActionButton(
              icon: Icons.cloud_upload,
              title: 'Upload vers le Cloud',
              subtitle: 'Uploader une sauvegarde vers Firebase Storage',
              color: const Color(0xFF6C63FF),
              onPressed: _isUploading ? null : () => _uploadToCloud(notifier),
              isLoading: _isUploading,
            ),

            const SizedBox(height: 16),

            // Delete Old Backups
            _buildActionButton(
              icon: Icons.delete_sweep,
              title: 'Supprimer les anciennes sauvegardes',
              subtitle: 'Supprimer les sauvegardes de plus de 90 jours',
              color: AppColors.emergencyRed,
              onPressed: () => _deleteOldBackups(notifier),
              isLoading: false,
            ),

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.medicalBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La sauvegarde conserve toutes les données incluant les dossiers médicaux, utilisateurs et alertes',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel(BackupState state, BackupNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.medicalBlue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Historique des sauvegardes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (state.totalBackups > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.medicalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.totalBackups} sauvegarde(s)',
                      style: TextStyle(color: AppColors.medicalBlue),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          state.totalBackups.toString(),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Nombre de sauvegardes', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(height: 40, width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          notifier.formatFileSize(state.totalSizeMB),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Taille totale',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(height: 40, width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          notifier.formatDate(state.lastBackupDate),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Text('Dernière sauvegarde', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Backups list
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.backups.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune sauvegarde existante',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez une nouvelle sauvegarde en utilisant les boutons ci-dessus',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: state.backups.length,
                  itemBuilder: (context, index) {
                    final backup = state.backups[index];
                    return _buildBackupCard(backup, notifier);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(
      Map<String, dynamic> backup, BackupNotifier notifier) {
    final fileName = backup['fileName'] ?? 'unknown.json';
    final fileSizeMB = backup['fileSizeMB'] as double? ?? 0;
    final createdAt = backup['createdAt'] as Timestamp?;
    final isCloud = backup['downloadUrl'] != null;
    final isManual = backup['backupType'] == 'manual';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isCloud ? AppColors.medicalBlue : AppColors.stableGreen,
          child: Icon(
            isCloud ? Icons.cloud : Icons.storage,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          fileName.length > 40
              ? '...${fileName.substring(fileName.length - 37)}'
              : fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Text(notifier.formatFileSize(fileSizeMB)),
            const SizedBox(width: 12),
            if (isManual)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Manuelle',
                  style: TextStyle(fontSize: 10, color: Colors.purple),
                ),
              ),
            const Spacer(),
            Text(
              notifier.formatDate(createdAt?.toDate().toString()),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCloud)
              IconButton(
                icon: const Icon(Icons.download, size: 20),
                onPressed: _isRestoring
                    ? null
                    : () => _restoreFromCloud(backup['id'], notifier),
                tooltip: 'Restaurer',
              ),
            IconButton(
              icon: const Icon(Icons.share, size: 20),
              onPressed: () => _shareBackupInfo(backup),
              tooltip: 'Partager',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAllData(BackupNotifier notifier) async {
    setState(() => _isExporting = true);
    try {
      final file = await notifier.exportAllData();
      if (file != null && mounted) {
        // Save to downloads
        final directory = await getDownloadsDirectory();
        final savedFile = await file.copy(
            '${directory?.path}/neosante_backup_${DateTime.now().millisecondsSinceEpoch}.json');

        await Share.shareXFiles(
          [XFile(savedFile.path)],
          text: 'Sauvegarde complète du système NéoSanté',
        );

        context.showSuccessSnackBar('Exportation des données réussie');
      }
    } catch (e) {
      context.showErrorSnackBar('Erreur lors de l\'exportation: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportDossiersOnly(BackupNotifier notifier) async {
    setState(() => _isExporting = true);
    try {
      final file = await notifier.exportDossiersOnly();
      if (file != null && mounted) {
        final directory = await getDownloadsDirectory();
        final savedFile = await file.copy(
            '${directory?.path}/neosante_dossiers_${DateTime.now().millisecondsSinceEpoch}.json');

        await Share.shareXFiles(
          [XFile(savedFile.path)],
          text: 'Sauvegarde des dossiers médicaux NéoSanté',
        );

        context.showSuccessSnackBar('Exportation des dossiers réussie');
      }
    } catch (e) {
      context.showErrorSnackBar('Erreur lors de l\'exportation: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData(BackupNotifier notifier) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isImporting = true);

      final file = File(result.files.first.path!);

      final confirmed = await context.showConfirmationDialog(
        title: 'Importer les données',
        message:
            '⚠️ Attention: L\'importation remplacera les données actuelles. Êtes-vous sûr?',
        confirmText: 'Importer',
        confirmColor: AppColors.warningOrange,
      );

      if (confirmed != true) {
        setState(() => _isImporting = false);
        return;
      }

      final stats = await notifier.importData(file);

      if (stats != null && mounted) {
        String message = 'Importation réussie:\n';
        stats.forEach((collection, count) {
          message += '- $collection: $count fichier(s)\n';
        });
        context.showSuccessSnackBar(message);
      }
    } catch (e) {
      context.showErrorSnackBar('Erreur lors de l\'importation: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _uploadToCloud(BackupNotifier notifier) async {
    setState(() => _isUploading = true);
    try {
      // First export data
      final file = await notifier.exportAllData();
      if (file == null) throw Exception('Échec de l\'exportation des données');

      // Then upload to cloud
      final url = await notifier.uploadBackupToCloud(file);

      if (url != null && mounted) {
        context.showSuccessSnackBar('Sauvegarde uploadée vers le cloud');

        // Show download link
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload réussi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lien de téléchargement:'),
                const SizedBox(height: 12),
                SelectableText(url, style: const TextStyle(fontSize: 10)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              ElevatedButton.icon(
                onPressed: () => Share.share(url),
                icon: const Icon(Icons.share),
                label: const Text('Partager'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      context.showErrorSnackBar('Erreur lors de l\'upload: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _restoreFromCloud(
      String backupId, BackupNotifier notifier) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Restaurer les données',
      message:
          '⚠️ Attention: La restauration remplacera les données actuelles. Êtes-vous sûr?',
      confirmText: 'Restaurer',
      confirmColor: AppColors.warningOrange,
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final stats = await notifier.restoreFromCloud(backupId);

      if (stats != null && mounted) {
        String message = 'Restauration réussie:\n';
        stats.forEach((collection, count) {
          message += '- $collection: $count fichier(s)\n';
        });
        context.showSuccessSnackBar(message);
      }
    } catch (e) {
      context.showErrorSnackBar('Erreur lors de la restauration: $e');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _deleteOldBackups(BackupNotifier notifier) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Supprimer les anciennes sauvegardes',
      message:
          'Toutes les sauvegardes de plus de 90 jours seront supprimées. Êtes-vous sûr?',
      confirmText: 'Supprimer',
      confirmColor: AppColors.emergencyRed,
    );

    if (confirmed != true) return;

    try {
      await notifier.deleteOldBackups();
      context.showSuccessSnackBar('Anciennes sauvegardes supprimées');
    } catch (e) {
      context.showErrorSnackBar('Erreur lors de la suppression: $e');
    }
  }

  void _shareBackupInfo(Map<String, dynamic> backup) {
    final createdAt = (backup['createdAt'] as Timestamp?)?.toDate();
    final fileSize = backup['fileSizeMB'] as double? ?? 0;
    final isCloud = backup['downloadUrl'] != null;

    final message = '''
📦 Informations de sauvegarde - NéoSanté

📁 Fichier: ${backup['fileName']}
📅 Date: ${createdAt?.toLocal().toString().split(' ')[0]}
⏰ Heure: ${createdAt?.toLocal().toString().split(' ')[1]}
💾 Taille: ${fileSize.toStringAsFixed(2)} MB
☁️ Cloud: ${isCloud ? 'Oui' : 'Non'}
    ''';

    Share.share(message);
  }
}