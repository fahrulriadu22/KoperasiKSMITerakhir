import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

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

// ✅ PERBAIKAN: Get multipart headers dengan token yang valid
Future<Map<String, String>> getMultipartHeaders() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('token');
    
    final headers = <String, String>{
      'DEVICE-ID': _deviceId,
      'DEVICE-TOKEN': _deviceToken,
      // ✅ TAMBAHKAN Content-Type untuk multipart
      'Content-Type': 'multipart/form-data',
    };
    
    if (userKey != null && userKey.isNotEmpty) {
      headers['x-api-key'] = userKey;
      print('✅ Token found: ${userKey.substring(0, 10)}...');
    } else {
      print('❌ Token tidak ditemukan di SharedPreferences');
    }
    
    return headers;
  } catch (e) {
    print('❌ Error getMultipartHeaders: $e');
    return {
      'DEVICE-ID': _deviceId,
      'DEVICE-TOKEN': _deviceToken,
      'Content-Type': 'multipart/form-data',
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
        
        // Validasi file exists
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
        
        // Validasi file exists
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

// ✅ PERBAIKAN BESAR: Upload foto dengan endpoint dan field yang benar
Future<Map<String, dynamic>> uploadFoto({
  required String type,
  required String filePath,
}) async {
  try {
    print('🚀 UPLOAD START: $type');
    print('📁 File path: $filePath');
    
    // ✅ VALIDASI FILE
    File file = File(filePath);
    if (!await file.exists()) {
      return {
        'success': false, 
        'message': 'File tidak ditemukan: $filePath'
      };
    }

    final fileSize = await file.length();
    print('📁 File size: $fileSize bytes');
    
    if (fileSize == 0) {
      return {
        'success': false, 
        'message': 'File kosong atau tidak dapat diakses'
      };
    }

    if (fileSize > 5 * 1024 * 1024) {
      return {
        'success': false, 
        'message': 'Ukuran file terlalu besar. Maksimal 5MB.'
      };
    }

    // ✅ GET HEADERS - PASTIKAN TOKEN ADA
    final headers = await getMultipartHeaders();
    print('📤 Headers: $headers');

    // ✅ BUAT MULTIPART REQUEST
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/users/setPhoto')
    );
    request.headers.addAll(headers);

    // ✅ TAMBAHKAN FILE - COBA FIELD NAME YANG BERBEDA
    final possibleFieldNames = ['file', 'foto', 'photo', 'image', 'upload', 'file_upload'];
    bool fileAdded = false;
    String usedFieldName = '';
    
    for (final fieldName in possibleFieldNames) {
      try {
        var multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          filePath,
          filename: '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
        fileAdded = true;
        usedFieldName = fieldName;
        print('✅ File berhasil dilampirkan dengan field: $fieldName');
        break;
      } catch (e) {
        print('❌ Gagal dengan field $fieldName: $e');
        continue;
      }
    }

    if (!fileAdded) {
      return {
        'success': false, 
        'message': 'Gagal menambahkan file ke request'
      };
    }

    // ✅ TAMBAHKAN FORM FIELDS YANG DIPERLUKAN
    request.fields['type'] = type;
    
    // ✅ TAMBAHKAN USER DATA JIKA DIPERLUKAN
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      if (currentUser['user_id'] != null) {
        request.fields['user_id'] = currentUser['user_id'].toString();
      }
      if (currentUser['username'] != null) {
        request.fields['username'] = currentUser['username'].toString();
      }
      if (currentUser['user_key'] != null) {
        request.fields['user_key'] = currentUser['user_key'].toString();
      }
    }

    print('📤 Request fields: ${request.fields}');
    print('📤 Files count: ${request.files.length}');
    print('📤 Used field name: $usedFieldName');

    // ✅ KIRIM REQUEST
    print('🔄 Mengirim request ke: $baseUrl/users/setPhoto');
    final response = await request.send().timeout(const Duration(seconds: 30));
    
    // ✅ BACA RESPONSE
    final responseBody = await response.stream.bytesToString();
    print('📡 Response Status: ${response.statusCode}');
    print('📡 Response Body: $responseBody');

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      
      if (data['status'] == true) {
        print('✅ UPLOAD SUCCESS');
        
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
        'message': 'Server error ${response.statusCode}: $responseBody'
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

  // ✅ UPDATE STATUS UPLOAD DI LOCAL STORAGE
  Future<void> _updateUploadStatus(String type, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = jsonDecode(userString);
        userData['${type}_upload_status'] = status;
        await prefs.setString('user', jsonEncode(userData));
        print('✅ Local storage updated for $type: $status');
      }
    } catch (e) {
      print('❌ Error updating upload status: $e');
    }
  }

  // ✅ UPLOAD DOKUMEN (UNTUK PDF, DOC, DLL)
  Future<Map<String, dynamic>> uploadDokumen({
    required String jenisDokumen,
    required String filePath,
  }) async {
    try {
      print('🚀 UPLOAD DOKUMEN: $jenisDokumen');
      print('📁 File path: $filePath');
      
      // Validasi file
      File file = File(filePath);
      if (!await file.exists()) {
        return {
          'success': false, 
          'message': 'File tidak ditemukan'
        };
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB untuk dokumen
        return {
          'success': false, 
          'message': 'Ukuran file terlalu besar. Maksimal 10MB.'
        };
      }

      // Get headers
      final headers = await getMultipartHeaders();
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/uploadDokumen')
      );
      request.headers.addAll(headers);

      // Tambahkan file
      final fileExtension = filePath.split('.').last.toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'dokumen',
        filePath,
        filename: '${jenisDokumen}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
      ));

      // Tambahkan fields
      request.fields['jenis_dokumen'] = jenisDokumen;
      
      final currentUser = await getCurrentUser();
      if (currentUser != null && currentUser['user_id'] != null) {
        request.fields['user_id'] = currentUser['user_id'].toString();
      }

      // Kirim request
      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Dokumen berhasil diupload',
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
      print('❌ UPLOAD DOKUMEN ERROR: $e');
      return {
        'success': false,
        'message': 'Upload dokumen error: $e'
      };
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
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(data['data']));
          
          return {
            'success': true,
            'data': data['data'],
            'message': data['message'] ?? 'Success get profile'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil profile'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil profile: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
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
      print('🔐 Token cleared due to expiration');
    } catch (e) {
      print('❌ Error clearing token: $e');
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

  // ✅ GET ALL SALDO
  Future<Map<String, dynamic>> getAllSaldo() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllSaldo'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'] ?? {},
            'message': data['message'] ?? 'Success get saldo'
          };
        } else {
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
        return {
          'success': false,
          'message': 'Gagal mengambil data saldo: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET ALL ANGSURAN
  Future<Map<String, dynamic>> getAllAngsuran() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllTaqsith'),
        headers: headers,
        body: '',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'] ?? {},
            'message': data['message'] ?? 'Success get angsuran'
          };
        } else {
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
        return {
          'success': false,
          'message': 'Gagal mengambil data angsuran: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
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

// ✅ PERBAIKAN BESAR: Upload bukti transfer dengan endpoint yang benar
Future<Map<String, dynamic>> uploadBuktiTransfer({
  required String transaksiId,
  required String filePath,
  required String jenisTransaksi,
}) async {
  try {
    print('🚀 UPLOAD BUKTI TRANSFER START');
    print('📁 Transaksi ID: $transaksiId');
    print('📁 Jenis: $jenisTransaksi');
    print('📁 File path: $filePath');
    
    // ✅ VALIDASI FILE
    File file = File(filePath);
    if (!await file.exists()) {
      return {
        'success': false,
        'message': 'File bukti transfer tidak ditemukan'
      };
    }
    
    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      return {
        'success': false,
        'message': 'Ukuran file terlalu besar. Maksimal 5MB.'
      };
    }

    // ✅ GET HEADERS
    final headers = await getMultipartHeaders();
    print('📤 Headers: $headers');

    // ✅ PERBAIKAN: GUNAKAN ENDPOINT YANG BENAR
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/transaction/uploadBukti')
    );
    
    request.headers.addAll(headers);
    
    // ✅ PERBAIKAN: TAMBAHKAN FILE DENGAN FIELD NAME YANG BENAR
    final fileExtension = filePath.toLowerCase().substring(filePath.lastIndexOf('.'));
    
    // ✅ COBA BERBAGAI FIELD NAME UNTUK BUKTI TRANSFER
    final possibleFieldNames = ['bukti_transfer', 'file', 'foto', 'bukti', 'transfer_proof'];
    bool fileAdded = false;
    
    for (final fieldName in possibleFieldNames) {
      try {
        request.files.add(await http.MultipartFile.fromPath(
          fieldName,
          filePath,
          filename: 'bukti_${jenisTransaksi}_${DateTime.now().millisecondsSinceEpoch}$fileExtension',
        ));
        fileAdded = true;
        print('✅ File bukti berhasil dilampirkan dengan field: $fieldName');
        break;
      } catch (e) {
        print('❌ Gagal dengan field $fieldName: $e');
        continue;
      }
    }

    if (!fileAdded) {
      return {
        'success': false,
        'message': 'Gagal menambahkan file bukti ke request'
      };
    }

    // ✅ PERBAIKAN: TAMBAHKAN FORM FIELDS YANG DIPERLUKAN
    request.fields['transaksi_id'] = transaksiId;
    request.fields['jenis_transaksi'] = jenisTransaksi;
    
    // ✅ TAMBAHKAN USER DATA JIKA DIPERLUKAN
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      if (currentUser['user_id'] != null) {
        request.fields['user_id'] = currentUser['user_id'].toString();
      }
      if (currentUser['username'] != null) {
        request.fields['username'] = currentUser['username'].toString();
      }
    }

    print('📤 Request fields: ${request.fields}');
    print('📤 Files count: ${request.files.length}');

    // ✅ KIRIM REQUEST
    print('🔄 Mengirim request ke: $baseUrl/transaction/uploadBukti');
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
          'file_path': data['file_path'] ?? data['path'] ?? data['url']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Upload bukti transfer gagal'
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
        'message': 'Upload bukti transfer gagal: ${response.statusCode} - $responseBody'
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

  // ✅ CHANGE PASSWORD
  Future<Map<String, dynamic>> changePassword(String oldPass, String newPass, String newPassConf) async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/changePass'),
        headers: headers,
        body: 'old_pass=${Uri.encodeComponent(oldPass)}&new_pass=${Uri.encodeComponent(newPass)}&new_pass_conf=${Uri.encodeComponent(newPassConf)}',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? (data['status'] == true ? 'Password berhasil diubah' : 'Gagal mengubah password')
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

  // ✅ CHECK USER EXIST
  Future<Map<String, dynamic>> checkUserExist(String username, String email) async {
    try {
      final headers = getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/checkUserExist'),
        headers: headers,
        body: 'username=${Uri.encodeComponent(username)}&email=${Uri.encodeComponent(email)}',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'exists': data['exists'] == true,
          'message': data['message'] ?? ''
        };
      } else {
        return {
          'exists': false,
          'message': 'Tidak dapat memeriksa user: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'exists': false,
        'message': 'Error: $e'
      };
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
}