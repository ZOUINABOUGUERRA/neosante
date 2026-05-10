import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

    // ✅ إصلاح: استخدام AndroidInitializationSettings و DarwinInitializationSettings بشكل صحيح
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // ✅ إضافة نوع المعامل
        // optional click handler
        print('Notification tapped: ${response.payload}');
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
      // Firestore logic here
      // TODO: Implement saving token to Firestore
    } catch (e) {
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
    // ✅ إزالة التحذير: استخدام المتغير أو إضافة شرطة سفلية
    print('Message opened with data: $data');
    // navigation logic (if needed)
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
    // TODO: Implement sending push notification to doctor
    print('Transfer request notification to: $doctorId for dossier: $dossierNumber');
  }

  static Future<void> notifyTransferApproved(
      String sageFemmeId, String dossierNumber) async {
    // TODO: Implement sending push notification to sage-femme
    print('Transfer approved notification to: $sageFemmeId for dossier: $dossierNumber');
  }

  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    // TODO: Implement sending push notification via FCM
    // This should call a Cloud Function to send the notification
    print('Sending push notification to: $userId');
    print('Title: $title, Body: $body, Type: $type');
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
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
    } catch (e) {
      throw NotificationFailure(
        message: 'Erreur lors de la désinscription du topic: $e',
        originalError: e,
      );
    }
  }
}