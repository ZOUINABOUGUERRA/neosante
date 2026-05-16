import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ==============================
/// HELPERS
/// ==============================

DateTime _parseDate(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  return DateTime.now();
}

double _parseDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is double) {
    return value;
  }

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  return 0;
}

/// ==============================
/// GLUCOSE READING
/// ==============================

class GlucoseReading extends Equatable {
  final String id;

  final String dossierId;

  final double value;

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

  factory GlucoseReading.fromJson(
    Map<String, dynamic> json,
    String docId,
  ) {
    return GlucoseReading(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      value: _parseDouble(json['value']),
      recordedAt: _parseDate(json['recordedAt']),
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
      'type': 'glucose',
    };
  }

  GlucoseReading copyWith({
    String? id,
    String? dossierId,
    double? value,
    DateTime? recordedAt,
    String? recordedBy,
    String? notes,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      dossierId: dossierId ?? this.dossierId,
      value: value ?? this.value,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dossierId,
        value,
        recordedAt,
        recordedBy,
        notes,
      ];
}

/// ==============================
/// TEMPERATURE READING
/// ==============================

class TemperatureReading extends Equatable {
  final String id;

  final String dossierId;

  final double value;

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

  factory TemperatureReading.fromJson(
    Map<String, dynamic> json,
    String docId,
  ) {
    return TemperatureReading(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      value: _parseDouble(json['value']),
      recordedAt: _parseDate(json['recordedAt']),
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
      'type': 'temperature',
    };
  }

  TemperatureReading copyWith({
    String? id,
    String? dossierId,
    double? value,
    DateTime? recordedAt,
    String? recordedBy,
    String? notes,
  }) {
    return TemperatureReading(
      id: id ?? this.id,
      dossierId: dossierId ?? this.dossierId,
      value: value ?? this.value,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dossierId,
        value,
        recordedAt,
        recordedBy,
        notes,
      ];
}

/// ==============================
/// MEDICATION
/// ==============================

class Medication extends Equatable {
  final String id;

  final String dossierId;

  final String medicationName;

  final String dosage;

  final String route;

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

  factory Medication.fromJson(
    Map<String, dynamic> json,
    String docId,
  ) {
    return Medication(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      route: json['route'] ?? '',
      frequency: json['frequency'] ?? '',
      prescribedAt: _parseDate(json['prescribedAt']),
      prescribedBy: json['prescribedBy'] ?? '',
      administrationTime: json['administrationTime'] != null
          ? _parseDate(json['administrationTime'])
          : null,
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
      'administrationTime': administrationTime != null
          ? Timestamp.fromDate(administrationTime!)
          : null,
      'administeredBy': administeredBy,
      'isAdministered': isAdministered,
      'notes': notes,
    };
  }

  Medication copyWith({
    String? id,
    String? dossierId,
    String? medicationName,
    String? dosage,
    String? route,
    String? frequency,
    DateTime? prescribedAt,
    String? prescribedBy,
    DateTime? administrationTime,
    String? administeredBy,
    bool? isAdministered,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      dossierId: dossierId ?? this.dossierId,
      medicationName:
          medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      route: route ?? this.route,
      frequency: frequency ?? this.frequency,
      prescribedAt:
          prescribedAt ?? this.prescribedAt,
      prescribedBy:
          prescribedBy ?? this.prescribedBy,
      administrationTime:
          administrationTime ??
              this.administrationTime,
      administeredBy:
          administeredBy ?? this.administeredBy,
      isAdministered:
          isAdministered ?? this.isAdministered,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dossierId,
        medicationName,
        dosage,
        route,
        frequency,
        prescribedAt,
        prescribedBy,
        administrationTime,
        administeredBy,
        isAdministered,
        notes,
      ];
}

/// ==============================
/// OBSERVATION
/// ==============================

class Observation extends Equatable {
  final String id;

  final String dossierId;

  final String content;

  final String category;

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

  factory Observation.fromJson(
    Map<String, dynamic> json,
    String docId,
  ) {
    return Observation(
      id: docId,
      dossierId: json['dossierId'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'general',
      recordedAt: _parseDate(json['recordedAt']),
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

  Observation copyWith({
    String? id,
    String? dossierId,
    String? content,
    String? category,
    DateTime? recordedAt,
    String? recordedBy,
  }) {
    return Observation(
      id: id ?? this.id,
      dossierId: dossierId ?? this.dossierId,
      content: content ?? this.content,
      category: category ?? this.category,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dossierId,
        content,
        category,
        recordedAt,
        recordedBy,
      ];
}