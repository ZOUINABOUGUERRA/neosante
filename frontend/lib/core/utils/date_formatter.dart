import 'package:intl/intl.dart';

/// Date formatting utilities for consistent date/time display across the app.
class DateFormatter {
  DateFormatter._(); // Private constructor

  /// Default date format: "13 Mai 2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }

  /// Default time format: "14:30"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Date and time format: "13 Mai 2026 à 14:30"
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} à ${formatTime(date)}';
  }

  /// Short date format: "13/05/2026"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// ISO date format: "2026-05-13"
  static String formatDateISO(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Time ago format (relative time): "il y a 5 minutes", "hier", etc.
  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return 'il y a ${(difference.inDays / 365).floor()} an(s)';
    } else if (difference.inDays > 30) {
      return 'il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 7) {
      return 'il y a ${(difference.inDays / 7).floor()} semaine(s)';
    } else if (difference.inDays > 1) {
      return 'il y a ${difference.inDays} jours';
    } else if (difference.inDays == 1) {
      return 'hier';
    } else if (difference.inHours > 1) {
      return 'il y a ${difference.inHours} heures';
    } else if (difference.inHours == 1) {
      return 'il y a 1 heure';
    } else if (difference.inMinutes > 1) {
      return 'il y a ${difference.inMinutes} minutes';
    } else if (difference.inMinutes == 1) {
      return 'il y a 1 minute';
    } else {
      return 'à l\'instant';
    }
  }

  /// Format for medical records: "13/05/2026 14:30"
  static String formatMedicalRecord(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }

  /// Format for dossier numbers with date: "DOS-20260513-001"
  static String formatDossierNumber(DateTime date, int sequence) {
    final dateStr = DateFormat('yyyyMMdd').format(date);
    return 'DOS-$dateStr-${sequence.toString().padLeft(3, '0')}';
  }

  /// Parse a string to DateTime with multiple format attempts
  static DateTime? parseFlexible(String dateString) {
    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd MMMM yyyy',
      'dd MMM yyyy',
    ];
    
    for (final format in formats) {
      try {
        return DateFormat(format, 'fr_FR').parseStrict(dateString);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Returns the age in years, months, days from birth date
  static String formatAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month - 1, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) {
      return '$years an(s)';
    } else if (months > 0) {
      return '$months mois';
    } else {
      return '$days jour(s)';
    }
  }

  /// Format gestational age in weeks + days
  static String formatGestationalAge(int weeks, {int days = 0}) {
    if (days > 0) {
      return '$weeks SA + $days jours';
    }
    return '$weeks SA';
  }
}