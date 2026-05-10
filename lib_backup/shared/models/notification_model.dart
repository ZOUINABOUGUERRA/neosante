import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Notification model for in-app and push notifications.
/// Supports transfer requests, approvals, rejections, and emergency alerts.
class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'transfer_request', 'transfer_approved', 'transfer_rejected', 'emergency_alert', 'system'
  final Map<String, dynamic>? data; // Additional data (e.g., dossierId, transferId)
  final bool isRead;
  final DateTime createdAt;
  final String? imageUrl;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.imageUrl,
  });

  /// Creates a NotificationModel from Firestore document.
  factory NotificationModel.fromJson(Map<String, dynamic> json, String docId) {
    return NotificationModel(
      id: docId,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'system',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: json['imageUrl'],
    );
  }

  /// Converts NotificationModel to Firestore document.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }

  /// Returns true if this is a transfer-related notification.
  bool get isTransferNotification => 
      type == 'transfer_request' || 
      type == 'transfer_approved' || 
      type == 'transfer_rejected';

  /// Returns true if this is an emergency alert.
  bool get isEmergencyAlert => type == 'emergency_alert';

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, isRead];
}