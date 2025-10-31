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

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // ✅ Load existing files jika ada dari user data
    _loadExistingFiles();
  }

  void _loadExistingFiles() {
    // Jika user data sudah ada path dokumen, load sebagai preview
    if (widget.user['foto_ktp'] != null && widget.user['foto_ktp'].isNotEmpty) {
      // Untuk existing files, kita hanya set state bahwa sudah diupload
      // File sebenarnya ada di server
    }
    if (widget.user['foto_kk'] != null && widget.user['foto_kk'].isNotEmpty) {
      // Same for KK
    }
    if (widget.user['foto_diri'] != null && widget.user['foto_diri'].isNotEmpty) {
      // Same for foto diri
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ UPLOAD KTP - MENGGUNAKAN METHOD BARU
  Future<void> _uploadKTP() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        
        final file = File(pickedFile.path);
        
        // ✅ GUNAKAN METHOD uploadFoto DENGAN TYPE 'foto_ktp'
        final success = await _apiService.uploadFoto(
          type: 'foto_ktp',
          filePath: pickedFile.path,
        );

        setState(() => _isLoading = false);

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
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat upload KTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ UPLOAD KK - MENGGUNAKAN METHOD BARU
  Future<void> _uploadKK() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        
        final file = File(pickedFile.path);
        
        // ✅ GUNAKAN METHOD uploadFoto DENGAN TYPE 'foto_kk'
        final success = await _apiService.uploadFoto(
          type: 'foto_kk',
          filePath: pickedFile.path,
        );

        setState(() => _isLoading = false);

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
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat upload Kartu Keluarga: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ UPLOAD FOTO DIRI - MENGGUNAKAN METHOD BARU
  Future<void> _uploadFotoDiri() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        
        final file = File(pickedFile.path);
        
        // ✅ GUNAKAN METHOD uploadFoto DENGAN TYPE 'foto_diri'
        final success = await _apiService.uploadFoto(
          type: 'foto_diri',
          filePath: pickedFile.path,
        );

        setState(() => _isLoading = false);

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
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat upload foto diri: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ UPLOAD SEMUA DOKUMEN SEKALIGUS
  Future<void> _uploadAllDocuments() async {
    if (_ktpFile == null || _kkFile == null || _fotoDiriFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap upload semua dokumen terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool allSuccess = true;
      String errorMessage = '';

      // Upload KTP
      final ktpSuccess = await _apiService.uploadFoto(
        type: 'foto_ktp',
        filePath: _ktpFile!.path,
      );
      if (!ktpSuccess) {
        allSuccess = false;
        errorMessage = 'Gagal upload KTP';
      }

      // Upload KK
      final kkSuccess = await _apiService.uploadFoto(
        type: 'foto_kk',
        filePath: _kkFile!.path,
      );
      if (!kkSuccess) {
        allSuccess = false;
        errorMessage = 'Gagal upload Kartu Keluarga';
      }

      // Upload Foto Diri
      final fotoDiriSuccess = await _apiService.uploadFoto(
        type: 'foto_diri',
        filePath: _fotoDiriFile!.path,
      );
      if (!fotoDiriSuccess) {
        allSuccess = false;
        errorMessage = 'Gagal upload foto diri';
      }

      setState(() => _isLoading = false);

      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua dokumen berhasil diupload! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Lanjut ke dashboard setelah 1 detik
        Future.delayed(const Duration(seconds: 1), () {
          _lanjutKeDashboard();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat upload dokumen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _lanjutKeDashboard() {
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
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_user_outlined, 
                      size: 80, 
                      color: Colors.green[700]
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lengkapi Dokumen Anda',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload KTP, Kartu Keluarga, dan Foto Diri untuk melanjutkan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // PROGRESS INDICATOR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProgressStep(1, 'KTP', isKTPUploaded),
                        Container(
                          width: 30,
                          height: 2,
                          color: isKTPUploaded ? Colors.green : Colors.grey[300],
                        ),
                        _buildProgressStep(2, 'KK', isKKUploaded),
                        Container(
                          width: 30,
                          height: 2,
                          color: isKKUploaded ? Colors.green : Colors.grey[300],
                        ),
                        _buildProgressStep(3, 'Foto', isFotoDiriUploaded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // KTP CARD
              _buildDokumenCard(
                title: 'KTP (Kartu Tanda Penduduk)',
                description: 'Upload foto KTP yang masih berlaku dan jelas terbaca',
                icon: Icons.credit_card,
                color: Colors.blue,
                isUploaded: isKTPUploaded,
                file: _ktpFile,
                onUpload: _uploadKTP,
              ),
              const SizedBox(height: 20),

              // KK CARD
              _buildDokumenCard(
                title: 'Kartu Keluarga (KK)',
                description: 'Upload foto Kartu Keluarga terbaru dan jelas terbaca',
                icon: Icons.family_restroom,
                color: Colors.green,
                isUploaded: isKKUploaded,
                file: _kkFile,
                onUpload: _uploadKK,
              ),
              const SizedBox(height: 20),

              // FOTO DIRI CARD
              _buildDokumenCard(
                title: 'Foto Diri',
                description: 'Upload foto diri terbaru (pas foto) dengan latar belakang netral',
                icon: Icons.person,
                color: Colors.orange,
                isUploaded: isFotoDiriUploaded,
                file: _fotoDiriFile,
                onUpload: _uploadFotoDiri,
              ),
              const SizedBox(height: 40),

              // TOMBOL UPLOAD SEMUA
              if (!allUploaded) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _uploadAllDocuments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Upload Semua Dokumen',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // TOMBOL LANJUT KE DASHBOARD
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
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (allUploaded) 
                        const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        allUploaded ? 'Lanjut ke Dashboard' : 'Upload Semua Dokumen Terlebih Dahulu',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // INFO
              if (!allUploaded) ...[
                const SizedBox(height: 20),
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
                          'Upload ketiga dokumen untuk melanjutkan ke dashboard',
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

              const SizedBox(height: 40),
            ],
          ),
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
    required File? file,
    required VoidCallback onUpload,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isUploaded ? Icons.check_circle : Icons.schedule,
                        color: isUploaded ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUploaded ? '✓ Sudah diupload' : '● Belum diupload',
                        style: TextStyle(
                          color: isUploaded ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (isUploaded && file != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'File: ${file.path.split('/').last}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: isUploaded ? Colors.orange : color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isUploaded ? 'Ganti' : 'Upload'),
            ),
          ],
        ),
      ),
    );
  }
}