import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize Firebase
  await Firebase.initializeApp();
  
  // ✅ Initialize Firebase Messaging
  await FirebaseNotificationService.initialize();
  
  // ✅ Check login status
  final apiService = ApiService();
  final bool isLoggedIn = await apiService.checkLoginStatus();
  
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
      home: isLoggedIn ? DashboardScreen(user: {}) : LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(user: {}),
      },
    );
  }
}