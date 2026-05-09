import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Transfer request model for patient transfers between services or to doctors.
class TransferModel extends Equatable {
  final String id;
  final String dossierId;
  final String dossierNumber;
  final String newbornName;
  final String requestedBy; // User ID of requester
  final String requestedByName; // Full name of requester
  final String requestedTo; // User ID of receiving doctor
  final String requestedToEmail; // Email of receiving doctor
  final String transferOption; // 'En néonatalogie', 'Avec sa mère', 'Autre'
  final String? transferReason;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? respondedBy;
  final DateTime? completedAt;

  const TransferModel({
    required this.id,
    required this.dossierId,
    required this.dossierNumber,
    required this.newbornName,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedTo,
    required this.requestedToEmail,
    required this.transferOption,
    this.transferReason,
    required this.status,
    this.rejectionReason,
    required this.requestedAt,
    this.respondedAt,
    this.respondedBy,
    this.completedAt,
  });

  /// Creates a TransferModel from Firestore document.
  factory TransferModel.fromJson(Map<String, dynamic> json, String docId) {
    return TransferModel(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      dossierNumber: json['dossierNumber'] ?? '',
      newbornName: json['newbornName'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      requestedByName: json['requestedByName'] ?? '',
      requestedTo: json['requestedTo'] ?? '',
      requestedToEmail: json['requestedToEmail'] ?? '',
      transferOption: json['transferOption'] ?? 'Avec sa mère',
      transferReason: json['transferReason'],
      status: json['status'] ?? AppConstants.transferStatusPending,
      rejectionReason: json['rejectionReason'],
      requestedAt: (json['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (json['respondedAt'] as Timestamp?)?.toDate(),
      respondedBy: json['respondedBy'],
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts TransferModel to Firestore document.
  Map<String, dynamic> toJson() {
    return {
      'dossierId': dossierId,
      'dossierNumber': dossierNumber,
      'newbornName': newbornName,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedTo': requestedTo,
      'requestedToEmail': requestedToEmail,
      'transferOption': transferOption,
      'transferReason': transferReason,
      'status': status,
      'rejectionReason': rejectionReason,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedBy': respondedBy,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Returns true if the transfer is pending approval.
  bool get isPending => status == AppConstants.transferStatusPending;

  /// Returns true if the transfer is approved.
  bool get isApproved => status == AppConstants.transferStatusApproved;

  /// Returns true if the transfer is rejected.
  bool get isRejected => status == AppConstants.transferStatusRejected;

  /// Returns true if the transfer is completed.
  bool get isCompleted => status == AppConstants.transferStatusCompleted;

  TransferModel copyWith({
    String? id,
    String? dossierId,
    String? dossierNumber,
    String? newbornName,
    String? requestedBy,
    String? requestedByName,
    String? requestedTo,
    String? requestedToEmail,
    String? transferOption,
    String? transferReason,
    String? status,
    String? rejectionReason,
    DateTime? requestedAt,
    DateTime? respondedAt,
    String? respondedBy,
    DateTime? completedAt,
  }) {
    return TransferModel(
      id: id ?? this.id,
      dossierId: dossierId ?? this.dossierId,
      dossierNumber: dossierNumber ?? this.dossierNumber,
      newbornName: newbornName ?? this.newbornName,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      requestedTo: requestedTo ?? this.requestedTo,
      requestedToEmail: requestedToEmail ?? this.requestedToEmail,
      transferOption: transferOption ?? this.transferOption,
      transferReason: transferReason ?? this.transferReason,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, dossierId, status];
}