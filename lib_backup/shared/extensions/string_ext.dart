import 'package:intl/intl.dart';
import 'dart:convert';


/// Extension methods for String to simplify common string operations.
extension StringExtension on String {
  /// Returns true if the string is null or empty
  bool get isNullOrEmpty => isEmpty;
  
  /// Returns true if the string is not null or empty
  bool get isNotNullOrEmpty => isNotEmpty;
  
  /// Returns true if the string is a valid email format
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }
  
  /// Returns true if the string is a valid phone number (French format)
  bool get isValidPhoneNumber {
    final phoneRegex = RegExp(
      r'^(0|\+33)[1-9][0-9]{8}$',
    );
    return phoneRegex.hasMatch(replaceAll(' ', '').replaceAll('-', ''));
  }
  
  /// Returns true if the string is a valid number (integer or decimal)
  bool get isNumeric {
    return double.tryParse(this) != null;
  }
  
  /// Returns true if the string is a valid integer
  bool get isInteger {
    return int.tryParse(this) != null;
  }
  
  /// Returns true if the string is a valid double
  bool get isDouble {
    return double.tryParse(this) != null;
  }
  
  /// Returns the string as an integer, or null if invalid
  int? get toIntOrNull => int.tryParse(this);
  
  /// Returns the string as a double, or null if invalid
  double? get toDoubleOrNull => double.tryParse(this);
  
  /// Capitalizes the first letter of the string
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
  
  /// Capitalizes the first letter of each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalizeFirst).join(' ');
  }
  
  /// Converts the string to title case
  String get toTitleCase {
    if (isEmpty) return this;
    final lowercased = toLowerCase();
    return lowercased.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  /// Truncates the string to maxLength and adds ellipsis if needed
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength) + ellipsis;
  }
  
  /// Removes all whitespace from the string
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');
  
  /// Returns the string with only alphanumeric characters
  String get alphanumericOnly => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  
  /// Returns the string with only numeric characters
  String get numericOnly => replaceAll(RegExp(r'[^0-9]'), '');
  
  /// Masks part of the string (useful for hiding sensitive data)
  String mask({int visibleStart = 2, int visibleEnd = 2, String maskChar = '*'}) {
    if (length <= visibleStart + visibleEnd) return this;
    final start = substring(0, visibleStart);
    final end = substring(length - visibleEnd);
    final maskedLength = length - visibleStart - visibleEnd;
    return start + maskChar * maskedLength + end;
  }
  
  /// Returns the initials from a name (e.g., "John Doe" -> "JD")
  String get initials {
    if (isEmpty) return '';
    final parts = trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  
  /// Parses the string to a DateTime object with flexible formats
  DateTime? parseToDateTime() {
    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd/MM/yyyy HH:mm',
      'dd-MM-yyyy HH:mm',
      'yyyy-MM-dd HH:mm',
      'dd MMMM yyyy',
      'dd MMM yyyy',
    ];
    
    for (final format in formats) {
      try {
        return DateFormat(format, 'fr_FR').parseStrict(this);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
  
  /// Formats the string as a medical dossier number (DOS-YYYYMMDD-XXX)
  String get formatAsDossierNumber {
    final numeric = numericOnly;
    if (numeric.length >= 8) {
      final date = numeric.substring(0, 8);
      final sequence = numeric.length > 8 ? numeric.substring(8) : '001';
      return 'DOS-$date-${sequence.padLeft(3, '0')}';
    }
    return this;
  }
  
  /// Validates if the string is a valid APGAR score (0-10)
  bool get isValidApgarScore {
    final score = toIntOrNull;
    return score != null && score >= 0 && score <= 10;
  }
  
  /// Validates if the string is a valid gestational age (22-42 weeks)
  bool get isValidGestationalAge {
    final weeks = toIntOrNull;
    return weeks != null && weeks >= 22 && weeks <= 42;
  }
  
  /// Validates if the string is a valid birth weight (200-6000 grams)
  bool get isValidBirthWeight {
    final grams = toDoubleOrNull;
    return grams != null && grams >= 200 && grams <= 6000;
  }
  
  /// Validates if the string is a valid temperature (25-45 °C)
  bool get isValidTemperature {
    final temp = toDoubleOrNull;
    return temp != null && temp >= 25 && temp <= 45;
  }
  
  /// Validates if the string is a valid glucose (10-500 mg/dL)
  bool get isValidGlucose {
    final glucose = toDoubleOrNull;
    return glucose != null && glucose >= 10 && glucose <= 500;
  }
  
  /// Returns the HTML escaped string
  String get escapeHtml {
    return replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
  
  /// Returns the URL encoded string
  String get urlEncode => Uri.encodeComponent(this);
  
  /// Returns the URL decoded string
  String get urlDecode => Uri.decodeComponent(this);
  
  /// Returns the base64 encoded string
  String get toBase64 => base64Encode(utf8.encode(this));
  
  /// Returns the base64 decoded string
  String get fromBase64 {
    try {
      return String.fromCharCodes(base64Decode(this));
    } catch (_) {
      return this;
    }
  }
  
  /// Returns the string with line breaks converted to HTML <br> tags
  String get nl2br => replaceAll('\n', '<br>');
  
  /// Returns the string with HTML <br> tags converted to line breaks
  String get br2nl => replaceAll('<br>', '\n').replaceAll('<br/>', '\n');
  
  /// Counts the number of words in the string
  int get wordCount => trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  
  /// Returns the string reversed
  String get reversed => split('').reversed.join();
  
  /// Returns true if the string contains only letters and spaces
  bool get isOnlyLettersAndSpaces => RegExp(r'^[a-zA-Z\s]+$').hasMatch(this);
  
  /// Returns true if the string contains only letters (no spaces)
  bool get isOnlyLetters => RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  
  /// Returns true if the string is a valid password (at least 8 chars, 1 uppercase, 1 lowercase, 1 number)
  bool get isValidPassword {
    if (length < 8) return false;
    if (!contains(RegExp(r'[A-Z]'))) return false;
    if (!contains(RegExp(r'[a-z]'))) return false;
    if (!contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
  
  /// Returns the Levenshtein distance between this string and another
  int levenshteinDistance(String other) {
    final a = this;
    final b = other;
    
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    
    final matrix = List.generate(
      a.length + 1,
      (i) => List<int>.filled(b.length + 1, 0),
    );
    
    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[a.length][b.length];
  }
  
  /// Returns true if this string is similar to another (Levenshtein distance <= 2)
  bool isSimilarTo(String other, {int maxDistance = 2}) {
    return levenshteinDistance(other) <= maxDistance;
  }
}

/// Extension methods for nullable strings
extension NullableStringExtension on String? {
  /// Returns true if the string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  
  /// Returns true if the string is not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
  
  /// Returns the string or a default value if null
  String orDefault(String defaultValue) => this ?? defaultValue;
  
  /// Returns the string or an empty string if null
  String get orEmpty => this ?? '';
  
  /// Capitalizes the first letter, or returns null if null
  String? get capitalizeFirst => this?.capitalizeFirst;
  
  /// Converts to integer, or returns null if null or invalid
  int? get toIntOrNull => this?.toIntOrNull;
  
  /// Converts to double, or returns null if null or invalid
  double? get toDoubleOrNull => this?.toDoubleOrNull;
}