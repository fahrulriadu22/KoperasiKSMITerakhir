import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'api_service.dart';

class FirebaseService {
  // ✅ Singleton instance
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ✅ Firebase instances
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ✅ Service instances
  final ApiService _apiService = ApiService();

  // ✅ Notification channels
  static const String _channelId = 'ksmi_channel_id';
  static const String _channelName = 'KSMI Koperasi';
  static const String _channelDescription = 'Channel untuk notifikasi Koperasi KSMI';

  // ✅ Callback functions
  static Function(Map<String, dynamic>)? onNotificationTap;
  static Function(Map<String, dynamic>)? onNotificationReceived;

  // ✅ Initialize Firebase Services
  Future<void> initialize() async {
    try {
      print('🚀 INITIALIZING FIREBASE SERVICES...');

      // Initialize Firebase Core
      await Firebase.initializeApp();
      print('✅ Firebase Core initialized');

      // Setup Local Notifications
      await _setupLocalNotifications();
      print('✅ Local notifications setup completed');

      // Request Notification Permissions
      await _requestNotificationPermissions();
      print('✅ Notification permissions requested');

      // Get FCM Token
      await _setupFCMToken();
      print('✅ FCM token setup completed');

      // Setup Message Handlers
      await _setupMessageHandlers();
      print('✅ Message handlers setup completed');

      // Setup Topic Subscriptions
      await _setupTopicSubscriptions();
      print('✅ Topic subscriptions setup completed');

      print('🎉 FIREBASE SERVICES INITIALIZED SUCCESSFULLY!');
    } catch (e) {
      print('❌ ERROR Initializing Firebase Services: $e');
      throw e;
    }
  }

  // ✅ Setup Local Notifications - FIXED: Remove invalid parameters
  Future<void> _setupLocalNotifications() async {
    try {
      // Android Notification Channel
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS Notification Settings - FIXED: Remove onDidReceiveLocalNotification
      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      // Initialize plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          // FIXED: Remove priority parameter
          showBadge: true,
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      print('✅ Local notifications configured');
    } catch (e) {
      print('❌ ERROR setting up local notifications: $e');
    }
  }

  // ✅ Request Notification Permissions
  Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 Notification Permission Status: ${settings.authorizationStatus}');

      // For iOS, additional setup might be needed
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      print('❌ ERROR requesting notification permissions: $e');
    }
  }

  // ✅ Setup FCM Token
  Future<void> _setupFCMToken() async {
    try {
      // Get current token
      String? token = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $token');

      // Save token to server
      if (token != null) {
        await _saveTokenToServer(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token Refreshed: $newToken');
        await _saveTokenToServer(newToken);
      });
    } catch (e) {
      print('❌ ERROR setting up FCM token: $e');
    }
  }

  // ✅ Save Token to Server
  Future<void> _saveTokenToServer(String token) async {
    try {
      // Implement your API call to save the token
      // Example: await _apiService.saveDeviceToken(token);
      print('💾 Saving FCM token to server: $token');
      
      // Simpan token ke SharedPreferences atau langsung ke API
      // await _apiService.updateDeviceToken(token);
      
    } catch (e) {
      print('❌ ERROR saving token to server: $e');
    }
  }

  // ✅ Setup Message Handlers
  Future<void> _setupMessageHandlers() async {
    try {
      // Handle messages when app is in FOREGROUND
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from TERMINATED state
      FirebaseMessaging.instance.getInitialMessage().then(_handleTerminatedMessage);

      // Handle when app is in BACKGROUND and opened via notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      print('✅ Message handlers registered');
    } catch (e) {
      print('❌ ERROR setting up message handlers: $e');
    }
  }

  // ✅ Setup Topic Subscriptions
  Future<void> _setupTopicSubscriptions() async {
    try {
      // Subscribe to general topics
      await subscribeToTopic('all_users');
      await subscribeToTopic('koperasi_ksmi');
      
      // You can add user-specific topics based on user data
      // await subscribeToTopic('user_${userId}');
      
      print('✅ Topic subscriptions completed');
    } catch (e) {
      print('❌ ERROR setting up topic subscriptions: $e');
    }
  }

  // ✅ Handle Foreground Messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 FOREGROUND MESSAGE RECEIVED');
    _processMessage(message, isForeground: true);
  }

  // ✅ Handle Background Messages
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('📱 BACKGROUND MESSAGE OPENED');
    _processMessage(message, isForeground: false);
  }

  // ✅ Handle Terminated Messages
  static void _handleTerminatedMessage(RemoteMessage? message) {
    if (message != null) {
      print('📱 TERMINATED MESSAGE OPENED');
      _processMessage(message, isForeground: false);
    }
  }

  // ✅ Process Message Data
  static void _processMessage(RemoteMessage message, {required bool isForeground}) {
    try {
      final notification = message.notification;
      final data = message.data;

      print('📨 Message Data: $data');
      print('📢 Notification: ${notification?.title} - ${notification?.body}');

      // Show local notification if app is in foreground
      if (isForeground) {
        _showLocalNotification(
          title: notification?.title ?? 'KSMI Koperasi',
          body: notification?.body ?? 'Pesan baru dari Koperasi KSMI',
          data: data,
        );
      }

      // Call callback for notification received
      if (onNotificationReceived != null) {
        onNotificationReceived!(data);
      }

      // If app was opened from notification, call tap callback
      if (!isForeground && onNotificationTap != null) {
        onNotificationTap!(data);
      }
    } catch (e) {
      print('❌ ERROR processing message: $e');
    }
  }

  // ✅ Show Local Notification - FIXED: Remove invalid parameters
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        // FIXED: Remove priority parameter
        showWhen: true,
        autoCancel: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
        payload: data.toString(),
      );

      print('📲 Local notification shown: $title');
    } catch (e) {
      print('❌ ERROR showing local notification: $e');
    }
  }

  // ✅ Notification Response Handler
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    try {
      print('👆 NOTIFICATION TAPPED: ${response.payload}');
      
      // Parse payload and handle navigation
      if (response.payload != null) {
        // You can parse the payload and navigate to specific screen
        // Example: Navigator.pushNamed(context, '/detail', arguments: parsedData);
        
        if (onNotificationTap != null) {
          // Convert payload string back to Map
          final payload = _parsePayload(response.payload!);
          onNotificationTap!(payload);
        }
      }
    } catch (e) {
      print('❌ ERROR handling notification response: $e');
    }
  }

  // ✅ Parse Payload String to Map
  static Map<String, dynamic> _parsePayload(String payload) {
    try {
      // Simple payload parsing - adjust based on your payload format
      return {'payload': payload};
    } catch (e) {
      return {'error': 'Failed to parse payload'};
    }
  }

  // ✅ SUBSCRIBE TO TOPIC
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ ERROR subscribing to topic $topic: $e');
    }
  }

  // ✅ UNSUBSCRIBE FROM TOPIC
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ ERROR unsubscribing from topic $topic: $e');
    }
  }

  // ✅ GET FCM TOKEN
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ ERROR getting FCM token: $e');
      return null;
    }
  }

  // ✅ DELETE FCM TOKEN (on logout)
  Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      print('✅ FCM token deleted');
    } catch (e) {
      print('❌ ERROR deleting FCM token: $e');
    }
  }

  // ✅ GET NOTIFICATION SETTINGS
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  // ✅ CHECK IF NOTIFICATIONS ARE ENABLED
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // ✅ REQUEST PERMISSION AGAIN
  Future<void> requestPermissionAgain() async {
    await _requestNotificationPermissions();
  }

  // ✅ DISPOSE (cleanup)
  void dispose() {
    // Cleanup if needed
    print('🧹 Firebase Service disposed');
  }
}

// ✅ Global instance for easy access
final firebaseService = FirebaseService();