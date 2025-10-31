import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // ✅ Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
    
    // ✅ Initialize Firebase Messaging
    await FirebaseNotificationService.initialize();
    print('✅ Firebase Messaging initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    // Tetap lanjut meski Firebase error
  }
  
  // ✅ Check login status dengan try-catch
  bool isLoggedIn = false;
  try {
    final apiService = ApiService();
    isLoggedIn = await apiService.checkLoginStatus();
    print('🔐 Auto-login status: $isLoggedIn');
  } catch (e) {
    print('❌ Auto-login check error: $e');
    isLoggedIn = false;
  }
  
  runApp(KoperasiKSMIApp(isLoggedIn: isLoggedIn));
}

class KoperasiKSMIApp extends StatelessWidget {
  final bool isLoggedIn;

  const KoperasiKSMIApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koperasi KSMI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green[800],
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.greenAccent),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      // ✅ AUTO-LOGIN: Langsung ke dashboard jika sudah login
      home: isLoggedIn ? const DashboardScreen(user: {}) : const LoginScreen(),
    );
  }
}