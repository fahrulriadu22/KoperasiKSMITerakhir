import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard_main.dart';

// ✅ DIO SERVICE UNTUK UPLOAD
class DioService {
  static const String baseUrl = 'http://demo.bsdeveloper.id/api';
  
  String _deviceId = '12341231313131';
  String _deviceToken = '1234232423424';

  Dio get dio => Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // ✅ GET HEADERS DENGAN DIO
  Future<Map<String, dynamic>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = prefs.getString('token');
      
      final headers = {
        'DEVICE-ID': _deviceId,
        'DEVICE-TOKEN': _deviceToken,
        'Content-Type': 'multipart/form-data',
      };
      
      if (userKey != null && userKey.isNotEmpty) {
        headers['x-api-key'] = userKey;
      }
      
      return headers;
    } catch (e) {
      return {
        'DEVICE-ID': _deviceId,
        'DEVICE-TOKEN': _deviceToken,
        'Content-Type': 'multipart/form-data',
      };
    }
  }

  // ✅ UPLOAD FOTO DENGAN DIO
  Future<Map<String, dynamic>> uploadFotoWithDio({
    required String type,
    required String filePath,
  }) async {
    try {
      print('🚀 DIO UPLOAD START: $type');
      
      final headers = await _getHeaders();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return {'success': false, 'message': 'File tidak ditemukan'};
      }

      // ✅ BUAT FORM DATA DENGAN DIO
      FormData formData = FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // ✅ TAMBAH USER DATA JIKA ADA
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = jsonDecode(userString);
        if (userData['user_id'] != null) {
          formData.fields.add(MapEntry('user_id', userData['user_id'].toString()));
        }
        if (userData['username'] != null) {
          formData.fields.add(MapEntry('username', userData['username'].toString()));
        }
      }

      print('📤 DIO Headers: $headers');
      print('📤 DIO Form data fields: ${formData.fields}');
      print('📤 DIO Files: ${formData.files}');

      // ✅ KIRIM DENGAN DIO
      final response = await dio.post(
        '/users/setPhoto',
        data: formData,
        options: Options(headers: headers),
      );

      print('📡 DIO Response: ${response.statusCode}');
      print('📡 DIO Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Upload berhasil',
            'data': data
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Upload gagal'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ DIO UPLOAD ERROR: $e');
      if (e is DioException) {
        print('❌ DIO Error Response: ${e.response?.data}');
        print('❌ DIO Error Status: ${e.response?.statusCode}');
        return {
          'success': false,
          'message': 'Upload error: ${e.response?.data?['message'] ?? e.message}'
        };
      }
      return {
        'success': false,
        'message': 'Upload error: $e'
      };
    }
  }
}

class UploadDokumenScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onDocumentsComplete;

  const UploadDokumenScreen({
    super.key, 
    required this.user,
    this.onDocumentsComplete,
  });

  @override
  State<UploadDokumenScreen> createState() => _UploadDokumenScreenState();
}

class _UploadDokumenScreenState extends State<UploadDokumenScreen> {
  final ApiService _apiService = ApiService();
  final DioService _dioService = DioService(); // ✅ DIO SERVICE
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
    _runDebug();
  }

  void _loadExistingFiles() {
    print('🔍 Loading existing files from user data:');
    print('   - KTP: ${widget.user['foto_ktp']}');
    print('   - KK: ${widget.user['foto_kk']}');
    print('   - Foto Diri: ${widget.user['foto_diri']}');
  }

  void _runDebug() async {
    print('🛠️ RUNNING UPLOAD DEBUG...');
    await _apiService.debugUploadSystem();
  }

  // ✅ METHOD UPLOAD DENGAN FALLBACK (HTTP + DIO)
  Future<void> _uploadDocumentWithFallback(String type, Function(File?) setFile, Function(bool) setLoading) async {
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
        
        // ✅ VALIDASI FILE
        if (!await file.exists()) {
          throw Exception('File tidak ditemukan');
        }

        final fileSize = file.lengthSync();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Ukuran file terlalu besar. Maksimal 5MB.');
        }

        final fileExtension = pickedFile.path.toLowerCase().split('.').last;
        if (!['jpg', 'jpeg', 'png', 'heic'].contains(fileExtension)) {
          throw Exception('Format file tidak didukung. Gunakan JPG, JPEG, atau PNG.');
        }

        // ✅ COBA UPLOAD DENGAN HTTP PACKAGE DULU
        print('🔄 Trying HTTP package upload...');
        final httpResult = await _apiService.uploadFoto(
          type: type,
          filePath: pickedFile.path,
        ).timeout(const Duration(seconds: 30));

        if (httpResult['success'] == true) {
          // ✅ HTTP BERHASIL
          _handleUploadSuccess(file, type, httpResult, setFile, setLoading);
          return;
        }

        // ✅ JIKA HTTP GAGAL, COBA DIO
        print('🔄 HTTP failed, trying DIO upload...');
        final dioResult = await _dioService.uploadFotoWithDio(
          type: type,
          filePath: pickedFile.path,
        );

        if (dioResult['success'] == true) {
          // ✅ DIO BERHASIL
          _handleUploadSuccess(file, type, dioResult, setFile, setLoading);
        } else {
          // ✅ KEDUANYA GAGAL
          _handleUploadFailure(type, dioResult['message'] ?? 'Upload gagal', setLoading);
        }
      }
    } catch (e) {
      _handleUploadFailure(type, 'Error: $e', setLoading);
    }
  }

  void _handleUploadSuccess(File file, String type, Map<String, dynamic> result, Function(File?) setFile, Function(bool) setLoading) {
    setState(() {
      setFile(file);
      setLoading(false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getDocumentName(type)} berhasil diupload ✅'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    _checkAllDocumentsUploaded();
  }

  void _handleUploadFailure(String type, String error, Function(bool) setLoading) {
    setState(() {
      setLoading(false);
      _uploadError = 'Error upload ${_getDocumentName(type)}: $error';
    });

    print('❌ Upload failed: $error');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal upload ${_getDocumentName(type)}: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ✅ METHOD UPLOAD DARI KAMERA DENGAN FALLBACK
  Future<void> _takePhotoWithFallback(String type, Function(File?) setFile, Function(bool) setLoading) async {
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
        
        // ✅ VALIDASI FILE
        if (!await file.exists()) {
          throw Exception('File tidak ditemukan');
        }

        final fileSize = file.lengthSync();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Ukuran file terlalu besar. Maksimal 5MB.');
        }

        // ✅ COBA UPLOAD DENGAN HTTP PACKAGE DULU
        print('🔄 Trying HTTP package upload from camera...');
        final httpResult = await _apiService.uploadFoto(
          type: type,
          filePath: pickedFile.path,
        ).timeout(const Duration(seconds: 30));

        if (httpResult['success'] == true) {
          // ✅ HTTP BERHASIL
          _handleUploadSuccess(file, type, httpResult, setFile, setLoading);
          return;
        }

        // ✅ JIKA HTTP GAGAL, COBA DIO
        print('🔄 HTTP failed, trying DIO upload from camera...');
        final dioResult = await _dioService.uploadFotoWithDio(
          type: type,
          filePath: pickedFile.path,
        );

        if (dioResult['success'] == true) {
          // ✅ DIO BERHASIL
          _handleUploadSuccess(file, type, dioResult, setFile, setLoading);
        } else {
          // ✅ KEDUANYA GAGAL
          _handleUploadFailure(type, dioResult['message'] ?? 'Upload gagal', setLoading);
        }
      }
    } catch (e) {
      _handleUploadFailure(type, 'Error: $e', setLoading);
    }
  }

  // ✅ PERBAIKAN: METHOD UNTUK HANDLE TOKEN EXPIRED
  void _showTokenExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesi Berakhir'),
        content: const Text('Sesi login Anda telah berakhir. Silakan login kembali.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Login Kembali'),
          ),
        ],
      ),
    );
  }

  // ✅ CEK JIKA SEMUA DOKUMEN SUDAH DIUPLOAD
  void _checkAllDocumentsUploaded() {
    final bool allUploaded = _ktpFile != null && _kkFile != null && _fotoDiriFile != null;
    if (allUploaded) {
      print('🎉 Semua dokumen sudah diupload!');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _proceedToDashboard();
        }
      });
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
    await _uploadDocumentWithFallback(
      'foto_ktp',
      (file) => _ktpFile = file,
      (loading) => _isUploadingKTP = loading,
    );
  }

  // ✅ UPLOAD KK
  Future<void> _uploadKK() async {
    await _uploadDocumentWithFallback(
      'foto_kk',
      (file) => _kkFile = file,
      (loading) => _isUploadingKK = loading,
    );
  }

  // ✅ UPLOAD FOTO DIRI
  Future<void> _uploadFotoDiri() async {
    await _uploadDocumentWithFallback(
      'foto_diri',
      (file) => _fotoDiriFile = file,
      (loading) => _isUploadingFotoDiri = loading,
    );
  }

  // ✅ UPLOAD KTP DARI KAMERA
  Future<void> _takePhotoKTP() async {
    await _takePhotoWithFallback(
      'foto_ktp',
      (file) => _ktpFile = file,
      (loading) => _isUploadingKTP = loading,
    );
  }

  // ✅ UPLOAD KK DARI KAMERA
  Future<void> _takePhotoKK() async {
    await _takePhotoWithFallback(
      'foto_kk',
      (file) => _kkFile = file,
      (loading) => _isUploadingKK = loading,
    );
  }

  // ✅ UPLOAD FOTO DIRI DARI KAMERA
  Future<void> _takePhotoFotoDiri() async {
    await _takePhotoWithFallback(
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

  // ✅ PROCEED TO DASHBOARD
  void _proceedToDashboard() {
    print('🚀 Starting proceed to dashboard...');
    setState(() => _isLoading = true);
    
    final updatedUser = Map<String, dynamic>.from(widget.user);
    updatedUser['foto_ktp'] = _ktpFile != null ? 'uploaded' : (widget.user['foto_ktp'] ?? 'pending');
    updatedUser['foto_kk'] = _kkFile != null ? 'uploaded' : (widget.user['foto_kk'] ?? 'pending');
    updatedUser['foto_diri'] = _fotoDiriFile != null ? 'uploaded' : (widget.user['foto_diri'] ?? 'pending');

    print('🚀 Proceeding to dashboard with user data:');
    print('   - KTP: ${updatedUser['foto_ktp']}');
    print('   - KK: ${updatedUser['foto_kk']}');
    print('   - Foto Diri: ${updatedUser['foto_diri']}');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (widget.onDocumentsComplete != null) {
          print('📞 Memanggil callback onDocumentsComplete...');
          widget.onDocumentsComplete!();
        } else {
          print('🔄 Callback tidak ada, navigasi langsung ke Dashboard...');
          try {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardMain(user: updatedUser)),
              (route) => false,
            );
            print('✅ Navigation to dashboard successful');
          } catch (e) {
            print('❌ Navigation error: $e');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardMain(user: widget.user)),
              (route) => false,
            );
          }
        }
      }
    });
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
                      description: 'Upload foto KTP yang jelas dan terbaca\n• Pastikan foto tidak blur\n• Semua informasi terbaca jelas\n• Format JPG/PNG (max 5MB)',
                      icon: Icons.credit_card,
                      color: Colors.blue,
                      isUploaded: isKTPUploaded,
                      isUploading: _isUploadingKTP,
                      onUpload: () => _showImageSourceDialog(_uploadKTP, _takePhotoKTP),
                    ),
                    const SizedBox(height: 16),

                    // KK CARD
                    _buildDokumenCard(
                      title: 'Kartu Keluarga (KK)',
                      description: 'Upload foto KK yang jelas dan terbaca\n• Pastikan foto tidak blur\n• Semua halaman penting terbaca\n• Format JPG/PNG (max 5MB)',
                      icon: Icons.family_restroom,
                      color: Colors.green,
                      isUploaded: isKKUploaded,
                      isUploading: _isUploadingKK,
                      onUpload: () => _showImageSourceDialog(_uploadKK, _takePhotoKK),
                    ),
                    const SizedBox(height: 16),

                    // FOTO DIRI CARD
                    _buildDokumenCard(
                      title: 'Foto Diri Terbaru',
                      description: 'Upload pas foto terbaru\n• Latar belakang polos\n• Wajah terlihat jelas\n• Ekspresi netral\n• Format JPG/PNG (max 5MB)',
                      icon: Icons.person,
                      color: Colors.orange,
                      isUploaded: isFotoDiriUploaded,
                      isUploading: _isUploadingFotoDiri,
                      onUpload: () => _showImageSourceDialog(_uploadFotoDiri, _takePhotoFotoDiri),
                    ),
                    const SizedBox(height: 32),

                    // PREVIEW SECTION
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
                            onPressed: allUploaded && !_isLoading ? _lanjutKeDashboard : null,
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
                            onPressed: _isLoading ? null : _lewatiUpload,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.orange,
                                    ),
                                  )
                                : const Text(
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

                    // TROUBLESHOOTING INFO
                    const SizedBox(height: 16),
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
                              Icon(Icons.help_outline, color: Colors.blue[700], size: 18),
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
                            '• Pastikan file JPG/PNG\n• Ukuran maksimal 5MB\n• Foto harus jelas dan terbaca\n• Jika gagal, coba foto ulang dengan pencahayaan baik\n• Pastikan koneksi internet stabil',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
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