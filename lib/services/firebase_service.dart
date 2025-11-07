import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'system_notifier.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Service instances
  final ApiService _apiService = ApiService();
  final SystemNotifier systemNotifier = SystemNotifier();

  // Constants
  static const String baseUrl = 'http://demo.bsdeveloper.id/api';

  // Notification channels
  static const String _channelId = 'ksmi_channel_id';
  static const String _channelName = 'KSMI Koperasi';
  static const String _channelDescription = 'Channel untuk notifikasi Koperasi KSMI';

  // Callback functions
  static Function(Map<String, dynamic>)? onNotificationTap;
  static Function(Map<String, dynamic>)? onNotificationReceived;
  static Function(int)? onUnreadCountUpdated;

  // Track initialization status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Track last unread count
  int _lastUnreadCount = 0;

  // ✅ INITIALIZE FIREBASE SERVICES DENGAN FCM
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        print('✅ FirebaseService already initialized');
        return;
      }

      print('🚀 INITIALIZING FIREBASE SERVICES WITH FCM...');

      // 1. Initialize Firebase Core
      print('🔥 Initializing Firebase Core...');
      await Firebase.initializeApp();
      print('✅ Firebase Core initialized');

      // 2. Initialize SystemNotifier
      print('🔄 Initializing SystemNotifier...');
      await systemNotifier.initialize();
      print('✅ SystemNotifier initialized');

      // 3. Setup FCM Token & Messaging
      print('🔄 Setting up FCM...');
      await _setupFCM();
      print('✅ FCM setup completed');

      // 4. Load Initial Inbox Data
      print('🔄 Loading initial inbox data...');
      await _loadInitialInboxData();
      print('✅ Initial inbox data loaded');

      _isInitialized = true;
      print('🎉 FIREBASE SERVICES WITH FCM INITIALIZED SUCCESSFULLY!');

    } catch (e) {
      print('❌ ERROR Initializing Firebase Services: $e');
      _isInitialized = false;
    }
  }

  // ✅ SETUP FCM TOKEN & MESSAGING
  Future<void> _setupFCM() async {
    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('📱 Notification Permission: ${settings.authorizationStatus}');

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $token');

      // Save token to server
      if (token != null && token.isNotEmpty) {
        await _saveFCMTokenToServer(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token Refreshed: $newToken');
        await _saveFCMTokenToServer(newToken);
      });

      // Setup message handlers
      await _setupMessageHandlers();

    } catch (e) {
      print('❌ ERROR setting up FCM: $e');
    }
  }

  // ✅ SAVE FCM TOKEN TO SERVER
  Future<void> _saveFCMTokenToServer(String token) async {
    try {
      print('💾 Saving FCM token to server: $token');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      
      // Kirim token ke API Anda
      final currentUser = await _apiService.getCurrentUser();
      if (currentUser != null && currentUser.isNotEmpty) {
        final result = await _apiService.updateDeviceToken(token);
        if (result['success'] == true) {
          print('✅ FCM token saved to server successfully');
        } else {
          print('⚠️ Failed to save FCM token to server: ${result['message']}');
        }
      }
      
    } catch (e) {
      print('❌ ERROR saving FCM token: $e');
    }
  }

  // ✅ SETUP MESSAGE HANDLERS UNTUK FCM
  Future<void> _setupMessageHandlers() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_firebaseForegroundHandler);

      // Handle when app is opened from terminated state
      FirebaseMessaging.instance.getInitialMessage().then(_firebaseTerminatedHandler);

      // Handle when app is in background and opened via notification
      FirebaseMessaging.onMessageOpenedApp.listen(_firebaseBackgroundOpenedHandler);

      print('✅ FCM message handlers registered');

    } catch (e) {
      print('❌ ERROR setting up FCM message handlers: $e');
    }
  }

  // ✅ BACKGROUND MESSAGE HANDLER
  @pragma('vm:entry-point')
  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('📱 FCM BACKGROUND MESSAGE: ${message.data}');
    
    // Tampilkan system notification untuk background message
    if (message.notification != null) {
      await _showSystemNotificationFromFCM(message);
    }
  }

  // ✅ FOREGROUND MESSAGE HANDLER
  static void _firebaseForegroundHandler(RemoteMessage message) {
    print('📱 FCM FOREGROUND MESSAGE: ${message.data}');
    
    // Tampilkan system notification untuk foreground message
    if (message.notification != null) {
      _showSystemNotificationFromFCM(message);
    }
  }

  // ✅ TERMINATED MESSAGE HANDLER
  static void _firebaseTerminatedHandler(RemoteMessage? message) {
    if (message != null) {
      print('📱 FCM TERMINATED MESSAGE: ${message.data}');
      // Handle app opened from terminated state
    }
  }

  // ✅ BACKGROUND OPENED HANDLER
  static void _firebaseBackgroundOpenedHandler(RemoteMessage message) {
    print('📱 FCM BACKGROUND OPENED: ${message.data}');
    // Handle notification tap when app is in background
  }

  // ✅ SHOW SYSTEM NOTIFICATION DARI FCM
  static Future<void> _showSystemNotificationFromFCM(RemoteMessage message) async {
    try {
      final notifier = SystemNotifier();
      await notifier.initialize();
      
      await notifier.showSystemNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: message.notification?.title ?? 'KSMI Koperasi',
        body: message.notification?.body ?? 'Pesan baru dari Koperasi KSMI',
      );
      
    } catch (e) {
      print('❌ ERROR showing FCM notification: $e');
    }
  }

  // ✅ GET ALL INBOX DENGAN SYSTEM NOTIFICATION
  Future<Map<String, dynamic>> getAllInbox() async {
    try {
      final headers = await getProtectedHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllinbox'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      print('📡 Inbox Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          final inboxData = data['data'] ?? {};
          final unreadCount = _calculateUnreadCount(inboxData);
          
          // ✅ TRIGGER SYSTEM NOTIFICATION JIKA ADA PESAN BARU
          if (unreadCount > 0) {
            await _triggerInboxNotification(unreadCount);
          }
          
          // ✅ UPDATE UNREAD COUNT CALLBACK
          if (onUnreadCountUpdated != null) {
            onUnreadCountUpdated!(unreadCount);
          }
          
          return {
            'success': true,
            'data': inboxData,
            'message': data['message'] ?? 'Success get inbox',
            'unread_count': unreadCount,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil data inbox'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data inbox: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Inbox API Exception: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ TRIGGER INBOX NOTIFICATION
  Future<void> _triggerInboxNotification(int currentUnreadCount) async {
    try {
      print('📧 Checking inbox: last=$_lastUnreadCount, current=$currentUnreadCount');
      
      // Hanya trigger jika ada pesan baru
      if (currentUnreadCount > _lastUnreadCount && currentUnreadCount > 0) {
        final newMessagesCount = currentUnreadCount - _lastUnreadCount;
        
        if (newMessagesCount > 0) {
          print('🎯 New inbox messages: $newMessagesCount');
          
          await systemNotifier.showSystemNotification(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: newMessagesCount == 1 ? 'Pesan Baru - KSMI' : '$newMessagesCount Pesan Baru - KSMI',
            body: newMessagesCount == 1 
                ? 'Anda memiliki 1 pesan belum dibaca di inbox' 
                : 'Anda memiliki $newMessagesCount pesan belum dibaca di inbox',
          );
        }
      }
      
      _lastUnreadCount = currentUnreadCount;
      
    } catch (e) {
      print('❌ Error triggering inbox notification: $e');
    }
  }

  // ✅ CALCULATE UNREAD COUNT
  static int _calculateUnreadCount(Map<String, dynamic> inboxData) {
    try {
      final inboxList = inboxData['inbox'] ?? [];
      final unreadCount = inboxList.where((item) {
        if (item is Map<String, dynamic>) {
          final readStatus = item['read_status']?.toString() ?? '1';
          return readStatus == '0';
        }
        return false;
      }).length;
      
      print('✅ Unread count calculated: $unreadCount');
      return unreadCount;
    } catch (e) {
      print('❌ Error calculating unread count: $e');
      return 0;
    }
  }

  // ✅ GET PROTECTED HEADERS
  Future<Map<String, String>> getProtectedHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = prefs.getString('token');
      final sessionCookie = prefs.getString('ci_session');
      
      final headers = <String, String>{
        'DEVICE-ID': '12341231313131',
        'DEVICE-TOKEN': '1234232423424',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      
      if (userKey != null && userKey.isNotEmpty) {
        headers['x-api-key'] = userKey;
      }
      
      if (sessionCookie != null && sessionCookie.isNotEmpty) {
        headers['Cookie'] = 'ci_session=$sessionCookie';
      }
      
      return headers;
    } catch (e) {
      print('❌ Error getProtectedHeaders: $e');
      return {
        'DEVICE-ID': '12341231313131',
        'DEVICE-TOKEN': '1234232423424',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
    }
  }

  // ✅ SUBSCRIBE TO TOPIC
Future<void> subscribeToTopic(String topic) async {
  try {
    if (topic.isNotEmpty) {
      print('🔔 Subscribing to topic: $topic');
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Successfully subscribed to topic: $topic');
    } else {
      print('⚠️ Cannot subscribe to empty topic');
    }
  } catch (e) {
    print('❌ ERROR subscribing to topic $topic: $e');
    throw e; // Re-throw agar error bisa ditangani di caller
  }
}

// ✅ UNSUBSCRIBE FROM TOPIC
Future<void> unsubscribeFromTopic(String topic) async {
  try {
    if (topic.isNotEmpty) {
      print('🔔 Unsubscribing from topic: $topic');
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Successfully unsubscribed from topic: $topic');
    } else {
      print('⚠️ Cannot unsubscribe from empty topic');
    }
  } catch (e) {
    print('❌ ERROR unsubscribing from topic $topic: $e');
    throw e; // Re-throw agar error bisa ditangani di caller
  }
}

// ✅ SUBSCRIBE TO MULTIPLE TOPICS
Future<void> subscribeToTopics(List<String> topics) async {
  try {
    for (final topic in topics) {
      if (topic.isNotEmpty) {
        await subscribeToTopic(topic);
      }
    }
    print('✅ Successfully subscribed to ${topics.length} topics');
  } catch (e) {
    print('❌ ERROR subscribing to multiple topics: $e');
    throw e;
  }
}

// ✅ UNSUBSCRIBE FROM MULTIPLE TOPICS
Future<void> unsubscribeFromTopics(List<String> topics) async {
  try {
    for (final topic in topics) {
      if (topic.isNotEmpty) {
        await unsubscribeFromTopic(topic);
      }
    }
    print('✅ Successfully unsubscribed from ${topics.length} topics');
  } catch (e) {
    print('❌ ERROR unsubscribing from multiple topics: $e');
    throw e;
  }
}

// ✅ GET CURRENT SUBSCRIPTIONS (Optional - untuk debugging)
Future<List<String>> getSubscribedTopics() async {
  try {
    // Note: Firebase Messaging tidak menyediakan method untuk mendapatkan daftar topic
    // Method ini hanya untuk interface consistency
    print('ℹ️ Firebase Messaging tidak menyediakan method untuk mendapatkan daftar topic');
    return [];
  } catch (e) {
    print('❌ ERROR getting subscribed topics: $e');
    return [];
  }
}

  // ✅ LOAD INITIAL INBOX DATA
  Future<void> _loadInitialInboxData() async {
    try {
      print('📥 Loading initial inbox data...');
      final result = await getAllInbox();
      
      if (result['success'] == true) {
        final inboxData = result['data'] ?? {};
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('last_inbox_data', jsonEncode(inboxData));
        await prefs.setInt('unread_notifications', result['unread_count'] ?? 0);
        
        print('✅ Initial inbox loaded: ${result['unread_count']} unread messages');
      }
    } catch (e) {
      print('❌ Error loading initial inbox data: $e');
    }
  }

  // ✅ REFRESH INBOX DATA
  Future<Map<String, dynamic>> refreshInboxData() async {
    return await getAllInbox();
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

  // ✅ GET FCM TOKEN
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ ERROR getting FCM token: $e');
      return null;
    }
  }

  // ✅ TEST SYSTEM NOTIFICATIONS
  Future<void> testSystemNotifications() async {
    try {
      await systemNotifier.testBasicNotification();
    } catch (e) {
      print('❌ System notification test failed: $e');
    }
  }

  // ✅ DISPOSE
  void dispose() {
    print('🧹 Firebase Service disposed');
    _isInitialized = false;
  }
}

// Global instance
final firebaseService = FirebaseService();