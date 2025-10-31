import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // ✅ CONTROLLERS SESUAI DENGAN API REGISTER
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController faxController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController jobController = TextEditingController();
  final TextEditingController birthPlaceController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController agamaIdController = TextEditingController(text: "1");
  final TextEditingController cabangIdController = TextEditingController(text: "1");
  final TextEditingController jenisIdentitasController = TextEditingController(text: "KTP");
  final TextEditingController tanggalBerlakuController = TextEditingController(text: "2025-12-31");
  final TextEditingController nomorIdentitasController = TextEditingController();
  final TextEditingController sumberInformasiController = TextEditingController(text: "Teman");
  final TextEditingController ktpAlamatController = TextEditingController();
  final TextEditingController ktpRtController = TextEditingController();
  final TextEditingController ktpRwController = TextEditingController();
  final TextEditingController ktpIdProvinceController = TextEditingController(text: "35");
  final TextEditingController ktpIdRegencyController = TextEditingController();
  final TextEditingController ktpPostalController = TextEditingController();
  final TextEditingController ktpNoController = TextEditingController();
  final TextEditingController domisiliAlamatController = TextEditingController();
  final TextEditingController domisiliRtController = TextEditingController();
  final TextEditingController domisiliRwController = TextEditingController();
  final TextEditingController domisiliIdRegencyController = TextEditingController();
  final TextEditingController domisiliPostalController = TextEditingController();
  final TextEditingController domisiliNoController = TextEditingController();
  final TextEditingController namaAhliWarisController = TextEditingController();
  final TextEditingController tempatLahirAhliWarisController = TextEditingController();
  final TextEditingController tanggalLahirAhliWarisController = TextEditingController();
  final TextEditingController hubunganController = TextEditingController(text: "Orang Tua");

  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  DateTime? _selectedDate;
  DateTime? _selectedTanggalBerlaku;
  DateTime? _selectedTanggalLahirAhliWaris;

  String? _selectedProvinsi;
  String? _selectedKota;
  String? _selectedDomisiliKota;

  // ✅ Daftar provinsi dan kota di Indonesia
  final Map<String, List<String>> _provinsiKotaMap = {
    '35': [
      'Jakarta Pusat',
      'Jakarta Utara', 
      'Jakarta Barat',
      'Jakarta Selatan',
      'Jakarta Timur',
    ],
    '32': [
      'Bandung',
      'Bekasi',
      'Bogor',
    ],
    '33': [
      'Semarang',
      'Surakarta',
    ],
  };

  List<String> get _provinsiList => _provinsiKotaMap.keys.toList();
  List<String> get _kotaList => _selectedProvinsi != null 
      ? _provinsiKotaMap[_selectedProvinsi]! 
      : [];

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ CHECK USER EXIST FIRST
      final checkResult = await _apiService.checkUserExist(
        usernameController.text.trim(),
        emailController.text.trim(),
      );

      if (checkResult['exists'] == true) {
        setState(() => _isLoading = false);
        _showErrorDialog(checkResult['message'] ?? 'Username atau email sudah terdaftar.');
        return;
      }

      // ✅ PREPARE REGISTER DATA
      final userData = {
        'username': usernameController.text.trim(),
        'password': passwordController.text.trim(),
        'email': emailController.text.trim(),
        'fullname': fullnameController.text.trim(),
        'fax': faxController.text.trim().isEmpty ? "-" : faxController.text.trim(),
        'phone': phoneController.text.trim(),
        'job': jobController.text.trim().isEmpty ? "Karyawan Swasta" : jobController.text.trim(),
        'birth_place': birthPlaceController.text.trim(),
        'birth_date': _selectedDate != null 
            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}' 
            : '2000-01-01',
        'agama_id': agamaIdController.text.trim(),
        'cabang_id': cabangIdController.text.trim(),
        'jenis_identitas': jenisIdentitasController.text.trim(),
        'tanggal_berlaku': _selectedTanggalBerlaku != null
            ? '${_selectedTanggalBerlaku!.year}-${_selectedTanggalBerlaku!.month.toString().padLeft(2, '0')}-${_selectedTanggalBerlaku!.day.toString().padLeft(2, '0')}'
            : '2025-12-31',
        'nomor_identitas': nomorIdentitasController.text.trim(),
        'sumber_informasi': sumberInformasiController.text.trim(),
        'ktp_alamat': ktpAlamatController.text.trim(),
        'ktp_rt': ktpRtController.text.trim().isEmpty ? "001" : ktpRtController.text.trim(),
        'ktp_rw': ktpRwController.text.trim().isEmpty ? "001" : ktpRwController.text.trim(),
        'ktp_id_province': ktpIdProvinceController.text.trim(),
        'ktp_id_regency': ktpIdRegencyController.text.trim().isEmpty ? "3578" : ktpIdRegencyController.text.trim(),
        'ktp_postal': ktpPostalController.text.trim().isEmpty ? "60111" : ktpPostalController.text.trim(),
        'ktp_no': ktpNoController.text.trim().isEmpty ? "01" : ktpNoController.text.trim(),
        'domisili_alamat': domisiliAlamatController.text.trim().isEmpty ? ktpAlamatController.text.trim() : domisiliAlamatController.text.trim(),
        'domisili_rt': domisiliRtController.text.trim().isEmpty ? ktpRtController.text.trim() : domisiliRtController.text.trim(),
        'domisili_rw': domisiliRwController.text.trim().isEmpty ? ktpRwController.text.trim() : domisiliRwController.text.trim(),
        'domisili_id_regency': domisiliIdRegencyController.text.trim().isEmpty ? ktpIdRegencyController.text.trim() : domisiliIdRegencyController.text.trim(),
        'domisili_postal': domisiliPostalController.text.trim().isEmpty ? ktpPostalController.text.trim() : domisiliPostalController.text.trim(),
        'domisili_no': domisiliNoController.text.trim().isEmpty ? ktpNoController.text.trim() : domisiliNoController.text.trim(),
        'nama_ahli_waris': namaAhliWarisController.text.trim().isEmpty ? fullnameController.text.trim() : namaAhliWarisController.text.trim(),
        'tempat_lahir_ahli_waris': tempatLahirAhliWarisController.text.trim().isEmpty ? birthPlaceController.text.trim() : tempatLahirAhliWarisController.text.trim(),
        'tanggal_lahir_ahli_waris': _selectedTanggalLahirAhliWaris != null
            ? '${_selectedTanggalLahirAhliWaris!.year}-${_selectedTanggalLahirAhliWaris!.month.toString().padLeft(2, '0')}-${_selectedTanggalLahirAhliWaris!.day.toString().padLeft(2, '0')}'
            : '2000-01-01',
        'hubungan': hubunganController.text.trim(),
      };

      // ✅ CALL REGISTER API
      final result = await _apiService.register(userData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessDialog(result['message']); // ✅ PERBAIKAN: Panggil dengan parameter
      } else {
        _showErrorDialog(result['message'] ?? 'Registrasi gagal. Silakan coba lagi.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  // ✅ PERBAIKAN: Method _showSuccessDialog yang menerima parameter
  void _showSuccessDialog([String? message]) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pendaftaran Berhasil 🎉'),
        content: Text(message ?? 'Akun Anda telah berhasil dibuat. Silakan login untuk melanjutkan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('LOGIN SEKARANG'),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrasi Gagal'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ✅ DATE PICKER METHODS
  Future<void> _selectDate(Function(DateTime) onDateSelected, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  // ✅ VALIDATION METHODS
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Minimal 6 karakter';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != passwordController.text) {
      return 'Password tidak cocok';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'No. telepon wajib diisi';
    }
    if (!RegExp(r'^08[0-9]{8,11}$').hasMatch(value)) {
      return 'Format no. telepon tidak valid';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Daftar Anggota'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ SECTION: DATA LOGIN
                _buildSectionHeader('Data Login'),
                _buildTextField(
                  controller: usernameController,
                  label: 'Username *',
                  icon: Icons.person_outline,
                  validator: (v) => _validateRequired(v, 'Username'),
                  hintText: 'min. 4 karakter',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: emailController,
                  label: 'Email *',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: passwordController,
                  label: 'Password *',
                  obscureText: _obscureText,
                  onToggle: () => setState(() => _obscureText = !_obscureText),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: 'Konfirmasi Password *',
                  obscureText: _obscureConfirmText,
                  onToggle: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
                  validator: _validateConfirmPassword,
                ),

                const SizedBox(height: 24),

                // ✅ SECTION: DATA PRIBADI
                _buildSectionHeader('Data Pribadi'),
                _buildTextField(
                  controller: fullnameController,
                  label: 'Nama Lengkap *',
                  icon: Icons.badge_outlined,
                  validator: (v) => _validateRequired(v, 'Nama lengkap'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: birthPlaceController,
                        label: 'Tempat Lahir *',
                        icon: Icons.place_outlined,
                        validator: (v) => _validateRequired(v, 'Tempat lahir'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateField(
                        label: 'Tanggal Lahir *',
                        value: _selectedDate,
                        onTap: () => _selectDate((date) {
                          setState(() => _selectedDate = date);
                        }, DateTime.now().subtract(const Duration(days: 365 * 18))),
                        validator: (v) => _selectedDate == null ? 'Tanggal lahir wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: phoneController,
                  label: 'No. Telepon *',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: jobController,
                  label: 'Pekerjaan *',
                  icon: Icons.work_outline,
                  validator: (v) => _validateRequired(v, 'Pekerjaan'),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: faxController,
                  label: 'Fax',
                  icon: Icons.fax_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),

                // ✅ SECTION: DATA KTP
                _buildSectionHeader('Data Identitas (KTP)'),
                _buildTextField(
                  controller: nomorIdentitasController,
                  label: 'Nomor KTP *',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => _validateRequired(v, 'Nomor KTP'),
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'Tanggal Berlaku KTP',
                  value: _selectedTanggalBerlaku,
                  onTap: () => _selectDate((date) {
                    setState(() => _selectedTanggalBerlaku = date);
                  }, DateTime.now().add(const Duration(days: 365 * 5))),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: ktpAlamatController,
                  label: 'Alamat KTP *',
                  icon: Icons.home_outlined,
                  maxLines: 2,
                  validator: (v) => _validateRequired(v, 'Alamat KTP'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: ktpRtController,
                        label: 'RT *',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => _validateRequired(v, 'RT'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: ktpRwController,
                        label: 'RW *',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => _validateRequired(v, 'RW'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: ktpNoController,
                  label: 'No. Rumah *',
                  icon: Icons.house_outlined,
                  validator: (v) => _validateRequired(v, 'No. Rumah'),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: ktpPostalController,
                  label: 'Kode Pos *',
                  icon: Icons.markunread_mailbox_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => _validateRequired(v, 'Kode Pos'),
                ),

                const SizedBox(height: 24),

                // ✅ SECTION: DATA AHLI WARIS
                _buildSectionHeader('Data Ahli Waris'),
                _buildTextField(
                  controller: namaAhliWarisController,
                  label: 'Nama Ahli Waris *',
                  icon: Icons.person_outlined,
                  validator: (v) => _validateRequired(v, 'Nama ahli waris'),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: tempatLahirAhliWarisController,
                  label: 'Tempat Lahir Ahli Waris *',
                  icon: Icons.place_outlined,
                  validator: (v) => _validateRequired(v, 'Tempat lahir ahli waris'),
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'Tanggal Lahir Ahli Waris *',
                  value: _selectedTanggalLahirAhliWaris,
                  onTap: () => _selectDate((date) {
                    setState(() => _selectedTanggalLahirAhliWaris = date);
                  }, DateTime.now().subtract(const Duration(days: 365 * 18))),
                  validator: (v) => _selectedTanggalLahirAhliWaris == null ? 'Tanggal lahir ahli waris wajib diisi' : null,
                ),

                const SizedBox(height: 32),

                // ✅ TOMBOL REGISTER
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'DAFTAR SEKARANG',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ LINK KE LOGIN
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Sudah punya akun? Login di sini',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET BUILDERS
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green[900],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: hintText,
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Pilih tanggal',
      ),
      controller: TextEditingController(
        text: value != null
            ? '${value.day}/${value.month}/${value.year}'
            : '',
      ),
      validator: validator,
    );
  }
}