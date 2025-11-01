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
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await _initializeApp(prefs);
  
  runApp(const KoperasiKSMIApp());
}

Future<void> _initializeApp(SharedPreferences prefs) async {
  try {
    await _initializeFirebase();
    await _initializeFirebaseMessaging();
    await _initializeOtherServices();
  } catch (e) {
    // Continue app even if some services fail
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Don't throw error, continue without Firebase
  }
}

Future<void> _initializeFirebaseMessaging() async {
  try {
    await firebaseService.initialize();
    _setupNotificationCallbacks();
  } catch (e) {
    // Don't throw error, continue without notifications
  }
}

void _setupNotificationCallbacks() {
  FirebaseService.onNotificationTap = (Map<String, dynamic> data) {
    _handleNotificationNavigation(data);
  };
  
  FirebaseService.onNotificationReceived = (Map<String, dynamic> data) {
    _handleNotificationData(data);
  };
}

void _handleNotificationNavigation(Map<String, dynamic> data) {
  final type = data['type']?.toString() ?? '';
  final id = data['id']?.toString() ?? '';
  
  // Example navigation logic
  switch (type) {
    case 'inbox':
      break;
    case 'transaction':
      break;
    case 'promo':
      break;
    default:
      break;
  }
}

void _handleNotificationData(Map<String, dynamic> data) {
  final title = data['title']?.toString() ?? 'KSMI Koperasi';
  final body = data['body']?.toString() ?? 'Pesan baru';
}

Future<void> _initializeOtherServices() async {
  try {
    await Future.delayed(const Duration(milliseconds: 100));
  } catch (e) {
    // Ignore error
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

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _apiService.isLoggedIn();
      
      if (isLoggedIn) {
        final userData = await _apiService.getCurrentUser();
        if (userData != null && userData.isNotEmpty) {
          setState(() {
            _isLoggedIn = true;
            _userData = userData;
          });
          _subscribeToUserTopics(userData);
        } else {
          await _handleLogout();
        }
      } else {
        setState(() {
          _isLoggedIn = false;
          _userData = {};
        });
      }
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _userData = {};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToUserTopics(Map<String, dynamic> userData) async {
    try {
      final userId = userData['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        await firebaseService.subscribeToTopic('user_$userId');
        await firebaseService.subscribeToTopic('koperasi_ksmi');
      }
    } catch (e) {
      // Ignore error
    }
  }

  void _handleLoginSuccess(Map<String, dynamic> userData) {
    setState(() {
      _isLoggedIn = true;
      _userData = userData;
    });
    
    _subscribeToUserTopics(userData);
    _checkDokumenStatus(userData);
  }

  void _checkDokumenStatus(Map<String, dynamic> userData) {
    final bool hasKTP = userData['foto_ktp'] != null && 
                        userData['foto_ktp'].toString().isNotEmpty && 
                        userData['foto_ktp'] != 'null';
    
    final bool hasKK = userData['foto_kk'] != null && 
                       userData['foto_kk'].toString().isNotEmpty && 
                       userData['foto_kk'] != 'null';
    
    final bool hasFotoDiri = userData['foto_diri'] != null && 
                             userData['foto_diri'].toString().isNotEmpty && 
                             userData['foto_diri'] != 'null';
    
    final bool allDokumenUploaded = hasKTP && hasKK && hasFotoDiri;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && navigatorKey.currentContext != null) {
        if (!allDokumenUploaded) {
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => UploadDokumenScreen(user: userData),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DashboardMain(user: userData),
            ),
            (route) => false,
          );
        }
      }
    });
  }

  Future<void> _handleLogout() async {
    try {
      final userId = _userData['user_id']?.toString();
      if (userId != null) {
        await firebaseService.unsubscribeFromTopic('user_$userId');
      }
      
      await _apiService.logout();
      
      setState(() {
        _isLoggedIn = false;
        _userData = {};
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginScreen(onLoginSuccess: _handleLoginSuccess),
            ),
            (route) => false,
          );
        }
      });
      
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _userData = {};
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginScreen(onLoginSuccess: _handleLoginSuccess),
            ),
            (route) => false,
          );
        }
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
      
      home: _isLoading
          ? _buildLoadingScreen()
          : _isLoggedIn
              ? DashboardMain(user: _userData)
              : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }

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
              child: const Icon(
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
    GlobalKey<ScaffoldMessengerState>();