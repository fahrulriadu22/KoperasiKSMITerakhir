import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import '../services/temporary_storage_service.dart';
import '../services/file_validator.dart';
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
  final VoidCallback? onLogout;

  const ProfileScreen({
    super.key, 
    required this.user,
    this.onProfileUpdated,
    this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _currentUser;
  final ApiService _apiService = ApiService();
  final TemporaryStorageService _storageService = TemporaryStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isRefreshing = false;
  String? _uploadError;

@override
void initState() {
  super.initState();
  _currentUser = Map<String, dynamic>.from(widget.user);
  
  // ✅ LOAD DATA SEGERA SETELAH INIT
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeStorage();
    _loadCurrentUser();
  });
}

  // ✅ INITIALIZE TEMPORARY STORAGE
  Future<void> _initializeStorage() async {
    await _storageService.loadFilesFromStorage();
    print('✅ TemporaryStorageService initialized for profile documents');
    _storageService.printDebugInfo();
  }

  // ✅ METHOD BARU: LOAD USER INFO DARI SERVER (GET USERINFO API)
Future<void> _loadUserInfoFromServer() async {
  try {
    print('🚀 Loading user info from getUserInfo API...');
    
    final userInfoResult = await _apiService.getUserInfo();
    
    if (userInfoResult['success'] == true && userInfoResult['data'] != null) {
      final userInfoData = userInfoResult['data'];
      
      print('✅ getUserInfo API success!');
      print('👤 Data received:');
      print('   - username: ${userInfoData['username']}');
      print('   - nama: ${userInfoData['nama']}');
      print('   - email: ${userInfoData['email']}');
      print('   - alamat: ${userInfoData['alamat']}');
      print('   - foto_ktp: ${userInfoData['foto_ktp']}');
      print('   - foto_kk: ${userInfoData['foto_kk']}');
      print('   - foto_diri: ${userInfoData['foto_diri']}');
      print('   - foto_bukti: ${userInfoData['foto_bukti']}');
      
      // ✅ UPDATE CURRENT USER DENGAN DATA DARI getUserInfo
      if (mounted) {
        setState(() {
          _currentUser = {
            ..._currentUser, // Pertahankan data lama
            ...userInfoData,  // Update dengan data baru dari getUserInfo
          };
        });
      }
      
      print('✅ User info updated from getUserInfo API');
      return;
    } else {
      print('❌ getUserInfo API failed: ${userInfoResult['message']}');
    }
  } catch (e) {
    print('❌ Error loading user info from server: $e');
  }
}

// ✅ FIX: LOAD CURRENT USER DENGAN DATA SUPER LENGKAP
Future<void> _loadCurrentUser() async {
  try {
    if (mounted) {
      setState(() => _isRefreshing = true);
    }
    
    print('🔄 Loading SUPER COMPLETE user data...');
    
    // ✅ PRIORITAS 1: AMBIL DATA SUPER LENGKAP
    final superResult = await _apiService.getCompleteUserInfo();
    
    if (superResult['success'] == true && superResult['data'] != null) {
      final superData = superResult['data'];
      
      if (mounted) {
        setState(() {
          _currentUser = superData;
        });
      }
      
      print('🎉 SUPER USER DATA LOADED!');
      _debugSuperUserData(superData);
      return;
    }
    
    // ✅ FALLBACK KE METHOD LAMA
    await _loadUserInfoFromServer();
    // ... rest of existing code
    
  } catch (e) {
    print('❌ Error loading current user: $e');
    await _loadLocalDataFallback();
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
}

// ✅ DEBUG SUPER USER DATA
void _debugSuperUserData(Map<String, dynamic> userData) {
  print('🐛 === SUPER USER DATA DEBUG ===');
  
  print('🔑 SYSTEM INFO:');
  print('   - user_id: ${userData['user_id']}');
  print('   - id: ${userData['id']}');
  print('   - user_key: ${userData['user_key']}');
  print('   - token: ${userData['token']}');
  print('   - status_user: ${userData['status_user']}');
  
  print('👤 BASIC INFO:');
  print('   - username: ${userData['username']}');
  print('   - nama: ${userData['nama']}');
  print('   - email: ${userData['email']}');
  print('   - telp: ${userData['telp']}');
  
  print('📄 DOCUMENT INFO:');
  print('   - foto_ktp: ${userData['foto_ktp']}');
  print('   - foto_kk: ${userData['foto_kk']}');
  print('   - foto_diri: ${userData['foto_diri']}');
  print('   - foto_bukti: ${userData['foto_bukti']}');
  
  print('🏠 ADDRESS INFO:');
  print('   - alamat: ${userData['alamat']}');
  print('   - ktp_alamat: ${userData['ktp_alamat']}');
  print('   - domisili_alamat: ${userData['domisili_alamat']}');
  
  print('📋 PERSONAL INFO:');
  print('   - job: ${userData['job']}');
  print('   - pekerjaan: ${userData['pekerjaan']}');
  print('   - birth_place: ${userData['birth_place']}');
  print('   - tempat_lahir: ${userData['tempat_lahir']}');
  
  print('🎯 TOTAL KEYS: ${userData.keys.length}');
  print('📋 ALL KEYS: ${userData.keys.toList()}');
  print('🐛 === DEBUG END ===');
}

// ✅ HELPER: CEK APAKAH DATA SUDAH LENGKAP
bool _hasCompleteData() {
  final hasBasicInfo = _currentUser['username'] != null || 
                      _currentUser['nama'] != null || 
                      _currentUser['email'] != null;
  
  final hasDocumentInfo = _currentUser['foto_ktp'] != null || 
                         _currentUser['foto_kk'] != null || 
                         _currentUser['foto_diri'] != null;
  
  return hasBasicInfo && hasDocumentInfo;
}

// ✅ FALLBACK: LOAD DATA DARI DASHBOARD
Future<void> _loadFromDashboardFallback() async {
  try {
    print('🔄 Trying dashboard fallback...');
    final dashboardResult = await _apiService.getDashboardDataRobust();
    
    if (dashboardResult['success'] == true && dashboardResult['data'] != null) {
      final dashboardData = dashboardResult['data'];
      final profileData = dashboardData['profile'] ?? {};
      
      if (profileData.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentUser = {..._currentUser, ...profileData};
          });
        }
        print('✅ Profile data updated from dashboard fallback');
      }
    }
  } catch (e) {
    print('❌ Dashboard fallback failed: $e');
    await _loadLocalDataFallback();
  }
}

// ✅ FALLBACK: LOAD DATA LOKAL
Future<void> _loadLocalDataFallback() async {
  try {
    print('🔄 Trying local data fallback...');
    final user = await _apiService.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
      print('✅ Using local user data');
    } else {
      print('❌ No local user data available');
    }
  } catch (e) {
    print('❌ Local data fallback failed: $e');
  }
}

// ✅ AUTO-REFRESH SETELAH EDIT PROFILE
void _onProfileUpdated(Map<String, dynamic> updatedData) {
  print('🔄 Profile updated callback received');
  print('📦 Updated data keys: ${updatedData.keys}');
  
  setState(() {
    // ✅ UPDATE CURRENT USER DENGAN DATA BARU
    _currentUser = {..._currentUser, ...updatedData};
  });
  
  // ✅ REFRESH DATA DARI SERVER UNTUK MEMASTIKAN
  _refreshProfile();
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Profile berhasil diperbarui'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );
}

// ✅ UPDATE: DEBUG METHOD UNTUK TAMPILKAN DATA DARI getUserInfo
void _debugAllUserData(Map<String, dynamic> userData) {
  print('🐛 === COMPLETE USER DATA DEBUG (FROM getUserInfo) ===');
  
  print('👤 Basic Info from getUserInfo:');
  print('   - username: ${userData['username']}');
  print('   - nama: ${userData['nama']}');
  print('   - email: ${userData['email']}');
  print('   - telp: ${userData['telp']}');
  print('   - alamat: ${userData['alamat']}');
  
  print('📄 Document Status from getUserInfo:');
  print('   - foto_ktp: ${userData['foto_ktp']}');
  print('   - foto_kk: ${userData['foto_kk']}');
  print('   - foto_diri: ${userData['foto_diri']}');
  print('   - foto_bukti: ${userData['foto_bukti']}');
  
  print('🔑 System Info:');
  print('   - user_id: ${userData['user_id']}');
  print('   - id: ${userData['id']}');
  print('   - user_key: ${userData['user_key']}');
  print('   - status_user: ${userData['status_user']}');
  
  print('🏠 Address Info:');
  print('   - ktp_alamat: ${userData['ktp_alamat']}');
  print('   - ktp_rt: ${userData['ktp_rt']}');
  print('   - ktp_rw: ${userData['ktp_rw']}');
  print('   - ktp_id_regency: ${userData['ktp_id_regency']}');
  print('   - domisili_alamat: ${userData['domisili_alamat']}');
  
  print('📋 Personal Info:');
  print('   - job: ${userData['job']}');
  print('   - pekerjaan: ${userData['pekerjaan']}');
  print('   - birth_place: ${userData['birth_place']}');
  print('   - tempatLahir: ${userData['tempatLahir']}');
  
  print('🐛 === DEBUG END ===');
}

// ✅ METHOD BARU: UPLOAD PROFILE PHOTO
Future<void> _uploadProfilePhoto() async {
  try {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _isUploading = true;
          _uploadError = null;
        });
      }

      final file = File(pickedFile.path);
      print('📤 Uploading profile photo: ${file.path}');
      
      // ✅ VALIDASI FILE
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan');
      }

      final fileSize = file.lengthSync();
      if (fileSize > 3 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar. Maksimal 3MB.');
      }

      final fileExtension = pickedFile.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        throw Exception('Format file tidak didukung. Gunakan JPG, JPEG, atau PNG.');
      }

      // ✅ UPLOAD KE API setProfilePhoto
      final result = await _apiService.setProfilePhoto(file.path);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      if (result['success'] == true) {
        _showSafeSnackBar('✅ Foto profil berhasil diupload!');
        
        // ✅ REFRESH DATA USER SETELAH UPLOAD BERHASIL
        await _refreshProfile();
        
      } else {
        throw Exception(result['message'] ?? 'Upload foto profil gagal');
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Error upload foto profil: $e';
      });
    }
    
    print('❌ Profile photo upload failed: $e');
    _showSafeSnackBar('Gagal upload foto profil: $e', isError: true);
  }
}

// ✅ METHOD BARU: AMBIL FOTO PROFIL DARI KAMERA
Future<void> _takeProfilePhoto() async {
  try {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _isUploading = true;
          _uploadError = null;
        });
      }

      final file = File(pickedFile.path);
      print('📸 Taking profile photo: ${file.path}');
      
      // ✅ VALIDASI FILE
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan');
      }

      final fileSize = file.lengthSync();
      if (fileSize > 3 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar. Maksimal 3MB.');
      }

      // ✅ UPLOAD KE API setProfilePhoto
      final result = await _apiService.setProfilePhoto(file.path);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      if (result['success'] == true) {
        _showSafeSnackBar('✅ Foto profil berhasil diambil!');
        
        // ✅ REFRESH DATA USER SETELAH UPLOAD BERHASIL
        await _refreshProfile();
        
      } else {
        throw Exception(result['message'] ?? 'Upload foto profil gagal');
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Error mengambil foto profil: $e';
      });
    }
    
    print('❌ Profile photo camera failed: $e');
    _showSafeSnackBar('Gagal mengambil foto profil: $e', isError: true);
  }
}

// ✅ INTEGRASI: UPLOAD DOKUMEN DENGAN SAFE CHECK
Future<void> _uploadDocument(String type, String documentName) async {
  try {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _uploadError = null;
        });
      }

      final file = File(pickedFile.path);
      print('📤 Uploading $documentName: ${file.path}');
      
      // ✅ VALIDASI FILE - HANYA JPG/JPEG
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan');
      }

      final fileSize = file.lengthSync();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar. Maksimal 5MB.');
      }

      final fileExtension = pickedFile.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg'].contains(fileExtension)) {
        throw Exception('Format file tidak didukung. Gunakan JPG atau JPEG saja.');
      }

      // ✅ SIMPAN FILE KE TEMPORARY STORAGE
      switch (type) {
        case 'ktp':
          await _storageService.setKtpFile(file);
          break;
        case 'kk':
          await _storageService.setKkFile(file);
          break;
        case 'diri':
          await _storageService.setDiriFile(file);
          break;
      }

      if (mounted) {
        setState(() {});
      }

      // ✅ GUNAKAN SAFE SNACKBAR
      _showSafeSnackBar('$documentName berhasil disimpan ✅');

      print('💾 $documentName saved to temporary storage');
      
      // ✅ CHECK AUTO UPLOAD SETELAH SIMPAN FILE
      _checkAutoUpload();
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _uploadError = 'Error upload $documentName: $e';
      });
    }

    print('❌ Upload failed: $e');
    _showSafeSnackBar('Gagal upload $documentName: $e', isError: true);
  }
}

 // ✅ INTEGRASI: TAKE PHOTO DENGAN SAFE CHECK
Future<void> _takePhoto(String type, String documentName) async {
  try {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _uploadError = null;
        });
      }

      final file = File(pickedFile.path);
      print('📸 Taking photo for $documentName: ${file.path}');
      
      // ✅ VALIDASI FILE - HANYA JPG/JPEG
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan');
      }

      final fileSize = file.lengthSync();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar. Maksimal 5MB.');
      }

      // ✅ SIMPAN FILE KE TEMPORARY STORAGE
      switch (type) {
        case 'ktp':
          await _storageService.setKtpFile(file);
          break;
        case 'kk':
          await _storageService.setKkFile(file);
          break;
        case 'diri':
          await _storageService.setDiriFile(file);
          break;
      }

      if (mounted) {
        setState(() {});
      }

      // ✅ GUNAKAN SAFE SNACKBAR
      _showSafeSnackBar('$documentName berhasil diambil ✅');

      print('💾 $documentName from camera saved to temporary storage');
      
      // ✅ CHECK AUTO UPLOAD SETELAH SIMPAN FILE
      _checkAutoUpload();
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _uploadError = 'Error mengambil foto $documentName: $e';
      });
    }

    print('❌ Camera failed: $e');
    _showSafeSnackBar('Gagal mengambil foto $documentName: $e', isError: true);
  }
}

// ✅ INTEGRASI: CHECK AUTO UPLOAD YANG SAMA
void _checkAutoUpload() {
  print('🔄 _checkAutoUpload called');
  print('   - isAllFilesComplete: ${_storageService.isAllFilesComplete}');
  print('   - isUploading: ${_storageService.isUploading}');
  print('   - hasKtpFile: ${_storageService.hasKtpFile}');
  print('   - hasKkFile: ${_storageService.hasKkFile}');
  print('   - hasDiriFile: ${_storageService.hasDiriFile}');
  
  // ✅ CEK APAKAH SUDAH ADA DI SERVER
  final ktpServer = _isDocumentUploadedToServer('ktp');
  final kkServer = _isDocumentUploadedToServer('kk');
  final diriServer = _isDocumentUploadedToServer('diri');
  
  print('   - KTP Server: $ktpServer');
  print('   - KK Server: $kkServer');
  print('   - Diri Server: $diriServer');
  
  // ✅ JIKA SEMUA FILE LENGKAP DAN BELUM DIUPLOAD KE SERVER
  if (_storageService.isAllFilesComplete && 
      !_storageService.isUploading &&
      (!ktpServer || !kkServer || !diriServer)) {
    print('🚀 All files complete, showing upload confirmation...');
    _showUploadConfirmationDialog();
  } else {
    print('⏳ Not ready for auto-upload yet');
  }
}

  // ✅ UPLOAD KTP
  Future<void> _uploadKTP() async {
    await _uploadDocument('ktp', 'KTP');
  }

  // ✅ UPLOAD KK
  Future<void> _uploadKK() async {
    await _uploadDocument('kk', 'Kartu Keluarga');
  }

  // ✅ UPLOAD FOTO DIRI
  Future<void> _uploadFotoDiri() async {
    await _uploadDocument('diri', 'Foto Diri');
  }

  // ✅ UPLOAD KTP DARI KAMERA
  Future<void> _takePhotoKTP() async {
    await _takePhoto('ktp', 'KTP');
  }

  // ✅ UPLOAD KK DARI KAMERA
  Future<void> _takePhotoKK() async {
    await _takePhoto('kk', 'Kartu Keluarga');
  }

  // ✅ UPLOAD FOTO DIRI DARI KAMERA
  Future<void> _takePhotoFotoDiri() async {
    await _takePhoto('diri', 'Foto Diri');
  }

  // ✅ CLEAR SPECIFIC FILE
  Future<void> _clearFile(String type, String documentName) async {
    await _storageService.clearFile(type);
    if (mounted) {
      setState(() {});
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$documentName dihapus'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ MANUAL UPLOAD ALL FILES - 3 ASLI + 1 DUMMY
  Future<void> _uploadAllFiles() async {
    if (!_storageService.isAllFilesComplete) {
      final missingFiles = _getMissingFilesList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Harap lengkapi semua dokumen terlebih dahulu:'),
              const SizedBox(height: 4),
              Text(
                missingFiles.join(', '),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_storageService.isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Upload sedang berjalan, harap tunggu...'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _showUploadConfirmationDialog();
  }

  // ✅ DIALOG KONFIRMASI UPLOAD 4 FILES (3 ASLI + 1 DUMMY)
  void _showUploadConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Upload Semua Dokumen?'),
        content: const Text(
          'Apakah Anda yakin ingin mengupload semua dokumen?\n\n'
          '• KTP\n'
          '• Kartu Keluarga\n'
          '• Foto Diri\n\n'
          'Sistem akan menambahkan file dummy bukti secara otomatis.\n'
          'Total 4 file akan dikirim ke server.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Periksa Lagi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startUploadProcess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Ya, Upload Sekarang'),
          ),
        ],
      ),
    );
  }

  // ✅ PROSES UPLOAD YANG SEBENARNYA - 3 ASLI + 1 DUMMY
  Future<void> _startUploadProcess() async {
    if (mounted) {
      setState(() {
        _isUploading = true;
      });
    }

    print('🚀 Starting upload process with dummy system...');
    
    try {
      // ✅ GUNAKAN UPLOAD WITH DUMMY SYSTEM YANG SUDAH FIX
      final result = await _storageService.uploadWithDummySystem();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Upload berhasil'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // ✅ REFRESH USER DATA SETELAH UPLOAD BERHASIL
        print('🔄 Refreshing user data after successful upload...');
        await _loadCurrentUser();
        widget.onProfileUpdated?.call();
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Upload gagal'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ✅ SHOW IMAGE SOURCE DIALOG dengan opsi kamera
  void _showImageSourceDialog(String type, String documentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Sumber $documentName'),
        content: Text('Pilih sumber untuk mengambil gambar $documentName'),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    switch (type) {
                      case 'ktp':
                        _takePhotoKTP();
                        break;
                      case 'kk':
                        _takePhotoKK();
                        break;
                      case 'diri':
                        _takePhotoFotoDiri();
                        break;
                    }
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
                    switch (type) {
                      case 'ktp':
                        _uploadKTP();
                        break;
                      case 'kk':
                        _uploadKK();
                        break;
                      case 'diri':
                        _uploadFotoDiri();
                        break;
                    }
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

// ✅ BUILD DOKUMEN CARD - GUNAKAN LOGIC YANG SAMA
Widget _buildDokumenCard({
  required String type,
  required String title,
  required String description,
  required IconData icon,
  required Color color,
}) {
  final fileInfo = _storageService.getFileInfo(type);
  final hasLocalFile = fileInfo['exists'] == true;
  final isUploading = _storageService.isUploading;
  
  // ✅ GUNAKAN METHOD YANG SAMA UNTUK CEK STATUS SERVER
  final isUploadedToServer = _isDocumentUploadedToServer(type);
  final serverUrl = _getDocumentServerUrl(type);

  print('🎨 Building $type card - Server: $isUploadedToServer, Local: $hasLocalFile');

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
                  
                  // ✅ STATUS INDICATOR (PRIORITAS SERVER STATUS)
                  if (isUploadedToServer) ...[
                    Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Terverifikasi di Server',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (serverUrl != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'URL: ${_shortenUrl(serverUrl)}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else if (hasLocalFile) ...[
                    Row(
                      children: [
                        Icon(Icons.pending, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Menunggu Upload',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(fileInfo['size'] / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    if (fileInfo['filename'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        fileInfo['filename'],
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else ...[
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Belum Diupload',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // UPLOAD/GANTI BUTTON
                SizedBox(
                  width: 80,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isUploading ? null : () => _showImageSourceDialog(type, title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUploadedToServer ? Colors.green : 
                                    hasLocalFile ? Colors.orange : color,
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
                            isUploadedToServer ? '✓ Verified' : 
                            hasLocalFile ? 'Upload' : 'Pilih',
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                ),
                if (hasLocalFile && !isUploadedToServer) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    height: 28,
                    child: OutlinedButton(
                      onPressed: isUploading ? null : () => _clearFile(type, title),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

// ✅ FIX: GET DOCUMENT SERVER STATUS - SAMA PERSIS DENGAN UPLOAD_DOKUMEN_SCREEN
Map<String, dynamic> _getDocumentServerStatus(String type) {
  String? documentUrl;
  
  switch (type) {
    case 'ktp':
      documentUrl = _currentUser['foto_ktp'];
      break;
    case 'kk':
      documentUrl = _currentUser['foto_kk'];
      break;
    case 'diri':
      documentUrl = _currentUser['foto_diri'];
      break;
  }
  
  // ✅ GUNAKAN LOGIC YANG SAMA PERSIS: CEK .jpg BUKAN http
  final isUploaded = documentUrl != null && 
                    documentUrl.toString().isNotEmpty && 
                    documentUrl != 'uploaded' &&
                    documentUrl.toString().contains('.jpg');
  
  print('🔍 Document $type server status: $documentUrl → $isUploaded');
  return {
    'uploaded': isUploaded,
    'url': isUploaded ? documentUrl : null,
  };
}

// ✅ INTEGRASI: SAFE SNACKBAR DENGAN MOUNTED CHECK
void _showSafeSnackBar(String message, {bool isError = false, int duration = 3}) {
  if (!mounted) {
    print('⚠️ Widget not mounted, skipping snackbar: $message');
    return;
  }
  
  try {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    print('❌ Error showing snackbar (safe): $e');
  }
}

// ✅ INTEGRASI: CEK STATUS DOKUMEN YANG LEBIH AKURAT
bool _isDocumentUploadedToServer(String type) {
  String? documentUrl;
  
  switch (type) {
    case 'ktp':
      documentUrl = _currentUser['foto_ktp'];
      break;
    case 'kk':
      documentUrl = _currentUser['foto_kk'];
      break;
    case 'diri':
      documentUrl = _currentUser['foto_diri'];
      break;
  }
  
  print('🔍 Document $type check: $documentUrl');
  
  // ✅ FIX: CEK LEBIH DETAIL
  if (documentUrl == null || documentUrl.toString().isEmpty) {
    return false;
  }
  
  final urlString = documentUrl.toString();
  
  // ✅ CEK BERBAGAI KONDISI YANG MENANDAKAN SUDAH UPLOAD
  final isUploaded = 
      // Ada filename dengan extension image
      (urlString.contains('.jpg') || 
       urlString.contains('.jpeg') || 
       urlString.contains('.png')) ||
      // Atau status uploaded
      urlString == 'uploaded' ||
      // Atau mengandung string tertentu
      urlString.contains('upload') ||
      // Atau panjang string menandakan filename
      (urlString.length > 10 && !urlString.contains('null'));
  
  print('   → Uploaded: $isUploaded');
  return isUploaded;
}

// ✅ INTEGRASI: VALIDASI SEBELUM UPLOAD
bool _validateBeforeUpload() {
  // ✅ CEK FILE LOKAL
  if (!_storageService.isAllFilesComplete) {
    _showSafeSnackBar('Harap lengkapi semua 3 dokumen terlebih dahulu', isError: true);
    return false;
  }

  // ✅ CEK APAKAH SUDAH DI SERVER
  final ktpServer = _isDocumentUploadedToServer('ktp');
  final kkServer = _isDocumentUploadedToServer('kk');
  final diriServer = _isDocumentUploadedToServer('diri');
  
  if (ktpServer && kkServer && diriServer) {
    _showSafeSnackBar('Semua dokumen sudah terupload ke server');
    return false;
  }

  // ✅ CEK FILE SIZE
  final ktpSize = _storageService.ktpFile?.lengthSync() ?? 0;
  final kkSize = _storageService.kkFile?.lengthSync() ?? 0;
  final diriSize = _storageService.diriFile?.lengthSync() ?? 0;

  if (ktpSize > 5 * 1024 * 1024 || kkSize > 5 * 1024 * 1024 || diriSize > 5 * 1024 * 1024) {
    _showSafeSnackBar('Ukuran file terlalu besar. Maksimal 5MB per file', isError: true);
    return false;
  }

  return true;
}

  // ✅ HELPER: SHORTEN URL UNTUK DISPLAY
  String _shortenUrl(String url) {
    if (url.length <= 30) return url;
    return '${url.substring(0, 15)}...${url.substring(url.length - 10)}';
  }

  // ✅ HELPER: GET DOCUMENT SERVER URL
String? _getDocumentServerUrl(String type) {
  switch (type) {
    case 'ktp':
      return _currentUser['foto_ktp'];
    case 'kk':
      return _currentUser['foto_kk'];
    case 'diri':
      return _currentUser['foto_diri'];
    default:
      return null;
  }
}

  // ✅ BUILD UPLOAD MANUAL SECTION - HANYA 3 FILE YANG DITAMPILKAN
  Widget _buildUploadManualSection() {
    final allFilesComplete = _storageService.isAllFilesComplete;
    final hasAnyFile = _storageService.hasAnyFile;

    // ✅ CEK APAKAH ADA FILE YANG BELUM TERUPLOAD KE SERVER
    final hasPendingUpload = hasAnyFile && 
        (!_getDocumentServerStatus('ktp')['uploaded'] || 
         !_getDocumentServerStatus('kk')['uploaded'] || 
         !_getDocumentServerStatus('diri')['uploaded']);

    if (!hasPendingUpload && !allFilesComplete) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                allFilesComplete ? 'Siap Upload 4 File!' : 'Upload Manual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            allFilesComplete 
                ? 'Semua 3 dokumen sudah lengkap. Sistem akan menambahkan 1 file dummy bukti otomatis. Total 4 file akan diupload ke server.'
                : 'Upload dokumen yang sudah dipilih atau lengkapi semua dokumen terlebih dahulu.',
            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _storageService.isUploading ? null : _uploadAllFiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: allFilesComplete ? Colors.green[700] : Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cloud_upload, size: 20),
              label: _storageService.isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      allFilesComplete ? 'Upload 4 File ke Server' : 'Upload Manual',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          if (!allFilesComplete) ...[
            const SizedBox(height: 8),
            Text(
              'File yang belum lengkap: ${_getMissingFilesList().join(', ')}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ HELPER: GET LIST OF MISSING FILES - HANYA 3 FILE YANG DITAMPILKAN
  List<String> _getMissingFilesList() {
    List<String> missing = [];
    if (!_storageService.hasKtpFile) missing.add('KTP');
    if (!_storageService.hasKkFile) missing.add('KK');
    if (!_storageService.hasDiriFile) missing.add('Foto Diri');
    return missing;
  }

  // ✅ HANDLE UPLOAD ERROR
  void _handleUploadError(dynamic e, String typeName) {
    setState(() {
      _uploadError = 'Error upload $typeName: $e';
    });
    
    print('❌ Upload failed: $e');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal upload $typeName: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ LOGOUT METHODS
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
      if (widget.onLogout != null) {
        widget.onLogout!();
        return;
      }
      _performDirectLogout();
    }
  }

  Future<void> _performDirectLogout() async {
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
      print('🔐 Logout result: $result');
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', 
          (Route<dynamic> route) => false
        );
      }
    } catch (e) {
      print('❌ Logout error: $e');
      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', 
          (Route<dynamic> route) => false
        );
      }
    }
  }

// ✅ UPDATE: REFRESH PROFILE YANG LEBIH ROBUST DENGAN getUserInfo
Future<void> _refreshProfile() async {
  try {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _uploadError = null;
      });
    }
    
    print('🔄 Manual refresh triggered with getUserInfo...');
    
    // ✅ LOAD DATA TERBARU DARI getUserInfo API
    await _loadUserInfoFromServer();
    
    // ✅ LOAD DATA TAMBAHAN DARI SUMBER LAIN
    await _loadCurrentUser();
    
    // ✅ PANGGIL CALLBACK JIKA ADA
    widget.onProfileUpdated?.call();
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
  } catch (e) {
    print('❌ Refresh error: $e');
    if (mounted) {
      setState(() => _isRefreshing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profile: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}


// ✅ UPDATE: BUILD PROFILE HEADER DENGAN UPLOAD PHOTO OPTION
Widget _buildProfileHeader() {
  return Center(
    child: Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _showProfilePhotoOptions,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green[50],
                backgroundImage: _getProfileImage(),
                child: _getProfilePlaceholder(),
              ),
            ),
            if (_isRefreshing || _isUploading)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _showProfilePhotoOptions,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
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
          textAlign: TextAlign.center,
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
          _isUploading ? 'Sedang mengupload...' : 
          _isRefreshing ? 'Memperbarui data...' : 'Tap foto untuk mengganti',
          style: TextStyle(
            color: _isUploading ? Colors.orange[700] : 
                  _isRefreshing ? Colors.blue[700] : Colors.grey[500],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ✅ METHOD BARU: SHOW PROFILE PHOTO OPTIONS
void _showProfilePhotoOptions() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ganti Foto Profil'),
      content: const Text('Pilih sumber untuk foto profil'),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _takeProfilePhoto();
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
                  _uploadProfilePhoto();
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

  // ✅ BUILD DOCUMENTS SECTION - HANYA 3 FILE YANG DITAMPILKAN
  Widget _buildDocumentsSection() {
    final allFilesComplete = _storageService.isAllFilesComplete;
    final uploadedCount = _countUploadedDocuments();

    print('📊 Document Section - Uploaded: $uploadedCount/3, All Complete: $allFilesComplete');

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
                  'Dokumen Wajib',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const Spacer(),
                Text(
                  '$uploadedCount/3',
                  style: TextStyle(
                    color: uploadedCount == 3 ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            
            // PROGRESS INDICATOR (SERVER STATUS) - HANYA 3 FILE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressStep(1, 'KTP', _getDocumentServerStatus('ktp')['uploaded']),
                Container(
                  width: 20, 
                  height: 2, 
                  color: _getDocumentServerStatus('ktp')['uploaded'] ? Colors.green : Colors.grey[300]
                ),
                _buildProgressStep(2, 'KK', _getDocumentServerStatus('kk')['uploaded']),
                Container(
                  width: 20, 
                  height: 2, 
                  color: _getDocumentServerStatus('kk')['uploaded'] ? Colors.green : Colors.grey[300]
                ),
                _buildProgressStep(3, 'Diri', _getDocumentServerStatus('diri')['uploaded']),
              ],
            ),
            const SizedBox(height: 20),

            // KTP CARD
            _buildDokumenCard(
              type: 'ktp',
              title: 'KTP (Kartu Tanda Penduduk)',
              description: 'Upload foto KTP yang jelas dan terbaca\n• Pastikan foto tidak blur\n• Semua informasi terbaca jelas\n• Format JPG/PNG (max 5MB)',
              icon: Icons.credit_card,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),

            // KK CARD
            _buildDokumenCard(
              type: 'kk',
              title: 'Kartu Keluarga (KK)',
              description: 'Upload foto KK yang jelas dan terbaca\n• Pastikan foto tidak blur\n• Semua halaman penting terbaca\n• Format JPG/PNG (max 5MB)',
              icon: Icons.family_restroom,
              color: Colors.green,
            ),
            const SizedBox(height: 16),

            // FOTO DIRI CARD
            _buildDokumenCard(
              type: 'diri',
              title: 'Foto Diri Terbaru',
              description: 'Upload pas foto terbaru\n• Latar belakang polos\n• Wajah terlihat jelas\n• Ekspresi netral\n• Format JPG/PNG (max 5MB)',
              icon: Icons.person,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),

            // UPLOAD MANUAL SECTION
            _buildUploadManualSection(),

            // UPLOAD STATUS
            if (_storageService.isUploading) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _storageService.uploadMessage,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // INFO STATUS
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Status Dokumen:',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Hijau: Sudah terverifikasi di server\n• Oranye: File lokal, belum diupload\n• Merah: Belum ada file',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Sistem akan mengupload 4 file (3 asli + 1 dummy)',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ HELPER: COUNT UPLOADED DOCUMENTS - GUNAKAN LOGIC YANG SAMA
  int _countUploadedDocuments() {
    int count = 0;
    if (_isDocumentUploadedToServer('ktp')) count++;
    if (_isDocumentUploadedToServer('kk')) count++;
    if (_isDocumentUploadedToServer('diri')) count++;
    return count;
  }

  // ✅ BUILD PERSONAL INFO SECTION
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

  // ✅ BUILD KTP ADDRESS SECTION
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

  // ✅ BUILD DOMISILI ADDRESS SECTION
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

  // ✅ BUILD COOPERATIVE INFO SECTION DENGAN USER KEY
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
            // ✅ TAMBAHKAN USER KEY DI SINI - FIXED
            _buildInfoTile(Icons.vpn_key, 'User Key', _getUserKeyDisplay(), maxLines: 2),
          ],
        ),
      ),
    );
  }

// ✅ BUILD SUPER API ACCESS SECTION
Widget _buildApiAccessSection() {
  // ✅ AMBIL DATA DARI SEMUA SUMBER YANG MUNGKIN
  final userKey = _currentUser['user_key']?.toString() ?? 
                 _currentUser['token']?.toString() ?? 
                 'Tidak tersedia';
  
  final userId = _currentUser['user_id']?.toString() ?? 
                _currentUser['id']?.toString() ?? 
                'Tidak tersedia';
  
  final username = _currentUser['username']?.toString() ?? 'Tidak tersedia';

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
              Icon(Icons.api, color: Colors.purple[700]),
              const SizedBox(width: 8),
              const Text(
                'API Access Information',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          
          // ✅ SYSTEM INFO
          _buildInfoTile(Icons.vpn_key, 'User Key', 
            userKey != 'Tidak tersedia' ? _getUserKeyDisplay(userKey) : 'Tidak tersedia', 
            maxLines: 2),
          
          _buildInfoTile(Icons.fingerprint, 'User ID', userId, maxLines: 1),
          _buildInfoTile(Icons.person, 'Username', username, maxLines: 1),
          
          const SizedBox(height: 16),
          
          if (userKey != 'Tidak tersedia') ...[
            Text(
              'Gunakan data berikut untuk testing API di Postman:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            
            // ✅ COPY USER KEY BUTTON
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () => _copyUserKeyToClipboard(userKey),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.content_copy, size: 20),
                label: const Text(
                  'Copy User Key',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // ✅ CURL COMMAND EXAMPLE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contoh curl command untuk getInbox:',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    'curl -X POST "http://demo.bsdeveloper.id/api/transaction/getAllinbox" \\\\\n'
                    '  -H "DEVICE-ID: 12341231313131" \\\\\n'
                    '  -H "x-api-key: $userKey" \\\\\n'
                    '  -H "Content-Type: application/x-www-form-urlencoded" \\\\\n'
                    '  -d ""',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 10,
                      fontFamily: 'Monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User ID: $userId | Username: $username',
                    style: TextStyle(
                      color: Colors.purple[600],
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildInfoTile(Icons.vpn_key, 'User Key', 'Tidak tersedia', maxLines: 1),
            const SizedBox(height: 8),
            Text(
              'User key tidak tersedia. Silakan refresh profile.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refreshProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
          ],
        ],
      ),
    ),
  );
}

// ✅ FIX: FUNCTION UNTUK DISPLAY USER KEY
String _getUserKeyDisplay([String? userKey]) {
  // Jika ada parameter, gunakan parameter
  if (userKey != null && userKey.isNotEmpty) {
    return userKey.length > 20 ? '${userKey.substring(0, 20)}...' : userKey;
  }
  
  // Jika tidak ada parameter, ambil dari _currentUser
  final keyFromUser = _currentUser['user_key']?.toString() ?? 
                     _currentUser['token']?.toString() ?? 
                     'Tidak tersedia';
  
  return keyFromUser.length > 20 ? '${keyFromUser.substring(0, 20)}...' : keyFromUser;
}

  // ✅ BUILD ACTION BUTTONS
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

// ✅ HELPER: BUILD INFO TILE YANG LEBIH SAFE
Widget _buildInfoTile(IconData icon, String label, String? value, {int maxLines = 1}) {
  final displayValue = value ?? '-';
  
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
                displayValue,
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

  // ✅ HELPER: BUILD PROGRESS STEP
  Widget _buildProgressStep(int step, String label, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
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

// ✅ HELPER: GET PROFILE IMAGE YANG LEBIH SAFE
ImageProvider? _getProfileImage() {
  try {
    final fotoDiri = _currentUser['foto_diri'];
    if (fotoDiri != null && 
        fotoDiri.toString().isNotEmpty && 
        fotoDiri != 'uploaded' &&
        fotoDiri.toString().startsWith('http')) {
      return NetworkImage(fotoDiri.toString());
    }
    return null;
  } catch (e) {
    print('❌ Error loading profile image: $e');
    return null;
  }
}

  // ✅ HELPER: GET PROFILE PLACEHOLDER
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

  // ✅ HELPER: FORMAT TANGGAL LAHIR
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

  // ✅ HELPER: GET KOTA NAME
  String? _getKotaName(dynamic kotaId) {
    if (kotaId == null) return null;
    return kotaId.toString();
  }

  // ✅ HELPER: GET TAHUN GABUNG
  String _getTahunGabung() {
    final now = DateTime.now();
    return now.year.toString();
  }

  // ✅ COPY USER KEY TO CLIPBOARD
  void _copyUserKeyToClipboard(String userKey) {
    // Import 'package:flutter/services.dart' di atas
    Clipboard.setData(ClipboardData(text: userKey));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User key berhasil disalin ke clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    print('📋 User key copied to clipboard: ${userKey.substring(0, 10)}...');
  }

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data profile...'),
          ],
        ),
      ),
    );
  }

  // ✅ CEK JIKA DATA USER MASIH KOSONG
  final hasUserData = _currentUser.isNotEmpty && 
                      (_currentUser['username'] != null || 
                       _currentUser['nama'] != null);

  if (!hasUserData) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Data profile tidak tersedia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan refresh atau login ulang',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
          ],
        ),
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
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
    ),
    body: RefreshIndicator(
      onRefresh: _refreshProfile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            _buildProfileHeader(),

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

            // ✅ INFORMASI KOPERASI (dengan user key)
            _buildCooperativeInfoSection(),

            const SizedBox(height: 16),

            // ✅ API ACCESS SECTION BARU
            _buildApiAccessSection(),

            const SizedBox(height: 30),

            // ✅ ACTION BUTTONS
            _buildActionButtons(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
}