/// Application-wide constants for the NéoSanté platform.
/// Includes Firebase collections, storage paths, validation rules,
/// and medical reference ranges.
//import 'app_constants.dart';
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ==================== FIREBASE COLLECTIONS ====================
  static const String usersCollection = 'users';
  static const String dossiersPrematuresCollection = 'dossiers_prematures';
  static const String dossiersATermeCollection = 'dossiers_a_terme';
  static const String surveillanceCollection = 'surveillance';
  static const String alertsCollection = 'alerts';
  static const String notificationsCollection = 'notifications';
  static const String transfersCollection = 'transfers';
  static const String archivesCollection = 'archives';
  static const String backupsCollection = 'backups';

  // ==================== FIREBASE STORAGE PATHS ====================
  static const String storageDossiersPath = 'dossiers';
  static const String storageProfilesPath = 'profiles';
  static const String storageBackupsPath = 'backups';
  static const String storageDocumentsPath = 'documents';

  // ==================== DOSSIER STATUS ====================
  static const String dossierStatusActive = 'active';
  static const String dossierStatusTransferred = 'transferred';
  static const String dossierStatusArchived = 'archived';
  static const String dossierStatusClosed = 'closed';

  // ==================== TRANSFER STATUS ====================
  static const String transferStatusPending = 'pending';
  static const String transferStatusApproved = 'approved';
  static const String transferStatusRejected = 'rejected';
  static const String transferStatusCompleted = 'completed';

  // ==================== ALERT SEVERITY ====================
  static const String alertSeverityCritical = 'critical';
  static const String alertSeverityWarning = 'warning';
  static const String alertSeverityMedium = 'medium';
  static const String alertSeverityInfo = 'info';

  // ==================== USER ROLES ====================
  static const String roleAdmin = 'admin';
  static const String roleSageFemme = 'sage-femme';

  // ==================== SERVICE TYPES ====================
  static const String servicePremature = 'premature';
  static const String serviceFullTerm = 'fullterm';

  // ==================== DELIVERY METHODS ====================
  static const String deliveryVaginal = 'voie basse';
  static const String deliveryCesarean = 'césarienne';
  static const String deliveryOther = 'autre';

  // ==================== MEDICAL REFERENCE RANGES (GLYCEMIA mg/dL) ====================
  static const double glucoseCriticalLow = 40.0;      // <40 → Critical
  static const double glucoseWarningLow = 45.0;       // 40-45 → Warning
  static const double glucoseNormalMin = 45.0;
  static const double glucoseNormalMax = 150.0;
  static const double glucoseHigh = 150.0;            // >150 → Medium alert

  // ==================== MEDICAL REFERENCE RANGES (TEMPERATURE °C) ====================
  static const double temperatureEmergency = 32.0;    // <32°C → Emergency
  static const double temperatureHypothermia = 36.0;  // 32-35.9 → Warning
  static const double temperatureNormalMin = 36.0;
  static const double temperatureNormalMax = 37.5;
  static const double temperatureFever = 37.5;        // >37.5°C → Infection risk

  // ==================== APGAR SCORES ====================
  static const int apgarEmergency = 3;                // <3 → Emergency
  static const int apgarWarning = 6;                  // 4-6 → Monitoring
  static const int apgarNormalMin = 7;

  // ==================== GESTATIONAL AGE (weeks) ====================
  static const int prematureThreshold = 37;           // <37 SA = premature
  static const int fullTermMin = 37;
  static const int fullTermMax = 42;

  // ==================== BIRTH WEIGHT (grams) ====================
  static const int lowBirthWeight = 2500;             // <2500g → Low birth weight
  static const int veryLowBirthWeight = 1500;
  static const int extremelyLowBirthWeight = 1000;

  // ==================== DOSSIER NUMBER PREFIX ====================
  static const String dossierNumberPrefix = 'DOS';
  static const String archiveNumberPrefix = 'ARC';

  // ==================== CACHE / OFFLINE ====================
  static const String hiveOfflineBox = 'offline_dossiers';
  static const String hiveSyncQueueBox = 'sync_queue';
  static const int maxOfflineDossiers = 50;
  static const int syncRetryIntervalSeconds = 30;

  // ==================== PAGINATION ====================
  static const int defaultPageSize = 20;
  static const int dashboardRecentLimit = 5;

  // ==================== ANIMATION DURATIONS ====================
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationLong = Duration(milliseconds: 600);

  // ==================== IMAGE UPLOAD ====================
  static const int maxImageSizeMB = 5;
  static const int maxImageCountPerDossier = 20;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];

  // ==================== PDF CONFIGURATION ====================
  static const String pdfPageFormat = 'A4';
  static const bool pdfIncludeQRCode = true;

  // ==================== ALERT MESSAGES ====================
  static const String alertGlucoseCritical = '🔴 GLUCOSE CRITIQUE: <40 mg/dL - Urgence immédiate';
  static const String alertGlucoseWarning = '🟠 GLUCOSE BASSE: 40-45 mg/dL - Surveillance rapprochée';
  static const String alertGlucoseHigh = '🟡 GLUCOSE ÉLEVÉE: >150 mg/dL - Contrôle nécessaire';
  static const String alertTemperatureEmergency = '🔴 TEMPÉRATURE CRITIQUE: <32°C - Hypothermie sévère';
  static const String alertTemperatureWarning = '🟠 HYPOTHERMIE: <36°C - Réchauffement nécessaire';
  static const String alertTemperatureFever = '🔴 RISQUE INFECTIEUX: >37.5°C - Évaluation urgente';
  static const String alertApgarEmergency = '🔴 APGAR CRITIQUE: <3 - Réanimation immédiate';
  static const String alertApgarWarning = '🟠 APGAR BAS: 4-6 - Surveillance étroite';
  static const String alertAirwayUnstable = '🔴 AIRWAY INSTABLE - Intervention immédiate';
  static const String alertCirculationUnstable = '🔴 CIRCULATION INSTABLE - Intervention immédiate';
  static const String alertTonusFlasque = '🟠 TONUS FLASQUE - Évaluation neurologique';
  static const String alertCriAbsent = '🔴 CRI ABSENT - Réanimation respiratoire';

  // ==================== DEFAULT TEST ACCOUNTS ====================
  static const String testAdminEmail = 'admin@neosante.com';
  static const String testAdminPassword = 'admin123';
  static const String testSageFemmeEmail = 'sagefemme@gmail.com';
  static const String testSageFemmePassword = 'sagefemme123';
}