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
  final TextEditingController _noTeleponController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _kotaController = TextEditingController();
  final TextEditingController _kodePosController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedProvinsi;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // ✅ Daftar provinsi (sama dengan register)
  final List<String> _provinsiList = [
    'DKI Jakarta',
    'Jawa Barat',
    'Jawa Tengah',
    'Jawa Timur',
    'Banten',
    'DI Yogyakarta',
    'Bali',
    'Sumatera Utara',
    'Sumatera Barat',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _fullNameController.text = widget.user['fullName'] ?? '';
      _emailController.text = widget.user['email'] ?? '';
      _noTeleponController.text = widget.user['noTelepon'] ?? '';
      _alamatController.text = widget.user['alamat'] ?? '';
      _kotaController.text = widget.user['kota'] ?? '';
      _kodePosController.text = widget.user['kodePos']?.toString() ?? '';
      _selectedProvinsi = widget.user['provinsi'];
    });
  }

  // ✅ FIX: Method update profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validasi password jika diisi
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password minimal 6 karakter'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
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

    final updatedData = {
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'noTelepon': _noTeleponController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'kota': _kotaController.text.trim(),
      'provinsi': _selectedProvinsi ?? '',
      'kodePos': _kodePosController.text.trim(),
    };

    // ✅ Tambah password jika diisi
    if (_passwordController.text.isNotEmpty) {
      updatedData['password'] = _passwordController.text.trim();
    }

    try {
      // ✅ FIX: Panggil method dengan 1 parameter saja
      final success = await _apiService.updateUserProfile(updatedData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (success) {
        // ✅ Panggil callback untuk update data di parent
        widget.onProfileUpdated(updatedData);
        
        // ✅ Clear password fields setelah sukses
        _passwordController.clear();
        _confirmPasswordController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _passwordController.text.isNotEmpty 
                ? 'Profile dan password berhasil diupdate ✅'
                : 'Profile berhasil diupdate ✅'
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context); // Kembali ke profile screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengupdate profile'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                        'Username tidak dapat diubah. Kosongkan password jika tidak ingin mengubah.',
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ✅ EMAIL
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                controller: _noTeleponController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'No. Telepon *',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              const SizedBox(height: 24),

              // ✅ SECTION: UBAH PASSWORD (OPTIONAL)
              Text(
                'Ubah Password (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kosongkan jika tidak ingin mengubah password',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // ✅ PASSWORD BARU
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ SECTION: ALAMAT
              Text(
                'Alamat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 12),

              // ✅ ALAMAT
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Alamat Lengkap',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Jl. Nama Jalan No. XX',
                ),
              ),
              const SizedBox(height: 16),

              // ✅ KOTA
              TextFormField(
                controller: _kotaController,
                decoration: InputDecoration(
                  labelText: 'Kota',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ PROVINSI
              DropdownButtonFormField<String>(
                value: _selectedProvinsi,
                decoration: InputDecoration(
                  labelText: 'Provinsi',
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _provinsiList.map((String provinsi) {
                  return DropdownMenuItem<String>(
                    value: provinsi,
                    child: Text(provinsi),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedProvinsi = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih provinsi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ✅ KODE POS
              TextFormField(
                controller: _kodePosController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kode Pos',
                  prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: '5 digit',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && !RegExp(r'^[0-9]{5}$').hasMatch(value)) {
                    return 'Kode pos harus 5 digit';
                  }
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.white,
                                fontWeight: FontWeight.w600
                              ),
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