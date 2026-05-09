import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Glucose reading record for surveillance monitoring.
class GlucoseReading extends Equatable {
  final String id;
  final String dossierId;
  final double value; // mg/dL
  final DateTime recordedAt;
  final String recordedBy;
  final String? notes;

  const GlucoseReading({
    required this.id,
    required this.dossierId,
    required this.value,
    required this.recordedAt,
    required this.recordedBy,
    this.notes,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json, String docId) {
    return GlucoseReading(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      recordedAt: (json['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: json['recordedBy'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dossierId': dossierId,
      'value': value,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'recordedBy': recordedBy,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, value, recordedAt];
}

/// Temperature reading record for surveillance monitoring.
class TemperatureReading extends Equatable {
  final String id;
  final String dossierId;
  final double value; // Celsius
  final DateTime recordedAt;
  final String recordedBy;
  final String? notes;

  const TemperatureReading({
    required this.id,
    required this.dossierId,
    required this.value,
    required this.recordedAt,
    required this.recordedBy,
    this.notes,
  });

  factory TemperatureReading.fromJson(Map<String, dynamic> json, String docId) {
    return TemperatureReading(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      recordedAt: (json['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: json['recordedBy'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dossierId': dossierId,
      'value': value,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'recordedBy': recordedBy,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, value, recordedAt];
}

/// Medication prescription record.
class Medication extends Equatable {
  final String id;
  final String dossierId;
  final String medicationName;
  final String dosage;
  final String route; // 'IV', 'IM', 'PO', 'SC'
  final String frequency;
  final DateTime prescribedAt;
  final String prescribedBy;
  final DateTime? administrationTime;
  final String? administeredBy;
  final bool isAdministered;
  final String? notes;

  const Medication({
    required this.id,
    required this.dossierId,
    required this.medicationName,
    required this.dosage,
    required this.route,
    required this.frequency,
    required this.prescribedAt,
    required this.prescribedBy,
    this.administrationTime,
    this.administeredBy,
    this.isAdministered = false,
    this.notes,
  });

  factory Medication.fromJson(Map<String, dynamic> json, String docId) {
    return Medication(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      route: json['route'] ?? '',
      frequency: json['frequency'] ?? '',
      prescribedAt: (json['prescribedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prescribedBy: json['prescribedBy'] ?? '',
      administrationTime: (json['administrationTime'] as Timestamp?)?.toDate(),
      administeredBy: json['administeredBy'],
      isAdministered: json['isAdministered'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dossierId': dossierId,
      'medicationName': medicationName,
      'dosage': dosage,
      'route': route,
      'frequency': frequency,
      'prescribedAt': Timestamp.fromDate(prescribedAt),
      'prescribedBy': prescribedBy,
      'administrationTime': administrationTime != null ? Timestamp.fromDate(administrationTime!) : null,
      'administeredBy': administeredBy,
      'isAdministered': isAdministered,
      'notes': notes,
    };
  }

  Medication copyWith({
    bool? isAdministered,
    DateTime? administrationTime,
    String? administeredBy,
  }) {
    return Medication(
      id: id,
      dossierId: dossierId,
      medicationName: medicationName,
      dosage: dosage,
      route: route,
      frequency: frequency,
      prescribedAt: prescribedAt,
      prescribedBy: prescribedBy,
      administrationTime: administrationTime ?? this.administrationTime,
      administeredBy: administeredBy ?? this.administeredBy,
      isAdministered: isAdministered ?? this.isAdministered,
      notes: notes,
    );
  }

  @override
  List<Object?> get props => [id, medicationName, isAdministered];
}

/// Clinical observation record.
class Observation extends Equatable {
  final String id;
  final String dossierId;
  final String content;
  final String category; // 'general', 'neurological', 'respiratory', 'cardiovascular', 'digestive'
  final DateTime recordedAt;
  final String recordedBy;

  const Observation({
    required this.id,
    required this.dossierId,
    required this.content,
    required this.category,
    required this.recordedAt,
    required this.recordedBy,
  });

  factory Observation.fromJson(Map<String, dynamic> json, String docId) {
    return Observation(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'general',
      recordedAt: (json['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: json['recordedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dossierId': dossierId,
      'content': content,
      'category': category,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'recordedBy': recordedBy,
    };
  }

  @override
  List<Object?> get props => [id, content, recordedAt];
}