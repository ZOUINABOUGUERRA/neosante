import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failure.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          debugPrint('Notification tapped: ${response.payload}');
        }
      },
    );

    await _getToken();

    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    _initialized = true;
  }

  static Future<String?> _getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      throw NotificationFailure(
        message: 'Erreur lors de la récupération du token: $e',
        originalError: e,
      );
    }
  }

  static Future<void> saveToken(String userId, String token) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(userId);
      await userRef.update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('Token saved for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving token: $e');
      }
      throw NotificationFailure(
        message: 'Erreur lors de la sauvegarde du token: $e',
        originalError: e,
      );
    }
  }

  static Future<void> _onMessage(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'NéoSanté',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    final Map<String, dynamic> data = message.data;
    if (kDebugMode) {
      debugPrint('Message opened with data: $data');
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'neosante_channel',
      'NéoSanté Notifications',
      channelDescription: 'Notifications médicales NéoSanté',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> showMedicalAlert(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medical_alerts',
      'Alertes Médicales',
      channelDescription: 'Alertes médicales urgentes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alert_sound'),
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  static Future<void> notifyTransferRequest(
      String doctorId, String dossierNumber, String newbornName) async {
    if (kDebugMode) {
      debugPrint('Transfer request notification to: $doctorId for dossier: $dossierNumber');
    }
    
    // ✅ حفظ الإشعار في Firestore بدلاً من إرساله مباشرة
    await _saveNotificationToFirestore(
      userId: doctorId,
      title: 'Demande de transfert',
      body: 'Le dossier $dossierNumber ($newbornName) demande un transfert',
      type: 'transfer_request',
      data: {
        'dossierNumber': dossierNumber,
        'newbornName': newbornName,
      },
    );
  }

  static Future<void> notifyTransferApproved(
      String sageFemmeId, String dossierNumber) async {
    if (kDebugMode) {
      debugPrint('Transfer approved notification to: $sageFemmeId for dossier: $dossierNumber');
    }
    
    await _saveNotificationToFirestore(
      userId: sageFemmeId,
      title: 'Transfert approuvé',
      body: 'Le transfert du dossier $dossierNumber a été approuvé',
      type: 'transfer_approved',
      data: {
        'dossierNumber': dossierNumber,
      },
    );
  }

  // ✅ دالة مساعدة لحفظ الإشعارات في Firestore
  static Future<void> _saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('Notification saved to Firestore for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving notification to Firestore: $e');
      }
    }
  }

  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    if (kDebugMode) {
      debugPrint('Sending push notification to: $userId');
      debugPrint('Title: $title, Body: $body, Type: $type');
    }
    
    // ✅ حفظ الإشعار في Firestore (سيتم إرساله عبر Cloud Function)
    await _saveNotificationToFirestore(
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('Subscribed to topic: $topic');
      }
    } catch (e) {
      throw NotificationFailure(
        message: 'Erreur lors de l\'inscription au topic: $e',
        originalError: e,
      );
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      throw NotificationFailure(
        message: 'Erreur lors de la désinscription du topic: $e',
        originalError: e,
      );
    }
  }
}