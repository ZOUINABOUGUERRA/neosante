import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Backup model for data export/import operations.
class BackupModel extends Equatable {
  final String id;
  final String fileName;
  final double fileSizeMB;
  final String backupType; // 'full', 'partial'
  final String createdBy;
  final DateTime createdAt;
  final String? downloadUrl;
  final Map<String, dynamic>? metadata; // Number of dossiers, alerts, etc.

  const BackupModel({
    required this.id,
    required this.fileName,
    required this.fileSizeMB,
    required this.backupType,
    required this.createdBy,
    required this.createdAt,
    this.downloadUrl,
    this.metadata,
  });

  /// Creates a BackupModel from Firestore document.
  factory BackupModel.fromJson(Map<String, dynamic> json, String docId) {
    return BackupModel(
      id: docId,
      fileName: json['fileName'] ?? '',
      fileSizeMB: (json['fileSizeMB'] ?? 0).toDouble(),
      backupType: json['backupType'] ?? 'full',
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      downloadUrl: json['downloadUrl'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts BackupModel to Firestore document.
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSizeMB': fileSizeMB,
      'backupType': backupType,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'downloadUrl': downloadUrl,
      'metadata': metadata,
    };
  }

  /// Returns a formatted string of the file size.
  String get formattedFileSize => '${fileSizeMB.toStringAsFixed(2)} MB';

  /// Returns the date formatted for display.
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 0) return 'il y a ${diff.inDays} jour(s)';
    if (diff.inHours > 0) return 'il y a ${diff.inHours} heure(s)';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes} minute(s)';
    return 'à l\'instant';
  }

  BackupModel copyWith({
    String? id,
    String? fileName,
    double? fileSizeMB,
    String? backupType,
    String? createdBy,
    DateTime? createdAt,
    String? downloadUrl,
    Map<String, dynamic>? metadata,
  }) {
    return BackupModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSizeMB: fileSizeMB ?? this.fileSizeMB,
      backupType: backupType ?? this.backupType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, fileName, backupType, createdAt];
}