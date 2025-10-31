import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';

// ✅ CUSTOM SHAPE UNTUK APPBAR DENGAN TENGAH PENDEK & SAMPING IKUT MELENGKUNG KE DALEM
class NotchedAppBarShape extends ContinuousRectangleBorder {
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double centerWidth = 180.0; // Lebar bagian tengah yang lurus
    final double centerDepth = 25.0; // Kedalaman bagian tengah
    final double sideCurveDepth = 25.0; // Kedalaman lengkungan samping
    
    return Path()
      // Mulai dari kiri atas
      ..moveTo(rect.left, rect.top)
      // Ke kanan atas
      ..lineTo(rect.right, rect.top)
      // Ke kanan bawah (sampai ke dasar appbar)
      ..lineTo(rect.right, rect.bottom)
      // ✅ LENGKUNG DARI KANAN KE TENGAH (IKUT PENDEK KE DALEM)
      ..quadraticBezierTo(
        rect.right - 40, 
        rect.bottom - sideCurveDepth,
        rect.right - 80, 
        rect.bottom - centerDepth,
      )
      // Garis lurus di TENGAH (FLAT)
      ..lineTo(rect.left + 80, rect.bottom - centerDepth)
      // ✅ LENGKUNG DARI TENGAH KE KIRI (IKUT PENDEK KE DALEM)
      ..quadraticBezierTo(
        rect.left + 40, 
        rect.bottom - sideCurveDepth,
        rect.left, 
        rect.bottom,
      )
      // Kembali ke kiri atas
      ..lineTo(rect.left, rect.top)
      ..close();
  }
}

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _currentUser;
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentUser = Map<String, dynamic>.from(widget.user);
  }

  // ✅ FITUR UPLOAD FOTO PROFILE
  Future<void> _uploadPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _showUploadingDialog('Mengupload Foto Profile...');

        final success = await _apiService.updatePhoto(
          _currentUser['username'], 
          pickedFile.path
        );

        if (!mounted) return;
        Navigator.pop(context); // Close dialog

        if (success) {
          setState(() {
            _currentUser['photoPath'] = pickedFile.path;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profile berhasil diupload ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat memilih foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ FITUR AMBIL FOTO DARI KAMERA UNTUK PROFILE
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _showUploadingDialog('Mengupload Foto Profile...');

        final success = await _apiService.updatePhoto(
          _currentUser['username'], 
          pickedFile.path
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (success) {
          setState(() {
            _currentUser['photoPath'] = pickedFile.path;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profile berhasil diambil ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat mengambil foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ubah Foto Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.grey[700]),
              title: const Text('Pilih dari Gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadPhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.grey[700]),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // ✅ BACKGROUND LEBIH PENDEK
        child: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 10.0), // ✅ TEXT DIATASIN
            child: Text(
              'Profil Saya',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.green.withOpacity(0.5),
          shape: NotchedAppBarShape(), // ✅ PAKAI CUSTOM SHAPE YANG BARU
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ PROFILE HEADER - WARNA HIJAU
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green[50], // ✅ HIJAU MUDA
                        backgroundImage: _currentUser['photoPath'] != null
                            ? FileImage(File(_currentUser['photoPath']))
                            : null,
                        child: _currentUser['photoPath'] == null
                            ? Icon(Icons.person, size: 60, color: Colors.green[700]) // ✅ HIJAU
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green[700], // ✅ HIJAU
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentUser['fullName'] ?? 'Anggota Koperasi',
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser['email'] ?? 'email@koperasi.com',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    'Anggota Aktif',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap foto untuk mengubah',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // ✅ INFORMASI AKUN - WARNA HIJAU
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.grey[700]), // ✅ HIJAU
                      const SizedBox(width: 8),
                      const Text(
                        'Informasi Akun',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfoTile(Icons.person, 'Username', _currentUser['username'] ?? '-'),
                  _buildInfoTile(Icons.phone, 'Nomor Telepon', _currentUser['noTelepon'] ?? '-'),
                  _buildInfoTile(Icons.badge, 'Tempat Lahir', _currentUser['tempatLahir'] ?? '-'),
                  _buildInfoTile(Icons.cake, 'Tanggal Lahir', 
                    _formatTanggalLahir(_currentUser['tanggalLahir']) ?? '-'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ✅ ALAMAT LENGKAP - WARNA HIJAU
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_outlined, color: Colors.grey[700]), // ✅ HIJAU
                      const SizedBox(width: 8),
                      const Text(
                        'Alamat Lengkap',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfoTile(Icons.home, 'Alamat', _currentUser['alamat'] ?? '-', maxLines: 3),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(Icons.location_city, 'Kota', _currentUser['kota'] ?? '-'),
                      ),
                      Expanded(
                        child: _buildInfoTile(Icons.map, 'Provinsi', _currentUser['provinsi'] ?? '-'),
                      ),
                    ],
                  ),
                  _buildInfoTile(Icons.markunread_mailbox, 'Kode Pos', _currentUser['kodePos']?.toString() ?? '-'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ✅ INFORMASI KOPERASI - WARNA HIJAU
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.grey[700]), // ✅ HIJAU
                      const SizedBox(width: 8),
                      const Text(
                        'Informasi Koperasi',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfoTile(Icons.credit_card, 'No. Anggota', _currentUser['username'] ?? '-'),
                  _buildInfoTile(Icons.calendar_today, 'Bergabung Sejak', '2024'),
                  _buildInfoTile(Icons.verified, 'Status Keanggotaan', 'Aktif'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ✅ ACTION BUTTONS - WARNA HIJAU
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.green[700]!), // ✅ HIJAU
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          user: _currentUser,
                          onProfileUpdated: (updatedData) {
                            setState(() {
                              _currentUser = {..._currentUser, ...updatedData};
                            });
                          },
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit, color: Colors.green[700]), // ✅ HIJAU
                  label: Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.grey[700], // ✅ HIJAU
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    _showLogoutConfirmation(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                  label: const Text(
                    'Keluar',
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
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green[600], size: 20), // ✅ HIJAU
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600], // ✅ HIJAU
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatTanggalLahir(String? tanggalLahir) {
    if (tanggalLahir == null || tanggalLahir.isEmpty) return null;
    
    try {
      final parts = tanggalLahir.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return tanggalLahir;
    } catch (e) {
      return tanggalLahir;
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false
                );
              },
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}