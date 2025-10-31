import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_main.dart';
import 'register_screen.dart';
import 'upload_dokumen_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController inputController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _authService = ApiService();
  bool _isLoading = false;
  bool _obscureText = true;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final input = inputController.text.trim();
    final pass = passwordController.text.trim();

    try {
      // ✅ FIX: Sekarang login() return Map<String, dynamic>
      final result = await _authService.login(input, pass);

      if (result['success'] == true) {
        if (!mounted) return;
        
        final user = result['user'];
        
        // ✅ CEK APAKAH SUDAH UPLOAD DOKUMEN (sesuaikan dengan field dari API)
        final bool sudahUploadKTP = user['foto_ktp'] != null && user['foto_ktp'].isNotEmpty;
        final bool sudahUploadKK = user['foto_kk'] != null && user['foto_kk'].isNotEmpty;
        final bool sudahUploadDiri = user['foto_diri'] != null && user['foto_diri'].isNotEmpty;

        print('🔍 Status Upload Dokumen:');
        print('   - KTP: $sudahUploadKTP');
        print('   - KK: $sudahUploadKK');
        print('   - Foto Diri: $sudahUploadDiri');

        if (sudahUploadKTP && sudahUploadKK && sudahUploadDiri) {
          // ✅ SUDAH UPLOAD SEMUA DOKUMEN, LANGSUNG KE DASHBOARD
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardMain(user: user)),
          );
        } else {
          // ✅ BELUM UPLOAD, ARAH KE UPLOAD DOKUMEN
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UploadDokumenScreen(user: user)),
          );
        }
      } else {
        _showErrorDialog(result['message'] ?? 'Login gagal. Silakan coba lagi.');
      }
    } catch (e) {
      print('❌ Login error: $e');
      _showErrorDialog('Terjadi kesalahan saat login: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Gagal'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('OK')
          ),
        ],
      ),
    );
  }

  // ✅ TEST LOGIN FUNCTION (untuk debugging)
  void _testLogin() async {
    // Test dengan credential default
    inputController.text = 'sonik';
    passwordController.text = 'sonik';
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ LOGO KSMI
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/KSMI_LOGO.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.green[700],
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // ✅ TITLE
                  Text(
                    'Koperasi KSMI',
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat Datang Kembali',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ✅ INPUT FIELD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green[100]!,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: inputController,
                      decoration: InputDecoration(
                        labelText: 'Username / Email',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Harap isi username/email' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ PASSWORD FIELD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[100]!,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Harap isi password' : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ✅ TOMBOL LOGIN
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: Colors.green[300],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, 
                                strokeWidth: 2
                              ),
                            )
                          : const Text(
                              'Login', 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w600
                              ),
                            ),
                    ),
                  ),

                  // ✅ TOMBOL TEST LOGIN (Hanya untuk development)
                  if (true) // Set false untuk production
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _testLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          side: BorderSide(color: Colors.green[700]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Test Login (sonik/sonik)',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ✅ TOMBOL REGISTER
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const RegisterScreen())
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Belum punya akun? ',
                        style: TextStyle(color: Colors.grey[600]),
                        children: const [
                          TextSpan(
                            text: 'Daftar',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}