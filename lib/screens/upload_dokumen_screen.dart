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
  
  String? _ktpPath;
  String? _kkPath;
  bool _isLoading = false;

  // ✅ FIX: TAMBAHKAN SCROLL CONTROLLER
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // ✅ Load existing paths jika ada
    _ktpPath = widget.user['ktpPath'];
    _kkPath = widget.user['kkPath'];
  }

  @override
  void dispose() {
    // ✅ FIX: DISPOSE SCROLL CONTROLLER
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _uploadKTP() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _showUploadingDialog('Mengupload KTP...');

        final success = await _apiService.updateKTP(
          widget.user['username'], 
          pickedFile.path
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (success) {
          setState(() {
            _ktpPath = pickedFile.path;
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
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat memilih KTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadKK() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _showUploadingDialog('Mengupload Kartu Keluarga...');

        final success = await _apiService.updateKK(
          widget.user['username'], 
          pickedFile.path
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (success) {
          setState(() {
            _kkPath = pickedFile.path;
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
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat memilih Kartu Keluarga: $e'),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green[700]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _lanjutKeDashboard() {
    if (_ktpPath == null || _ktpPath!.isEmpty || _kkPath == null || _kkPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap upload KTP dan KK terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Update user data dengan path dokumen
    final updatedUser = Map<String, dynamic>.from(widget.user);
    updatedUser['ktpPath'] = _ktpPath;
    updatedUser['kkPath'] = _kkPath;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardMain(user: updatedUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKTPUploaded = _ktpPath != null && _ktpPath!.isNotEmpty;
    final bool isKKUploaded = _kkPath != null && _kkPath!.isNotEmpty;
    final bool allUploaded = isKTPUploaded && isKKUploaded;

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        // ✅ FIX: GUNAKAN SINGLECHILDSCROLLVIEW DENGAN CONTROLLER
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
                      'Upload KTP dan Kartu Keluarga untuk melanjutkan',
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
                          width: 40,
                          height: 2,
                          color: isKTPUploaded ? Colors.green : Colors.grey[300],
                        ),
                        _buildProgressStep(2, 'KK', isKKUploaded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // KTP CARD
              _buildDokumenCard(
                title: 'KTP (Kartu Tanda Penduduk)',
                description: 'Upload foto KTP yang masih berlaku',
                icon: Icons.credit_card,
                color: Colors.blue,
                isUploaded: isKTPUploaded,
                filePath: _ktpPath,
                onUpload: _uploadKTP,
              ),
              const SizedBox(height: 20),

              // KK CARD
              _buildDokumenCard(
                title: 'Kartu Keluarga (KK)',
                description: 'Upload foto Kartu Keluarga terbaru',
                icon: Icons.family_restroom,
                color: Colors.green,
                isUploaded: isKKUploaded,
                filePath: _kkPath,
                onUpload: _uploadKK,
              ),
              const SizedBox(height: 40),

              // TOMBOL LANJUT - ✅ FIX: TOMBOL TIDAK AKAN KETUTUP LAGI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: SizedBox(
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
                          allUploaded ? 'Lanjut ke Dashboard' : 'Upload Dokumen Terlebih Dahulu',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
                          'Upload kedua dokumen untuk melanjutkan',
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

              // ✅ FIX: TAMBAH EXTRA SPACE DI BAWAH UNTUK MEMASTIKAN TOMBOL TIDAK KETUTUP
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
    required String? filePath,
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
                  if (isUploaded && filePath != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'File: ${filePath.split('/').last}',
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