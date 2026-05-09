import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/notification_model.dart';
import '../../../services/auth_service.dart';

/// Notifications state class
class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Notifications provider
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});

/// Notifications notifier
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationsSubscription;

  NotificationsNotifier() : super(const NotificationsState()) {
    _loadNotifications();
  }

  void _loadNotifications() {
    final currentUser = _authService.currentFirebaseUser;
    if (currentUser == null) return;

    _notificationsSubscription = _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
              .toList();
          
          final unreadCount = notifications.where((n) => !n.isRead).length;
          
          state = state.copyWith(
            notifications: notifications,
            unreadCount: unreadCount,
          );
        });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      // ✅ Correction: utiliser kDebugMode pour le débogage
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    final currentUser = _authService.currentFirebaseUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all as read: $e');
      }
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  Future<void> deleteAllNotifications() async {
    final currentUser = _authService.currentFirebaseUser;
    if (currentUser == null) return;

    try {
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all notifications: $e');
      }
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}

/// Unread notifications count provider (for badge)
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final authService = AuthService();
  final currentUser = authService.currentFirebaseUser;
  
  if (currentUser == null) {
    return Stream.value(0);
  }
  
  return FirebaseFirestore.instance
      .collection(AppConstants.notificationsCollection)
      .where('userId', isEqualTo: currentUser.uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});