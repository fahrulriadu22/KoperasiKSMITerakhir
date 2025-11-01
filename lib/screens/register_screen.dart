import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService _apiService = ApiService();
  
  // ✅ STATE UNTUK STEP-BY-STEP REGISTER
  int _currentStep = 0;
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // ✅ CONTROLLERS
  // Data Umum
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController birthPlaceController = TextEditingController();
  final TextEditingController faxController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController jobController = TextEditingController();
  DateTime? _selectedBirthDate;

  // Identitas
  final TextEditingController agamaIdController = TextEditingController();
  final TextEditingController cabangIdController = TextEditingController();
  final TextEditingController jenisIdentitasController = TextEditingController(text: "KTP");
  final TextEditingController nomorIdentitasController = TextEditingController();
  final TextEditingController sumberInformasiController = TextEditingController();
  DateTime? _selectedTanggalBerlaku;

  // Data KTP
  final TextEditingController ktpAlamatController = TextEditingController();
  final TextEditingController ktpNoController = TextEditingController();
  final TextEditingController ktpRtController = TextEditingController();
  final TextEditingController ktpRwController = TextEditingController();
  final TextEditingController ktpPostalController = TextEditingController();
  String? _selectedProvinsiKtp;
  String? _selectedKotaKtp;

  // Data Domisili
  final TextEditingController domisiliAlamatController = TextEditingController();
  final TextEditingController domisiliNoController = TextEditingController();
  final TextEditingController domisiliRtController = TextEditingController();
  final TextEditingController domisiliRwController = TextEditingController();
  final TextEditingController domisiliPostalController = TextEditingController();
  String? _selectedProvinsiDomisili;
  String? _selectedKotaDomisili;
  bool _sameAsKtp = false;

  // Data Ahli Waris
  final TextEditingController namaAhliWarisController = TextEditingController();
  final TextEditingController tempatLahirAhliWarisController = TextEditingController();
  final TextEditingController hubunganController = TextEditingController(text: "Orang Tua");
  DateTime? _selectedTanggalLahirAhliWaris;

  // ✅ DATA MASTER (akan diisi dari API)
  List<dynamic> _provinsiList = [];
  List<dynamic> _kotaListKtp = [];
  List<dynamic> _kotaListDomisili = [];
  List<dynamic> _agamaList = [];
  List<dynamic> _cabangList = [];
  List<dynamic> _sumberInfoList = [
    {'id': '1', 'nama': 'Teman/Keluarga'},
    {'id': '2', 'nama': 'Media Sosial'},
    {'id': '3', 'nama': 'Iklan'},
    {'id': '4', 'nama': 'Event'},
    {'id': '5', 'nama': 'Lainnya'},
  ];

  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _agreedToTerms = false; // ✅ FIX: Tambah state untuk persetujuan

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  // ✅ LOAD DATA PROVINSI, AGAMA, CABANG DARI API - FIXED
// ✅ LOAD DATA PROVINSI, AGAMA, CABANG DARI API - DEEP DEBUG
Future<void> _loadMasterData() async {
  try {
    setState(() => _isLoading = true);
    
    print('🔄 Loading master data...');
    
    // Load provinsi
    final provinsiResult = await _apiService.getProvince();
    print('📍 Provinsi result: ${provinsiResult['success']}');
    print('📍 Provinsi data length: ${provinsiResult['data']?.length}');
    if (provinsiResult['data'] != null && provinsiResult['data']!.isNotEmpty) {
      print('📍 Sample provinsi: ${provinsiResult['data']![0]}');
    }

    // Load master data untuk agama dan cabang
    final masterResult = await _apiService.getMasterData();
    print('📦 Master data success: ${masterResult['success']}');
    print('📦 Master data keys: ${masterResult['data']?.keys}');
    
    if (masterResult['success'] == true && masterResult['data'] != null) {
      final data = masterResult['data']!;
      
      // Debug agama
      _agamaList = data['agama'] ?? [];
      print('🕌 Agama list length: ${_agamaList.length}');
      if (_agamaList.isNotEmpty) {
        print('🕌 Sample agama:');
        for (int i = 0; i < _agamaList.length && i < 3; i++) {
          print('   - ${_agamaList[i]}');
        }
      }
      
      // Debug cabang
      _cabangList = data['cabang'] ?? [];
      print('🏢 Cabang list length: ${_cabangList.length}');
      if (_cabangList.isNotEmpty) {
        print('🏢 Sample cabang:');
        for (int i = 0; i < _cabangList.length && i < 3; i++) {
          print('   - ${_cabangList[i]}');
        }
      }
      
      setState(() {});
    } else {
      print('❌ Master data failed: ${masterResult['message']}');
    }
  } catch (e) {
    print('❌ Error loading master data: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  // ✅ LOAD KOTA BERDASARKAN PROVINSI - FIXED
  Future<void> _loadKota(String idProvinsi, bool forKtp) async {
    try {
      final result = await _apiService.getRegency(idProvinsi);
      if (result['success'] == true) {
        setState(() {
          if (forKtp) {
            _kotaListKtp = result['data'] ?? [];
          } else {
            _kotaListDomisili = result['data'] ?? [];
          }
        });
      } else {
        print('❌ Failed to load kota: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error loading kota: $e');
    }
  }

  // ✅ HANDLE REGISTER - FIXED
  void _handleRegister() async {
    if (!_validateAllForms()) return;

    setState(() => _isLoading = true);

    try {
      // Check user exist
      final checkResult = await _apiService.checkUserExist(
        usernameController.text.trim(),
        emailController.text.trim(),
      );

      if (checkResult['exists'] == true) {
        setState(() => _isLoading = false);
        _showErrorDialog(checkResult['message'] ?? 'Username atau email sudah terdaftar.');
        return;
      }

      // Prepare register data
      final userData = {
        // Data Umum
        'username': usernameController.text.trim(),
        'password': passwordController.text.trim(),
        'email': emailController.text.trim(),
        'fullname': fullnameController.text.trim(),
        'fax': faxController.text.trim().isEmpty ? "-" : faxController.text.trim(),
        'phone': phoneController.text.trim(),
        'job': jobController.text.trim().isEmpty ? "Karyawan Swasta" : jobController.text.trim(),
        'birth_place': birthPlaceController.text.trim(),
        'birth_date': _selectedBirthDate != null 
            ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}' 
            : '2000-01-01',

        // Identitas
        'agama_id': agamaIdController.text.trim(),
        'cabang_id': cabangIdController.text.trim(),
        'jenis_identitas': jenisIdentitasController.text.trim(),
        'tanggal_berlaku': _selectedTanggalBerlaku != null
            ? '${_selectedTanggalBerlaku!.year}-${_selectedTanggalBerlaku!.month.toString().padLeft(2, '0')}-${_selectedTanggalBerlaku!.day.toString().padLeft(2, '0')}'
            : '2025-12-31',
        'nomor_identitas': nomorIdentitasController.text.trim(),
        'sumber_informasi': sumberInformasiController.text.trim(),

        // Data KTP
        'ktp_alamat': ktpAlamatController.text.trim(),
        'ktp_rt': ktpRtController.text.trim().isEmpty ? "001" : ktpRtController.text.trim(),
        'ktp_rw': ktpRwController.text.trim().isEmpty ? "001" : ktpRwController.text.trim(),
        'ktp_id_province': _selectedProvinsiKtp ?? "35",
        'ktp_id_regency': _selectedKotaKtp ?? "3578",
        'ktp_postal': ktpPostalController.text.trim().isEmpty ? "60111" : ktpPostalController.text.trim(),
        'ktp_no': ktpNoController.text.trim().isEmpty ? "01" : ktpNoController.text.trim(),

        // Data Domisili
        'domisili_alamat': _sameAsKtp ? ktpAlamatController.text.trim() : domisiliAlamatController.text.trim(),
        'domisili_rt': _sameAsKtp ? ktpRtController.text.trim() : domisiliRtController.text.trim(),
        'domisili_rw': _sameAsKtp ? ktpRwController.text.trim() : domisiliRwController.text.trim(),
        'domisili_id_regency': _sameAsKtp ? (_selectedKotaKtp ?? "3578") : (_selectedKotaDomisili ?? "3578"),
        'domisili_postal': _sameAsKtp ? ktpPostalController.text.trim() : domisiliPostalController.text.trim(),
        'domisili_no': _sameAsKtp ? ktpNoController.text.trim() : domisiliNoController.text.trim(),

        // Data Ahli Waris
        'nama_ahli_waris': namaAhliWarisController.text.trim().isEmpty ? fullnameController.text.trim() : namaAhliWarisController.text.trim(),
        'tempat_lahir_ahli_waris': tempatLahirAhliWarisController.text.trim().isEmpty ? birthPlaceController.text.trim() : tempatLahirAhliWarisController.text.trim(),
        'tanggal_lahir_ahli_waris': _selectedTanggalLahirAhliWaris != null
            ? '${_selectedTanggalLahirAhliWaris!.year}-${_selectedTanggalLahirAhliWaris!.month.toString().padLeft(2, '0')}-${_selectedTanggalLahirAhliWaris!.day.toString().padLeft(2, '0')}'
            : '2000-01-01',
        'hubungan': hubunganController.text.trim(),
      };

      // Call register API
      final result = await _apiService.register(userData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessDialog(result['message'] ?? 'Pendaftaran berhasil!');
      } else {
        _showErrorDialog(result['message'] ?? 'Registrasi gagal. Silakan coba lagi.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  bool _validateAllForms() {
    for (int i = 0; i < _formKeys.length; i++) {
      if (!_formKeys[i].currentState!.validate()) {
        setState(() => _currentStep = i + (_currentStep == 0 ? 0 : 0)); // Adjust step logic
        return false;
      }
    }
    return true;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pendaftaran Berhasil 🎉'),
        content: Text(message),
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

  Future<void> _selectDate(Function(DateTime) onDateSelected, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
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

  // ✅ STEP CONTENT
  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildInfoStep();
      case 1:
        return _buildDataUmumStep();
      case 2:
        return _buildIdentitasStep();
      case 3:
        return _buildDataKtpStep();
      case 4:
        return _buildDataDomisiliStep();
      case 5:
        return _buildDataAhliWarisStep();
      default:
        return Container();
    }
  }

  // ✅ STEP 0: INFORMASI KOPERASI - FIXED
  Widget _buildInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Profil Koperasi KSMI',
            'Koperasi Serba Usaha KSMI adalah koperasi yang berfokus pada pemberdayaan anggota melalui berbagai layanan keuangan dan non-keuangan yang berkualitas.',
            Icons.business,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Visi',
            'Menjadi koperasi terdepan dalam meningkatkan kesejahteraan anggota melalui layanan yang profesional dan inovatif.',
            Icons.visibility,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Misi',
            '• Memberikan layanan keuangan yang terjangkau\n• Meningkatkan kapasitas usaha anggota\n• Mengembangkan jaringan kemitraan yang strategis\n• Menerapkan prinsip tata kelola yang baik',
            Icons.flag,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Manfaat Bergabung',
            '• Akses pinjaman dengan bunga kompetitif\n• Bagi hasil dari usaha koperasi\n• Pelatihan dan pengembangan usaha\n• Jaringan bisnis yang luas\n• Layanan konsultasi keuangan',
            Icons.emoji_events,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Manfaat Anggota',
            '• Hak suara dalam Rapat Anggota\n• Hak mendapatkan pembagian SHU\n• Akses terhadap semua produk koperasi\n• Perlindungan asuransi\n• Program kesejahteraan anggota',
            Icons.people,
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text(
                      'Saya telah membaca dan menyetujui semua ketentuan yang berlaku',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (!_agreedToTerms)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: Text(
                        'Anda harus menyetujui ketentuan untuk melanjutkan',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green[800]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ STEP 1: DATA UMUM - FIXED OVERFLOW
  Widget _buildDataUmumStep() {
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextField(
              controller: usernameController,
              label: 'Username *',
              icon: Icons.person_outline,
              validator: (v) => _validateRequired(v, 'Username'),
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
            const SizedBox(height: 16),
            _buildTextField(
              controller: fullnameController,
              label: 'Nama Lengkap *',
              icon: Icons.badge_outlined,
              validator: (v) => _validateRequired(v, 'Nama lengkap'),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Desktop/Tablet layout
                  return Row(
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
                          value: _selectedBirthDate,
                          onTap: () => _selectDate((date) {
                            setState(() => _selectedBirthDate = date);
                          }, DateTime.now().subtract(const Duration(days: 365 * 18))),
                          validator: (v) => _selectedBirthDate == null ? 'Tanggal lahir wajib diisi' : null,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile layout
                  return Column(
                    children: [
                      _buildTextField(
                        controller: birthPlaceController,
                        label: 'Tempat Lahir *',
                        icon: Icons.place_outlined,
                        validator: (v) => _validateRequired(v, 'Tempat lahir'),
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        label: 'Tanggal Lahir *',
                        value: _selectedBirthDate,
                        onTap: () => _selectDate((date) {
                          setState(() => _selectedBirthDate = date);
                        }, DateTime.now().subtract(const Duration(days: 365 * 18))),
                        validator: (v) => _selectedBirthDate == null ? 'Tanggal lahir wajib diisi' : null,
                      ),
                    ],
                  );
                }
              },
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
              label: 'No. Fax',
              icon: Icons.fax_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16), // Extra space for scrolling
          ],
        ),
      ),
    );
  }

  // ✅ STEP 2: IDENTITAS - FIXED DROPDOWN
  Widget _buildIdentitasStep() {
    return Form(
      key: _formKeys[1],
      child: SingleChildScrollView(
        child: Column(
          children: [
_buildDropdown(
  label: 'Agama *',
  value: agamaIdController.text.isEmpty ? null : agamaIdController.text,
  items: _agamaList.isNotEmpty 
      ? _agamaList.map((agama) {
          final id = agama['id']?.toString() ?? '';
          final nama = agama['nama']?.toString() ?? 'Unknown';
          return DropdownMenuItem(
            value: id,
            child: Text(nama),
          );
        }).toList()
      : [
          DropdownMenuItem(
            value: 'empty',
            child: Text(
              _isLoading ? 'Loading agama...' : 'Data agama tidak tersedia',
              style: const TextStyle(color: Colors.grey),
            ),
          )
        ],
  onChanged: _agamaList.isNotEmpty ? (value) {
    if (value != null) {
      setState(() {
        agamaIdController.text = value;
      });
      print('✅ Agama dipilih: $value');
    }
  } : null,
  validator: (v) {
    if (agamaIdController.text.isEmpty) {
      return 'Pilih agama terlebih dahulu';
    }
    return null;
  },
),
            const SizedBox(height: 16),
_buildDropdown(
  label: 'Cabang *',
  value: cabangIdController.text.isEmpty ? null : cabangIdController.text,
  items: _cabangList.isNotEmpty
      ? _cabangList.map((cabang) {
          final id = cabang['id']?.toString() ?? '';
          final nama = cabang['nama']?.toString() ?? 'Unknown';
          return DropdownMenuItem(
            value: id,
            child: Text(nama),
          );
        }).toList()
      : [
          DropdownMenuItem(
            value: 'empty',
            child: Text(
              _isLoading ? 'Loading cabang...' : 'Data cabang tidak tersedia',
              style: const TextStyle(color: Colors.grey),
            ),
          )
        ],
  onChanged: _cabangList.isNotEmpty ? (value) {
    if (value != null) {
      setState(() {
        cabangIdController.text = value;
      });
      print('✅ Cabang dipilih: $value');
    }
  } : null,
  validator: (v) {
    if (cabangIdController.text.isEmpty) {
      return 'Pilih cabang terlebih dahulu';
    }
    return null;
  },
),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Jenis Identitas *',
              value: jenisIdentitasController.text,
              items: const [
                DropdownMenuItem(value: 'KTP', child: Text('KTP')),
                DropdownMenuItem(value: 'SIM', child: Text('SIM')),
                DropdownMenuItem(value: 'Passport', child: Text('Passport')),
              ],
              onChanged: (value) {
                setState(() => jenisIdentitasController.text = value!);
              },
              validator: (v) => _validateRequired(jenisIdentitasController.text, 'Jenis identitas'),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: nomorIdentitasController,
              label: 'Nomor Identitas *',
              icon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              validator: (v) => _validateRequired(v, 'Nomor identitas'),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Tanggal Berlaku Identitas',
              value: _selectedTanggalBerlaku,
              onTap: () => _selectDate((date) {
                setState(() => _selectedTanggalBerlaku = date);
              }, DateTime.now().add(const Duration(days: 365 * 5))),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Dari mana Anda mengetahui kami? *',
              value: sumberInformasiController.text.isEmpty ? null : sumberInformasiController.text,
              items: _sumberInfoList.map((sumber) {
                return DropdownMenuItem(
                  value: sumber['id'].toString(),
                  child: Text(sumber['nama']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => sumberInformasiController.text = value!);
              },
              validator: (v) => _validateRequired(sumberInformasiController.text, 'Sumber informasi'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ✅ STEP 3: DATA KTP - FIXED DROPDOWN
  Widget _buildDataKtpStep() {
    return Form(
      key: _formKeys[2],
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextField(
              controller: ktpAlamatController,
              label: 'Alamat Sesuai KTP *',
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (v) => _validateRequired(v, 'Alamat KTP'),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: ktpNoController,
              label: 'No. Rumah *',
              icon: Icons.house_outlined,
              validator: (v) => _validateRequired(v, 'No. Rumah'),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
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
                  );
                } else {
                  return Column(
                    children: [
                      _buildTextField(
                        controller: ktpRtController,
                        label: 'RT *',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => _validateRequired(v, 'RT'),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: ktpRwController,
                        label: 'RW *',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => _validateRequired(v, 'RW'),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Provinsi *',
              value: _selectedProvinsiKtp,
              items: _provinsiList.isNotEmpty
                  ? _provinsiList.map((provinsi) {
                      return DropdownMenuItem(
                        value: provinsi['id'].toString(),
                        child: Text(provinsi['nama']?.toString() ?? 'Unknown'),
                      );
                    }).toList()
                  : [const DropdownMenuItem(value: 'loading', child: Text('Loading...'))],
              onChanged: _provinsiList.isNotEmpty ? (value) {
                setState(() {
                  _selectedProvinsiKtp = value;
                  _selectedKotaKtp = null;
                  _kotaListKtp = [];
                });
                if (value != null) _loadKota(value, true);
              } : null,
              validator: (v) => _selectedProvinsiKtp == null ? 'Provinsi wajib dipilih' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Kabupaten/Kota *',
              value: _selectedKotaKtp,
              items: _kotaListKtp.isNotEmpty
                  ? _kotaListKtp.map((kota) {
                      return DropdownMenuItem(
                        value: kota['id'].toString(),
                        child: Text(kota['nama']?.toString() ?? 'Unknown'),
                      );
                    }).toList()
                  : [const DropdownMenuItem(value: 'empty', child: Text('Pilih provinsi dulu'))],
              onChanged: _kotaListKtp.isNotEmpty ? (value) {
                setState(() => _selectedKotaKtp = value);
              } : null,
              validator: (v) => _selectedKotaKtp == null ? 'Kabupaten/Kota wajib dipilih' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: ktpPostalController,
              label: 'Kode Pos *',
              icon: Icons.markunread_mailbox_outlined,
              keyboardType: TextInputType.number,
              validator: (v) => _validateRequired(v, 'Kode Pos'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ✅ STEP 4: DATA DOMISILI - FIXED
  Widget _buildDataDomisiliStep() {
    return Form(
      key: _formKeys[3],
      child: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: CheckboxListTile(
                title: const Text('Sama dengan alamat KTP'),
                value: _sameAsKtp,
                onChanged: (value) {
                  setState(() => _sameAsKtp = value!);
                  if (value!) {
                    domisiliAlamatController.text = ktpAlamatController.text;
                    domisiliNoController.text = ktpNoController.text;
                    domisiliRtController.text = ktpRtController.text;
                    domisiliRwController.text = ktpRwController.text;
                    domisiliPostalController.text = ktpPostalController.text;
                    _selectedProvinsiDomisili = _selectedProvinsiKtp;
                    _selectedKotaDomisili = _selectedKotaKtp;
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: domisiliAlamatController,
              label: 'Alamat Saat Ini *',
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: _sameAsKtp ? null : (v) => _validateRequired(v, 'Alamat domisili'),
              enabled: !_sameAsKtp,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: domisiliNoController,
              label: 'No. Rumah *',
              icon: Icons.house_outlined,
              validator: _sameAsKtp ? null : (v) => _validateRequired(v, 'No. Rumah'),
              enabled: !_sameAsKtp,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: domisiliRtController,
                          label: 'RT *',
                          icon: Icons.numbers_outlined,
                          keyboardType: TextInputType.number,
                          validator: _sameAsKtp ? null : (v) => _validateRequired(v, 'RT'),
                          enabled: !_sameAsKtp,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: domisiliRwController,
                          label: 'RW *',
                          icon: Icons.numbers_outlined,
                          keyboardType: TextInputType.number,
                          validator: _sameAsKtp ? null : (v) => _validateRequired(v, 'RW'),
                          enabled: !_sameAsKtp,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTextField(
                        controller: domisiliRtController,
                        label: 'RT *',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        validator: _sameAsKtp ? null : (v) => _validateRequired(v, 'RT'),
                        enabled: !_sameAsKtp,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: domisiliRwController,
                        label: 'RW *',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        validator: _sameAsKtp ? null : (v) => _validateRequired(v, 'RW'),
                        enabled: !_sameAsKtp,
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Provinsi *',
              value: _selectedProvinsiDomisili,
              items: _provinsiList.isNotEmpty
                  ? _provinsiList.map((provinsi) {
                      return DropdownMenuItem(
                        value: provinsi['id'].toString(),
                        child: Text(provinsi['nama']?.toString() ?? 'Unknown'),
                      );
                    }).toList()
                  : [const DropdownMenuItem(value: 'loading', child: Text('Loading...'))],
              onChanged: _sameAsKtp || _provinsiList.isEmpty ? null : (value) {
                setState(() {
                  _selectedProvinsiDomisili = value;
                  _selectedKotaDomisili = null;
                  _kotaListDomisili = [];
                });
                if (value != null) _loadKota(value, false);
              },
              validator: _sameAsKtp ? null : (v) => _selectedProvinsiDomisili == null ? 'Provinsi wajib dipilih' : null,
            ),
            const SizedBox(height: 16),
            // ✅ PERBAIKAN: Di bagian _buildDataKtpStep()
            _buildDropdown(
              label: 'Kabupaten/Kota *',
              value: _selectedKotaKtp,
              items: _kotaListKtp.isNotEmpty
                  ? _kotaListKtp.map((kota) {
                      return DropdownMenuItem(
                        value: kota['id'].toString(),
                        child: Text(kota['nama']?.toString() ?? 'Unknown'),
                      );
                    }).toList()
                  : [
                      DropdownMenuItem( // ✅ HAPUS CONST DI SINI
                        value: 'empty',
                        child: Text('Pilih provinsi dulu'), // ✅ HAPUS TERNARY OPERATOR
                      )
                    ],
              onChanged: _kotaListKtp.isNotEmpty ? (value) {
                setState(() => _selectedKotaKtp = value);
              } : null,
              validator: (v) => _selectedKotaKtp == null ? 'Kabupaten/Kota wajib dipilih' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: domisiliPostalController,
              label: 'Kode Pos *',
              icon: Icons.markunread_mailbox_outlined,
              keyboardType: TextInputType.number,
              validator: _sameAsKtp ? null : (v) => _validateRequired(v, 'Kode Pos'),
              enabled: !_sameAsKtp,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ✅ STEP 5: DATA AHLI WARIS - FIXED
  Widget _buildDataAhliWarisStep() {
    return Form(
      key: _formKeys[4],
      child: SingleChildScrollView(
        child: Column(
          children: [
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
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Hubungan Keluarga *',
              value: hubunganController.text,
              items: const [
                DropdownMenuItem(value: 'Orang Tua', child: Text('Orang Tua')),
                DropdownMenuItem(value: 'Suami/Istri', child: Text('Suami/Istri')),
                DropdownMenuItem(value: 'Anak', child: Text('Anak')),
                DropdownMenuItem(value: 'Saudara Kandung', child: Text('Saudara Kandung')),
              ],
              onChanged: (value) {
                setState(() => hubunganController.text = value!);
              },
              validator: (v) => _validateRequired(hubunganController.text, 'Hubungan keluarga'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET BUILDERS
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
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
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'Pilih tanggal',
        filled: true,
        fillColor: Colors.white,
      ),
      controller: TextEditingController(
        text: value != null ? '${value.day}/${value.month}/${value.year}' : '',
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?)? onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      isExpanded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Pendaftaran Anggota KSMI'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _provinsiList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // ✅ STEPPER
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < 6; i++) ...[
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: i <= _currentStep ? Colors.green[800] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (i < 5) const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ),

                  // ✅ STEP LABELS
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Info', style: TextStyle(fontSize: 12)),
                        Text('Data Umum', style: TextStyle(fontSize: 12)),
                        Text('Identitas', style: TextStyle(fontSize: 12)),
                        Text('KTP', style: TextStyle(fontSize: 12)),
                        Text('Domisili', style: TextStyle(fontSize: 12)),
                        Text('Ahli Waris', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),

                  // ✅ STEP CONTENT
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildStepContent(_currentStep),
                    ),
                  ),

                  // ✅ NAVIGATION BUTTONS - FIXED LOGIC
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _currentStep--);
                              },
                              child: const Text('KEMBALI'),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 16),
                        Expanded(
                          child: _currentStep == 5
                              ? ElevatedButton(
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
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    if (_currentStep == 0) {
                                      if (_agreedToTerms) {
                                        setState(() => _currentStep++);
                                      }
                                    } else {
                                      if (_formKeys[_currentStep - 1].currentState!.validate()) {
                                        setState(() => _currentStep++);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _currentStep == 0 ? 'SETUJU & LANJUT' : 'LANJUT',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}