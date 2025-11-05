import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String baseUrl = 'http://demo.bsdeveloper.id/api';
  
  String _deviceId = '12341231313131';
  String _deviceToken = '1234232423424';

  final ImagePicker _imagePicker = ImagePicker();

  // ✅ GET AUTH HEADERS UNTUK REQUEST TANPA TOKEN
  Map<String, String> getAuthHeaders() {
    return {
      'DEVICE-ID': _deviceId,
      'DEVICE-TOKEN': _deviceToken,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  // ✅ GET PROTECTED HEADERS DENGAN TOKEN
  Future<Map<String, String>> getProtectedHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = prefs.getString('token');
      final sessionCookie = prefs.getString('ci_session');
      
      final headers = <String, String>{
        'DEVICE-ID': _deviceId,
        'DEVICE-TOKEN': _deviceToken,
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      
      if (userKey != null && userKey.isNotEmpty) {
        headers['x-api-key'] = userKey;
      } else {
        print('⚠️ Token tidak ditemukan di SharedPreferences');
      }
      
      // Tambahkan cookie session jika ada
      if (sessionCookie != null && sessionCookie.isNotEmpty) {
        headers['Cookie'] = 'ci_session=$sessionCookie';
      }
      
      return headers;
    } catch (e) {
      print('❌ Error getProtectedHeaders: $e');
      return {
        'DEVICE-ID': _deviceId,
        'DEVICE-TOKEN': _deviceToken,
        'Content-Type': 'application/x-www-form-urlencoded',
      };
    }
  }

  // ✅ GET MULTIPART HEADERS UNTUK UPLOAD FILE
  Future<Map<String, String>> getMultipartHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = prefs.getString('token');
      final sessionCookie = prefs.getString('ci_session');
      
      final headers = <String, String>{
        'DEVICE-ID': _deviceId,
        'DEVICE-TOKEN': _deviceToken,
      };
      
      if (userKey != null && userKey.isNotEmpty) {
        headers['x-api-key'] = userKey;
      }
      
      // Tambahkan cookie session jika ada
      if (sessionCookie != null && sessionCookie.isNotEmpty) {
        headers['Cookie'] = 'ci_session=$sessionCookie';
      }
      
      return headers;
    } catch (e) {
      print('❌ Error getMultipartHeaders: $e');
      return {
        'DEVICE-ID': _deviceId,
        'DEVICE-TOKEN': _deviceToken,
      };
    }
  }

  // ✅ METHOD UNTUK PILIH GAMBAR DARI GALLERY
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        print('📁 Image selected: ${image.path}');
        
        File file = File(image.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          print('📁 File size: $fileSize bytes');
          
          if (fileSize > 0) {
            return image.path;
          } else {
            print('❌ File kosong');
            return null;
          }
        } else {
          print('❌ File tidak ditemukan');
          return null;
        }
      } else {
        print('❌ User cancel pemilihan gambar');
        return null;
      }
    } catch (e) {
      print('❌ Error pick image: $e');
      return null;
    }
  }

  // ✅ METHOD UNTUK AMBIL FOTO DARI KAMERA
  Future<String?> takePhotoFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (photo != null) {
        print('📸 Photo taken: ${photo.path}');
        
        File file = File(photo.path);
        if (await file.exists()) {
          return photo.path;
        } else {
          print('❌ File tidak ditemukan');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error take photo: $e');
      return null;
    }
  }

  // ✅ METHOD UNTUK MENDAPATKAN PATH FILE DUMMY (test.jpg)
  Future<String?> getDummyFilePath() async {
    try {
      // Coba beberapa lokasi yang mungkin untuk test.jpg
      final possiblePaths = [
        'test.jpg',
        './test.jpg',
        '../test.jpg',
        'assets/test.jpg',
        'images/test.jpg',
      ];

      for (var path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          print('✅ Dummy file found: $path');
          return path;
        }
      }

      print('❌ Dummy file (test.jpg) tidak ditemukan di project');
      return null;
    } catch (e) {
      print('❌ Error getting dummy file: $e');
      return null;
    }
  }

  // ✅ CREATE DUMMY FILE JIKA TIDAK ADA
  Future<String?> createDummyFile() async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/test.jpg');
      
      // Buat file dummy dengan konten kosong
      await file.writeAsBytes(List.generate(100, (index) => 0));
      
      if (await file.exists()) {
        print('✅ Dummy file created: ${file.path}');
        return file.path;
      }
      
      return null;
    } catch (e) {
      print('❌ Error creating dummy file: $e');
      return null;
    }
  }

  // ✅ GET TEMPORARY DIRECTORY
  Future<Directory> getTemporaryDirectory() async {
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  // ========== METHOD BARU UNTUK UPLOAD YANG BENAR ==========

  // ✅ UPLOAD DOKUMEN: 3 FILE ASLI + 1 DUMMY
  Future<Map<String, dynamic>> uploadDokumenLengkap({
    required String fotoKtpPath,    // ASLI
    required String fotoKkPath,     // ASLI  
    required String fotoDiriPath,   // ASLI
    required String dummyFilePath,  // DUMMY untuk bukti
  }) async {
    try {
      print('🚀 UPLOAD DOKUMEN: 3 ASLI + 1 DUMMY');
      print('📁 KTP: $fotoKtpPath');
      print('📁 KK: $fotoKkPath');
      print('📁 Foto Diri: $fotoDiriPath');
      print('📁 Dummy Bukti: $dummyFilePath');

      // Validasi semua file
      final filesToValidate = {
        'foto_ktp': fotoKtpPath,
        'foto_kk': fotoKkPath,
        'foto_diri': fotoDiriPath,
        'foto_bukti': dummyFilePath,
      };

      for (var entry in filesToValidate.entries) {
        final file = File(entry.value);
        if (!await file.exists()) {
          return {
            'success': false,
            'message': 'File ${entry.key} tidak ditemukan: ${entry.value}'
          };
        }
      }

      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {'success': false, 'message': 'User tidak ditemukan'};
      }

      final headers = await getMultipartHeaders();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/setPhoto'));
      request.headers.addAll(headers);

      // Tambahkan 4 file
      request.files.add(await http.MultipartFile.fromPath('foto_ktp', fotoKtpPath));
      request.files.add(await http.MultipartFile.fromPath('foto_kk', fotoKkPath));
      request.files.add(await http.MultipartFile.fromPath('foto_diri', fotoDiriPath));
      request.files.add(await http.MultipartFile.fromPath('foto_bukti', dummyFilePath));

      // Tambahkan form fields
      request.fields['type'] = 'foto_ktp';
      request.fields['user_id'] = currentUser['user_id']?.toString() ?? '';
      request.fields['user_key'] = currentUser['user_key']?.toString() ?? '';

      final response = await request.send().timeout(Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Upload dokumen berhasil',
          'data': data
        };
      } else {
        return {'success': false, 'message': 'Upload gagal: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

// ✅ UPLOAD BUKTI TABUNGAN: 4 FILE SAMA DARI BUKTI TRANSFER
Future<Map<String, dynamic>> uploadBuktiTabunganFourFiles({
  required String transaksiId,
  required String jenisTransaksi,
  required String buktiTransferPath,
}) async {
  try {
    print('🚀 UPLOAD BUKTI TABUNGAN START (4 FILE SAMA)');
    print('📁 Transaksi ID: $transaksiId');
    print('📁 Jenis Transaksi: $jenisTransaksi');
    print('📁 Bukti Transfer: $buktiTransferPath');

    // ✅ VALIDASI FILE BUKTI TRANSFER
    final fileBukti = File(buktiTransferPath);
    if (!await fileBukti.exists()) {
      return {'success': false, 'message': 'File bukti transfer tidak ditemukan'};
    }

    final fileSize = await fileBukti.length();
    if (fileSize == 0) {
      return {'success': false, 'message': 'File bukti transfer kosong'};
    }

    print('✅ File bukti valid, size: $fileSize bytes');

    // ✅ GET HEADERS
    final headers = await getMultipartHeaders();
    
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/transaction/uploadBukti')
    );
    request.headers.addAll(headers);

    // ✅ TAMBAHKAN 4 FILE SAMA DENGAN FIELD NAME YANG BERBEDA
    try {
      // ✅ FILE 1: bukti_transfer (FIELD UTAMA)
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_transfer',
        buktiTransferPath,
        filename: 'bukti_${jenisTransaksi}_main_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // ✅ FILE 2: foto_ktp (COPY DARI BUKTI TRANSFER)
      request.files.add(await http.MultipartFile.fromPath(
        'foto_ktp',
        buktiTransferPath,
        filename: 'bukti_${jenisTransaksi}_ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // ✅ FILE 3: foto_kk (COPY DARI BUKTI TRANSFER)
      request.files.add(await http.MultipartFile.fromPath(
        'foto_kk',
        buktiTransferPath,
        filename: 'bukti_${jenisTransaksi}_kk_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // ✅ FILE 4: foto_diri (COPY DARI BUKTI TRANSFER)
      request.files.add(await http.MultipartFile.fromPath(
        'foto_diri',
        buktiTransferPath,
        filename: 'bukti_${jenisTransaksi}_diri_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      print('✅ 4 file berhasil ditambahkan (sama-sama dari bukti transfer)');
    } catch (e) {
      print('❌ Gagal menambahkan file: $e');
      return {
        'success': false,
        'message': 'Gagal menambahkan file: $e'
      };
    }

    // ✅ TAMBAHKAN FORM FIELDS
    request.fields['transaksi_id'] = transaksiId;
    request.fields['jenis_transaksi'] = jenisTransaksi;
    
    // ✅ TAMBAHKAN USER DATA
    final currentUser = await getCurrentUser();
    if (currentUser != null && currentUser['user_id'] != null) {
      request.fields['user_id'] = currentUser['user_id'].toString();
    }

    print('📤 Request fields: ${request.fields}');
    print('📤 Total files: ${request.files.length}');

    // ✅ KIRIM REQUEST
    print('🔄 Mengirim request ke server...');
    final response = await request.send().timeout(const Duration(seconds: 60));
    final responseBody = await response.stream.bytesToString();
    
    print('📡 Response Status: ${response.statusCode}');
    print('📡 Response Body: $responseBody');

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      
      if (data['status'] == true) {
        print('✅ UPLOAD BUKTI TABUNGAN SUCCESS (4 FILE SAMA)');
        return {
          'success': true,
          'message': data['message'] ?? 'Bukti tabungan berhasil diupload',
          'data': data
        };
      } else {
        print('❌ Upload gagal: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Upload bukti tabungan gagal'
        };
      }
    } else {
      print('❌ Server error: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Upload gagal: ${response.statusCode}'
      };
    }
  } catch (e) {
    print('❌ UPLOAD BUKTI TABUNGAN ERROR: $e');
    return {
      'success': false,
      'message': 'Upload error: $e'
    };
  }
}

  // ========== METHOD UNTUK TEMPORARY STORAGE SERVICE ==========

// ✅ TAMBAHKAN METHOD INI DI ApiService
Future<Map<String, dynamic>> uploadFourPhotos({
  required String userId,
  required String userKey,
  required String fotoKtpPath,
  required String fotoKkPath,
  required String fotoDiriPath,
  required String fotoBuktiPath,
}) async {
  try {
    print('🚀 UPLOAD 4 FOTO START');
    print('👤 User ID: $userId');
    print('🔑 User Key: ${userKey.substring(0, 10)}...');
    print('📁 Files to upload:');
    print('   - foto_ktp: $fotoKtpPath');
    print('   - foto_kk: $fotoKkPath');
    print('   - foto_diri: $fotoDiriPath');
    print('   - foto_bukti: $fotoBuktiPath');

    // ✅ VALIDASI SEMUA FILE SEBELUM UPLOAD
    final filesToValidate = {
      'foto_ktp': fotoKtpPath,
      'foto_kk': fotoKkPath,
      'foto_diri': fotoDiriPath,
      'foto_bukti': fotoBuktiPath,
    };

    for (var entry in filesToValidate.entries) {
      final file = File(entry.value);
      if (!await file.exists()) {
        return {
          'success': false,
          'message': 'File ${entry.key} tidak ditemukan: ${entry.value}'
        };
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        return {
          'success': false,
          'message': 'File ${entry.key} kosong'
        };
      }
    }

    // ✅ GET HEADERS
    final headers = await getMultipartHeaders();
    
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/users/setPhoto')
    );
    request.headers.addAll(headers);

    // ✅ TAMBAHKAN SEMUA FILE KE REQUEST
    try {
      // ✅ foto_ktp
      request.files.add(await http.MultipartFile.fromPath(
        'foto_ktp',
        fotoKtpPath,
        filename: 'foto_ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // ✅ foto_kk
      request.files.add(await http.MultipartFile.fromPath(
        'foto_kk',
        fotoKkPath,
        filename: 'foto_kk_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // ✅ foto_diri
      request.files.add(await http.MultipartFile.fromPath(
        'foto_diri',
        fotoDiriPath,
        filename: 'foto_diri_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // ✅ foto_bukti
      request.files.add(await http.MultipartFile.fromPath(
        'foto_bukti',
        fotoBuktiPath,
        filename: 'foto_bukti_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      print('✅ Semua file berhasil ditambahkan');
    } catch (e) {
      print('❌ Gagal menambahkan file: $e');
      return {
        'success': false,
        'message': 'Gagal menambahkan file: $e'
      };
    }

    // ✅ TAMBAHKAN FORM FIELDS
    request.fields['type'] = 'foto_ktp';
    request.fields['user_id'] = userId;
    request.fields['user_key'] = userKey;

    print('📤 Request fields: ${request.fields}');
    print('📤 Total files: ${request.files.length}');

    // ✅ KIRIM REQUEST
    final response = await request.send().timeout(const Duration(seconds: 60));
    final responseBody = await response.stream.bytesToString();
    
    print('📡 Response Status: ${response.statusCode}');
    print('📡 Response Body: $responseBody');

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      
      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Semua foto berhasil diupload',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Upload foto gagal'
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Server error ${response.statusCode}: $responseBody'
      };
    }
  } catch (e) {
    print('❌ UPLOAD 4 FOTO ERROR: $e');
    return {
      'success': false,
      'message': 'Upload foto error: $e'
    };
  }
}

// ✅ PASTIKAN FIELD NAME SESUAI DENGAN BACKEND
Future<Map<String, dynamic>> uploadFourPhotosWithUser({
  required String fotoKtpPath,
  required String fotoKkPath,
  required String fotoDiriPath,
  required String fotoBuktiPath,
}) async {
  try {
    final currentUser = await getCurrentUserForUpload();
    if (currentUser == null) {
      return {'success': false, 'message': 'User tidak ditemukan'};
    }

    final userId = currentUser['user_id']?.toString();
    final userKey = currentUser['user_key']?.toString();

    if (userId == null || userKey == null) {
      return {'success': false, 'message': 'Data user tidak lengkap'};
    }

    return await uploadFourPhotos(
      userId: userId,
      userKey: userKey,
      fotoKtpPath: fotoKtpPath,
      fotoKkPath: fotoKkPath,
      fotoDiriPath: fotoDiriPath,
      fotoBuktiPath: fotoBuktiPath, // ✅ INI AKAN JADI FILE KE-4
    );
  } catch (e) {
    return {'success': false, 'message': 'Upload error: $e'};
  }
}

  Future<Map<String, dynamic>> uploadSinglePhotoWithUser({
    required String type,
    required String filePath,
  }) async {
    return await uploadFoto(type: type, filePath: filePath);
  }

  // ========== SEMUA METHOD LAMA DARI CODE AWAL ==========

  // ✅ PERBAIKAN BESAR: Upload 4 Foto Sekaligus sesuai curl command
  Future<Map<String, dynamic>> uploadFourPhotosOriginal({
    required String userId,
    required String userKey,
    required String fotoKtpPath,
    required String fotoKkPath,
    required String fotoDiriPath,
    required String fotoBuktiPath,
  }) async {
    try {
      print('🚀 UPLOAD 4 FOTO START');
      print('👤 User ID: $userId');
      print('🔑 User Key: ${userKey.substring(0, 10)}...');
      print('📁 Files to upload:');
      print('   - foto_ktp: $fotoKtpPath');
      print('   - foto_kk: $fotoKkPath');
      print('   - foto_diri: $fotoDiriPath');
      print('   - foto_bukti: $fotoBuktiPath');

      // ✅ VALIDASI SEMUA FILE SEBELUM UPLOAD
      final filesToValidate = {
        'foto_ktp': fotoKtpPath,
        'foto_kk': fotoKkPath,
        'foto_diri': fotoDiriPath,
        'foto_bukti': fotoBuktiPath,
      };

      for (var entry in filesToValidate.entries) {
        final file = File(entry.value);
        if (!await file.exists()) {
          return {
            'success': false,
            'message': 'File ${entry.key} tidak ditemukan: ${entry.value}'
          };
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          return {
            'success': false,
            'message': 'File ${entry.key} kosong'
          };
        }

        // Validasi format file
        final fileExtension = entry.value.toLowerCase().split('.').last;
        final allowedExtensions = ['jpg', 'jpeg', 'png'];
        if (!allowedExtensions.contains(fileExtension)) {
          return {
            'success': false,
            'message': 'Format file .$fileExtension tidak didukung untuk ${entry.key}. Gunakan JPG, JPEG, atau PNG.'
          };
        }
      }

      // ✅ GET HEADERS
      final headers = await getMultipartHeaders();
      print('📤 Headers: ${headers.keys}');
      print('📤 x-api-key: ${headers['x-api-key']?.substring(0, 10)}...');

      // ✅ BUAT MULTIPART REQUEST
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/setPhoto')
      );
      request.headers.addAll(headers);

      // ✅ TAMBAHKAN SEMUA FILE KE REQUEST DENGAN FIELD NAME YANG BENAR
      try {
        // ✅ foto_ktp
        var multipartFileKtp = await http.MultipartFile.fromPath(
          'foto_ktp',
          fotoKtpPath,
          filename: 'foto_ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFileKtp);
        print('✅ Added foto_ktp: $fotoKtpPath');

        // ✅ foto_kk
        var multipartFileKk = await http.MultipartFile.fromPath(
          'foto_kk',
          fotoKkPath,
          filename: 'foto_kk_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFileKk);
        print('✅ Added foto_kk: $fotoKkPath');

        // ✅ foto_diri
        var multipartFileDiri = await http.MultipartFile.fromPath(
          'foto_diri',
          fotoDiriPath,
          filename: 'foto_diri_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFileDiri);
        print('✅ Added foto_diri: $fotoDiriPath');

        // ✅ foto_bukti
        var multipartFileBukti = await http.MultipartFile.fromPath(
          'foto_bukti',
          fotoBuktiPath,
          filename: 'foto_bukti_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFileBukti);
        print('✅ Added foto_bukti: $fotoBuktiPath');

      } catch (e) {
        print('❌ Gagal menambahkan file ke request: $e');
        return {
          'success': false, 
          'message': 'Gagal menambahkan file ke request: $e'
        };
      }

      // ✅ TAMBAHKAN FORM FIELDS SESUAI CURL COMMAND
      request.fields['type'] = 'foto_ktp'; // Sesuai curl command
      request.fields['user_id'] = userId;
      request.fields['user_key'] = userKey;

      print('📤 Request fields: ${request.fields}');
      print('📤 Total files: ${request.files.length}');

      // ✅ KIRIM REQUEST
      print('🔄 Mengirim request ke: $baseUrl/users/setPhoto');
      final response = await request.send().timeout(const Duration(seconds: 60));
      
      // ✅ BACA RESPONSE
      final responseBody = await response.stream.bytesToString();
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        
        if (data['status'] == true) {
          print('✅ UPLOAD 4 FOTO SUCCESS');
          
          return {
            'success': true,
            'message': data['message'] ?? 'Semua foto berhasil diupload',
            'data': data
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Upload foto gagal'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error ${response.statusCode}: $responseBody'
        };
      }
    } catch (e) {
      print('❌ UPLOAD 4 FOTO ERROR: $e');
      return {
        'success': false,
        'message': 'Upload foto error: $e'
      };
    }
  }

  // ✅ UPLOAD DOKUMEN LENGKAP: 3 ASLI + 1 DUMMY (test.jpg)
  Future<Map<String, dynamic>> uploadDokumenLengkapOriginal({
    required String userId,
    required String userKey,
    required String fotoKtpPath,    // ASLI
    required String fotoKkPath,     // ASLI  
    required String fotoDiriPath,   // ASLI
    required String dummyFilePath,  // DUMMY (test.jpg dari project)
  }) async {
    try {
      print('🚀 UPLOAD DOKUMEN LENGKAP START (3 ASLI + 1 DUMMY)');
      print('👤 User ID: $userId');
      print('📁 Files to upload:');
      print('   - foto_ktp (ASLI): $fotoKtpPath');
      print('   - foto_kk (ASLI): $fotoKkPath');
      print('   - foto_diri (ASLI): $fotoDiriPath');
      print('   - foto_bukti (DUMMY): $dummyFilePath');

      // ✅ VALIDASI FILE ASLI
      final filesToValidate = {
        'foto_ktp': fotoKtpPath,
        'foto_kk': fotoKkPath,
        'foto_diri': fotoDiriPath,
        'foto_bukti': dummyFilePath,
      };

      for (var entry in filesToValidate.entries) {
        final file = File(entry.value);
        if (!await file.exists()) {
          return {
            'success': false,
            'message': 'File ${entry.key} tidak ditemukan: ${entry.value}'
          };
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          return {
            'success': false,
            'message': 'File ${entry.key} kosong'
          };
        }
      }

      // ✅ GET HEADERS
      final headers = await getMultipartHeaders();
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/setPhoto')
      );
      request.headers.addAll(headers);

      // ✅ TAMBAHKAN SEMUA FILE
      try {
        // ✅ foto_ktp (ASLI)
        request.files.add(await http.MultipartFile.fromPath(
          'foto_ktp',
          fotoKtpPath,
          filename: 'foto_ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        // ✅ foto_kk (ASLI)
        request.files.add(await http.MultipartFile.fromPath(
          'foto_kk',
          fotoKkPath,
          filename: 'foto_kk_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        // ✅ foto_diri (ASLI)
        request.files.add(await http.MultipartFile.fromPath(
          'foto_diri',
          fotoDiriPath,
          filename: 'foto_diri_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        // ✅ foto_bukti (DUMMY)
        request.files.add(await http.MultipartFile.fromPath(
          'foto_bukti',
          dummyFilePath,
          filename: 'foto_bukti_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        print('✅ Semua file berhasil ditambahkan');
      } catch (e) {
        print('❌ Gagal menambahkan file: $e');
        return {
          'success': false,
          'message': 'Gagal menambahkan file: $e'
        };
      }

      // ✅ TAMBAHKAN FORM FIELDS
      request.fields['type'] = 'foto_ktp';
      request.fields['user_id'] = userId;
      request.fields['user_key'] = userKey;

      print('📤 Request fields: ${request.fields}');
      print('📤 Total files: ${request.files.length}');

      // ✅ KIRIM REQUEST
      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();
      
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Dokumen lengkap berhasil diupload',
            'data': data
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Upload dokumen gagal'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Upload dokumen gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ UPLOAD DOKUMEN LENGKAP ERROR: $e');
      return {
        'success': false,
        'message': 'Upload dokumen error: $e'
      };
    }
  }

  // ✅ FIX: CEK STATUS DOKUMEN YANG BENAR
Map<String, dynamic> _getDokumenStatus(Map<String, dynamic> user) {
  final ktp = user['foto_ktp'];
  final kk = user['foto_kk'];
  final diri = user['foto_diri'];
  final bukti = user['foto_bukti'];
  
  print('🐛 === DOCUMENT STATUS DEBUG ===');
  print('📄 KTP Status: $ktp');
  print('📄 KK Status: $kk');
  print('📄 Foto Diri Status: $diri');
  print('📄 Foto Bukti Status: $bukti');
  
  // ✅ FIX: CEK APAKAH FILE SUDAH ADA DI SERVER
  final hasKTP = ktp != null && 
                ktp.toString().isNotEmpty && 
                ktp != 'uploaded' &&
                ktp.toString().contains('.jpg');
  
  final hasKK = kk != null && 
               kk.toString().isNotEmpty && 
               kk != 'uploaded' &&
               kk.toString().contains('.jpg');
  
  final hasDiri = diri != null && 
                 diri.toString().isNotEmpty && 
                 diri != 'uploaded' &&
                 diri.toString().contains('.jpg');
  
  final hasBukti = bukti != null && 
                  bukti.toString().isNotEmpty && 
                  bukti != 'uploaded' &&
                  bukti.toString().contains('.jpg');
  
  print('✅ KTP Uploaded: $hasKTP');
  print('✅ KK Uploaded: $hasKK');
  print('✅ Foto Diri Uploaded: $hasDiri');
  print('✅ Foto Bukti Uploaded: $hasBukti');
  print('🐛 === DEBUG END ===');
  
  return {
    'ktp': hasKTP,
    'kk': hasKK,
    'diri': hasDiri,
    'bukti': hasBukti,
    'allComplete': hasKTP && hasKK && hasDiri && hasBukti,
  };
}

  // ✅ UPLOAD BUKTI TRANSFER: 3 DUMMY + 1 ASLI
  Future<Map<String, dynamic>> uploadBuktiTransferLengkap({
    required String transaksiId,
    required String jenisTransaksi,
    required String buktiTransferAsliPath, // ASLI
    required String dummyFilePath1,        // DUMMY 1
    required String dummyFilePath2,        // DUMMY 2  
    required String dummyFilePath3,        // DUMMY 3
  }) async {
    try {
      print('🚀 UPLOAD BUKTI TRANSFER LENGKAP START (3 DUMMY + 1 ASLI)');
      print('📁 Transaksi ID: $transaksiId');
      print('📁 Jenis: $jenisTransaksi');
      print('📁 Files to upload:');
      print('   - bukti_transfer (ASLI): $buktiTransferAsliPath');
      print('   - dummy_1: $dummyFilePath1');
      print('   - dummy_2: $dummyFilePath2');
      print('   - dummy_3: $dummyFilePath3');

      // ✅ VALIDASI SEMUA FILE
      final filesToValidate = {
        'bukti_transfer': buktiTransferAsliPath,
        'dummy_1': dummyFilePath1,
        'dummy_2': dummyFilePath2,
        'dummy_3': dummyFilePath3,
      };

      for (var entry in filesToValidate.entries) {
        final file = File(entry.value);
        if (!await file.exists()) {
          return {
            'success': false,
            'message': 'File ${entry.key} tidak ditemukan: ${entry.value}'
          };
        }
      }

      // ✅ GET HEADERS
      final headers = await getMultipartHeaders();
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/transaction/uploadBukti')
      );
      request.headers.addAll(headers);

      // ✅ TAMBAHKAN SEMUA FILE
      try {
        // ✅ bukti_transfer (ASLI)
        request.files.add(await http.MultipartFile.fromPath(
          'bukti_transfer',
          buktiTransferAsliPath,
          filename: 'bukti_${jenisTransaksi}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        // ✅ DUMMY 1
        request.files.add(await http.MultipartFile.fromPath(
          'foto_dummy_1',
          dummyFilePath1,
          filename: 'dummy_1_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        // ✅ DUMMY 2
        request.files.add(await http.MultipartFile.fromPath(
          'foto_dummy_2',
          dummyFilePath2,
          filename: 'dummy_2_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        // ✅ DUMMY 3
        request.files.add(await http.MultipartFile.fromPath(
          'foto_dummy_3',
          dummyFilePath3,
          filename: 'dummy_3_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        print('✅ Semua file bukti transfer berhasil ditambahkan');
      } catch (e) {
        print('❌ Gagal menambahkan file bukti: $e');
        return {
          'success': false,
          'message': 'Gagal menambahkan file bukti: $e'
        };
      }

      // ✅ TAMBAHKAN FORM FIELDS
      request.fields['transaksi_id'] = transaksiId;
      request.fields['jenis_transaksi'] = jenisTransaksi;
      
      // ✅ TAMBAHKAN USER DATA
      final currentUser = await getCurrentUser();
      if (currentUser != null && currentUser['user_id'] != null) {
        request.fields['user_id'] = currentUser['user_id'].toString();
      }

      print('📤 Request fields: ${request.fields}');
      print('📤 Total files: ${request.files.length}');

      // ✅ KIRIM REQUEST
      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();
      
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Bukti transfer berhasil diupload',
            'data': data
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Upload bukti transfer gagal'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Upload bukti transfer gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ UPLOAD BUKTI TRANSFER ERROR: $e');
      return {
        'success': false,
        'message': 'Upload bukti transfer error: $e'
      };
    }
  }

  // ✅ METHOD SINGLE UPLOAD (backward compatibility)
  Future<Map<String, dynamic>> uploadFoto({
    required String type,
    required String filePath,
  }) async {
    try {
      print('🚀 SINGLE UPLOAD START: $type');
      print('📁 File path: $filePath');
      
      File file = File(filePath);
      if (!await file.exists()) {
        return {
          'success': false, 
          'message': 'File tidak ditemukan: $filePath'
        };
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        return {
          'success': false, 
          'message': 'File kosong'
        };
      }

      final headers = await getMultipartHeaders();
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/setPhoto')
      );
      request.headers.addAll(headers);

      String usedFieldName = 'foto';
      
      try {
        var multipartFile = await http.MultipartFile.fromPath(
          usedFieldName,
          filePath,
          filename: '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
        print('✅ File berhasil dilampirkan dengan field: $usedFieldName');
      } catch (e) {
        print('❌ Gagal dengan field $usedFieldName: $e');
        return {
          'success': false, 
          'message': 'Gagal menambahkan file ke request'
        };
      }

      request.fields['type'] = type;
      
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        if (currentUser['user_id'] != null) {
          request.fields['user_id'] = currentUser['user_id'].toString();
        }
        if (currentUser['user_key'] != null) {
          request.fields['user_key'] = currentUser['user_key'].toString();
        }
      }

      print('📤 Request fields: ${request.fields}');
      print('📤 Files count: ${request.files.length}');

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Upload berhasil',
            'data': data,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Upload gagal',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error ${response.statusCode}: $responseBody',
        };
      }
    } catch (e) {
      print('❌ UPLOAD ERROR: $e');
      return {
        'success': false,
        'message': 'Upload error: $e'
      };
    }
  }

// ✅ FIX: GET USER DATA DENGAN PRIORITAS DATA LOGIN
Future<Map<String, dynamic>?> getCurrentUserForUpload() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    print('🔍 Getting user data for upload...');
    
    // ✅ PRIORITAS 1: CEK DATA LOGIN (YANG ADA user_id dan user_key)
    final loginUserString = prefs.getString('login_user');
    if (loginUserString != null && loginUserString.isNotEmpty) {
      final loginData = jsonDecode(loginUserString);
      if (loginData['user'] != null) {
        final userData = loginData['user'];
        print('✅ Using login user data:');
        print('   - user_id: ${userData['user_id']}');
        print('   - user_key: ${userData['user_key']?.substring(0, 10)}...');
        return userData;
      }
    }
    
    // ✅ PRIORITAS 2: CEK USER DATA BIASA
    final userString = prefs.getString('user');
    if (userString != null && userString.isNotEmpty) {
      final userData = jsonDecode(userString);
      print('⚠️ Using regular user data (may lack user_id/user_key):');
      print('   - Available keys: ${userData.keys}');
      return userData;
    }
    
    print('❌ No user data found in storage');
    return null;
  } catch (e) {
    print('❌ Error getting user data for upload: $e');
    return null;
  }
}

// ✅ FIX: SIMPAN DATA LOGIN DENGAN BENAR
Future<void> saveLoginData(Map<String, dynamic> loginResponse) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    print('💾 Saving login data...');
    
    // Simpan token
    if (loginResponse['token'] != null) {
      await prefs.setString('token', loginResponse['token']);
      print('   ✅ Token saved');
    }
    
    // ✅ SIMPAN USER DATA LENGKAP (DENGAN user_id DAN user_key)
    if (loginResponse['user'] != null) {
      final userData = loginResponse['user'];
      await prefs.setString('user', jsonEncode(userData));
      print('   ✅ User data saved with keys: ${userData.keys}');
    }
    
    // ✅ SIMPAN SEBAGAI login_user UNTUK BACKUP
    await prefs.setString('login_user', jsonEncode(loginResponse));
    print('   ✅ Login response saved as backup');
    
    // ✅ DEBUG: CEK DATA YANG DISIMPAN
    final savedUser = prefs.getString('user');
    final savedLogin = prefs.getString('login_user');
    
    print('📦 Storage check:');
    print('   - User data: ${savedUser != null ? "✅" : "❌"}');
    print('   - Login data: ${savedLogin != null ? "✅" : "❌"}');
    
    if (loginResponse['user'] != null) {
      final user = loginResponse['user'];
      print('👤 Final saved user data:');
      print('   - user_id: ${user['user_id']}');
      print('   - user_key: ${user['user_key']?.substring(0, 10)}...');
      print('   - username: ${user['username']}');
    }
  } catch (e) {
    print('❌ Error saving login data: $e');
  }
}

  // ✅ GET CURRENT USER FROM LOCAL STORAGE
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null && userString.isNotEmpty) {
        return jsonDecode(userString);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // ✅ CLEAR TOKEN
  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      await prefs.remove('ci_session');
      print('🔐 Token cleared due to expiration');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }

  // ✅ LOGIN METHOD
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final headers = getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/login/auth'),
        headers: headers,
        body: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          final userKey = data['user_key'].toString();
          final userData = {
            'user_id': data['user_id'],
            'user_name': data['user_name'],
            'nama': data['nama'],
            'email': data['email'],
            'status_user': data['status_user'],
            'user_key': userKey,
          };

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', userKey);
          await prefs.setString('user', jsonEncode(userData));
          
          if (response.headers['set-cookie'] != null) {
            final cookies = response.headers['set-cookie'];
            if (cookies != null && cookies.contains('ci_session')) {
              final sessionMatch = RegExp(r'ci_session=([^;]+)').firstMatch(cookies);
              if (sessionMatch != null) {
                final sessionValue = sessionMatch.group(1);
                await prefs.setString('ci_session', sessionValue!);
                print('✅ CI Session saved: ${sessionValue.substring(0, 10)}...');
              }
            }
          }
          
          return {
            'success': true,
            'token': userKey,
            'user': userData,
            'message': data['message'] ?? 'Login berhasil'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Username atau password salah'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Terjadi kesalahan server (${response.statusCode})'
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Tidak ada koneksi internet'
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server'
      };
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // ✅ LOGOUT METHOD
  Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/logout'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 5));

    } catch (e) {
      print('🔐 Logout API call failed: $e');
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      await prefs.remove('ci_session');
      await prefs.clear();
      
      return {
        'success': true,
        'message': 'Logout berhasil'
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menghapus data local'
      };
    }
  }

  // ✅ GET USER PROFILE
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await getProtectedHeaders();
      
      final prefs = await SharedPreferences.getInstance();
      final sessionCookie = prefs.getString('ci_session');
      
      var finalHeaders = Map<String, String>.from(headers);
      if (sessionCookie != null && sessionCookie.isNotEmpty) {
        finalHeaders['Cookie'] = 'ci_session=$sessionCookie';
      }
      
      print('🚀 Fetching user profile...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/userInfo'),
        headers: finalHeaders,
        body: '',
      ).timeout(const Duration(seconds: 30));

      print('📡 Profile API Response Status: ${response.statusCode}');
      print('📡 Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          if (data['data'] != null) {
            await prefs.setString('user', jsonEncode(data['data']));
            print('✅ User profile saved to local storage');
          } else {
            await prefs.setString('user', jsonEncode(data));
            print('✅ User profile (root data) saved to local storage');
          }
          
          return {
            'success': true,
            'data': data['data'] ?? data,
            'message': data['message'] ?? 'Success get profile'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil profile'
          };
        }
      } else if (response.statusCode == 401) {
        await _clearToken();
        return {
          'success': false,
          'message': 'Sesi telah berakhir',
          'token_expired': true
        };
      } else {
        print('❌ Profile API Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Gagal mengambil profile: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Profile API Exception: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET DASHBOARD DATA
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/dashboard/getData'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'] ?? {},
            'message': data['message'] ?? 'Success get dashboard data'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil data dashboard'
          };
        }
      } else if (response.statusCode == 401) {
        await _clearToken();
        return {
          'success': false,
          'message': 'Sesi telah berakhir, silakan login kembali',
          'token_expired': true
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data dashboard: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ FIX: ROBUST DASHBOARD DATA FETCHING
Future<Map<String, dynamic>> getDashboardDataRobust() async {
  try {
    print('🚀 Starting robust dashboard data loading...');
    
    // Coba ambil data dashboard utama dulu
    final dashboardResult = await getDashboardData();
    
    if (dashboardResult['success'] == true) {
      print('✅ Dashboard data loaded successfully');
      return dashboardResult;
    }
    
    print('🔄 Fallback ke manual data loading...');
    
    // Fallback: Ambil data secara manual dan parallel
    final results = await Future.wait([
      getAllSaldo(),
      getAlltaqsith(),
      getUserProfile(),
    ], eagerError: true);
    
    final saldoResult = results[0] as Map<String, dynamic>;
    final taqsithResult = results[1] as Map<String, dynamic>;
    final profileResult = results[2] as Map<String, dynamic>;
    
    // ✅ GABUNGKAN SEMUA DATA DENGAN HANDLING ERROR
    final combinedData = {
      'saldo': saldoResult['success'] == true ? saldoResult['data'] : _createDefaultSaldoData(),
      'taqsith': taqsithResult['success'] == true ? taqsithResult['processed_data'] : {'total_angsuran': 0, 'items': []},
      'profile': profileResult['success'] == true ? profileResult['data'] : {},
      'raw_taqsith': taqsithResult['success'] == true ? taqsithResult['data'] : [],
      'raw_master': taqsithResult['success'] == true ? taqsithResult['data_master'] : [],
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    print('✅ Manual dashboard data loaded successfully');
    
    return {
      'success': true,
      'data': combinedData,
      'message': 'Data dashboard berhasil diambil (fallback mode)',
      'source': 'fallback'
    };
    
  } catch (e) {
    print('❌ All dashboard methods failed: $e');
    return {
      'success': true,
      'data': {
        'saldo': _createDefaultSaldoData(),
        'taqsith': {'total_angsuran': 0, 'items': []},
        'profile': {},
        'raw_taqsith': [],
        'raw_master': [],
        'timestamp': DateTime.now().toIso8601String(),
      },
      'message': 'Menggunakan data default karena error',
      'source': 'default'
    };
  }
}

// ✅ CREATE DEFAULT SALDO DATA
Map<String, dynamic> _createDefaultSaldoData() {
  return {
    'pokok': 0,
    'wajib': 0,
    'sukarela': 0,
    'sitabung': 0,
    'siumna': 0,
    'siquna': 0,
    'saldo': 0,
  };
}

// ✅ FIX: GET ALL SALDO YANG SESUAI DENGAN RESPONSE
Future<Map<String, dynamic>> getAllSaldo() async {
  try {
    final headers = await getProtectedHeaders();
    
    print('🚀 Fetching saldo data from API...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/transaction/getAllSaldo'),
      headers: headers,
      body: '',
    ).timeout(const Duration(seconds: 30));

    print('📡 Saldo API Response Status: ${response.statusCode}');
    print('📡 Saldo API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == true) {
        final responseData = data['data'] ?? {};
        
        print('✅ Saldo data structure: ${responseData.keys}');
        
        // ✅ NORMALISASI DATA SESUAI RESPONSE AKTUAL
        final normalizedData = _normalizeSaldoDataNew(responseData);
        
        return {
          'success': true,
          'data': normalizedData,
          'message': data['message'] ?? 'Success get saldo'
        };
      } else {
        print('❌ Saldo API status false: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data saldo'
        };
      }
    } else if (response.statusCode == 401) {
      await _clearToken();
      return {
        'success': false,
        'message': 'Sesi telah berakhir',
        'token_expired': true
      };
    } else {
      print('❌ Saldo API HTTP error: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Gagal mengambil data saldo: ${response.statusCode}'
      };
    }
  } catch (e) {
    print('❌ Saldo API Exception: $e');
    return {
      'success': false,
      'message': 'Error: $e'
    };
  }
}

// ✅ FIX: NORMALISASI DATA SALDO BARU - SESUAI RESPONSE
Map<String, dynamic> _normalizeSaldoDataNew(Map<String, dynamic> rawData) {
  final normalized = <String, dynamic>{};
  
  print('🔧 Normalizing saldo data from: ${rawData.keys}');
  
  // ✅ HANDLE POKOK
  if (rawData.containsKey('pokok') && rawData['pokok'] is List) {
    final pokokList = rawData['pokok'] as List;
    if (pokokList.isNotEmpty) {
      final pokokItem = pokokList[0] as Map<String, dynamic>;
      normalized['pokok'] = _safeConvertToInt(pokokItem['saldo']);
      print('✅ Normalized pokok: ${pokokItem['saldo']} → ${normalized['pokok']}');
    } else {
      normalized['pokok'] = 0;
    }
  } else {
    normalized['pokok'] = 0;
  }
  
  // ✅ HANDLE WAJIB
  if (rawData.containsKey('wajib') && rawData['wajib'] is List) {
    final wajibList = rawData['wajib'] as List;
    if (wajibList.isNotEmpty) {
      final wajibItem = wajibList[0] as Map<String, dynamic>;
      normalized['wajib'] = _safeConvertToInt(wajibItem['saldo']);
      print('✅ Normalized wajib: ${wajibItem['saldo']} → ${normalized['wajib']}');
    } else {
      normalized['wajib'] = 0;
    }
  } else {
    normalized['wajib'] = 0;
  }
  
  // ✅ HANDLE SUKARELA (bisa null)
  if (rawData.containsKey('sukarela') && rawData['sukarela'] != null) {
    if (rawData['sukarela'] is List) {
      final sukarelaList = rawData['sukarela'] as List;
      if (sukarelaList.isNotEmpty) {
        final sukarelaItem = sukarelaList[0] as Map<String, dynamic>;
        normalized['sukarela'] = _safeConvertToInt(sukarelaItem['saldo']);
        print('✅ Normalized sukarela: ${sukarelaItem['saldo']} → ${normalized['sukarela']}');
      } else {
        normalized['sukarela'] = 0;
      }
    } else {
      normalized['sukarela'] = 0;
    }
  } else {
    normalized['sukarela'] = 0;
    print('⚠️ sukarela is null, setting to 0');
  }
  
  // ✅ HANDLE SITABUNG
  if (rawData.containsKey('sitabung') && rawData['sitabung'] is List) {
    final sitabungList = rawData['sitabung'] as List;
    if (sitabungList.isNotEmpty) {
      final sitabungItem = sitabungList[0] as Map<String, dynamic>;
      normalized['sitabung'] = _safeConvertToInt(sitabungItem['saldo']);
      print('✅ Normalized sitabung: ${sitabungItem['saldo']} → ${normalized['sitabung']}');
    } else {
      normalized['sitabung'] = 0;
    }
  } else {
    normalized['sitabung'] = 0;
  }
  
  // ✅ HANDLE SIUMNA (bisa null)
  if (rawData.containsKey('siumna') && rawData['siumna'] != null) {
    if (rawData['siumna'] is List) {
      final siumnaList = rawData['siumna'] as List;
      if (siumnaList.isNotEmpty) {
        final siumnaItem = siumnaList[0] as Map<String, dynamic>;
        normalized['siumna'] = _safeConvertToInt(siumnaItem['saldo']);
        print('✅ Normalized siumna: ${siumnaItem['saldo']} → ${normalized['siumna']}');
      } else {
        normalized['siumna'] = 0;
      }
    } else {
      normalized['siumna'] = 0;
    }
  } else {
    normalized['siumna'] = 0;
    print('⚠️ siumna is null, setting to 0');
  }
  
  // ✅ HANDLE SIQUNA (bisa null)
  if (rawData.containsKey('siquna') && rawData['siquna'] != null) {
    if (rawData['siquna'] is List) {
      final siqunaList = rawData['siquna'] as List;
      if (siqunaList.isNotEmpty) {
        final siqunaItem = siqunaList[0] as Map<String, dynamic>;
        normalized['siquna'] = _safeConvertToInt(siqunaItem['saldo']);
        print('✅ Normalized siquna: ${siqunaItem['saldo']} → ${normalized['siquna']}');
      } else {
        normalized['siquna'] = 0;
      }
    } else {
      normalized['siquna'] = 0;
    }
  } else {
    normalized['siquna'] = 0;
    print('⚠️ siquna is null, setting to 0');
  }
  
  // ✅ HITUNG TOTAL SALDO
  final total = (normalized['pokok'] ?? 0) + 
               (normalized['wajib'] ?? 0) + 
               (normalized['sukarela'] ?? 0) + 
               (normalized['sitabung'] ?? 0) + 
               (normalized['siumna'] ?? 0) + 
               (normalized['siquna'] ?? 0);
  normalized['saldo'] = total;
  
  print('📊 Final normalized saldo data:');
  print('   - Pokok: ${normalized['pokok']}');
  print('   - Wajib: ${normalized['wajib']}');
  print('   - Sukarela: ${normalized['sukarela']}');
  print('   - Sitabung: ${normalized['sitabung']}');
  print('   - Siumna: ${normalized['siumna']}');
  print('   - Siquna: ${normalized['siquna']}');
  print('   - TOTAL: ${normalized['saldo']}');
  
  return normalized;
}

  // ✅ GET ALL ANGSURAN/TAQSITH
  Future<Map<String, dynamic>> getAllAngsuran() async {
    try {
      final headers = await getProtectedHeaders();
      
      print('🚀 Fetching angsuran data from API...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllTaqsith'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      print('📡 Angsuran API Response Status: ${response.statusCode}');
      print('📡 Angsuran API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          dynamic responseData = data['data'] ?? {};
          
          if (responseData is List) {
            print('✅ Angsuran data is List with ${responseData.length} items');
            return {
              'success': true,
              'data': responseData,
              'message': data['message'] ?? 'Success get angsuran'
            };
          }
          else if (responseData is Map) {
            if (responseData.containsKey('angsuran')) {
              final angsuranList = responseData['angsuran'];
              if (angsuranList is List) {
                print('✅ Found angsuran list with ${angsuranList.length} items');
                return {
                  'success': true,
                  'data': angsuranList,
                  'message': data['message'] ?? 'Success get angsuran'
                };
              }
            }
            if (responseData.containsKey('taqsith')) {
              final taqsithList = responseData['taqsith'];
              if (taqsithList is List) {
                print('✅ Found taqsith list with ${taqsithList.length} items');
                return {
                  'success': true,
                  'data': taqsithList,
                  'message': data['message'] ?? 'Success get angsuran'
                };
              }
            }
            if (responseData.containsKey('data')) {
              final nestedData = responseData['data'];
              if (nestedData is List) {
                print('✅ Found nested data list with ${nestedData.length} items');
                return {
                  'success': true,
                  'data': nestedData,
                  'message': data['message'] ?? 'Success get angsuran'
                };
              }
            }
            
            print('⚠️ Angsuran data is Map but no valid list found, returning empty');
            return {
              'success': true,
              'data': [],
              'message': data['message'] ?? 'Success get angsuran'
            };
          }
          else {
            print('⚠️ Angsuran data is null or other type: ${responseData.runtimeType}');
            return {
              'success': true,
              'data': [],
              'message': data['message'] ?? 'Success get angsuran'
            };
          }
        } else {
          print('❌ Angsuran API status false: ${data['message']}');
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil data angsuran'
          };
        }
      } else if (response.statusCode == 401) {
        await _clearToken();
        return {
          'success': false,
          'message': 'Sesi telah berakhir',
          'token_expired': true
        };
      } else {
        print('❌ Angsuran API HTTP error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Gagal mengambil data angsuran: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Angsuran API Exception: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

// ✅ FIX: GET ALL TAQSITH YANG SESUAI DENGAN RESPONSE
Future<Map<String, dynamic>> getAlltaqsith() async {
  try {
    final headers = await getProtectedHeaders();
    
    print('🚀 Fetching taqsith data from API...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/transaction/getAlltaqsith'),
      headers: headers,
      body: '',
    ).timeout(const Duration(seconds: 30));

    print('📡 Taqsith API Response Status: ${response.statusCode}');
    print('📡 Taqsith API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['status'] == true) {
        final responseData = data['data'] ?? [];
        final dataMaster = data['data_master'] ?? [];
        
        print('✅ Taqsith data: ${responseData.length} items');
        print('✅ Data master: ${dataMaster.length} items');
        
        // ✅ PROCESS DATA UNTUK DASHBOARD
        final processedData = _processTaqsithForDashboard(responseData, dataMaster);
        
        return {
          'success': true,
          'data': responseData,
          'data_master': dataMaster,
          'processed_data': processedData,
          'total_angsuran': processedData['total_angsuran'],
          'message': data['message'] ?? 'Success get taqsith'
        };
      } else {
        print('❌ Taqsith API status false: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data taqsith',
          'data': [],
          'data_master': [],
          'processed_data': {'total_angsuran': 0, 'items': []},
          'total_angsuran': 0
        };
      }
    } else if (response.statusCode == 401) {
      await _clearToken();
      return {
        'success': false,
        'message': 'Sesi telah berakhir',
        'token_expired': true,
        'data': [],
        'data_master': [],
        'processed_data': {'total_angsuran': 0, 'items': []},
        'total_angsuran': 0
      };
    } else {
      print('❌ Taqsith API HTTP error: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Gagal mengambil data taqsith: ${response.statusCode}',
        'data': [],
        'data_master': [],
        'processed_data': {'total_angsuran': 0, 'items': []},
        'total_angsuran': 0
      };
    }
  } catch (e) {
    print('❌ Taqsith API Exception: $e');
    return {
      'success': false,
      'message': 'Error: $e',
      'data': [],
      'data_master': [],
      'processed_data': {'total_angsuran': 0, 'items': []},
      'total_angsuran': 0
    };
  }
}

// ✅ PROCESS TAQSITH DATA UNTUK DASHBOARD
Map<String, dynamic> _processTaqsithForDashboard(List<dynamic> data, List<dynamic> dataMaster) {
  double totalAngsuran = 0;
  final List<Map<String, dynamic>> items = [];
  
  print('🔧 Processing taqsith data for dashboard...');
  
  for (var item in data) {
    if (item is Map<String, dynamic>) {
      final idKredit = item['id_kredit']?.toString();
      final namaBarang = item['nama_barang']?.toString() ?? 'Unknown';
      final angsuranList = item['angsuran'] ?? [];
      
      // ✅ CARI DATA MASTER YANG SESUAI
      Map<String, dynamic>? masterItem;
      for (var master in dataMaster) {
        if (master is Map<String, dynamic> && master['id_kredit']?.toString() == idKredit) {
          masterItem = Map<String, dynamic>.from(master);
          break;
        }
      }
      
      // ✅ HITUNG TOTAL ANGSURAN DARI DATA MASTER
      if (masterItem != null && masterItem['angsuran'] != null) {
        final angsuranValue = _safeConvertToDouble(masterItem['angsuran']);
        totalAngsuran += angsuranValue;
        
        print('✅ Angsuran for $namaBarang: $angsuranValue');
      }
      
      items.add({
        'id_kredit': idKredit,
        'nama_barang': namaBarang,
        'total_angsuran': angsuranList.length,
        'master_data': masterItem,
      });
    }
  }
  
  print('📊 Total angsuran calculated: $totalAngsuran');
  
  return {
    'total_angsuran': totalAngsuran,
    'items': items,
  };
}

  // ✅ GET RIWAYAT TABUNGAN
  Future<Map<String, dynamic>> getRiwayatTabungan() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getRiwayatTabungan'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'] ?? [],
            'message': data['message'] ?? 'Success get riwayat tabungan'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil riwayat tabungan'
          };
        }
      } else if (response.statusCode == 401) {
        await _clearToken();
        return {
          'success': false,
          'message': 'Sesi telah berakhir',
          'token_expired': true
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil riwayat tabungan: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET RIWAYAT ANGSURAN
  Future<Map<String, dynamic>> getRiwayatAngsuran() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getRiwayatAngsuran'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'] ?? [],
            'message': data['message'] ?? 'Success get riwayat angsuran'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil riwayat angsuran'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil riwayat angsuran: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ REGISTER METHOD
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final headers = getAuthHeaders();
      
      final body = userData.entries
          .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
          .join('&');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Registrasi berhasil'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Registrasi gagal'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Registrasi gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET MASTER DATA
  Future<Map<String, dynamic>> getMasterData() async {
    try {
      final headers = getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/master/get'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Success get master data'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil master data'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET PROVINCE
  Future<Map<String, dynamic>> getProvince() async {
    try {
      final headers = getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/master/getProvince'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          if (data.containsKey('provinces')) {
            return {
              'success': true,
              'data': data['provinces'] ?? [],
              'message': data['message'] ?? 'Success get province'
            };
          } else {
            return {
              'success': false,
              'message': 'Format response tidak sesuai: tidak ada key provinces'
            };
          }
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil data province'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data province: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET REGENCY
  Future<Map<String, dynamic>> getRegency(String idProvince) async {
    try {
      final headers = getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/master/getRegency'),
        headers: headers,
        body: 'id_province=$idProvince',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          if (data.containsKey('regency')) {
            return {
              'success': true,
              'data': data['regency'] ?? [],
              'message': data['message'] ?? 'Success get regency'
            };
          } else {
            return {
              'success': false,
              'message': 'Format response tidak sesuai: tidak ada key regency'
            };
          }
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil data regency'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data regency: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ INSERT INBOX
  Future<Map<String, dynamic>> insertInbox({
    required String subject,
    required String keterangan,
    required String userId,
  }) async {
    try {
      final headers = await getProtectedHeaders();
      
      final body = 'subject=${Uri.encodeComponent(subject)}&keterangan=${Uri.encodeComponent(keterangan)}&user_id=${Uri.encodeComponent(userId)}';

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/InsertInbox'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Notifikasi berhasil dikirim'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengirim notifikasi: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET ALL INBOX
  Future<Map<String, dynamic>> getAllInbox() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllinbox'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'] ?? {},
            'message': data['message'] ?? 'Success get inbox'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil data inbox'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data inbox: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET INBOX READ
  Future<Map<String, dynamic>> getInboxRead(String idInbox) async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getInboxRead'),
        headers: headers,
        body: 'id_inbox=$idInbox',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Inbox ditandai terbaca'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal menandai inbox'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET INBOX READ ALL
  Future<Map<String, dynamic>> getInboxReadAll() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getInboxReadAll'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Semua inbox ditandai terbaca'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal menandai semua inbox'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET INBOX DELETED
  Future<Map<String, dynamic>> getInboxDeleted(String idInbox) async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getInboxDeleted'),
        headers: headers,
        body: 'id_inbox=$idInbox',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Inbox berhasil dihapus'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal menghapus inbox'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET INBOX DELETED ALL
  Future<Map<String, dynamic>> getInboxDeletedAll() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getInboxDeletedAll'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Semua inbox berhasil dihapus'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal menghapus semua inbox'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ CHANGE PASSWORD
// ✅ FIX: CHANGE PASSWORD
Future<Map<String, dynamic>> changePassword(String oldPass, String newPass, String newPassConf) async {
  try {
    final headers = await getProtectedHeaders();
    
    print('🔐 Changing password...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/users/changePass'),
      headers: headers,
      body: 'old_pass=${Uri.encodeComponent(oldPass)}&new_pass=${Uri.encodeComponent(newPass)}&new_pass_conf=${Uri.encodeComponent(newPassConf)}',
    ).timeout(const Duration(seconds: 30));

    print('📡 ChangePass Response Status: ${response.statusCode}');
    print('📡 ChangePass Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      return {
        'success': data['status'] == true,
        'message': data['message'] ?? (data['status'] == true ? 'Password berhasil diubah' : 'Gagal mengubah password'),
        'data': data
      };
    } else {
      return {
        'success': false,
        'message': 'Gagal mengubah password: ${response.statusCode}'
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e'
    };
  }
}

// ✅ FIX: CHECK USER EXIST YANG SESUAI DENGAN RESPONSE
Future<Map<String, dynamic>> checkUserExist(String username, String email) async {
  try {
    final headers = getAuthHeaders();
    
    print('🔍 Checking user exist: username=$username, email=$email');
    
    final response = await http.post(
      Uri.parse('$baseUrl/users/checkUserExist'),
      headers: headers,
      body: 'username=${Uri.encodeComponent(username)}&email=${Uri.encodeComponent(email)}',
    ).timeout(const Duration(seconds: 30));

    print('📡 CheckUserExist Response Status: ${response.statusCode}');
    print('📡 CheckUserExist Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // ✅ SESUAI RESPONSE AKTUAL: {"status": true, "is_exist": 1, "message": "..."}
      final isExist = data['is_exist'] == 1;
      
      return {
        'exists': isExist,
        'message': data['message'] ?? (isExist ? 'User sudah ada' : 'User tersedia'),
        'status': data['status'] ?? false
      };
    } else {
      return {
        'exists': false,
        'message': 'Tidak dapat memeriksa user: ${response.statusCode}',
        'status': false
      };
    }
  } catch (e) {
    return {
      'exists': false,
      'message': 'Error: $e',
      'status': false
    };
  }
}

// ✅ UPDATE DEVICE TOKEN KE SERVER
Future<Map<String, dynamic>> updateDeviceToken(String token) async {
  try {
    final headers = await getProtectedHeaders();
    
    final response = await http.post(
      Uri.parse('$baseUrl/users/updateDeviceToken'),
      headers: headers,
      body: 'device_token=$token&device_type=${Platform.isAndroid ? 'android' : 'ios'}',
    ).timeout(const Duration(seconds: 30));

    print('📡 Update Device Token Response: ${response.statusCode}');
    print('📡 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': data['status'] == true,
        'message': data['message'] ?? 'Token updated successfully'
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to update token: ${response.statusCode}'
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error updating token: $e'
    };
  }
}

// ✅ MARK NOTIFICATION AS READ
Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
  try {
    final headers = await getProtectedHeaders();
    
    final response = await http.post(
      Uri.parse('$baseUrl/transaction/getInboxRead'),
      headers: headers,
      body: 'id_inbox=$notificationId',
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': data['status'] == true,
        'message': data['message'] ?? 'Notification marked as read'
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to mark notification as read'
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error marking notification as read: $e'
    };
  }
}

// ✅ GET UNREAD NOTIFICATION COUNT
Future<int> getUnreadNotificationCount() async {
  try {
    final result = await getAllInbox();
    if (result['success'] == true) {
      final data = result['data'] ?? {};
      List<dynamic> inboxList = [];
      
      if (data['inbox'] is List) {
        inboxList = data['inbox'];
      } else if (data is List) {
        inboxList = data;
      }
      
      return inboxList.where((item) {
        if (item is Map) {
          final readStatus = item['read_status'] ?? item['is_read'] ?? item['status_baca'] ?? '0';
          return readStatus == '0' || readStatus == 0 || readStatus == false;
        }
        return false;
      }).length;
    }
    return 0;
  } catch (e) {
    return 0;
  }
}

  // ✅ UPDATE USER PROFILE
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final headers = await getProtectedHeaders();
      
      final body = profileData.entries
          .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
          .join('&');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/updateProfile'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          final prefs = await SharedPreferences.getInstance();
          final currentUser = await getCurrentUser();
          if (currentUser != null) {
            currentUser.addAll(profileData);
            await prefs.setString('user', jsonEncode(currentUser));
          }
          
          return {
            'success': true,
            'message': data['message'] ?? 'Profile berhasil diupdate',
            'data': data['data']
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengupdate profile'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Gagal mengupdate profile: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ CHECK LOGIN STATUS
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final user = prefs.getString('user');
      return token != null && token.isNotEmpty && user != null && user.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ✅ VALIDATE TOKEN
  Future<bool> validateToken() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/validateToken'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ✅ HELPER METHODS UNTUK NORMALISASI DATA SALDO
  Map<String, dynamic> _normalizeSaldoData(Map<String, dynamic> rawData) {
    final normalized = <String, dynamic>{};
    
    print('🔧 Normalizing saldo data from: ${rawData.keys}');
    
    for (var key in ['pokok', 'wajib', 'sukarela', 'sitabung', 'sita', 'siumna', 'simuna', 'siquna', 'taqsith']) {
      if (rawData.containsKey(key)) {
        final value = rawData[key];
        
        if (value is List && value.isNotEmpty) {
          final firstItem = value[0];
          if (firstItem is Map && firstItem.containsKey('saldo')) {
            normalized[key] = firstItem['saldo'];
            print('✅ Normalized $key from array: ${firstItem['saldo']}');
          } else {
            normalized[key] = 0;
          }
        } 
        else if (value is Map && value.containsKey('saldo')) {
          normalized[key] = value['saldo'];
          print('✅ Normalized $key from map: ${value['saldo']}');
        }
        else if (value is num) {
          normalized[key] = value;
          print('✅ Normalized $key from direct value: $value');
        }
        else {
          normalized[key] = 0;
          print('⚠️ Could not normalize $key, setting to 0');
        }
      } else {
        normalized[key] = 0;
      }
    }
    
    if (rawData.containsKey('saldo')) {
      normalized['saldo'] = _parseSaldoValue(rawData['saldo']);
    } else {
      final total = (normalized['pokok'] ?? 0) + 
                   (normalized['wajib'] ?? 0) + 
                   (normalized['sukarela'] ?? 0) + 
                   (normalized['sitabung'] ?? normalized['sita'] ?? 0) + 
                   (normalized['siumna'] ?? normalized['simuna'] ?? 0) + 
                   (normalized['siquna'] ?? normalized['taqsith'] ?? 0);
      normalized['saldo'] = total;
    }
    
    print('📊 Normalized saldo data: $normalized');
    return normalized;
  }

  // ✅ IMPROVED: SAFE CONVERSION METHODS
int _safeConvertToInt(dynamic value) {
  try {
    if (value == null) return 0;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Handle string dengan decimal
      if (value.contains('.')) {
        return double.tryParse(value)?.toInt() ?? 0;
      }
      return int.tryParse(value) ?? 0;
    }
    
    return 0;
  } catch (e) {
    print('❌ Error converting $value to int: $e');
    return 0;
  }
}

double _safeConvertToDouble(dynamic value) {
  try {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    
    return 0.0;
  } catch (e) {
    print('❌ Error converting $value to double: $e');
    return 0.0;
  }
}

String _safeConvertToString(dynamic value) {
  try {
    if (value == null) return '';
    return value.toString();
  } catch (e) {
    return '';
  }
}

  dynamic _parseSaldoValue(dynamic value) {
    if (value == null) return 0;
    
    if (value is num) return value;
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0;
    }
    if (value is Map && value.containsKey('saldo')) {
      return _parseSaldoValue(value['saldo']);
    }
    if (value is List && value.isNotEmpty) {
      return _parseSaldoValue(value[0]);
    }
    
    return 0;
  }
}