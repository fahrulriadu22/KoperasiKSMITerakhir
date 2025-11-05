import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ TAMBAH INI

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
      // Jangan throw error agar app tidak crash
    }
  }

  // ✅ Setup Local Notifications - IMPROVED VERSION
  Future<void> _setupLocalNotifications() async {
    try {
      // Android Notification Channel - FIXED: Use proper initialization
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS Notification Settings - FIXED: Proper iOS configuration
      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // ✅ FIX: Add default present options
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      // Initialize settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      // Initialize plugin - FIXED: Proper initialization
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        // ✅ FIX: Add onDidReceiveBackgroundNotificationResponse for background
        onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
      );

      // Create notification channel for Android - FIXED: Proper channel setup
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high, // ✅ FIX: Changed from max to high
          playSound: true,
          showBadge: true,
          enableVibration: true,
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

  // ✅ Request Notification Permissions - IMPROVED
  Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false, // ✅ Set true jika mau permission provisional (iOS)
        sound: true,
      );

      print('📱 Notification Permission Status: ${settings.authorizationStatus}');

      // For iOS, additional setup - FIXED: Better iOS handling
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true, // Show alert when in foreground
          badge: true, // Update app badge
          sound: true, // Play sound
        );
      }

      // For Android 13+, request POST_NOTIFICATIONS permission
      if (Platform.isAndroid) {
        // Android 13+ requires runtime permission
        // flutter_local_notifications akan handle ini secara otomatis
      }
    } catch (e) {
      print('❌ ERROR requesting notification permissions: $e');
    }
  }

  // ✅ Setup FCM Token - IMPROVED
  Future<void> _setupFCMToken() async {
    try {
      // Get current token
      String? token = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $token');

      // Save token to server
      if (token != null && token.isNotEmpty) {
        await _saveTokenToServer(token);
      } else {
        print('⚠️ FCM token is null or empty');
      }

      // Listen for token refresh - FIXED: Better error handling
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token Refreshed: $newToken');
        if (newToken.isNotEmpty) {
          await _saveTokenToServer(newToken);
        }
      });
    } catch (e) {
      print('❌ ERROR setting up FCM token: $e');
    }
  }

// ✅ PERBAIKAN: Save Token to Server dengan API integration
Future<void> _saveTokenToServer(String token) async {
  try {
    print('💾 Saving FCM token to server: $token');
    
    // ✅ SIMPAN KE SHAREDPREFERENCES DULU
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    
    // ✅ COBA KIRIM KE SERVER JIKA USER SUDAH LOGIN
    try {
      final currentUser = await _apiService.getCurrentUser();
      if (currentUser != null && currentUser.isNotEmpty) {
        final result = await _apiService.updateDeviceToken(token);
        if (result['success'] == true) {
          print('✅ FCM token saved to server successfully');
        } else {
          print('⚠️ FCM token saved locally but failed to send to server: ${result['message']}');
        }
      } else {
        print('⚠️ User not logged in, token saved locally only');
      }
    } catch (apiError) {
      print('⚠️ API error, token saved locally: $apiError');
    }
    
  } catch (e) {
    print('❌ ERROR saving FCM token: $e');
  }
}

// ✅ TAMBAHKAN METHOD PUBLIC INI DI FIREBASE_SERVICE.DART
FlutterLocalNotificationsPlugin getLocalNotificationsPlugin() {
  return _flutterLocalNotificationsPlugin;
}

// ✅ BUAT PUBLIC METHOD UNTUK TESTING (Opsional)
Future<void> showTestNotification({
  required String title,
  required String body,
  Map<String, dynamic> data = const {},
}) async {
  await _showLocalNotification(
    title: title,
    body: body,
    data: data,
  );
}

  // ✅ Setup Message Handlers - IMPROVED
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
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic('koperasi_ksmi');
      
      print('✅ Subscribed to topics: all_users, koperasi_ksmi');
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

  // ✅ Process Message Data - IMPROVED
  static void _processMessage(RemoteMessage message, {required bool isForeground}) {
    try {
      final notification = message.notification;
      final data = message.data;

      print('📨 Message Data: $data');
      print('📢 Notification: ${notification?.title} - ${notification?.body}');
      print('🎯 Message ID: ${message.messageId}');
      print('📧 From: ${message.from}');
      print('⏰ Sent Time: ${message.sentTime}');

      // Show local notification if app is in foreground
      if (isForeground && notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'KSMI Koperasi',
          body: notification.body ?? 'Pesan baru dari Koperasi KSMI',
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

  // ✅ Show Local Notification - IMPROVED
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
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableVibration: true,
        showWhen: true,
        autoCancel: true,
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

      // Generate unique ID for notification
      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: _convertMapToJson(data), // ✅ FIX: Convert map to JSON string
      );

      print('📲 Local notification shown: $title (ID: $notificationId)');
    } catch (e) {
      print('❌ ERROR showing local notification: $e');
    }
  }

  // ✅ Convert Map to JSON String
  static String _convertMapToJson(Map<String, dynamic> data) {
    try {
      return data.toString(); // Simple conversion
      // Atau gunakan jsonEncode jika butuh proper JSON
      // return jsonEncode(data);
    } catch (e) {
      return '{}';
    }
  }

  // ✅ Notification Response Handler (Foreground)
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _handleNotificationTap(response);
  }

  // ✅ Background Notification Response Handler
  static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
    _handleNotificationTap(response);
  }

  // ✅ Handle Notification Tap - IMPROVED
  static void _handleNotificationTap(NotificationResponse response) {
    try {
      print('👆 NOTIFICATION TAPPED: ${response.payload}');
      print('📱 Notification ID: ${response.id}');
      print('📝 Action: ${response.actionId}');
      print('💬 Input: ${response.input}');
      
      if (response.payload != null && response.payload!.isNotEmpty) {
        final payload = _parsePayload(response.payload!);
        
        // Call the tap callback
        if (onNotificationTap != null) {
          onNotificationTap!(payload);
        }
        
        // You can add navigation logic here based on payload
        _handleNavigation(payload);
      }
    } catch (e) {
      print('❌ ERROR handling notification response: $e');
    }
  }

  // ✅ Handle Navigation Based on Payload
  static void _handleNavigation(Map<String, dynamic> payload) {
    // Example navigation logic based on payload
    final String? type = payload['type'];
    final String? screen = payload['screen'];
    
    print('🧭 Navigation - Type: $type, Screen: $screen');
    
    // TODO: Implement your navigation logic here
    // Example:
    // if (screen == 'inbox') {
    //   Navigator.pushNamed(context, '/inbox');
    // } else if (screen == 'transaction') {
    //   Navigator.pushNamed(context, '/transaction', arguments: payload);
    // }
  }

  // ✅ Parse Payload String to Map - IMPROVED
  static Map<String, dynamic> _parsePayload(String payload) {
    try {
      // Simple parsing - adjust based on your payload format
      if (payload.startsWith('{') && payload.endsWith('}')) {
        // If it's JSON-like string
        return {'raw_payload': payload};
      } else {
        // Simple key-value parsing
        final Map<String, dynamic> result = {};
        final pairs = payload.split(',');
        for (final pair in pairs) {
          final keyValue = pair.split(':');
          if (keyValue.length == 2) {
            result[keyValue[0].trim()] = keyValue[1].trim();
          }
        }
        return result.isNotEmpty ? result : {'message': payload};
      }
    } catch (e) {
      print('❌ ERROR parsing payload: $e');
      return {'error': 'Failed to parse payload', 'raw': payload};
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
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // ✅ REQUEST PERMISSION AGAIN
  Future<void> requestPermissionAgain() async {
    await _requestNotificationPermissions();
  }

  // ✅ GET APNS TOKEN (iOS only)
  Future<String?> getAPNSToken() async {
    if (Platform.isIOS) {
      return await _firebaseMessaging.getAPNSToken();
    }
    return null;
  }

  // ✅ DISPOSE (cleanup)
  void dispose() {
    // Cleanup if needed
    print('🧹 Firebase Service disposed');
  }
}

// ✅ Global instance for easy access
final firebaseService = FirebaseService();