import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_main.dart';
import 'screens/upload_dokumen_screen.dart';
import 'services/api_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // ✅ App Startup Configuration
  await _initializeApp(prefs);
  
  runApp(const KoperasiKSMIApp());
}

// ✅ Initialize App Services
Future<void> _initializeApp(SharedPreferences prefs) async {
  try {
    print('🚀 STARTING KOPERASI KSMI APP...');
    
    // ✅ Initialize Firebase Services
    await _initializeFirebase();
    
    // ✅ Initialize Firebase Messaging with error handling
    await _initializeFirebaseMessaging();
    
    // ✅ Initialize other services if needed
    await _initializeOtherServices();
    
    print('🎉 APP INITIALIZATION COMPLETED SUCCESSFULLY!');
    
  } catch (e) {
    print('⚠️ APP INITIALIZATION WARNING: $e');
    // Continue app even if some services fail
  }
}

// ✅ Initialize Firebase Core
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    print('✅ Firebase Core initialized successfully');
  } catch (e) {
    print('❌ Firebase Core initialization failed: $e');
    // Don't throw error, continue without Firebase
  }
}

// ✅ Initialize Firebase Messaging
Future<void> _initializeFirebaseMessaging() async {
  try {
    await firebaseService.initialize();
    print('✅ Firebase Messaging initialized successfully');
    
    // Setup notification callbacks
    _setupNotificationCallbacks();
    
  } catch (e) {
    print('❌ Firebase Messaging initialization failed: $e');
    // Don't throw error, continue without notifications
  }
}

// ✅ Setup Notification Callbacks
void _setupNotificationCallbacks() {
  FirebaseService.onNotificationTap = (Map<String, dynamic> data) {
    print('👆 Notification tapped with data: $data');
    _handleNotificationNavigation(data);
  };
  
  FirebaseService.onNotificationReceived = (Map<String, dynamic> data) {
    print('📱 Notification received with data: $data');
    _handleNotificationData(data);
  };
}

// ✅ Handle Notification Navigation
void _handleNotificationNavigation(Map<String, dynamic> data) {
  // Handle navigation based on notification data
  final type = data['type']?.toString() ?? '';
  final id = data['id']?.toString() ?? '';
  
  print('📍 Navigating to: $type, ID: $id');
  
  // Example navigation logic:
  switch (type) {
    case 'inbox':
      // Navigator.push(context, MaterialPageRoute(builder: (_) => InboxScreen()));
      break;
    case 'transaction':
      // Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(id: id)));
      break;
    case 'promo':
      // Navigator.push(context, MaterialPageRoute(builder: (_) => PromoScreen()));
      break;
    default:
      // Navigate to default screen
      break;
  }
}

// ✅ Handle Notification Data
void _handleNotificationData(Map<String, dynamic> data) {
  // Update UI, show snackbar, etc. based on notification data
  final title = data['title']?.toString() ?? 'KSMI Koperasi';
  final body = data['body']?.toString() ?? 'Pesan baru';
  
  print('📢 Notification: $title - $body');
}

// ✅ Initialize Other Services
Future<void> _initializeOtherServices() async {
  try {
    // Initialize other services here if needed
    await Future.delayed(const Duration(milliseconds: 100));
    print('✅ Other services initialized');
  } catch (e) {
    print('❌ Other services initialization failed: $e');
  }
}

class KoperasiKSMIApp extends StatefulWidget {
  const KoperasiKSMIApp({super.key});

  @override
  State<KoperasiKSMIApp> createState() => _KoperasiKSMIAppState();
}

class _KoperasiKSMIAppState extends State<KoperasiKSMIApp> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // ✅ Check Authentication Status
  Future<void> _checkAuthStatus() async {
    try {
      print('🔐 Checking authentication status...');
      
      final isLoggedIn = await _apiService.isLoggedIn();
      
      if (isLoggedIn) {
        final userData = await _apiService.getCurrentUser();
        if (userData != null) {
          setState(() {
            _isLoggedIn = true;
            _userData = userData;
          });
          print('✅ User is logged in: ${userData['user_name']}');
          
          // Subscribe to user-specific topics
          _subscribeToUserTopics(userData);
        } else {
          setState(() {
            _isLoggedIn = false;
          });
          print('❌ User data not found');
        }
      } else {
        setState(() {
          _isLoggedIn = false;
        });
        print('❌ User is not logged in');
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      setState(() {
        _isLoggedIn = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ Subscribe to User-specific Topics
  Future<void> _subscribeToUserTopics(Map<String, dynamic> userData) async {
    try {
      final userId = userData['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        await firebaseService.subscribeToTopic('user_$userId');
        await firebaseService.subscribeToTopic('koperasi_ksmi');
        await firebaseService.subscribeToTopic('all_users');
        print('✅ Subscribed to user topics');
      }
    } catch (e) {
      print('❌ Error subscribing to topics: $e');
    }
  }

  // ✅ Handle Login Success
  void _handleLoginSuccess(Map<String, dynamic> userData) {
    setState(() {
      _isLoggedIn = true;
      _userData = userData;
    });
    
    // Subscribe to topics after login
    _subscribeToUserTopics(userData);
    
    // ✅ CEK APAKAH USER SUDAH UPLOAD DOKUMEN
    _checkDokumenStatus(userData);
  }

  // ✅ Check Dokumen Status untuk menentukan navigasi
  void _checkDokumenStatus(Map<String, dynamic> userData) {
    final bool hasKTP = userData['foto_ktp'] != null && userData['foto_ktp'].toString().isNotEmpty && userData['foto_ktp'] != 'uploaded';
    final bool hasKK = userData['foto_kk'] != null && userData['foto_kk'].toString().isNotEmpty && userData['foto_kk'] != 'uploaded';
    final bool hasFotoDiri = userData['foto_diri'] != null && userData['foto_diri'].toString().isNotEmpty && userData['foto_diri'] != 'uploaded';
    
    final bool allDokumenUploaded = hasKTP && hasKK && hasFotoDiri;
    
    print('📋 Dokumen Status:');
    print('   - KTP: ${hasKTP ? "✅" : "❌"}');
    print('   - KK: ${hasKK ? "✅" : "❌"}');
    print('   - Foto Diri: ${hasFotoDiri ? "✅" : "❌"}');
    print('   - All Uploaded: $allDokumenUploaded');
    
    if (!allDokumenUploaded) {
      // Navigate to UploadDokumenScreen jika belum lengkap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => UploadDokumenScreen(user: userData),
            ),
            (route) => false,
          );
        }
      });
    } else {
      // Langsung ke dashboard jika sudah lengkap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DashboardMain(user: userData),
            ),
            (route) => false,
          );
        }
      });
    }
  }

  // ✅ Handle Logout
  void _handleLogout() async {
    try {
      // Unsubscribe from topics
      final userId = _userData['user_id']?.toString();
      if (userId != null) {
        await firebaseService.unsubscribeFromTopic('user_$userId');
      }
      
      // Delete FCM token
      await firebaseService.deleteFCMToken();
      
      // Clear local data
      await _apiService.logout();
    } catch (e) {
      print('❌ Error during logout: $e');
    } finally {
      setState(() {
        _isLoggedIn = false;
        _userData = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koperasi KSMI',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      
      // ✅ Home based on auth status
      home: _isLoading
          ? _buildLoadingScreen()
          : _isLoggedIn
              ? DashboardMain(user: _userData)
              : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }

  // ✅ Loading Screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Koperasi KSMI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            const Text(
              'Memuat...',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ App Theme
  ThemeData _buildAppTheme() {
    return ThemeData(
      primaryColor: Colors.green[800],
      primarySwatch: Colors.green,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green[800]!,
        primary: Colors.green[800]!,
        secondary: Colors.greenAccent[400]!,
      ),
      scaffoldBackgroundColor: Colors.green[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.green.withOpacity(0.3),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green[600]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      useMaterial3: true,
    );
  }

  @override
  void dispose() {
    firebaseService.dispose();
    super.dispose();
  }
}

// ✅ Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ Global scaffold messenger key for showing snackbars from anywhere
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
    GlobalKey<ScaffoldMessengerState>();