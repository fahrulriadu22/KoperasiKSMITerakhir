// services/notification_tester.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_service.dart';

class NotificationTester {
  static bool _isFirebaseInitialized = false;
  static late FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  // ✅ INITIALIZATION METHOD (DIPERBAIKI)
  static Future<void> initialize() async {
    try {
      _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _localNotificationsPlugin.initialize(initializationSettings);
      
      // Try to initialize Firebase
      try {
        // Coba akses Firebase Messaging untuk check availability
        await FirebaseMessaging.instance.getToken();
        _isFirebaseInitialized = true;
        print('✅ Firebase NotificationTester initialized successfully');
      } catch (e) {
        print('⚠️ Firebase initialization failed, using local notifications only: $e');
        _isFirebaseInitialized = false;
      }
      
    } catch (e) {
      print('❌ NotificationTester initialization failed: $e');
      rethrow;
    }
  }

  // ✅ CHECK IF FIREBASE IS AVAILABLE
  static Future<bool> _checkFirebaseAvailability() async {
    if (!_isFirebaseInitialized) {
      print('⚠️ Firebase not available, using local notifications');
      return false;
    }
    return true;
  }

  // ✅ MAIN TEST METHOD
  static Future<void> testLocalNotification() async {
    try {
      print('🧪 Starting notification test...');
      
      final bool useFirebase = await _checkFirebaseAvailability();
      
      if (useFirebase) {
        await _triggerFirebaseTestNotification();
      } else {
        await _showFallbackNotification();
      }
      
      print('✅ Test notification completed successfully');
    } catch (e) {
      print('❌ Test notification failed: $e');
      // Fallback to basic notification
      await _showBasicNotification();
    }
  }

  // ✅ FIREBASE TEST NOTIFICATION (DIPERBAIKI - PERBAIKAN UTAMA)
  static Future<void> _triggerFirebaseTestNotification() async {
    try {
      final testData = {
        'title': 'Test Notification - KSMI Koperasi',
        'body': 'Ini adalah test notifikasi dari KSMI Koperasi',
        'type': 'test',
        'screen': 'dashboard',
        'id': 'test_${DateTime.now().millisecondsSinceEpoch}'
      };

      // ✅ PERBAIKAN: Akses static getter langsung dari class, bukan instance
      if (FirebaseService.onNotificationReceived != null) {
        FirebaseService.onNotificationReceived!(testData);
        print('📱 Firebase callback triggered');
      } else {
        print('⚠️ FirebaseService.onNotificationReceived is null');
      }
      
      // Juga tampilkan local notification
      await _showTestLocalNotification();
      
    } catch (e) {
      print('❌ Firebase test notification failed: $e');
      throw e;
    }
  }

  // ✅ FALLBACK NOTIFICATION (JIKA FIREBASE GAGAL)
  static Future<void> _showFallbackNotification() async {
    try {
      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Test Notification - KSMI Koperasi',
        'Ini adalah test notifikasi fallback (Firebase tidak tersedia)',
        _getNotificationDetails(),
        payload: '{"type": "test_fallback", "screen": "dashboard"}',
      );
      print('📲 Fallback notification shown successfully');
    } catch (e) {
      print('❌ Fallback notification failed: $e');
      await _showBasicNotification();
    }
  }

  // ✅ BASIC NOTIFICATION (ULTIMATE FALLBACK)
  static Future<void> _showBasicNotification() async {
    try {
      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'KSMI Koperasi',
        'Test notifikasi berhasil!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ksmi_basic_channel',
            'KSMI Basic',
            channelDescription: 'Channel basic untuk Koperasi KSMI',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
      print('📲 Basic notification shown successfully');
    } catch (e) {
      print('❌ Basic notification failed: $e');
      print('💡 Notification system completely unavailable');
    }
  }

  // ✅ TEST LOCAL NOTIFICATION (ORIGINAL)
  static Future<void> _showTestLocalNotification() async {
    try {
      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Test Notification - KSMI Koperasi',
        'Ini adalah test notifikasi lokal dari aplikasi Koperasi KSMI',
        _getNotificationDetails(),
        payload: '{"type": "test", "screen": "dashboard"}',
      );
      print('📲 Test local notification shown successfully');
    } catch (e) {
      print('❌ Error showing test local notification: $e');
      rethrow;
    }
  }

  // ✅ NOTIFICATION DETAILS HELPER
  static NotificationDetails _getNotificationDetails() {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ksmi_test_channel',
      'KSMI Test Channel',
      channelDescription: 'Channel untuk test notifikasi Koperasi KSMI',
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

    return const NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
  }

  // ✅ FCM TOKEN
  static Future<void> printFCMToken() async {
    try {
      final bool useFirebase = await _checkFirebaseAvailability();
      if (!useFirebase) {
        print('❌ Cannot get FCM token: Firebase not available');
        return;
      }
      
      final token = await FirebaseMessaging.instance.getToken();
      print('🔑 FCM Token: $token');
      
      if (token != null) {
        print('📋 Token available for testing');
      } else {
        print('⚠️ FCM Token is null');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  // ✅ CHECK PERMISSIONS
  static Future<void> checkPermissions() async {
    try {
      final bool useFirebase = await _checkFirebaseAvailability();
      if (!useFirebase) {
        print('❌ Cannot check permissions: Firebase not available');
        return;
      }
      
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      print('📱 Notification Settings:');
      print('   - Authorization Status: ${settings.authorizationStatus}');
      print('   - Alert: ${settings.alert}');
      print('   - Badge: ${settings.badge}');
      print('   - Sound: ${settings.sound}');
      print('   - Lock Screen: ${settings.lockScreen}');
      print('   - Car Play: ${settings.carPlay}');
      print('   - Announcement: ${settings.announcement}');
      print('   - Critical Alert: ${settings.criticalAlert}');
      
      // Check local notification permissions
      print('📱 Local Notifications Status:');
      print('   - Plugin Initialized: ${_localNotificationsPlugin != null}');
      
    } catch (e) {
      print('❌ Error checking permissions: $e');
    }
  }

  // ✅ TEST MULTIPLE SCENARIOS
  static Future<void> testMultipleScenarios() async {
    try {
      print('🧪 Testing Multiple Notification Scenarios...');
      
      // Test 1: Simple notification
      await _showSimpleNotification();
      await Future.delayed(const Duration(seconds: 1));
      
      // Test 2: Notification with action
      await _showNotificationWithAction();
      await Future.delayed(const Duration(seconds: 1));
      
      // Test 3: Notification with deep link
      await _showNotificationWithDeepLink();
      
      print('✅ All notification scenarios tested successfully');
    } catch (e) {
      print('❌ Error testing notification scenarios: $e');
    }
  }

  static Future<void> _showSimpleNotification() async {
    try {
      await _localNotificationsPlugin.show(
        1001,
        'Notifikasi Sederhana - KSMI',
        'Ini adalah contoh notifikasi sederhana dari Koperasi KSMI',
        _getNotificationDetails(),
        payload: '{"type": "simple", "screen": "dashboard"}',
      );
      print('📲 Simple notification shown');
    } catch (e) {
      print('❌ Simple notification failed: $e');
    }
  }

  static Future<void> _showNotificationWithAction() async {
    try {
      await _localNotificationsPlugin.show(
        1002,
        'Notifikasi dengan Aksi - KSMI',
        'Tap notifikasi ini untuk membuka halaman tertentu di aplikasi KSMI',
        _getNotificationDetails(),
        payload: '{"type": "action", "screen": "inbox", "action": "view"}',
      );
      print('📲 Action notification shown');
    } catch (e) {
      print('❌ Action notification failed: $e');
    }
  }

  static Future<void> _showNotificationWithDeepLink() async {
    try {
      await _localNotificationsPlugin.show(
        1003,
        'Notifikasi dengan Deep Link - KSMI',
        'Notifikasi ini akan membuka halaman transaksi spesifik',
        _getNotificationDetails(),
        payload: '{"type": "deeplink", "screen": "transaction", "id": "12345"}',
      );
      print('📲 Deep link notification shown');
    } catch (e) {
      print('❌ Deep link notification failed: $e');
    }
  }

  // ✅ CLEAR ALL NOTIFICATIONS
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotificationsPlugin.cancelAll();
      print('🗑️ All local notifications cleared');
      
      // Also try to clear Firebase notifications if available
      final bool useFirebase = await _checkFirebaseAvailability();
      if (useFirebase) {
        print('🗑️ Firebase notifications cleared (if any)');
      }
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  // ✅ GET NOTIFICATION PLUGIN (FOR EXTERNAL USE)
  static FlutterLocalNotificationsPlugin getLocalNotificationsPlugin() {
    return _localNotificationsPlugin;
  }

  // ✅ CHECK INITIALIZATION STATUS
  static bool get isInitialized => _localNotificationsPlugin != null;
  static bool get isFirebaseAvailable => _isFirebaseInitialized;

  // ✅ SIMPLE TEST METHOD (ALTERNATIF)
  static Future<void> simpleTest() async {
    try {
      if (!isInitialized) {
        await initialize();
      }
      
      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Test KSMI Koperasi',
        'Notifikasi test berhasil! 🎉',
        _getNotificationDetails(),
      );
      
      print('✅ Simple test notification sent');
    } catch (e) {
      print('❌ Simple test failed: $e');
    }
  }

  // ✅ QUICK TEST METHOD (PALING SIMPLE)
  static Future<void> quickTest() async {
    try {
      if (!isInitialized) {
        await initialize();
      }
      
      // Langsung tampilkan notifikasi tanpa Firebase
      await _localNotificationsPlugin.show(
        9999,
        'KSMI Koperasi - Test',
        'Test notifikasi berhasil dijalankan!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ksmi_quick_channel',
            'KSMI Quick Test',
            channelDescription: 'Channel untuk test cepat',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      
      print('✅ Quick test notification sent successfully');
    } catch (e) {
      print('❌ Quick test failed: $e');
      rethrow;
    }
  }
}