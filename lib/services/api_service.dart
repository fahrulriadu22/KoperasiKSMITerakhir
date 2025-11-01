import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://demo.bsdeveloper.id/api';
  
  String _deviceId = '12341231313131';
  String _deviceToken = '1234232423424';

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
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('token');
    
    final headers = <String, String>{
      'DEVICE-ID': _deviceId,
      'DEVICE-TOKEN': _deviceToken,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    
    if (userKey != null && userKey.isNotEmpty) {
      headers['x-api-key'] = userKey;
    }
    
    return headers;
  }

  // ✅ GET PROTECTED HEADERS UNTUK MULTIPART/FILE UPLOAD
  Future<Map<String, String>> getMultipartHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('token');
    
    final headers = <String, String>{
      'DEVICE-ID': _deviceId,
      'DEVICE-TOKEN': _deviceToken,
    };
    
    if (userKey != null && userKey.isNotEmpty) {
      headers['x-api-key'] = userKey;
    }
    
    return headers;
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
      // ✅ PERBAIKAN: Handle timeout dan error lainnya dengan generic catch
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': 'Success get province'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data province'
        };
      }
    } catch (e) {
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': 'Success get regency'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data regency'
        };
      }
    } catch (e) {
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data saldo: ${response.statusCode}'
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Tidak ada koneksi internet'
      };
    } catch (e) {
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data angsuran: ${response.statusCode}'
        };
      }
    } catch (e) {
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ UPLOAD FOTO
  Future<Map<String, dynamic>> uploadFoto({
    required String type,
    required String filePath,
  }) async {
    try {
      final headers = await getMultipartHeaders();
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/setPhoto')
      );
      
      request.headers.addAll(headers);
      
      String fieldName = type;
      
      File file = File(filePath);
      if (!await file.exists()) {
        return {
          'success': false,
          'message': 'File tidak ditemukan: $filePath'
        };
      }
      
      // Check file size (max 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Ukuran file terlalu besar. Maksimal 5MB.'
        };
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        fieldName, 
        filePath,
        filename: '${fieldName}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      request.fields['type'] = type;

      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        
        if (data['status'] == true) {
          await _updateUserPhoto(type, data['file_path'] ?? 'uploaded');
          
          return {
            'success': true,
            'message': data['message'] ?? 'Upload berhasil',
            'file_path': data['file_path']
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Upload gagal'
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Endpoint upload tidak ditemukan (404). Periksa URL API.'
        };
      } else {
        return {
          'success': false,
          'message': 'Upload gagal: ${response.statusCode} - $responseBody'
        };
      }
    } catch (e) {
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Upload timeout, coba lagi'
        };
      }
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ UPDATE USER PHOTO IN LOCAL STORAGE
  Future<void> _updateUserPhoto(String type, String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = jsonDecode(userString);
        userData[type] = filePath;
        await prefs.setString('user', jsonEncode(userData));
      }
    } catch (e) {
      print('Error updating user photo locally: $e');
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'exists': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
      return {
        'exists': false,
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
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data dashboard: ${response.statusCode}'
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Tidak ada koneksi internet'
      };
    } catch (e) {
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
      return {
        'success': false,
        'message': 'Error: $e'
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
      return {
        'success': false,
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
          // Update local user data
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil riwayat tabungan: ${response.statusCode}'
        };
      }
    } catch (e) {
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
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
      // ✅ PERBAIKAN: Handle timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return {
          'success': false,
          'message': 'Timeout, server tidak merespons'
        };
      }
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // ✅ GET CURRENT USER FROM LOCAL STORAGE
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        return jsonDecode(userString);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // ✅ CHECK LOGIN STATUS
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final user = prefs.getString('user');
      return token != null && user != null;
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