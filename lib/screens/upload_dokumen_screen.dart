import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'dashboard_main.dart';

class UploadDokumenScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UploadDokumenScreen({super.key, required this.user});

  @override
  State<UploadDokumenScreen> createState() => _UploadDokumenScreenState();
}

class _UploadDokumenScreenState extends State<UploadDokumenScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _ktpFile;
  File? _kkFile;
  File? _fotoDiriFile;
  bool _isLoading = false;
  bool _isUploadingKTP = false;
  bool _isUploadingKK = false;
  bool _isUploadingFotoDiri = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _loadExistingFiles();
  }

  void _loadExistingFiles() {
    print('🔍 Loading existing files from user data:');
    print('   - KTP: ${widget.user['foto_ktp']}');
    print('   - KK: ${widget.user['foto_kk']}');
    print('   - Foto Diri: ${widget.user['foto_diri']}');
  }

  // ✅ GENERIC UPLOAD METHOD
  Future<void> _uploadDocument(String type, Function(File?) setFile, Function(bool) setLoading) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          setLoading(true);
          _uploadError = null;
        });
        
        final file = File(pickedFile.path);
        print('📤 Uploading $type: ${file.path}');
        print('📤 File size: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB');
        
        // ✅ PERBAIKAN: Gunakan uploadFotoFixed untuk response yang lebih detail
        final result = await _apiService.uploadFotoFixed(
          type: type,
          filePath: pickedFile.path,
        );

        setState(() => setLoading(false));

        if (result['success'] == true) {
          setState(() => setFile(file));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDocumentName(type)} berhasil diupload ✅'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          setState(() => setFile(null));
          final errorMessage = result['message'] ?? 'Gagal upload ${_getDocumentName(type)}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        setLoading(false);
        setFile(null);
        _uploadError = 'Error upload ${_getDocumentName(type)}: $e';
      });
      
      print('❌ Error upload $type: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error upload ${_getDocumentName(type)}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Helper method untuk nama dokumen
  String _getDocumentName(String type) {
    switch (type) {
      case 'foto_ktp': return 'KTP';
      case 'foto_kk': return 'Kartu Keluarga';
      case 'foto_diri': return 'Foto Diri';
      default: return 'Dokumen';
    }
  }

  // ✅ UPLOAD KTP
  Future<void> _uploadKTP() async {
    await _uploadDocument(
      'foto_ktp',
      (file) => _ktpFile = file,
      (loading) => _isUploadingKTP = loading,
    );
  }

  // ✅ UPLOAD KK
  Future<void> _uploadKK() async {
    await _uploadDocument(
      'foto_kk',
      (file) => _kkFile = file,
      (loading) => _isUploadingKK = loading,
    );
  }

  // ✅ UPLOAD FOTO DIRI
  Future<void> _uploadFotoDiri() async {
    await _uploadDocument(
      'foto_diri',
      (file) => _fotoDiriFile = file,
      (loading) => _isUploadingFotoDiri = loading,
    );
  }

  // ✅ FITUR LEWATI - Skip upload dan langsung ke dashboard
  void _lewatiUpload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lewati Upload Dokumen?'),
        content: const Text(
          'Anda dapat mengupload dokumen nanti di menu Profile. '
          'Apakah Anda yakin ingin melanjutkan ke dashboard?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lanjut Upload'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToDashboard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Ya, Lewati'),
          ),
        ],
      ),
    );
  }

  // ✅ LANJUT KE DASHBOARD
  void _lanjutKeDashboard() {
    print('🎯 Lanjut ke Dashboard');
    
    // Konfirmasi sebelum lanjut
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin dokumen yang diupload sudah benar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Periksa Lagi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToDashboard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _proceedToDashboard() {
    setState(() => _isLoading = true);
    
    // Update user data dengan status dokumen
    final updatedUser = Map<String, dynamic>.from(widget.user);
    updatedUser['foto_ktp'] = _ktpFile != null ? 'uploaded' : widget.user['foto_ktp'];
    updatedUser['foto_kk'] = _kkFile != null ? 'uploaded' : widget.user['foto_kk'];
    updatedUser['foto_diri'] = _fotoDiriFile != null ? 'uploaded' : widget.user['foto_diri'];

    // ✅ Navigasi ke dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => DashboardMain(user: updatedUser)),
      (route) => false,
    );
  }

  // ✅ SHOW IMAGE SOURCE DIALOG dengan opsi kamera
  void _showImageSourceDialog(Function() onGallery, Function() onCamera) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: const Text('Pilih sumber untuk mengambil gambar'),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onCamera();
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onGallery();
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Take photo from camera
  Future<void> _takePhoto(String type, Function(File?) setFile, Function(bool) setLoading) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          setLoading(true);
          _uploadError = null;
        });
        
        final file = File(pickedFile.path);
        print('📸 Taking photo for $type: ${file.path}');
        
        final result = await _apiService.uploadFotoFixed(
          type: type,
          filePath: pickedFile.path,
        );

        setState(() => setLoading(false));

        if (result['success'] == true) {
          setState(() => setFile(file));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDocumentName(type)} berhasil diambil ✅'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          setState(() => setFile(null));
          final errorMessage = result['message'] ?? 'Gagal mengambil ${_getDocumentName(type)}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        setLoading(false);
        setFile(null);
        _uploadError = 'Error mengambil ${_getDocumentName(type)}: $e';
      });
      
      print('❌ Error take photo $type: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengambil ${_getDocumentName(type)}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKTPUploaded = _ktpFile != null;
    final bool isKKUploaded = _kkFile != null;
    final bool isFotoDiriUploaded = _fotoDiriFile != null;
    final bool allUploaded = isKTPUploaded && isKKUploaded && isFotoDiriUploaded;
    final int uploadedCount = [isKTPUploaded, isKKUploaded, isFotoDiriUploaded].where((e) => e).length;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Upload Dokumen'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (uploadedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$uploadedCount/3',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user_outlined, 
                    size: 60, 
                    color: Colors.green[700]
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lengkapi Dokumen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload dokumen untuk melanjutkan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // PROGRESS INDICATOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProgressStep(1, 'KTP', isKTPUploaded),
                      Container(width: 20, height: 2, color: isKTPUploaded ? Colors.green : Colors.grey[300]),
                      _buildProgressStep(2, 'KK', isKKUploaded),
                      Container(width: 20, height: 2, color: isKKUploaded ? Colors.green : Colors.grey[300]),
                      _buildProgressStep(3, 'Foto', isFotoDiriUploaded),
                    ],
                  ),
                ],
              ),
            ),

            // ERROR MESSAGE
            if (_uploadError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
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

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // KTP CARD
                    _buildDokumenCard(
                      title: 'KTP (Kartu Tanda Penduduk)',
                      description: 'Upload foto KTP yang jelas dan terbaca\n• Pastikan foto tidak blur\n• Semua informasi terbaca jelas\n• Format JPG/PNG',
                      icon: Icons.credit_card,
                      color: Colors.blue,
                      isUploaded: isKTPUploaded,
                      isUploading: _isUploadingKTP,
                      onUpload: () => _showImageSourceDialog(_uploadKTP, () => _takePhoto('foto_ktp', (file) => _ktpFile = file, (loading) => _isUploadingKTP = loading)),
                    ),
                    const SizedBox(height: 16),

                    // KK CARD
                    _buildDokumenCard(
                      title: 'Kartu Keluarga (KK)',
                      description: 'Upload foto KK yang jelas dan terbaca\n• Pastikan foto tidak blur\n• Semua halaman penting terbaca\n• Format JPG/PNG',
                      icon: Icons.family_restroom,
                      color: Colors.green,
                      isUploaded: isKKUploaded,
                      isUploading: _isUploadingKK,
                      onUpload: () => _showImageSourceDialog(_uploadKK, () => _takePhoto('foto_kk', (file) => _kkFile = file, (loading) => _isUploadingKK = loading)),
                    ),
                    const SizedBox(height: 16),

                    // FOTO DIRI CARD
                    _buildDokumenCard(
                      title: 'Foto Diri Terbaru',
                      description: 'Upload pas foto terbaru\n• Latar belakang polos\n• Wajah terlihat jelas\n• Ekspresi netral\n• Format JPG/PNG',
                      icon: Icons.person,
                      color: Colors.orange,
                      isUploaded: isFotoDiriUploaded,
                      isUploading: _isUploadingFotoDiri,
                      onUpload: () => _showImageSourceDialog(_uploadFotoDiri, () => _takePhoto('foto_diri', (file) => _fotoDiriFile = file, (loading) => _isUploadingFotoDiri = loading)),
                    ),
                    const SizedBox(height: 32),

                    // PREVIEW SECTION (jika ada file yang diupload)
                    if (_ktpFile != null || _kkFile != null || _fotoDiriFile != null) ...[
                      _buildPreviewSection(),
                      const SizedBox(height: 16),
                    ],

                    // TOMBOL LANJUT & LEWATI
                    Column(
                      children: [
                        // TOMBOL LANJUT
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: allUploaded ? _lanjutKeDashboard : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allUploaded ? Colors.green[700] : Colors.grey[400],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
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
                                    allUploaded ? 'Lanjut ke Dashboard' : 'Upload $uploadedCount/3 Dokumen',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // TOMBOL LEWATI
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: OutlinedButton(
                            onPressed: _lewatiUpload,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Lewati & Lanjut ke Dashboard',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // INFO
                    if (!allUploaded) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Upload semua dokumen untuk pengalaman terbaik. Anda bisa melewatinya dan upload nanti di menu Profile.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ PREVIEW SECTION
  Widget _buildPreviewSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Dokumen Terupload',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_ktpFile != null) _buildPreviewItem('KTP', _ktpFile!),
            if (_kkFile != null) _buildPreviewItem('Kartu Keluarga', _kkFile!),
            if (_fotoDiriFile != null) _buildPreviewItem('Foto Diri', _fotoDiriFile!),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String title, File file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted 
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isCompleted ? Colors.green : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDokumenCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isUploaded,
    required bool isUploading,
    required VoidCallback onUpload,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isUploaded ? Icons.check_circle : Icons.schedule,
                        color: isUploaded ? Colors.green : Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUploaded ? 'Sudah diupload' : 'Belum diupload',
                        style: TextStyle(
                          color: isUploaded ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              height: 36,
              child: ElevatedButton(
                onPressed: isUploading ? null : onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploaded ? Colors.orange : color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isUploaded ? 'Ganti' : 'Upload',
                        style: const TextStyle(fontSize: 12),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}