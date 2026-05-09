import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Medical dossier model for a newborn patient.
/// Supports both premature and full-term newborns.
class DossierModel extends Equatable {
  final String id;
  final String dossierNumber;
  final String serviceType; // 'premature' or 'fullterm'
  
  // Step 2: Identification
  final String newbornName;
  final DateTime birthDateTime;
  final String motherName;
  final int gestationalAge; // in weeks
  final String atcd; // Antécédents
  final String previousChildrenHistory;
  final String deliveryMethod; // 'voie basse', 'césarienne', or custom
  final String amnioticFluidColor;
  final String sageFemmeObservations;
  final List<String> imageUrls;
  
  // Step 3: Données à la naissance
  final double birthWeight; // grams
  final double bodyTemperature; // Celsius
  final double bloodGlucose; // mg/dL
  final int apgar1; // 1 minute
  final int apgar5; // 5 minutes
  final String coloration; // 'bleu/pâle', 'corps rose extrémités bleues', 'tout rose'
  final String respiration; // 'absente', 'faible irrégulière', 'régulière'
  final String cry; // 'absent', 'irrégulier', 'fort'
  final String tonus; // 'flasque', 'faible', 'bon'
  final String malformations;
  
  // Step 4: Gestes systématiques
  final bool prechauffe;
  final bool sechage;
  final bool stimulation;
  final String clampage; // 'immédiate' or 'tardif'
  final bool verificationTonusRespiration;
  final String verificationTonusRespirationOther;
  final String miseSousChaleur; // 'Incubateur préchauffé + bonnet', 'lampe chauffante', 'peau à peau', 'sac', or custom
  final String miseSousChaleurOther;
  final bool vitamineK;
  final bool bracelet;
  
  // Step 5: Réanimation
  final String airway; // 'stable' or 'unstable'
  final String breathing; // 'VPP', 'CPAP', 'Ajuster O2' (only if airway unstable)
  final String circulation; // 'VPP + compression thoracique', 'intubation' (only if breathing unstable)
  final String disabilityMedications;
  final String disabilityDoses;
  final String disabilityObservations;
  final String doctorName;
  final String sageFemmeName;
  
  // Step 6: Transfert
  final String transferOption; // 'En néonatalogie', 'Avec sa mère', 'Autre'
  final String? transferDoctorEmail;
  final String transferStatus; // 'pending', 'approved', 'rejected', 'none'
  final String? assignedDoctorId;
  
  // Metadata
  final String createdBy; // User ID
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? transferredAt;
  final DateTime? archivedAt;
  final String status; // 'active', 'transferred', 'archived', 'closed'
  final String? alertSeverity; // highest active alert severity

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
    required this.transferDoctorEmail,
    required this.transferStatus,
    required this.assignedDoctorId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.transferredAt,
    this.archivedAt,
    required this.status,
    this.alertSeverity,
  });

  /// Creates a DossierModel from Firestore document.
  factory DossierModel.fromJson(Map<String, dynamic> json, String docId) {
    return DossierModel(
      id: docId,
      dossierNumber: json['dossierNumber'] ?? '',
      serviceType: json['serviceType'] ?? AppConstants.serviceFullTerm,
      newbornName: json['newbornName'] ?? '',
      birthDateTime: (json['birthDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      motherName: json['motherName'] ?? '',
      gestationalAge: json['gestationalAge'] ?? 0,
      atcd: json['atcd'] ?? '',
      previousChildrenHistory: json['previousChildrenHistory'] ?? '',
      deliveryMethod: json['deliveryMethod'] ?? AppConstants.deliveryVaginal,
      amnioticFluidColor: json['amnioticFluidColor'] ?? 'clair',
      sageFemmeObservations: json['sageFemmeObservations'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      birthWeight: (json['birthWeight'] ?? 0).toDouble(),
      bodyTemperature: (json['bodyTemperature'] ?? 0).toDouble(),
      bloodGlucose: (json['bloodGlucose'] ?? 0).toDouble(),
      apgar1: json['apgar1'] ?? 0,
      apgar5: json['apgar5'] ?? 0,
      coloration: json['coloration'] ?? 'tout rose',
      respiration: json['respiration'] ?? 'régulière',
      cry: json['cry'] ?? 'fort',
      tonus: json['tonus'] ?? 'bon',
      malformations: json['malformations'] ?? '',
      prechauffe: json['prechauffe'] ?? false,
      sechage: json['sechage'] ?? false,
      stimulation: json['stimulation'] ?? false,
      clampage: json['clampage'] ?? 'tardif',
      verificationTonusRespiration: json['verificationTonusRespiration'] ?? false,
      verificationTonusRespirationOther: json['verificationTonusRespirationOther'] ?? '',
      miseSousChaleur: json['miseSousChaleur'] ?? 'Incubateur préchauffé + bonnet',
      miseSousChaleurOther: json['miseSousChaleurOther'] ?? '',
      vitamineK: json['vitamineK'] ?? false,
      bracelet: json['bracelet'] ?? false,
      airway: json['airway'] ?? 'stable',
      breathing: json['breathing'] ?? '',
      circulation: json['circulation'] ?? '',
      disabilityMedications: json['disabilityMedications'] ?? '',
      disabilityDoses: json['disabilityDoses'] ?? '',
      disabilityObservations: json['disabilityObservations'] ?? '',
      doctorName: json['doctorName'] ?? '',
      sageFemmeName: json['sageFemmeName'] ?? '',
      transferOption: json['transferOption'] ?? 'Avec sa mère',
      transferDoctorEmail: json['transferDoctorEmail'],
      transferStatus: json['transferStatus'] ?? 'none',
      assignedDoctorId: json['assignedDoctorId'],
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      transferredAt: (json['transferredAt'] as Timestamp?)?.toDate(),
      archivedAt: (json['archivedAt'] as Timestamp?)?.toDate(),
      status: json['status'] ?? AppConstants.dossierStatusActive,
      alertSeverity: json['alertSeverity'],
    );
  }

  /// Converts DossierModel to Firestore document.
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
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'transferredAt': transferredAt != null ? Timestamp.fromDate(transferredAt!) : null,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'status': status,
      'alertSeverity': alertSeverity,
    };
  }

  /// Returns true if the newborn is premature (<37 weeks).
  bool get isPremature => gestationalAge < AppConstants.prematureThreshold;

  /// Returns true if the dossier is active (not closed or archived).
  bool get isActive => status == AppConstants.dossierStatusActive;

  /// Returns true if transfer is pending.
  bool get isTransferPending => transferStatus == AppConstants.transferStatusPending;

  /// Returns the age in days.
  int get ageInDays => DateTime.now().difference(birthDateTime).inDays;

  DossierModel copyWith({
    String? id,
    String? dossierNumber,
    String? serviceType,
    String? newbornName,
    DateTime? birthDateTime,
    String? motherName,
    int? gestationalAge,
    String? atcd,
    String? previousChildrenHistory,
    String? deliveryMethod,
    String? amnioticFluidColor,
    String? sageFemmeObservations,
    List<String>? imageUrls,
    double? birthWeight,
    double? bodyTemperature,
    double? bloodGlucose,
    int? apgar1,
    int? apgar5,
    String? coloration,
    String? respiration,
    String? cry,
    String? tonus,
    String? malformations,
    bool? prechauffe,
    bool? sechage,
    bool? stimulation,
    String? clampage,
    bool? verificationTonusRespiration,
    String? verificationTonusRespirationOther,
    String? miseSousChaleur,
    String? miseSousChaleurOther,
    bool? vitamineK,
    bool? bracelet,
    String? airway,
    String? breathing,
    String? circulation,
    String? disabilityMedications,
    String? disabilityDoses,
    String? disabilityObservations,
    String? doctorName,
    String? sageFemmeName,
    String? transferOption,
    String? transferDoctorEmail,
    String? transferStatus,
    String? assignedDoctorId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? transferredAt,
    DateTime? archivedAt,
    String? status,
    String? alertSeverity,
  }) {
    return DossierModel(
      id: id ?? this.id,
      dossierNumber: dossierNumber ?? this.dossierNumber,
      serviceType: serviceType ?? this.serviceType,
      newbornName: newbornName ?? this.newbornName,
      birthDateTime: birthDateTime ?? this.birthDateTime,
      motherName: motherName ?? this.motherName,
      gestationalAge: gestationalAge ?? this.gestationalAge,
      atcd: atcd ?? this.atcd,
      previousChildrenHistory: previousChildrenHistory ?? this.previousChildrenHistory,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      amnioticFluidColor: amnioticFluidColor ?? this.amnioticFluidColor,
      sageFemmeObservations: sageFemmeObservations ?? this.sageFemmeObservations,
      imageUrls: imageUrls ?? this.imageUrls,
      birthWeight: birthWeight ?? this.birthWeight,
      bodyTemperature: bodyTemperature ?? this.bodyTemperature,
      bloodGlucose: bloodGlucose ?? this.bloodGlucose,
      apgar1: apgar1 ?? this.apgar1,
      apgar5: apgar5 ?? this.apgar5,
      coloration: coloration ?? this.coloration,
      respiration: respiration ?? this.respiration,
      cry: cry ?? this.cry,
      tonus: tonus ?? this.tonus,
      malformations: malformations ?? this.malformations,
      prechauffe: prechauffe ?? this.prechauffe,
      sechage: sechage ?? this.sechage,
      stimulation: stimulation ?? this.stimulation,
      clampage: clampage ?? this.clampage,
      verificationTonusRespiration: verificationTonusRespiration ?? this.verificationTonusRespiration,
      verificationTonusRespirationOther: verificationTonusRespirationOther ?? this.verificationTonusRespirationOther,
      miseSousChaleur: miseSousChaleur ?? this.miseSousChaleur,
      miseSousChaleurOther: miseSousChaleurOther ?? this.miseSousChaleurOther,
      vitamineK: vitamineK ?? this.vitamineK,
      bracelet: bracelet ?? this.bracelet,
      airway: airway ?? this.airway,
      breathing: breathing ?? this.breathing,
      circulation: circulation ?? this.circulation,
      disabilityMedications: disabilityMedications ?? this.disabilityMedications,
      disabilityDoses: disabilityDoses ?? this.disabilityDoses,
      disabilityObservations: disabilityObservations ?? this.disabilityObservations,
      doctorName: doctorName ?? this.doctorName,
      sageFemmeName: sageFemmeName ?? this.sageFemmeName,
      transferOption: transferOption ?? this.transferOption,
      transferDoctorEmail: transferDoctorEmail ?? this.transferDoctorEmail,
      transferStatus: transferStatus ?? this.transferStatus,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transferredAt: transferredAt ?? this.transferredAt,
      archivedAt: archivedAt ?? this.archivedAt,
      status: status ?? this.status,
      alertSeverity: alertSeverity ?? this.alertSeverity,
    );
  }

  @override
  List<Object?> get props => [id, dossierNumber, newbornName, status];
}