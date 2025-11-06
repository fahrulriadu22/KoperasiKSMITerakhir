import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // ✅ IMPORT BARU UNTUK JSON
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static Function(int)? onUnreadCountUpdated; // ✅ CALLBACK BARU UNTUK UPDATE BADGE

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

      // ✅ LOAD INBOX DATA AWAL
      await _loadInitialInboxData();
      print('✅ Initial inbox data loaded');

      print('🎉 FIREBASE SERVICES INITIALIZED SUCCESSFULLY!');
    } catch (e) {
      print('❌ ERROR Initializing Firebase Services: $e');
      // Jangan throw error agar app tidak crash
    }
  }

  // ✅ LOAD INITIAL INBOX DATA
  Future<void> _loadInitialInboxData() async {
    try {
      print('📥 Loading initial inbox data...');
      final result = await _apiService.getAllInbox();
      
      if (result['success'] == true) {
        final inboxData = result['data'] ?? {};
        final prefs = await SharedPreferences.getInstance();
        
        // Simpan data inbox
        await prefs.setString('last_inbox_data', jsonEncode(inboxData));
        
        // Hitung unread count
        final unreadCount = _calculateUnreadCount(inboxData);
        await prefs.setInt('unread_notifications', unreadCount);
        
        print('✅ Initial inbox loaded: $unreadCount unread messages');
        
        // Trigger callback untuk update UI
        if (onUnreadCountUpdated != null) {
          onUnreadCountUpdated!(unreadCount);
        }
      } else {
        print('❌ Failed to load initial inbox data');
      }
    } catch (e) {
      print('❌ Error loading initial inbox data: $e');
    }
  }

  // ✅ BACKGROUND MESSAGE HANDLER DENGAN GETINBOX SYNC
  @pragma('vm:entry-point')
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    
    print('📱 BACKGROUND MESSAGE HANDLER TRIGGERED');
    print('📨 Message Data: ${message.data}');
    print('📢 Notification: ${message.notification?.title} - ${message.notification?.body}');
    
    try {
      // ✅ PANGGIL GETINBOX API UNTUK SYNC DATA TERBARU
      final ApiService apiService = ApiService();
      final inboxResult = await apiService.getAllInbox();
      
      if (inboxResult['success'] == true) {
        print('✅ Background: Inbox data synced successfully');
        
        // ✅ SIMPAN DATA INBOX KE LOCAL STORAGE
        final prefs = await SharedPreferences.getInstance();
        final inboxData = inboxResult['data'] ?? {};
        await prefs.setString('last_inbox_data', jsonEncode(inboxData));
        
        // ✅ HITUNG UNREAD COUNT DAN SIMPAN
        final unreadCount = _calculateUnreadCount(inboxData);
        await prefs.setInt('unread_notifications', unreadCount);
        
        print('✅ Background: Unread count updated: $unreadCount');
        
        // ✅ KIRIM BROADCAST UNTUK UPDATE UI JIKA APP AKTIF
        // Note: Di background tidak bisa update UI langsung
        // Tapi data sudah tersimpan di SharedPreferences
        
      } else {
        print('❌ Background: Failed to sync inbox data');
      }
      
    } catch (e) {
      print('❌ Background Handler Error: $e');
    }
    
    // ✅ TAMPILKAN NOTIFIKASI SISTEM
    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'KSMI Koperasi',
        body: message.notification!.body ?? 'Pesan baru dari Koperasi KSMI',
        data: message.data,
      );
    }
  }

  // ✅ CALCULATE UNREAD COUNT DARI INBOX DATA
  static int _calculateUnreadCount(Map<String, dynamic> inboxData) {
    try {
      final inboxList = inboxData['inbox'] ?? [];
      final unreadCount = inboxList.where((item) {
        if (item is Map<String, dynamic>) {
          final readStatus = item['read_status'] ?? item['is_read'] ?? '0';
          return readStatus == '0' || readStatus == 0 || readStatus == false;
        }
        return false;
      }).length;
      
      return unreadCount;
    } catch (e) {
      print('❌ Error calculating unread count: $e');
      return 0;
    }
  }

  // ✅ GET CURRENT UNREAD COUNT
  Future<int> getUnreadNotificationsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('unread_notifications') ?? 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // ✅ REFRESH INBOX DATA MANUALLY
  Future<Map<String, dynamic>> refreshInboxData() async {
    try {
      print('🔄 Manually refreshing inbox data...');
      final result = await _apiService.getAllInbox();
      
      if (result['success'] == true) {
        final inboxData = result['data'] ?? {};
        final prefs = await SharedPreferences.getInstance();
        
        // Simpan data inbox
        await prefs.setString('last_inbox_data', jsonEncode(inboxData));
        
        // Hitung unread count
        final unreadCount = _calculateUnreadCount(inboxData);
        await prefs.setInt('unread_notifications', unreadCount);
        
        print('✅ Inbox refreshed: $unreadCount unread messages');
        
        // Trigger callback untuk update UI
        if (onUnreadCountUpdated != null) {
          onUnreadCountUpdated!(unreadCount);
        }
        
        return {
          'success': true,
          'unread_count': unreadCount,
          'data': inboxData,
          'message': 'Inbox data refreshed successfully'
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to refresh inbox'
        };
      }
    } catch (e) {
      print('❌ Error refreshing inbox data: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ Setup Local Notifications
  Future<void> _setupLocalNotifications() async {
    try {
      // Android Notification Channel
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS Notification Settings
      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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

      // Initialize plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
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

      // For iOS, additional setup
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
      if (token != null && token.isNotEmpty) {
        await _saveTokenToServer(token);
      } else {
        print('⚠️ FCM token is null or empty');
      }

      // Listen for token refresh
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

  // ✅ Save Token to Server
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

  // ✅ Setup Message Handlers DENGAN BACKGROUND SYNC
  Future<void> _setupMessageHandlers() async {
    try {
      // ✅ SETUP BACKGROUND HANDLER (PENTING!)
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

      // Handle messages when app is in FOREGROUND
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from TERMINATED state
      FirebaseMessaging.instance.getInitialMessage().then(_handleTerminatedMessage);

      // Handle when app is in BACKGROUND and opened via notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      print('✅ Message handlers registered with background sync');
    } catch (e) {
      print('❌ ERROR setting up message handlers: $e');
    }
  }

  // ✅ Handle Foreground Messages DENGAN REAL-TIME SYNC
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 FOREGROUND MESSAGE RECEIVED');
    _processMessage(message, isForeground: true);
    
    // ✅ REAL-TIME SYNC INBOX DATA
    _syncInboxDataInForeground();
  }

  // ✅ REAL-TIME SYNC INBOX DATA DI FOREGROUND
  static void _syncInboxDataInForeground() {
    // Gunakan Future untuk tidak blocking main thread
    Future.microtask(() async {
      try {
        final ApiService apiService = ApiService();
        final result = await apiService.getAllInbox();
        
        if (result['success'] == true) {
          final inboxData = result['data'] ?? {};
          final prefs = await SharedPreferences.getInstance();
          
          await prefs.setString('last_inbox_data', jsonEncode(inboxData));
          
          final unreadCount = _calculateUnreadCount(inboxData);
          await prefs.setInt('unread_notifications', unreadCount);
          
          print('✅ Foreground sync: Unread count updated: $unreadCount');
          
          // Trigger UI update via callback
          if (onUnreadCountUpdated != null) {
            onUnreadCountUpdated!(unreadCount);
          }
        }
      } catch (e) {
        print('❌ Foreground sync error: $e');
      }
    });
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

  // ✅ Show Local Notification
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
        payload: _convertMapToJson(data),
      );

      print('📲 Local notification shown: $title (ID: $notificationId)');
    } catch (e) {
      print('❌ ERROR showing local notification: $e');
    }
  }

  // ✅ Convert Map to JSON String
  static String _convertMapToJson(Map<String, dynamic> data) {
    try {
      return data.toString();
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

  // ✅ Handle Notification Tap
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
        
        // Navigation logic
        _handleNavigation(payload);
      }
    } catch (e) {
      print('❌ ERROR handling notification response: $e');
    }
  }

  // ✅ Handle Navigation Based on Payload
  static void _handleNavigation(Map<String, dynamic> payload) {
    final String? type = payload['type'];
    final String? screen = payload['screen'];
    
    print('🧭 Navigation - Type: $type, Screen: $screen');
    
    // TODO: Implement navigation logic based on your app structure
  }

  // ✅ Parse Payload String to Map
  static Map<String, dynamic> _parsePayload(String payload) {
    try {
      if (payload.startsWith('{') && payload.endsWith('}')) {
        return {'raw_payload': payload};
      } else {
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

  // ✅ GET LOCAL NOTIFICATIONS PLUGIN
  FlutterLocalNotificationsPlugin getLocalNotificationsPlugin() {
    return _flutterLocalNotificationsPlugin;
  }

  // ✅ TEST NOTIFICATION
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

  // ✅ DISPOSE
  void dispose() {
    print('🧹 Firebase Service disposed');
  }
}

// ✅ Global instance for easy access
final firebaseService = FirebaseService();