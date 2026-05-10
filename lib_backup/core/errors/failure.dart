import 'package:equatable/equatable.dart';

/// Base failure class for error handling throughout the application.
/// Uses the Either pattern (success/failure) for functional error handling.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Network-related failures (no internet, connection timeout, etc.)
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Server-side failures (Firebase errors, API errors)
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Authentication failures (invalid credentials, user not found, etc.)
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Database operation failures (Firestore read/write errors)
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Storage operation failures (Firebase Storage upload/download errors)
class StorageFailure extends Failure {
  const StorageFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Cache/offline storage failures (Hive errors)
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Notification failures (FCM errors)
class NotificationFailure extends Failure {
  const NotificationFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// AI service failures (Claude API errors)
class AIFailure extends Failure {
  const AIFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// PDF generation failures
class PDFFailure extends Failure {
  const PDFFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Validation failures (form validation errors)
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required String message,
    this.fieldErrors,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Permission failures (missing permissions for camera, storage, etc.)
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(message: message, statusCode: statusCode, originalError: originalError);
}

/// Helper function to map Firebase Auth exceptions to Failure objects
Failure mapAuthExceptionToFailure(dynamic exception, {String? customMessage}) {
  final String errorMessage = exception.toString();
  
  if (errorMessage.contains('user-not-found')) {
    return const AuthFailure(message: 'Aucun utilisateur trouvé avec cet email.');
  }
  if (errorMessage.contains('wrong-password')) {
    return const AuthFailure(message: 'Mot de passe incorrect.');
  }
  if (errorMessage.contains('email-already-in-use')) {
    return const AuthFailure(message: 'Cet email est déjà utilisé.');
  }
  if (errorMessage.contains('invalid-email')) {
    return const AuthFailure(message: 'Format d\'email invalide.');
  }
  if (errorMessage.contains('weak-password')) {
    return const AuthFailure(message: 'Le mot de passe est trop faible.');
  }
  if (errorMessage.contains('network-request-failed')) {
    return const NetworkFailure(message: 'Erreur réseau. Vérifiez votre connexion.');
  }
  if (errorMessage.contains('too-many-requests')) {
    return const AuthFailure(message: 'Trop de tentatives. Veuillez réessayer plus tard.');
  }
  
  return AuthFailure(
    message: customMessage ?? 'Une erreur d\'authentification est survenue.',
    originalError: exception,
  );
}

/// Helper function to map Firestore exceptions to Failure objects
Failure mapFirestoreExceptionToFailure(dynamic exception, {String? customMessage}) {
  final String errorMessage = exception.toString();
  
  if (errorMessage.contains('permission-denied')) {
    return const DatabaseFailure(message: 'Permission refusée. Vous n\'avez pas accès à ces données.');
  }
  if (errorMessage.contains('not-found')) {
    return const DatabaseFailure(message: 'Document non trouvé.');
  }
  if (errorMessage.contains('unavailable')) {
    return const NetworkFailure(message: 'Service indisponible. Veuillez réessayer.');
  }
  if (errorMessage.contains('deadline-exceeded')) {
    return const NetworkFailure(message: 'Délai dépassé. Vérifiez votre connexion.');
  }
  
  return DatabaseFailure(
    message: customMessage ?? 'Une erreur de base de données est survenue.',
    originalError: exception,
  );
}