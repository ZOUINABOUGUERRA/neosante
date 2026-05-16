import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class DossierModel extends Equatable {
  final String id;
  final String dossierNumber;
  final String serviceType;

  // Step 2
  final String newbornName;
  final DateTime birthDateTime;
  final String motherName;
  final int gestationalAge;
  final String atcd;
  final String previousChildrenHistory;
  final String deliveryMethod;
  final String amnioticFluidColor;
  final String sageFemmeObservations;
  final List<String> imageUrls;

  // Step 3
  final double birthWeight;
  final double bodyTemperature;
  final double bloodGlucose;
  final int apgar1;
  final int apgar5;
  final String coloration;
  final String respiration;
  final String cry;
  final String tonus;
  final String malformations;

  // Step 4
  final bool prechauffe;
  final bool sechage;
  final bool stimulation;
  final String clampage;
  final bool verificationTonusRespiration;
  final String verificationTonusRespirationOther;
  final String miseSousChaleur;
  final String miseSousChaleurOther;
  final bool vitamineK;
  final bool bracelet;

  // Step 5
  final String airway;
  final String breathing;
  final String circulation;
  final String disabilityMedications;
  final String disabilityDoses;
  final String disabilityObservations;
  final String doctorName;
  final String sageFemmeName;

  // Step 6
  final String transferOption;
  final String? transferDoctorEmail;
  final String transferStatus;
  final String? assignedDoctorId;

  // Meta
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? transferredAt;
  final DateTime? archivedAt;
  final String status;
  final String? alertSeverity;

  const DossierModel({
    required this.id,
    required this.dossierNumber,
    required this.serviceType,
    required this.newbornName,
    required this.birthDateTime,
    required this.motherName,
    required this.gestationalAge,
    required this.atcd,
    required this.previousChildrenHistory,
    required this.deliveryMethod,
    required this.amnioticFluidColor,
    required this.sageFemmeObservations,
    required this.imageUrls,
    required this.birthWeight,
    required this.bodyTemperature,
    required this.bloodGlucose,
    required this.apgar1,
    required this.apgar5,
    required this.coloration,
    required this.respiration,
    required this.cry,
    required this.tonus,
    required this.malformations,
    required this.prechauffe,
    required this.sechage,
    required this.stimulation,
    required this.clampage,
    required this.verificationTonusRespiration,
    required this.verificationTonusRespirationOther,
    required this.miseSousChaleur,
    required this.miseSousChaleurOther,
    required this.vitamineK,
    required this.bracelet,
    required this.airway,
    required this.breathing,
    required this.circulation,
    required this.disabilityMedications,
    required this.disabilityDoses,
    required this.disabilityObservations,
    required this.doctorName,
    required this.sageFemmeName,
    required this.transferOption,
    this.transferDoctorEmail,
    required this.transferStatus,
    this.assignedDoctorId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.transferredAt,
    this.archivedAt,
    required this.status,
    this.alertSeverity,
  });

  // ---------------- SAFE PARSERS ----------------

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();

    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ---------------- FROM JSON ----------------

  factory DossierModel.fromJson(Map<String, dynamic> json, String id) {
    return DossierModel(
      id: id,
      dossierNumber: json['dossierNumber']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? AppConstants.serviceFullTerm,

      newbornName: json['newbornName']?.toString() ?? '',
      birthDateTime: _parseDate(json['birthDateTime']),
      motherName: json['motherName']?.toString() ?? '',
      gestationalAge: _parseInt(json['gestationalAge']),
      atcd: json['atcd']?.toString() ?? '',
      previousChildrenHistory: json['previousChildrenHistory']?.toString() ?? '',
      deliveryMethod: json['deliveryMethod']?.toString() ?? AppConstants.deliveryVaginal,
      amnioticFluidColor: json['amnioticFluidColor']?.toString() ?? 'clair',
      sageFemmeObservations: json['sageFemmeObservations']?.toString() ?? '',
      imageUrls: _parseStringList(json['imageUrls']),

      birthWeight: _parseDouble(json['birthWeight']),
      bodyTemperature: _parseDouble(json['bodyTemperature']),
      bloodGlucose: _parseDouble(json['bloodGlucose']),
      apgar1: _parseInt(json['apgar1']),
      apgar5: _parseInt(json['apgar5']),

      coloration: json['coloration']?.toString() ?? 'tout rose',
      respiration: json['respiration']?.toString() ?? 'régulière',
      cry: json['cry']?.toString() ?? 'fort',
      tonus: json['tonus']?.toString() ?? 'bon',
      malformations: json['malformations']?.toString() ?? '',

      prechauffe: _parseBool(json['prechauffe']),
      sechage: _parseBool(json['sechage']),
      stimulation: _parseBool(json['stimulation']),
      clampage: json['clampage']?.toString() ?? 'tardif',
      verificationTonusRespiration: _parseBool(json['verificationTonusRespiration']),
      verificationTonusRespirationOther: json['verificationTonusRespirationOther']?.toString() ?? '',

      miseSousChaleur: json['miseSousChaleur']?.toString() ?? 'Incubateur préchauffé + bonnet',
      miseSousChaleurOther: json['miseSousChaleurOther']?.toString() ?? '',
      vitamineK: _parseBool(json['vitamineK']),
      bracelet: _parseBool(json['bracelet']),

      airway: json['airway']?.toString() ?? 'stable',
      breathing: json['breathing']?.toString() ?? '',
      circulation: json['circulation']?.toString() ?? '',
      disabilityMedications: json['disabilityMedications']?.toString() ?? '',
      disabilityDoses: json['disabilityDoses']?.toString() ?? '',
      disabilityObservations: json['disabilityObservations']?.toString() ?? '',

      doctorName: json['doctorName']?.toString() ?? '',
      sageFemmeName: json['sageFemmeName']?.toString() ?? '',

      transferOption: json['transferOption']?.toString() ?? 'Avec sa mère',
      transferDoctorEmail: json['transferDoctorEmail']?.toString(),
      transferStatus: json['transferStatus']?.toString() ?? 'none',
      assignedDoctorId: json['assignedDoctorId']?.toString(),

      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
      transferredAt: json['transferredAt'] != null ? _parseDate(json['transferredAt']) : null,
      archivedAt: json['archivedAt'] != null ? _parseDate(json['archivedAt']) : null,

      status: json['status']?.toString() ?? AppConstants.dossierStatusActive,
      alertSeverity: json['alertSeverity']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dossierNumber': dossierNumber,
      'serviceType': serviceType,
      'newbornName': newbornName,
      'birthDateTime': Timestamp.fromDate(birthDateTime),
      'motherName': motherName,
      'gestationalAge': gestationalAge,
      'atcd': atcd,
      'previousChildrenHistory': previousChildrenHistory,
      'deliveryMethod': deliveryMethod,
      'amnioticFluidColor': amnioticFluidColor,
      'sageFemmeObservations': sageFemmeObservations,
      'imageUrls': imageUrls,

      'birthWeight': birthWeight,
      'bodyTemperature': bodyTemperature,
      'bloodGlucose': bloodGlucose,

      'apgar1': apgar1,
      'apgar5': apgar5,

      'coloration': coloration,
      'respiration': respiration,
      'cry': cry,
      'tonus': tonus,
      'malformations': malformations,

      'prechauffe': prechauffe,
      'sechage': sechage,
      'stimulation': stimulation,
      'clampage': clampage,
      'verificationTonusRespiration': verificationTonusRespiration,
      'verificationTonusRespirationOther': verificationTonusRespirationOther,

      'miseSousChaleur': miseSousChaleur,
      'miseSousChaleurOther': miseSousChaleurOther,
      'vitamineK': vitamineK,
      'bracelet': bracelet,

      'airway': airway,
      'breathing': breathing,
      'circulation': circulation,
      'disabilityMedications': disabilityMedications,
      'disabilityDoses': disabilityDoses,
      'disabilityObservations': disabilityObservations,

      'doctorName': doctorName,
      'sageFemmeName': sageFemmeName,

      'transferOption': transferOption,
      'transferDoctorEmail': transferDoctorEmail,
      'transferStatus': transferStatus,
      'assignedDoctorId': assignedDoctorId,

      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),

      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (transferredAt != null) 'transferredAt': Timestamp.fromDate(transferredAt!),
      if (archivedAt != null) 'archivedAt': Timestamp.fromDate(archivedAt!),

      if (alertSeverity != null) 'alertSeverity': alertSeverity,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dossierNumber': dossierNumber,
      'newbornName': newbornName,
      'serviceType': serviceType,
      'motherName': motherName,
      'birthWeight': birthWeight,
      'status': status,
      'alertSeverity': alertSeverity,
      'createdAt': createdAt,
    };
  }

  bool get isPremature => gestationalAge < AppConstants.prematureThreshold;
  bool get isActive => status == AppConstants.dossierStatusActive;
  bool get isTransferPending => transferStatus == AppConstants.transferStatusPending;

  int get ageInDays {
    final days = DateTime.now().difference(birthDateTime).inDays;
    return days < 0 ? 0 : days;
  }

  @override
  List<Object?> get props => [id, dossierNumber, newbornName, status];
}