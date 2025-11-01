import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';

// ✅ CUSTOM SHAPE UNTUK APPBAR DENGAN TENGAH PENDEK & SAMPING IKUT MELENGKUNG KE DALEM
class NotchedAppBarShape extends ContinuousRectangleBorder {
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double centerWidth = 180.0;
    final double centerDepth = 25.0;
    final double sideCurveDepth = 25.0;
    
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..quadraticBezierTo(
        rect.right - 40, 
        rect.bottom - sideCurveDepth,
        rect.right - 80, 
        rect.bottom - centerDepth,
      )
      ..lineTo(rect.left + 80, rect.bottom - centerDepth)
      ..quadraticBezierTo(
        rect.left + 40, 
        rect.bottom - sideCurveDepth,
        rect.left, 
        rect.bottom,
      )
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = Map<String, dynamic>.from(widget.user);
    _loadCurrentUser();
  }

  // ✅ LOAD CURRENT USER DARI SESSION
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('❌ Error loading current user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ FITUR UPLOAD FOTO PROFILE - COMPATIBLE DENGAN API SERVICE BARU
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

        // ✅ GUNAKAN METHOD uploadFoto DENGAN TYPE 'foto_diri' - COMPATIBLE
        final success = await _apiService.uploadFoto(
          type: 'foto_diri',
          filePath: pickedFile.path,
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (success) {
          // ✅ Refresh user data untuk mendapatkan update terbaru
          await _loadCurrentUser();
          
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

  // ✅ FITUR AMBIL FOTO DARI KAMERA - COMPATIBLE
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

        // ✅ GUNAKAN METHOD uploadFoto DENGAN TYPE 'foto_diri' - COMPATIBLE
        final success = await _apiService.uploadFoto(
          type: 'foto_diri',
          filePath: pickedFile.path,
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (success) {
          // ✅ Refresh user data untuk mendapatkan update terbaru
          await _loadCurrentUser();
          
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

  // ✅ UPLOAD FOTO KTP
  Future<void> _uploadKTP() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _showUploadingDialog('Mengupload Foto KTP...');

        final success = await _apiService.uploadFoto(
          type: 'foto_ktp',
          filePath: pickedFile.path,
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (success) {
          await _loadCurrentUser();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto KTP berhasil diupload ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload foto KTP'),
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
          content: Text('Error saat upload KTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ UPLOAD FOTO KK
  Future<void> _uploadKK() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _showUploadingDialog('Mengupload Foto KK...');

        final success = await _apiService.uploadFoto(
          type: 'foto_kk',
          filePath: pickedFile.path,
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (success) {
          await _loadCurrentUser();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto KK berhasil diupload ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload foto KK'),
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
          content: Text('Error saat upload KK: $e'),
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

  void _showDocumentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Dokumen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blue[700]),
              title: const Text('Upload KTP'),
              onTap: () {
                Navigator.pop(context);
                _uploadKTP();
              },
            ),
            ListTile(
              leading: Icon(Icons.family_restroom, color: Colors.green[700]),
              title: const Text('Upload Kartu Keluarga'),
              onTap: () {
                Navigator.pop(context);
                _uploadKK();
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

  // ✅ LOGOUT FUNCTION - COMPATIBLE
  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiService.logout();
      
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false
      );
    }
  }

  // ✅ REFRESH PROFILE DATA - COMPATIBLE
  Future<void> _refreshProfile() async {
    await _loadCurrentUser();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile berhasil diperbarui'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil Saya'),
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Profil Saya',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.green.withOpacity(0.5),
          shape: NotchedAppBarShape(),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshProfile,
              tooltip: 'Refresh Profile',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ✅ PROFILE HEADER
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green[50],
                          backgroundImage: _currentUser['foto_diri'] != null && _currentUser['foto_diri'] != 'uploaded'
                              ? NetworkImage(_currentUser['foto_diri']) // Jika ada URL dari server
                              : null,
                          child: _currentUser['foto_diri'] == null || _currentUser['foto_diri'] == 'uploaded'
                              ? Icon(Icons.person, size: 60, color: Colors.green[700])
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
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
                    _currentUser['fullname'] ?? _currentUser['fullName'] ?? 'Anggota Koperasi',
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

            // ✅ DOKUMEN SECTION
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
                        Icon(Icons.folder_open, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Dokumen',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildDocumentStatus('KTP', _currentUser['foto_ktp']),
                    _buildDocumentStatus('Kartu Keluarga', _currentUser['foto_kk']),
                    _buildDocumentStatus('Foto Diri', _currentUser['foto_diri']),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showDocumentOptions,
                        icon: Icon(Icons.upload, color: Colors.green[700]),
                        label: Text(
                          'Upload Dokumen',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ INFORMASI PRIBADI
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
                        Icon(Icons.person_outline, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Informasi Pribadi',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildInfoTile(Icons.person, 'Username', _currentUser['username'] ?? '-'),
                    _buildInfoTile(Icons.phone, 'Nomor Telepon', _currentUser['phone'] ?? _currentUser['noTelepon'] ?? '-'),
                    _buildInfoTile(Icons.work, 'Pekerjaan', _currentUser['job'] ?? _currentUser['pekerjaan'] ?? '-'),
                    _buildInfoTile(Icons.place, 'Tempat Lahir', _currentUser['birth_place'] ?? _currentUser['tempatLahir'] ?? '-'),
                    _buildInfoTile(Icons.cake, 'Tanggal Lahir', 
                      _formatTanggalLahir(_currentUser['birth_date'] ?? _currentUser['tanggalLahir']) ?? '-'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ ALAMAT KTP
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
                        Icon(Icons.credit_card, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Alamat KTP',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildInfoTile(Icons.home, 'Alamat KTP', _currentUser['ktp_alamat'] ?? _currentUser['alamatKtp'] ?? '-', maxLines: 3),
                    Row(
                      children: [
                        Expanded(child: _buildInfoTile(Icons.numbers, 'RT', _currentUser['ktp_rt'] ?? _currentUser['rtKtp'] ?? '-')),
                        Expanded(child: _buildInfoTile(Icons.numbers, 'RW', _currentUser['ktp_rw'] ?? _currentUser['rwKtp'] ?? '-')),
                      ],
                    ),
                    _buildInfoTile(Icons.house, 'No. Rumah', _currentUser['ktp_no'] ?? _currentUser['noRumahKtp'] ?? '-'),
                    _buildInfoTile(Icons.location_city, 'Kota/Kabupaten', _getKotaName(_currentUser['ktp_id_regency']) ?? '-'),
                    _buildInfoTile(Icons.markunread_mailbox, 'Kode Pos', _currentUser['ktp_postal'] ?? _currentUser['kodePosKtp'] ?? '-'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ ALAMAT DOMISILI
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
                        Icon(Icons.home_work, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Alamat Domisili',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildInfoTile(Icons.home, 'Alamat Domisili', 
                      _currentUser['domisili_alamat'] ?? _currentUser['alamatDomisili'] ?? '-', maxLines: 3),
                    Row(
                      children: [
                        Expanded(child: _buildInfoTile(Icons.numbers, 'RT', _currentUser['domisili_rt'] ?? _currentUser['rtDomisili'] ?? '-')),
                        Expanded(child: _buildInfoTile(Icons.numbers, 'RW', _currentUser['domisili_rw'] ?? _currentUser['rwDomisili'] ?? '-')),
                      ],
                    ),
                    _buildInfoTile(Icons.house, 'No. Rumah', _currentUser['domisili_no'] ?? _currentUser['noRumahDomisili'] ?? '-'),
                    _buildInfoTile(Icons.location_city, 'Kota/Kabupaten', _getKotaName(_currentUser['domisili_id_regency']) ?? '-'),
                    _buildInfoTile(Icons.markunread_mailbox, 'Kode Pos', _currentUser['domisili_postal'] ?? _currentUser['kodePosDomisili'] ?? '-'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ INFORMASI KOPERASI
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
                        Icon(Icons.account_balance, color: Colors.orange[700]),
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
                    _buildInfoTile(Icons.calendar_today, 'Bergabung Sejak', _getTahunGabung()),
                    _buildInfoTile(Icons.verified, 'Status Keanggotaan', 'Aktif'),
                    _buildInfoTile(Icons.fingerprint, 'ID Member', _currentUser['id']?.toString() ?? '-'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ✅ ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.green[700]!),
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
                    icon: Icon(Icons.edit, color: Colors.green[700]),
                    label: Text(
                      'Edit Profil',
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.green[700],
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _logout,
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
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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

  Widget _buildDocumentStatus(String docName, dynamic status) {
    final isUploaded = status != null && status.toString().isNotEmpty && status != 'uploaded';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.pending,
            color: isUploaded ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              docName,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUploaded ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isUploaded ? Colors.green[200]! : Colors.orange[200]!,
              ),
            ),
            child: Text(
              isUploaded ? 'Terverifikasi' : 'Belum Upload',
              style: TextStyle(
                fontSize: 10,
                color: isUploaded ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
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

  String? _getKotaName(dynamic kotaId) {
    if (kotaId == null) return null;
    // TODO: Implement mapping dari ID kota ke nama kota
    // Untuk sementara return ID-nya
    return kotaId.toString();
  }

  String _getTahunGabung() {
    final now = DateTime.now();
    return now.year.toString();
  }
}