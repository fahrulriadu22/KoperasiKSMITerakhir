import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';

// ✅ CUSTOM SHAPE UNTUK APPBAR
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
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({
    super.key, 
    required this.user,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _currentUser;
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;
  bool _isUploading = false;
  String? _uploadError;

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

  // ✅ PERBAIKAN: FITUR UPLOAD FOTO YANG LEBIH BAIK
  Future<void> _uploadPhoto(String type, String typeName) async {
    if (_isUploading) return;
    
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _processPhotoUpload(pickedFile, type, typeName);
      }
    } catch (e) {
      _handleUploadError(e, typeName);
    }
  }

  // ✅ PERBAIKAN: FITUR AMBIL FOTO DARI KAMERA
  Future<void> _takePhoto(String type, String typeName) async {
    if (_isUploading) return;
    
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _processPhotoUpload(pickedFile, type, typeName);
      }
    } catch (e) {
      _handleUploadError(e, typeName);
    }
  }

  // ✅ PROCESS PHOTO UPLOAD - REUSABLE METHOD
  Future<void> _processPhotoUpload(XFile pickedFile, String type, String typeName) async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });
    
    _showUploadingDialog('Mengupload $typeName...');

    try {
      final file = File(pickedFile.path);
      
      // ✅ VALIDASI FILE
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan');
      }

      // ✅ CHECK FILE SIZE (max 5MB)
      final fileSize = file.lengthSync();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar. Maksimal 5MB.');
      }

      // ✅ CHECK FILE EXTENSION
      final allowedExtensions = ['.jpg', '.jpeg', '.png'];
      final fileExtension = pickedFile.path.toLowerCase().substring(pickedFile.path.lastIndexOf('.'));
      if (!allowedExtensions.any((ext) => pickedFile.path.toLowerCase().endsWith(ext))) {
        throw Exception('Format file tidak didukung. Gunakan JPG, JPEG, atau PNG.');
      }

      print('📤 Uploading $type: ${file.path}');
      print('📤 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // ✅ GUNAKAN METHOD UPLOAD FOTO
      final result = await _apiService.uploadFoto(
        type: type,
        filePath: pickedFile.path,
      );

      if (!mounted) return;
      
      Navigator.pop(context); // Tutup dialog
      setState(() => _isUploading = false);

      print('📤 Upload result for $type: $result');

      if (result['success'] == true) {
        // ✅ Refresh user data untuk mendapatkan update terbaru
        await _loadCurrentUser();
        
        // ✅ Panggil callback jika ada
        widget.onProfileUpdated?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$typeName berhasil diupload ✅'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final errorMessage = result['message'] ?? 'Gagal upload $typeName';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog
      setState(() => _isUploading = false);
      _handleUploadError(e, typeName);
    }
  }

  // ✅ HANDLE UPLOAD ERROR - REUSABLE METHOD
  void _handleUploadError(dynamic e, String typeName) {
    setState(() {
      _isUploading = false;
      _uploadError = 'Error upload $typeName: $e';
    });
    
    print('❌ Error upload: $e');
    
    // ✅ User-friendly error messages
    String userMessage = 'Terjadi kesalahan saat upload';
    if (e.toString().contains('File tidak ditemukan')) {
      userMessage = 'File tidak ditemukan';
    } else if (e.toString().contains('Ukuran file terlalu besar')) {
      userMessage = 'Ukuran file terlalu besar. Maksimal 5MB.';
    } else if (e.toString().contains('timeout')) {
      userMessage = 'Upload timeout, coba lagi';
    } else if (e.toString().contains('permission')) {
      userMessage = 'Izin akses ditolak';
    } else if (e.toString().contains('Format file tidak didukung')) {
      userMessage = 'Format file tidak didukung. Gunakan JPG, JPEG, atau PNG.';
    }
    
    _showErrorSnackBar('$userMessage ($typeName)');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
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
            const SizedBox(height: 8),
            Text(
              'Harap tunggu...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SHOW PHOTO OPTIONS UNTUK FOTO PROFILE
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
                _uploadPhoto('foto_diri', 'Foto Diri');
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.grey[700]),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto('foto_diri', 'Foto Diri');
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

  // ✅ SHOW DOCUMENT OPTIONS UNTUK KTP & KK
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
            
            // KTP Options
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.credit_card, color: Colors.blue[700]),
                    title: const Text('Upload KTP'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : () {
                              Navigator.pop(context);
                              _uploadPhoto('foto_ktp', 'Foto KTP');
                            },
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text('Galeri'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : () {
                              Navigator.pop(context);
                              _takePhoto('foto_ktp', 'Foto KTP');
                            },
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Kamera'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // KK Options
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.family_restroom, color: Colors.green[700]),
                    title: const Text('Upload Kartu Keluarga'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : () {
                              Navigator.pop(context);
                              _uploadPhoto('foto_kk', 'Foto KK');
                            },
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text('Galeri'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : () {
                              Navigator.pop(context);
                              _takePhoto('foto_kk', 'Foto KK');
                            },
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Kamera'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
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

  // ✅ LOGOUT FUNCTION
  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sedang logout...'),
            ],
          ),
        ),
      );

      try {
        final result = await _apiService.logout();
        
        if (mounted) {
          Navigator.pop(context);
          
          if (result['success'] == true) {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/login', 
              (route) => false
            );
          } else {
            // Fallback ke login meski API gagal
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/login', 
              (route) => false
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login', 
            (route) => false
          );
        }
      }
    }
  }

  // ✅ REFRESH PROFILE DATA
  Future<void> _refreshProfile() async {
    await _loadCurrentUser();
    widget.onProfileUpdated?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
            // ✅ ERROR MESSAGE
            if (_uploadError != null) ...[
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
                        _uploadError!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red[700], size: 16),
                      onPressed: () => setState(() => _uploadError = null),
                    ),
                  ],
                ),
              ),
            ],

            // ✅ PROFILE HEADER
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _showPhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green[50],
                          backgroundImage: _getProfileImage(),
                          child: _getProfilePlaceholder(),
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          )
                        else
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
                    _currentUser['fullname'] ?? _currentUser['fullName'] ?? _currentUser['nama'] ?? 'Anggota Koperasi',
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
                    _isUploading ? 'Sedang mengupload...' : 'Tap foto untuk mengubah',
                    style: TextStyle(
                      color: _isUploading ? Colors.orange[700] : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ✅ DOKUMEN SECTION
            _buildDocumentsSection(),

            const SizedBox(height: 16),

            // ✅ INFORMASI PRIBADI
            _buildPersonalInfoSection(),

            const SizedBox(height: 16),

            // ✅ ALAMAT KTP
            _buildKtpAddressSection(),

            const SizedBox(height: 16),

            // ✅ ALAMAT DOMISILI
            _buildDomisiliAddressSection(),

            const SizedBox(height: 16),

            // ✅ INFORMASI KOPERASI
            _buildCooperativeInfoSection(),

            const SizedBox(height: 30),

            // ✅ ACTION BUTTONS
            _buildActionButtons(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ HELPER METHODS UNTUK BUILD WIDGETS

  ImageProvider? _getProfileImage() {
    final fotoDiri = _currentUser['foto_diri'];
    if (fotoDiri != null && 
        fotoDiri.toString().isNotEmpty && 
        fotoDiri != 'uploaded' &&
        fotoDiri.toString().startsWith('http')) {
      return NetworkImage(fotoDiri);
    }
    return null;
  }

  Widget? _getProfilePlaceholder() {
    final fotoDiri = _currentUser['foto_diri'];
    if (fotoDiri == null || 
        fotoDiri.toString().isEmpty || 
        fotoDiri == 'uploaded' ||
        !fotoDiri.toString().startsWith('http')) {
      return Icon(Icons.person, size: 60, color: Colors.green[700]);
    }
    return null;
  }

  Widget _buildDocumentsSection() {
    return Card(
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
            
            // ✅ TROUBLESHOOTING INFO
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Tips Upload:',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Format file: JPG, JPEG, PNG\n• Ukuran maksimal: 5MB\n• Foto harus jelas dan terbaca\n• Jika gagal, coba foto ulang dengan pencahayaan baik\n• Pastikan koneksi internet stabil',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _showDocumentOptions,
                icon: Icon(Icons.upload, color: _isUploading ? Colors.grey : Colors.green[700]),
                label: Text(
                  _isUploading ? 'Sedang Upload...' : 'Upload Dokumen',
                  style: TextStyle(color: _isUploading ? Colors.grey : Colors.green[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
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
    );
  }

  Widget _buildKtpAddressSection() {
    return Card(
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
    );
  }

  Widget _buildDomisiliAddressSection() {
    return Card(
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
    );
  }

  Widget _buildCooperativeInfoSection() {
    return Card(
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
            _buildInfoTile(Icons.fingerprint, 'ID Member', _currentUser['id']?.toString() ?? _currentUser['user_id']?.toString() ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.green[700]!),
            ),
            onPressed: _isUploading ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    user: _currentUser,
                    onProfileUpdated: (updatedData) {
                      setState(() {
                        _currentUser = {..._currentUser, ...updatedData};
                      });
                      widget.onProfileUpdated?.call();
                    },
                  ),
                ),
              );
            },
            icon: Icon(Icons.edit, color: _isUploading ? Colors.grey : Colors.green[700]),
            label: Text(
              'Edit Profil',
              style: TextStyle(
                fontSize: 16, 
                color: _isUploading ? Colors.grey : Colors.green[700],
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isUploading ? Colors.grey : Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _isUploading ? null : _logout,
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
    final isUploaded = _isDocumentUploaded(status);
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

  bool _isDocumentUploaded(dynamic status) {
    return status != null && 
           status.toString().isNotEmpty && 
           status != 'uploaded' &&
           status.toString().startsWith('http');
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
    return kotaId.toString();
  }

  String _getTahunGabung() {
    final now = DateTime.now();
    return now.year.toString();
  }
}