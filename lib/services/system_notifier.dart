// services/system_notifier.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SystemNotifier {
  static final SystemNotifier _instance = SystemNotifier._internal();
  factory SystemNotifier() => _instance;
  SystemNotifier._internal();

  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  // ✅ CHANNEL ID HARUS SAMA DENGAN MANIFEST
  static const String _channelId = 'ksmi_channel_id';
  static const String _channelName = 'KSMI Koperasi';
  static const String _channelDescription = 'Notifikasi dari Koperasi KSMI';

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      print('🔄 Initializing SystemNotifier...');

      // ✅ 1. INIT PLUGIN DULU
      _notifications = FlutterLocalNotificationsPlugin();

      // ✅ 2. SETUP ANDROID - PAKAI @mipmap/ic_launcher
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // ✅ 3. SETUP iOS 
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // ✅ 4. INITIALIZATION SETTINGS
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // ✅ 5. INITIALIZE PLUGIN
      await _notifications.initialize(initSettings);

      // ✅ 6. CREATE ANDROID CHANNEL - ID HARUS SAMA DENGAN MANIFEST
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId, // ✅ HARUS SAMA: 'ksmi_channel_id'
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // ✅ PERBAIKAN: HAPUS DOT SHORTHAND
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
      print('✅ SystemNotifier initialized SUCCESSFULLY!');
      print('✅ Channel ID: $_channelId');
      
    } catch (e) {
      print('❌ SystemNotifier initialization FAILED: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // ✅ SHOW SYSTEM NOTIFICATION
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      // ✅ PASTIKAN INIT DULU
      if (!_isInitialized) {
        await initialize();
      }

      print('📱 Preparing SYSTEM notification: $title');

      // ✅ ANDROID NOTIFICATION DETAILS - TANPA BigTextStyle
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId, // ✅ HARUS SAMA: 'ksmi_channel_id'
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        autoCancel: true,
      );

      // ✅ NOTIFICATION DETAILS - PAKAI CONST
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // ✅ SHOW NOTIFICATION
      await _notifications.show(id, title, body, details);
      
      print('🎉 SYSTEM NOTIFICATION BERHASIL: $title');
      print('   → ID: $id');
      print('   → Channel: $_channelId');
      print('   → Body: $body');
      
    } catch (e) {
      print('❌ ERROR showing system notification: $e');
      print('   → Channel ID: $_channelId');
      rethrow;
    }
  }

  // ✅ TEST METHODS - DENGAN DELAY
  Future<void> testBasicNotification() async {
    await showSystemNotification(
      id: 1001,
      title: 'TEST: System Notification',
      body: 'Ini adalah test notifikasi SYSTEM dari KSMI - Harus muncul di panel Android!',
    );
  }

  Future<void> testInboxNotification() async {
    await showSystemNotification(
      id: 1002,
      title: 'Pesan Baru - KSMI',
      body: 'Anda memiliki 2 pesan belum dibaca di inbox KSMI',
    );
  }

  Future<void> testMultipleNotifications() async {
    // Notification 1
    await showSystemNotification(
      id: 1003,
      title: 'Penarikan SIQUNA',
      body: 'Penarikan SIQUNA Sebesar Rp. 100.000 Telah Berhasil',
    );

    await Future.delayed(const Duration(seconds: 2));

    // Notification 2  
    await showSystemNotification(
      id: 1004,
      title: 'Pembayaran SIQUNA',
      body: 'Pembayaran SIQUNA Sebesar Rp. 500.000 Telah Berhasil',
    );

    await Future.delayed(const Duration(seconds: 2));

    // Notification 3 - Summary
    await showSystemNotification(
      id: 1005,
      title: '2 Transaksi Baru',
      body: 'Anda memiliki 2 transaksi baru di KSMI',
    );
  }

  // ✅ CLEAR ALL NOTIFICATIONS
  Future<void> clearAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('🧹 All system notifications cleared');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  bool get isInitialized => _isInitialized;
}