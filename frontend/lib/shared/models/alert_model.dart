import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class AlertModel extends Equatable {
  final String id;
  final String dossierId;
  final String dossierNumber;
  final String newbornName;
  final String parameter;
  final dynamic value;
  final String severity;
  final String message;
  final bool isRead;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final DateTime timestamp;
  final String? actionTaken;

  const AlertModel({
    required this.id,
    required this.dossierId,
    required this.dossierNumber,
    required this.newbornName,
    required this.parameter,
    required this.value,
    required this.severity,
    required this.message,
    this.isRead = false,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    required this.timestamp,
    this.actionTaken,
  });

  /// ---------------- FIRESTORE FROM JSON ----------------
  factory AlertModel.fromJson(Map<String, dynamic> json, String docId) {
    return AlertModel(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      dossierNumber: json['dossierNumber'] ?? '',
      newbornName: json['newbornName'] ?? '',
      parameter: json['parameter'] ?? '',
      value: json['value'],
      severity: json['severity'] ?? AppConstants.alertSeverityInfo,
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      isAcknowledged: json['isAcknowledged'] ?? false,
      acknowledgedBy: json['acknowledgedBy'],
      acknowledgedAt: (json['acknowledgedAt'] is Timestamp)
          ? (json['acknowledgedAt'] as Timestamp).toDate()
          : null,
      timestamp: (json['timestamp'] is Timestamp)
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      actionTaken: json['actionTaken'],
    );
  }

  /// ---------------- TO FIRESTORE ----------------
  Map<String, dynamic> toJson() {
    return {
      'dossierId': dossierId,
      'dossierNumber': dossierNumber,
      'newbornName': newbornName,
      'parameter': parameter,
      'value': value,
      'severity': severity,
      'message': message,
      'isRead': isRead,
      'isAcknowledged': isAcknowledged,
      'acknowledgedBy': acknowledgedBy,
      'acknowledgedAt':
          acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'timestamp': Timestamp.fromDate(timestamp),
      'actionTaken': actionTaken,
    };
  }

  /// ---------------- LOGIC ----------------
  bool get requiresImmediateAttention =>
      severity == AppConstants.alertSeverityCritical;

  int get severityColor {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return 0xFFFF3B3B;
      case AppConstants.alertSeverityWarning:
        return 0xFFFFA500;
      case AppConstants.alertSeverityMedium:
        return 0xFFFFD700;
      default:
        return 0xFF4CAF50;
    }
  }

  String get severityLabel {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return 'Urgence';
      case AppConstants.alertSeverityWarning:
        return 'Surveillance';
      case AppConstants.alertSeverityMedium:
        return 'Attention';
      default:
        return 'Information';
    }
  }

  /// ---------------- COPY ----------------
  AlertModel copyWith({
    String? id,
    String? dossierId,
    String? dossierNumber,
    String? newbornName,
    String? parameter,
    dynamic value,
    String? severity,
    String? message,
    bool? isRead,
    bool? isAcknowledged,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    DateTime? timestamp,
    String? actionTaken,
  }) {
    return AlertModel(
      id: id ?? this.id,
      dossierId: dossierId ?? this.dossierId,
      dossierNumber: dossierNumber ?? this.dossierNumber,
      newbornName: newbornName ?? this.newbornName,
      parameter: parameter ?? this.parameter,
      value: value ?? this.value,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      timestamp: timestamp ?? this.timestamp,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dossierId,
        dossierNumber,
        parameter,
        severity,
        isRead,
        isAcknowledged,
        timestamp,
      ];
}