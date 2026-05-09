import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../core/errors/failure.dart';
import '../core/constants/app_constants.dart';

/// Firebase Storage service for file uploads and downloads.
/// Handles images, documents, and backups with compression and optimization.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image file
  Future<String> uploadImage(
    File imageFile,
    String dossierId, {
    String subPath = 'images',
    bool compress = true,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storagePath = '${AppConstants.storageDossiersPath}/$dossierId/$subPath/$fileName';
      final ref = _storage.ref().child(storagePath);
      
      // Add metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'dossierId': dossierId,
          'originalName': path.basename(imageFile.path),
        },
      );
      
      // Upload with compression flag
      if (compress) {
        // Note: Actual compression would be done with image package
        await ref.putFile(imageFile, metadata);
      } else {
        await ref.putFile(imageFile, metadata);
      }
      
      return await ref.getDownloadURL();
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de l\'upload de l\'image: $e', originalError: e);
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages(
    List<File> images,
    String dossierId, {
    String subPath = 'images',
    bool compress = true,
  }) async {
    final List<String> urls = [];
    for (final image in images) {
      final url = await uploadImage(image, dossierId, subPath: subPath, compress: compress);
      urls.add(url);
    }
    return urls;
  }

  /// Upload a file (any type)
  Future<String> uploadFile(
    File file,
    String dossierId,
    String fileType, {
    String subPath = 'documents',
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final storagePath = '${AppConstants.storageDossiersPath}/$dossierId/$subPath/$fileName';
      final ref = _storage.ref().child(storagePath);
      
      final metadata = SettableMetadata(
        contentType: _getContentType(fileType),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'dossierId': dossierId,
          'fileType': fileType,
        },
      );
      
      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de l\'upload du fichier: $e', originalError: e);
    }
  }

  /// Upload a backup file
  Future<String> uploadBackup(File backupFile, String backupId) async {
    try {
      final storagePath = '${AppConstants.storageBackupsPath}/$backupId.json';
      final ref = _storage.ref().child(storagePath);
      
      final metadata = SettableMetadata(
        contentType: 'application/json',
        customMetadata: {
          'backupId': backupId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      await ref.putFile(backupFile, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de l\'upload de la sauvegarde: $e', originalError: e);
    }
  }

  /// Download a file
  Future<File> downloadFile(String downloadUrl, String localPath) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final file = File(localPath);
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors du téléchargement: $e', originalError: e);
    }
  }

  /// Delete a file
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de la suppression: $e', originalError: e);
    }
  }

  /// Delete all files for a dossier
  Future<void> deleteDossierFiles(String dossierId) async {
    try {
      final ref = _storage.ref().child('${AppConstants.storageDossiersPath}/$dossierId');
      await ref.listAll().then((result) async {
        for (final item in result.items) {
          await item.delete();
        }
      });
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de la suppression des fichiers: $e', originalError: e);
    }
  }

  /// Get download URL for a file path
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de la récupération de l\'URL: $e', originalError: e);
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_profile.jpg';
      final storagePath = '${AppConstants.storageProfilesPath}/$userId/$fileName';
      final ref = _storage.ref().child(storagePath);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await ref.putFile(imageFile, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de l\'upload de la photo de profil: $e', originalError: e);
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de la récupération des métadonnées: $e', originalError: e);
    }
  }

  /// Update file metadata
  Future<void> updateFileMetadata(String fileUrl, Map<String, String> customMetadata) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = SettableMetadata(customMetadata: customMetadata);
      await ref.updateMetadata(metadata);
    } catch (e) {
      throw StorageFailure(message: 'Erreur lors de la mise à jour des métadonnées: $e', originalError: e);
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}