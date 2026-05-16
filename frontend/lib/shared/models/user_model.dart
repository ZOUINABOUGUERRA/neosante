import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// User model representing platform users (admin or sage-femme).
/// Each user must contain firstName, lastName, email, password (handled by Firebase Auth),
/// profileImage, createdAt, and role.
class UserModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // 'admin' or 'sage-femme'
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? phoneNumber;
  final String? hospitalId;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profileImage,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.phoneNumber,
    this.hospitalId,
  });

  /// Creates a UserModel from Firestore document (JSON).
  factory UserModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return UserModel(
      id: docId ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? AppConstants.roleSageFemme,
      profileImage: json['profileImage'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] ?? true,
      phoneNumber: json['phoneNumber'],
      hospitalId: json['hospitalId'],
    );
  }

  /// Converts UserModel to Firestore document (JSON).
 Map<String, dynamic> toJson() {
  return {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role,
    'profileImage': profileImage,
    'createdAt': Timestamp.fromDate(createdAt),
    if (lastLoginAt != null)
      'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    'isActive': isActive,
    'phoneNumber': phoneNumber,
    'hospitalId': hospitalId,
  };
}

  /// Returns the full name (first + last).
  String get fullName => '$firstName $lastName';

  /// Returns the user's initials (e.g., "JD" for John Doe).
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }

  /// Returns true if user has admin role.
  bool get isAdmin => role == AppConstants.roleAdmin;

  /// Returns true if user has sage-femme role.
  bool get isSageFemme => role == AppConstants.roleSageFemme;

  /// Returns true if user account is active.
  bool get isAccountActive => isActive;

  /// Creates a copy of this user with updated fields.
  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? phoneNumber,
    String? hospitalId,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      hospitalId: hospitalId ?? this.hospitalId,
    );
  }

  /// Creates a new user for registration (without id).
  Map<String, dynamic> toRegistrationJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'profileImage': profileImage,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'phoneNumber': phoneNumber,
      'hospitalId': hospitalId,
    };
  }

  @override
  List<Object?> get props => [id, email, role, firstName, lastName, isActive];

  @override
  String toString() => 'UserModel(id: $id, fullName: $fullName, email: $email, role: $role)';
}

/// Default test users matching the specification.
/// - Admin: admin@neosante.com / admin123
/// - Sage-femme: sagefemme@gmail.com / sagefemme123
class DefaultUsers {
  static UserModel get admin => UserModel(
    id: 'admin_default_id',
    firstName: 'Admin',
    lastName: 'NéoSanté',
    email: AppConstants.testAdminEmail,
    role: AppConstants.roleAdmin,
    profileImage: null,
    createdAt: DateTime.now(),
    isActive: true,
  );

  static UserModel get sageFemme => UserModel(
    id: 'sage_femme_default_id',
    firstName: 'Sage',
    lastName: 'Femme',
    email: AppConstants.testSageFemmeEmail,
    role: AppConstants.roleSageFemme,
    profileImage: null,
    createdAt: DateTime.now(),
    isActive: true,
  );

  static List<UserModel> get all => [admin, sageFemme];

  /// Creates a map of default credentials for easy testing.
  static Map<String, String> get defaultCredentials => {
    AppConstants.testAdminEmail: AppConstants.testAdminPassword,
    AppConstants.testSageFemmeEmail: AppConstants.testSageFemmePassword,
  };
}

/// Extension methods for List<UserModel> to provide common filtering operations.
extension UserModelListExtension on List<UserModel> {
  /// Returns only admin users.
  List<UserModel> get admins => where((user) => user.isAdmin).toList();

  /// Returns only sage-femme users.
  List<UserModel> get sageFemmes => where((user) => user.isSageFemme).toList();

  /// Returns only active users.
  List<UserModel> get activeUsers => where((user) => user.isActive).toList();

  /// Finds a user by email (case-insensitive).
  UserModel? findByEmail(String email) {
  try {
    return firstWhere(
      (user) =>
          user.email.toLowerCase() ==
          email.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
}
}