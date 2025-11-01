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

  // ✅ UPLOAD KTP - DENGAN DEBUG
  Future<void> _uploadKTP() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isUploadingKTP = true);
        
        final file = File(pickedFile.path);
        print('📤 Uploading KTP: ${file.path}');
        
        // ✅ GUNAKAN METHOD uploadFoto
        final success = await _apiService.uploadFoto(
          type: 'foto_ktp',
          filePath: pickedFile.path,
        );

        setState(() => _isUploadingKTP = false);

        if (success) {
          setState(() {
            _ktpFile = file;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('KTP berhasil diupload ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload KTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingKTP = false);
      print('❌ Error upload KTP: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ UPLOAD KK - DENGAN DEBUG
  Future<void> _uploadKK() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isUploadingKK = true);
        
        final file = File(pickedFile.path);
        print('📤 Uploading KK: ${file.path}');
        
        final success = await _apiService.uploadFoto(
          type: 'foto_kk',
          filePath: pickedFile.path,
        );

        setState(() => _isUploadingKK = false);

        if (success) {
          setState(() {
            _kkFile = file;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kartu Keluarga berhasil diupload ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload Kartu Keluarga'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingKK = false);
      print('❌ Error upload KK: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ UPLOAD FOTO DIRI - DENGAN DEBUG
  Future<void> _uploadFotoDiri() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isUploadingFotoDiri = true);
        
        final file = File(pickedFile.path);
        print('📤 Uploading Foto Diri: ${file.path}');
        
        final success = await _apiService.uploadFoto(
          type: 'foto_diri',
          filePath: pickedFile.path,
        );

        setState(() => _isUploadingFotoDiri = false);

        if (success) {
          setState(() {
            _fotoDiriFile = file;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto diri berhasil diupload ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload foto diri'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingFotoDiri = false);
      print('❌ Error upload Foto Diri: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _lanjutKeDashboard() {
    print('🎯 Lanjut ke Dashboard');
    
    // Update user data dengan status dokumen
    final updatedUser = Map<String, dynamic>.from(widget.user);
    updatedUser['foto_ktp'] = _ktpFile != null ? 'uploaded' : null;
    updatedUser['foto_kk'] = _kkFile != null ? 'uploaded' : null;
    updatedUser['foto_diri'] = _fotoDiriFile != null ? 'uploaded' : null;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardMain(user: updatedUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKTPUploaded = _ktpFile != null;
    final bool isKKUploaded = _kkFile != null;
    final bool isFotoDiriUploaded = _fotoDiriFile != null;
    final bool allUploaded = isKTPUploaded && isKKUploaded && isFotoDiriUploaded;

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        child: Column(
          children: [
            // HEADER - FIXED HEIGHT
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

            // CONTENT - SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // KTP CARD
                    _buildDokumenCard(
                      title: 'KTP',
                      description: 'Upload foto KTP yang jelas',
                      icon: Icons.credit_card,
                      color: Colors.blue,
                      isUploaded: isKTPUploaded,
                      isUploading: _isUploadingKTP,
                      onUpload: _uploadKTP,
                    ),
                    const SizedBox(height: 16),

                    // KK CARD
                    _buildDokumenCard(
                      title: 'Kartu Keluarga',
                      description: 'Upload foto KK yang jelas',
                      icon: Icons.family_restroom,
                      color: Colors.green,
                      isUploaded: isKKUploaded,
                      isUploading: _isUploadingKK,
                      onUpload: _uploadKK,
                    ),
                    const SizedBox(height: 16),

                    // FOTO DIRI CARD
                    _buildDokumenCard(
                      title: 'Foto Diri',
                      description: 'Upload pas foto terbaru',
                      icon: Icons.person,
                      color: Colors.orange,
                      isUploaded: isFotoDiriUploaded,
                      isUploading: _isUploadingFotoDiri,
                      onUpload: _uploadFotoDiri,
                    ),
                    const SizedBox(height: 32),

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
                        ),
                        child: const Text(
                          'Lanjut ke Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                                'Upload semua dokumen untuk melanjutkan',
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
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
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