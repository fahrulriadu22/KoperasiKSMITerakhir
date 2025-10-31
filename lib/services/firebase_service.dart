import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final ApiService _apiService = ApiService();

  // ✅ Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    
    // Setup local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
    
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('User granted permission: ${settings.authorizationStatus}');
    
    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Save token to server
    if (token != null) {
      await _apiService.saveDeviceToken(token);
    }
    
    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Setup background message handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  // ✅ Handle notification ketika app terbuka
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground Message: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'KSMI Notification',
      body: message.notification?.body ?? 'New message from KSMI',
      data: message.data,
    );
  }

  // ✅ Handle notification ketika app di-tap dari background
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Background Message: ${message.notification?.title}');
    // Handle navigation based on message data
  }

  // ✅ Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ksmi_channel_id',
      'KSMI Notifications',
      channelDescription: 'Channel for KSMI notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: data.toString(),
    );
  }

  // ✅ Get current FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // ✅ Subscribe to topics
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // ✅ Unsubscribe from topics
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}