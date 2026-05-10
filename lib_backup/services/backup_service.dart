import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../core/errors/failure.dart';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';
import 'firestore_service.dart';

/// Backup service for exporting and importing data.
/// Supports JSON export/import, cloud backup, and local backup.
class BackupService {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  /// Export all data to JSON file
  Future<File> exportAllData() async {
    try {
      final backupData = <String, dynamic>{};
      
      // Export all collections
      final collections = [
        AppConstants.dossiersPrematuresCollection,
        AppConstants.dossiersATermeCollection,
        AppConstants.usersCollection,
        AppConstants.alertsCollection,
        AppConstants.transfersCollection,
        AppConstants.archivesCollection,
      ];
      
      for (final collection in collections) {
        final snapshot = await _firestoreService.getCollection(collection);
        backupData[collection] = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      }
      
      // Create JSON file
      final jsonString = jsonEncode(backupData);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/neosante_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      
      return file;
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de l\'export des données: $e', originalError: e);
    }
  }

  /// Import data from JSON file
  Future<Map<String, int>> importData(File jsonFile) async {
    try {
      final jsonString = await jsonFile.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final importStats = <String, int>{};
      
      for (final entry in data.entries) {
        final collection = entry.key;
        final documents = entry.value as List<dynamic>;
        int count = 0;
        
        for (final doc in documents) {
          final docId = doc['id'] as String;
          final docData = Map<String, dynamic>.from(doc);
          docData.remove('id');
          
          await _firestoreService.setDocument(collection, docId, docData);
          count++;
        }
        
        importStats[collection] = count;
      }
      
      return importStats;
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de l\'import des données: $e', originalError: e);
    }
  }

  /// Upload backup to cloud storage
  Future<String> uploadBackupToCloud(File backupFile, String userId) async {
    try {
      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      final downloadUrl = await _storageService.uploadBackup(backupFile, backupId);
      
      // Save backup metadata to Firestore
      await _firestoreService.addDocument(AppConstants.backupsCollection, {
        'id': backupId,
        'fileName': backupFile.path.split('/').last,
        'fileSizeMB': await backupFile.length() / (1024 * 1024),
        'backupType': 'full',
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'downloadUrl': downloadUrl,
        'metadata': {
          'collections': [
            AppConstants.dossiersPrematuresCollection,
            AppConstants.dossiersATermeCollection,
            AppConstants.usersCollection,
          ],
        },
      });
      
      return downloadUrl;
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de l\'upload de la sauvegarde: $e', originalError: e);
    }
  }

  /// Restore from cloud backup
  Future<Map<String, int>> restoreFromCloud(String backupId) async {
    try {
      // Get backup metadata
      final backupDoc = await _firestoreService.getDocument(AppConstants.backupsCollection, backupId);
      if (!backupDoc.exists) {
        throw Exception('Sauvegarde non trouvée');
      }
      
      final backupData = backupDoc.data() as Map<String, dynamic>;
      final downloadUrl = backupData['downloadUrl'] as String;
      
      // Download backup file
      final directory = await getTemporaryDirectory();
      final localFile = File('${directory.path}/temp_backup.json');
      await _storageService.downloadFile(downloadUrl, localFile.path);
      
      // Import data
      final stats = await importData(localFile);
      
      // Clean up
      await localFile.delete();
      
      return stats;
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de la restauration: $e', originalError: e);
    }
  }

  /// Get backup history
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    try {
      final snapshot = await _firestoreService.getCollection(
        AppConstants.backupsCollection,
        orderBy: 'createdAt',
        descending: true,
      );
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'fileName': data['fileName'],
          'fileSizeMB': data['fileSizeMB'],
          'createdAt': data['createdAt'],
          'downloadUrl': data['downloadUrl'],
        };
      }).toList();
    } catch (e) {
      throw DatabaseFailure(message: 'Erreur lors de la récupération de l\'historique: $e', originalError: e);
    }
  }

  /// Delete old backups (older than 90 days)
  Future<void> deleteOldBackups() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      final snapshot = await _firestoreService.getCollection(
        AppConstants.backupsCollection,
      );
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        
        if (createdAt != null && createdAt.isBefore(cutoffDate)) {
          // Delete from storage
          final downloadUrl = data['downloadUrl'] as String?;
          if (downloadUrl != null) {
            await _storageService.deleteFile(downloadUrl);
          }
          
          // Delete metadata
          await _firestoreService.deleteDocument(AppConstants.backupsCollection, doc.id);
        }
      }
    } catch (e) {
      throw DatabaseFailure(message: 'Erreur lors de la suppression des anciennes sauvegardes: $e', originalError: e);
    }
  }

  /// Create partial backup (only dossiers)
  Future<File> exportDossiersOnly() async {
    try {
      final backupData = <String, dynamic>{};
      
      final collections = [
        AppConstants.dossiersPrematuresCollection,
        AppConstants.dossiersATermeCollection,
      ];
      
      for (final collection in collections) {
        final snapshot = await _firestoreService.getCollection(collection);
        backupData[collection] = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      }
      
      final jsonString = jsonEncode(backupData);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/neosante_dossiers_backup.json');
      await file.writeAsString(jsonString);
      
      return file;
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de l\'export des dossiers: $e', originalError: e);
    }
  }

  /// Validate backup file
  static Future<bool> validateBackupFile(File file) async {
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      // Check if at least one expected collection exists
      final validCollections = [
        AppConstants.dossiersPrematuresCollection,
        AppConstants.dossiersATermeCollection,
      ];
      
      return validCollections.any((collection) => data.containsKey(collection));
    } catch (_) {
      return false;
    }
  }
}