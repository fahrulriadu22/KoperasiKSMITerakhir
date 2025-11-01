import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _ktpAlamatController = TextEditingController();
  final TextEditingController _ktpRtController = TextEditingController();
  final TextEditingController _ktpRwController = TextEditingController();
  final TextEditingController _ktpNoController = TextEditingController();
  final TextEditingController _ktpPostalController = TextEditingController();
  final TextEditingController _domisiliAlamatController = TextEditingController();
  final TextEditingController _domisiliRtController = TextEditingController();
  final TextEditingController _domisiliRwController = TextEditingController();
  final TextEditingController _domisiliNoController = TextEditingController();
  final TextEditingController _domisiliPostalController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // ✅ DATA MASTER
  List<dynamic> _provinsiList = [];
  List<dynamic> _kotaListKtp = [];
  List<dynamic> _kotaListDomisili = [];
  List<dynamic> _agamaList = [];
  
  String? _selectedProvinsiKtp;
  String? _selectedKotaKtp;
  String? _selectedProvinsiDomisili;
  String? _selectedKotaDomisili;
  String? _selectedAgama;
  
  bool _isLoading = false;
  bool _isLoadingMasterData = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _sameAsKtp = false;

  // ✅ DEBUG STATE
  bool _provinsiLoaded = false;
  bool _kotaKtpLoaded = false;
  bool _kotaDomisiliLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMasterData();
  }

  void _loadUserData() {
    setState(() {
      // ✅ Load data dari user sesuai dengan field API
      _fullNameController.text = widget.user['fullname'] ?? widget.user['fullName'] ?? '';
      _emailController.text = widget.user['email'] ?? '';
      _phoneController.text = widget.user['phone'] ?? widget.user['noTelepon'] ?? '';
      _jobController.text = widget.user['job'] ?? widget.user['pekerjaan'] ?? '';
      _birthPlaceController.text = widget.user['birth_place'] ?? widget.user['tempatLahir'] ?? '';
      _selectedAgama = widget.user['agama_id']?.toString() ?? widget.user['agama']?.toString();
      
      // ✅ Data KTP
      _ktpAlamatController.text = widget.user['ktp_alamat'] ?? widget.user['alamatKtp'] ?? '';
      _ktpRtController.text = widget.user['ktp_rt'] ?? widget.user['rtKtp'] ?? '';
      _ktpRwController.text = widget.user['ktp_rw'] ?? widget.user['rwKtp'] ?? '';
      _ktpNoController.text = widget.user['ktp_no'] ?? widget.user['noRumahKtp'] ?? '';
      _ktpPostalController.text = widget.user['ktp_postal'] ?? widget.user['kodePosKtp'] ?? '';
      _selectedProvinsiKtp = widget.user['ktp_id_province']?.toString();
      _selectedKotaKtp = widget.user['ktp_id_regency']?.toString();
      
      // ✅ Data Domisili
      _domisiliAlamatController.text = widget.user['domisili_alamat'] ?? widget.user['alamatDomisili'] ?? '';
      _domisiliRtController.text = widget.user['domisili_rt'] ?? widget.user['rtDomisili'] ?? '';
      _domisiliRwController.text = widget.user['domisili_rw'] ?? widget.user['rwDomisili'] ?? '';
      _domisiliNoController.text = widget.user['domisili_no'] ?? widget.user['noRumahDomisili'] ?? '';
      _domisiliPostalController.text = widget.user['domisili_postal'] ?? widget.user['kodePosDomisili'] ?? '';
      _selectedProvinsiDomisili = widget.user['domisili_id_province']?.toString();
      _selectedKotaDomisili = widget.user['domisili_id_regency']?.toString();
      
      // ✅ Check jika alamat domisili sama dengan KTP
      _sameAsKtp = _domisiliAlamatController.text.isEmpty || 
                   _domisiliAlamatController.text == _ktpAlamatController.text;
    });
  }

  // ✅ PERBAIKAN: LOAD DATA MASTER DENGAN DEBUGGING
  Future<void> _loadMasterData() async {
    try {
      setState(() => _isLoadingMasterData = true);
      print('🔄 Loading master data...');

      // Load provinsi
      final provinsiResult = await _apiService.getProvince();
      print('📊 Provinsi API Result: ${provinsiResult['success']}');
      print('📊 Provinsi Data: ${provinsiResult['data']}');
      
      if (provinsiResult['success'] == true && mounted) {
        final data = provinsiResult['data'];
        print('📊 Provinsi raw data type: ${data.runtimeType}');
        
        if (data is List) {
          setState(() {
            _provinsiList = data;
            _provinsiLoaded = true;
          });
          print('✅ Provinsi loaded: ${_provinsiList.length} items');
        } else {
          print('❌ Provinsi data is not a List: $data');
          setState(() {
            _provinsiList = [];
            _provinsiLoaded = true;
          });
        }
        
        // Setelah provinsi terload, load kota untuk KTP jika ada
        if (_selectedProvinsiKtp != null && _selectedProvinsiKtp!.isNotEmpty) {
          print('🔄 Loading kota KTP for provinsi: $_selectedProvinsiKtp');
          await _loadKota(_selectedProvinsiKtp!, true);
        }
        
        // Load kota untuk domisili jika ada
        if (_selectedProvinsiDomisili != null && _selectedProvinsiDomisili!.isNotEmpty) {
          print('🔄 Loading kota Domisili for provinsi: $_selectedProvinsiDomisili');
          await _loadKota(_selectedProvinsiDomisili!, false);
        }
      } else {
        print('❌ Failed to load provinsi: ${provinsiResult['message']}');
        setState(() {
          _provinsiLoaded = true;
        });
      }

      // Load master data untuk agama
      final masterResult = await _apiService.getMasterData();
      if (masterResult['success'] == true && mounted) {
        final data = masterResult['data'];
        if (data is Map && data.containsKey('agama')) {
          setState(() {
            _agamaList = data['agama'] ?? [];
          });
          print('✅ Agama loaded: ${_agamaList.length} items');
        }
      }
    } catch (e) {
      print('❌ Error loading master data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data provinsi dan agama: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMasterData = false);
      }
      print('✅ Master data loading completed');
    }
  }

  // ✅ PERBAIKAN: LOAD KOTA DENGAN DEBUGGING
  Future<void> _loadKota(String idProvinsi, bool forKtp) async {
    try {
      print('🔄 Loading kota for provinsi: $idProvinsi, forKtp: $forKtp');
      
      final result = await _apiService.getRegency(idProvinsi);
      print('📊 Kota API Result: ${result['success']}');
      print('📊 Kota Data: ${result['data']}');
      
      if (result['success'] == true && mounted) {
        final data = result['data'];
        print('📊 Kota raw data type: ${data.runtimeType}');
        
        if (data is List) {
          setState(() {
            if (forKtp) {
              _kotaListKtp = data;
              _kotaKtpLoaded = true;
              // Reset selected kota jika tidak ada di list baru
              if (_selectedKotaKtp != null && 
                  !_kotaListKtp.any((kota) => kota['id'].toString() == _selectedKotaKtp)) {
                _selectedKotaKtp = null;
              }
            } else {
              _kotaListDomisili = data;
              _kotaDomisiliLoaded = true;
              // Reset selected kota jika tidak ada di list baru
              if (_selectedKotaDomisili != null && 
                  !_kotaListDomisili.any((kota) => kota['id'].toString() == _selectedKotaDomisili)) {
                _selectedKotaDomisili = null;
              }
            }
          });
          print('✅ Kota loaded: ${forKtp ? _kotaListKtp.length : _kotaListDomisili.length} items');
        } else {
          print('❌ Kota data is not a List: $data');
          setState(() {
            if (forKtp) {
              _kotaListKtp = [];
              _kotaKtpLoaded = true;
            } else {
              _kotaListDomisili = [];
              _kotaDomisiliLoaded = true;
            }
          });
        }
      } else {
        print('❌ Failed to load kota: ${result['message']}');
        setState(() {
          if (forKtp) {
            _kotaKtpLoaded = true;
          } else {
            _kotaDomisiliLoaded = true;
          }
        });
      }
    } catch (e) {
      print('❌ Error loading kota: $e');
      setState(() {
        if (forKtp) {
          _kotaKtpLoaded = true;
        } else {
          _kotaDomisiliLoaded = true;
        }
      });
    }
  }

  // ✅ METHOD UPDATE PROFILE
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validasi password jika diisi
    if (_newPasswordController.text.isNotEmpty) {
      if (_oldPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap masukkan password lama'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_newPasswordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password baru minimal 6 karakter'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfirmasi password tidak cocok'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Prepare update data sesuai dengan API
      final updatedData = {
        'username': widget.user['username'] ?? '',
        'fullname': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'job': _jobController.text.trim(),
        'birth_place': _birthPlaceController.text.trim(),
        'agama_id': _selectedAgama ?? '1',
        
        // Data KTP
        'ktp_alamat': _ktpAlamatController.text.trim(),
        'ktp_rt': _ktpRtController.text.trim(),
        'ktp_rw': _ktpRwController.text.trim(),
        'ktp_no': _ktpNoController.text.trim(),
        'ktp_postal': _ktpPostalController.text.trim(),
        'ktp_id_province': _selectedProvinsiKtp ?? '',
        'ktp_id_regency': _selectedKotaKtp ?? '',
        
        // Data Domisili
        'domisili_alamat': _sameAsKtp ? _ktpAlamatController.text.trim() : _domisiliAlamatController.text.trim(),
        'domisili_rt': _sameAsKtp ? _ktpRtController.text.trim() : _domisiliRtController.text.trim(),
        'domisili_rw': _sameAsKtp ? _ktpRwController.text.trim() : _domisiliRwController.text.trim(),
        'domisili_no': _sameAsKtp ? _ktpNoController.text.trim() : _domisiliNoController.text.trim(),
        'domisili_postal': _sameAsKtp ? _ktpPostalController.text.trim() : _domisiliPostalController.text.trim(),
        'domisili_id_province': _sameAsKtp ? (_selectedProvinsiKtp ?? '') : (_selectedProvinsiDomisili ?? ''),
        'domisili_id_regency': _sameAsKtp ? (_selectedKotaKtp ?? '') : (_selectedKotaDomisili ?? ''),
      };

      // ✅ Hapus field yang kosong untuk menghindari error
      updatedData.removeWhere((key, value) => value.toString().isEmpty);

      // ✅ Update profile menggunakan method dari ApiService
      final profileResult = await _apiService.updateUserProfile(updatedData);
      
      // ✅ Update password jika diisi
      Map<String, dynamic> passwordResult = {'success': true};
      if (_newPasswordController.text.isNotEmpty) {
        passwordResult = await _apiService.changePassword(
          _oldPasswordController.text.trim(),
          _newPasswordController.text.trim(),
          _confirmPasswordController.text.trim(),
        );
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (profileResult['success'] == true) {
        // ✅ Panggil callback untuk update data di parent
        widget.onProfileUpdated(updatedData);
        
        // ✅ Clear password fields setelah sukses
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        String message = 'Profile berhasil diupdate ✅';
        if (_newPasswordController.text.isNotEmpty) {
          message = passwordResult['success'] == true
            ? 'Profile dan password berhasil diupdate ✅'
            : 'Profile berhasil diupdate, tetapi gagal mengubah password';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileResult['message'] ?? 'Gagal mengupdate profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ PERBAIKAN: BUILD DROPDOWN DENGAN DEBUG INFO
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<dynamic> items,
    required Function(String?)? onChanged,
    required String? Function(String?)? validator,
    bool enabled = true,
    bool isLoading = false,
    String debugInfo = '',
  }) {
    final dropdownItems = items.map((item) {
      final id = item['id']?.toString() ?? '';
      final nama = item['nama']?.toString() ?? item['name']?.toString() ?? 'Unknown';
      return DropdownMenuItem<String>(
        value: id,
        child: Text(nama),
      );
    }).toList();

    // Add empty item if no items
    if (dropdownItems.isEmpty && !isLoading) {
      dropdownItems.add(
        DropdownMenuItem(
          value: '',
          child: Text('Tidak ada data $debugInfo'),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: value,
      items: isLoading 
          ? [DropdownMenuItem(value: '', child: Text('Loading...'))]
          : dropdownItems,
      onChanged: enabled && !isLoading ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      validator: validator,
      disabledHint: isLoading ? const Text('Loading...') : Text('$debugInfo (${items.length} items)'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingMasterData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data provinsi dan kota...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // ✅ DEBUG INFO
                    if (!_provinsiLoaded || !_kotaKtpLoaded || !_kotaDomisiliLoaded)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status Data:',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Provinsi: ${_provinsiLoaded ? '✅' : '🔄'}, '
                                    'Kota KTP: ${_kotaKtpLoaded ? '✅' : '🔄'}, '
                                    'Kota Domisili: ${_kotaDomisiliLoaded ? '✅' : '🔄'}',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ✅ INFO
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Username tidak dapat diubah. Isi password hanya jika ingin mengubah.',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ USERNAME (READONLY)
                    TextFormField(
                      initialValue: widget.user['username'] ?? '',
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // ✅ NAMA LENGKAP
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap *',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ EMAIL
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email wajib diisi';
                        if (!value.contains('@')) return 'Email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ✅ NO TELEPON
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'No. Telepon *',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: '08xxxxxxxxxx',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'No. telepon wajib diisi';
                        if (!RegExp(r'^08[0-9]{8,11}$').hasMatch(value)) {
                          return 'Format no. telepon tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ✅ PEKERJAAN
                    TextFormField(
                      controller: _jobController,
                      decoration: InputDecoration(
                        labelText: 'Pekerjaan *',
                        prefixIcon: const Icon(Icons.work_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Pekerjaan wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ TEMPAT LAHIR
                    TextFormField(
                      controller: _birthPlaceController,
                      decoration: InputDecoration(
                        labelText: 'Tempat Lahir *',
                        prefixIcon: const Icon(Icons.place_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Tempat lahir wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ AGAMA
                    _buildDropdown(
                      label: 'Agama *',
                      value: _selectedAgama,
                      items: _agamaList.map((agama) {
                        return DropdownMenuItem<String>(
                          value: agama['id'].toString(),
                          child: Text(agama['nama'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAgama = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Pilih agama' : null,
                    ),
                    const SizedBox(height: 24),

                    // ✅ SECTION: UBAH PASSWORD
                    Text(
                      'Ubah Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kosongkan jika tidak ingin mengubah password',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),

                    // ✅ PASSWORD LAMA
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: !_showOldPassword,
                      decoration: InputDecoration(
                        labelText: 'Password Lama',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_showOldPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _showOldPassword = !_showOldPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ PASSWORD BARU
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_showNewPassword,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_showNewPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Minimal 6 karakter',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ KONFIRMASI PASSWORD
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ✅ SECTION: ALAMAT KTP
                    Text(
                      'Alamat KTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ ALAMAT KTP
                    TextFormField(
                      controller: _ktpAlamatController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Alamat KTP *',
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Alamat KTP wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ RT/RW KTP
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ktpRtController,
                            decoration: InputDecoration(
                              labelText: 'RT *',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'RT wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ktpRwController,
                            decoration: InputDecoration(
                              labelText: 'RW *',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'RW wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ✅ NO RUMAH KTP
                    TextFormField(
                      controller: _ktpNoController,
                      decoration: InputDecoration(
                        labelText: 'No. Rumah *',
                        prefixIcon: const Icon(Icons.house_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'No. rumah wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ PROVINSI KTP
                    _buildDropdown(
                      label: 'Provinsi KTP *',
                      value: _selectedProvinsiKtp,
                      items: _provinsiList,
                      onChanged: (String? newValue) {
                        print('Provinsi KTP changed to: $newValue');
                        setState(() {
                          _selectedProvinsiKtp = newValue;
                          _selectedKotaKtp = null;
                          _kotaListKtp = [];
                          _kotaKtpLoaded = false;
                        });
                        if (newValue != null && newValue.isNotEmpty) {
                          _loadKota(newValue, true);
                        }
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Pilih provinsi KTP' : null,
                      debugInfo: '(${_provinsiList.length} provinsi)',
                    ),
                    const SizedBox(height: 16),

                    // ✅ KOTA KTP
                    _buildDropdown(
                      label: 'Kota/Kabupaten KTP *',
                      value: _selectedKotaKtp,
                      items: _kotaListKtp,
                      onChanged: (String? newValue) {
                        print('Kota KTP changed to: $newValue');
                        setState(() => _selectedKotaKtp = newValue);
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Pilih kota/kabupaten KTP' : null,
                      isLoading: !_kotaKtpLoaded,
                      debugInfo: '(${_kotaListKtp.length} kota)',
                    ),
                    const SizedBox(height: 16),

                    // ✅ KOTA KTP
                    _buildDropdown(
                      label: 'Kota/Kabupaten KTP *',
                      value: _selectedKotaKtp,
                      items: _kotaListKtp.map((kota) {
                        return DropdownMenuItem<String>(
                          value: kota['id'].toString(),
                          child: Text(kota['nama'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedKotaKtp = newValue);
                      },
                      validator: (value) => value == null ? 'Pilih kota/kabupaten KTP' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ KODE POS KTP
                    TextFormField(
                      controller: _ktpPostalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Kode Pos KTP *',
                        prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Kode pos wajib diisi';
                        if (!RegExp(r'^[0-9]{5}$').hasMatch(value)) return 'Kode pos harus 5 digit';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ✅ SECTION: ALAMAT DOMISILI
                    Text(
                      'Alamat Domisili',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ CHECKBOX SAMA DENGAN KTP
                    CheckboxListTile(
                      title: const Text('Sama dengan alamat KTP'),
                      value: _sameAsKtp,
                      onChanged: (value) {
                        setState(() => _sameAsKtp = value!);
                        if (value!) {
                          _domisiliAlamatController.text = _ktpAlamatController.text;
                          _domisiliRtController.text = _ktpRtController.text;
                          _domisiliRwController.text = _ktpRwController.text;
                          _domisiliNoController.text = _ktpNoController.text;
                          _domisiliPostalController.text = _ktpPostalController.text;
                          _selectedProvinsiDomisili = _selectedProvinsiKtp;
                          _selectedKotaDomisili = _selectedKotaKtp;
                          
                          // Load kota untuk domisili jika provinsi berbeda
                          if (_selectedProvinsiDomisili != null) {
                            _loadKota(_selectedProvinsiDomisili!, false);
                          }
                        }
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),

                    // ✅ ALAMAT DOMISILI
                    TextFormField(
                      controller: _domisiliAlamatController,
                      maxLines: 2,
                      enabled: !_sameAsKtp,
                      decoration: InputDecoration(
                        labelText: 'Alamat Domisili *',
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: _sameAsKtp ? null : (value) => value == null || value.isEmpty ? 'Alamat domisili wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ RT/RW DOMISILI
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _domisiliRtController,
                            enabled: !_sameAsKtp,
                            decoration: InputDecoration(
                              labelText: 'RT *',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: _sameAsKtp ? null : (value) => value == null || value.isEmpty ? 'RT wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _domisiliRwController,
                            enabled: !_sameAsKtp,
                            decoration: InputDecoration(
                              labelText: 'RW *',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: _sameAsKtp ? null : (value) => value == null || value.isEmpty ? 'RW wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ✅ NO RUMAH DOMISILI
                    TextFormField(
                      controller: _domisiliNoController,
                      enabled: !_sameAsKtp,
                      decoration: InputDecoration(
                        labelText: 'No. Rumah *',
                        prefixIcon: const Icon(Icons.house_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: _sameAsKtp ? null : (value) => value == null || value.isEmpty ? 'No. rumah wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ PROVINSI DOMISILI
                    _buildDropdown(
                      label: 'Provinsi Domisili *',
                      value: _selectedProvinsiDomisili,
                      items: _provinsiList,
                      onChanged: _sameAsKtp ? null : (String? newValue) {
                        print('Provinsi Domisili changed to: $newValue');
                        setState(() {
                          _selectedProvinsiDomisili = newValue;
                          _selectedKotaDomisili = null;
                          _kotaListDomisili = [];
                          _kotaDomisiliLoaded = false;
                        });
                        if (newValue != null && newValue.isNotEmpty) {
                          _loadKota(newValue, false);
                        }
                      },
                      validator: _sameAsKtp ? null : (value) => value == null || value.isEmpty ? 'Pilih provinsi domisili' : null,
                      enabled: !_sameAsKtp,
                      debugInfo: '(${_provinsiList.length} provinsi)',
                    ),
                    const SizedBox(height: 16),

                    // ✅ KOTA DOMISILI
                    _buildDropdown(
                      label: 'Kota/Kabupaten Domisili *',
                      value: _selectedKotaDomisili,
                      items: _kotaListDomisili.map((kota) {
                        return DropdownMenuItem<String>(
                          value: kota['id'].toString(),
                          child: Text(kota['nama'] ?? ''),
                        );
                      }).toList(),
                      onChanged: _sameAsKtp ? null : (String? newValue) {
                        setState(() => _selectedKotaDomisili = newValue);
                      },
                      validator: _sameAsKtp ? null : (value) => value == null ? 'Pilih kota/kabupaten domisili' : null,
                      enabled: !_sameAsKtp,
                    ),
                    const SizedBox(height: 16),

                    // ✅ KODE POS DOMISILI
                    TextFormField(
                      controller: _domisiliPostalController,
                      enabled: !_sameAsKtp,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Kode Pos Domisili *',
                        prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: _sameAsKtp ? null : (value) {
                        if (value == null || value.isEmpty) return 'Kode pos wajib diisi';
                        if (!RegExp(r'^[0-9]{5}$').hasMatch(value)) return 'Kode pos harus 5 digit';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // ✅ ACTION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Batal',
                              style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isLoading ? null : _updateProfile,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Simpan',
                                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}