import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_main.dart';
import 'register_screen.dart';
import 'upload_dokumen_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onLoginSuccess; // ✅ TAMBAHKAN INI

  const LoginScreen({
    Key? key,
    this.onLoginSuccess, // ✅ TAMBAHKAN INI
  }) : super(key: key);

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
  String _errorMessage = '';

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final input = inputController.text.trim();
    final pass = passwordController.text.trim();

    try {
      final result = await _authService.login(input, pass);

      if (result['success'] == true) {
        if (!mounted) return;
        
        final user = result['user'];
        
        // ✅ PERBAIKAN: CEK APAKAH ADA CALLBACK onLoginSuccess
        if (widget.onLoginSuccess != null) {
          // Jika ada callback, panggil callback
          widget.onLoginSuccess!(user!);
        } else {
          // Jika tidak ada callback, handle navigation sendiri
          _checkDokumenStatusAndNavigate(user!);
        }
        
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login gagal. Silakan coba lagi.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat login: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ PERBAIKAN: Method untuk cek status dokumen dan navigasi
  void _checkDokumenStatusAndNavigate(Map<String, dynamic> user) {
    final bool hasKTP = user['foto_ktp'] != null && 
                        user['foto_ktp'].toString().isNotEmpty && 
                        user['foto_ktp'] != 'uploaded';
    
    final bool hasKK = user['foto_kk'] != null && 
                       user['foto_kk'].toString().isNotEmpty && 
                       user['foto_kk'] != 'uploaded';
    
    final bool hasFotoDiri = user['foto_diri'] != null && 
                             user['foto_diri'].toString().isNotEmpty && 
                             user['foto_diri'] != 'uploaded';
    
    final bool allDokumenUploaded = hasKTP && hasKK && hasFotoDiri;
    
    if (!allDokumenUploaded) {
      // ✅ Navigasi ke UploadDokumenScreen jika dokumen belum lengkap
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UploadDokumenScreen(user: user)),
      );
    } else {
      // ✅ Langsung ke dashboard jika dokumen sudah lengkap
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardMain(user: user)),
      );
    }
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
                            decoration: BoxDecoration(
                              color: Colors.green[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
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
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat Datang Kembali',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ✅ ERROR MESSAGE
                  if (_errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                        prefixIcon: Icon(Icons.person_outline, color: Colors.green[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          color: Colors.green[100]!,
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
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.green[700]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off : Icons.visibility,
                            color: Colors.green[700],
                          ),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    Column(
                      children: [
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
                      ],
                    ),
                  const SizedBox(height: 16),

                  // ✅ TOMBOL REGISTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const RegisterScreen())
                          );
                        },
                        child: Text(
                          'Daftar',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ✅ INFO TAMBAHAN
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green[700], size: 24),
                        const SizedBox(height: 8),
                        Text(
                          'Setelah login, Anda akan diminta untuk melengkapi dokumen KTP, KK, dan Foto Diri',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    inputController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}