import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ BASE URL REAL
  static const String baseUrl = 'http://demo.bsdeveloper.id/api';
  
  // ✅ DEVICE INFO - FIXED VALUES (NO DEVICE_INFO_PLUS)
  String _deviceId = '12341231313131';
  String _deviceToken = '1234232423424';

  // ============ HEADERS ============

  // ✅ HEADERS FOR AUTH & MASTER DATA
  Map<String, String> getAuthHeaders() {
    return {
      'DEVICE-ID': _deviceId,
      'DEVICE-TOKEN': _deviceToken,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  // ✅ HEADERS PROTECTED + USER_KEY DARI LOGIN
  Future<Map<String, String>> getProtectedHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('token');
    
    final headers = <String, String>{
      'DEVICE-ID': _deviceId,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    
    // ✅ PASTIKAN USER_KEY DARI LOGIN DIPAKAI
    if (userKey != null && userKey.isNotEmpty) {
      headers['x-api-key'] = userKey;
    }
    
    return headers;
  }

  // ============ AUTH METHODS ============

  // ✅ LOGIN - SIMPAN USER_KEY SEBAGAI TOKEN
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final headers = getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/login/auth'),
        headers: headers,
        body: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
      );

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

          // ✅ SIMPAN USER_KEY SEBAGAI TOKEN
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', userKey);
          await prefs.setString('user', jsonEncode(userData));
          
          return {
            'success': true,
            'token': userKey,
            'user': userData,
            'message': 'Login berhasil'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Login gagal'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Login gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ REGISTER
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
      );

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

  // ============ MASTER DATA ============

  // ✅ GET MASTER DATA
  Future<Map<String, dynamic>> getMasterData() async {
    try {
      final headers = getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/master/get'),
        headers: headers,
        body: '',
      );

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
      );

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
      );

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
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ============ TRANSACTION ============

  // ✅ GET ALL SALDO
  Future<Map<String, dynamic>> getAllSaldo() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllSaldo'),
        headers: headers,
        body: '',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
          'message': 'Success get saldo'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data saldo'
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
          'message': 'Success get angsuran'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data angsuran'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ============ NOTIFICATION ============

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Notifikasi berhasil dikirim'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengirim notifikasi'
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': 'Success get inbox'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data inbox'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ UPLOAD FOTO - OLD VERSION (KEEP FOR BACKWARD COMPATIBILITY)
  Future<bool> uploadFoto({
    required String type,
    required String filePath,
  }) async {
    try {
      final headers = await getProtectedHeaders();
      headers.remove('Content-Type');
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/setPhoto')
      );
      
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath(type, filePath));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        return data['status'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ✅ UPLOAD FOTO - FIXED VERSION WITH BETTER ERROR HANDLING
  Future<Map<String, dynamic>> uploadFotoFixed({
    required String type,
    required String filePath,
  }) async {
    try {
      final headers = await getProtectedHeaders();
      headers.remove('Content-Type'); // Important for multipart
      
      print('🔄 Uploading photo: type=$type, path=$filePath');
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/setPhoto')
      );
      
      request.headers.addAll(headers);
      
      // ✅ Add file with correct field name based on type
      String fieldName;
      switch (type) {
        case 'foto_ktp':
          fieldName = 'foto_ktp';
          break;
        case 'foto_kk':
          fieldName = 'foto_kk';
          break;
        case 'foto_diri':
        default:
          fieldName = 'foto_diri';
          break;
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        fieldName, 
        filePath,
        filename: '${fieldName}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // ✅ Add type parameter to body
      request.fields['type'] = type;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('📤 Upload Response Status: ${response.statusCode}');
      print('📤 Upload Response Body: $responseBody');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        print('✅ Upload success: ${data['status']}');
        print('✅ Upload message: ${data['message']}');
        
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Upload berhasil',
          'data': data
        };
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Upload gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ CHANGE PASSWORD
  Future<bool> changePassword(String oldPass, String newPass, String newPassConf) async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/changePass'),
        headers: headers,
        body: 'old_pass=$oldPass&new_pass=$newPass&new_pass_conf=$newPassConf',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true;
      }
    } catch (e) {
      // Silent error
    }
    return false;
  }

  // ✅ CHECK USER EXIST
  Future<Map<String, dynamic>> checkUserExist(String username, String email) async {
    try {
      final headers = getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/checkUserExist'),
        headers: headers,
        body: 'username=${Uri.encodeComponent(username)}&email=${Uri.encodeComponent(email)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'exists': data['exists'] == true,
          'message': data['message'] ?? ''
        };
      } else {
        return {
          'exists': false,
          'message': 'Tidak dapat memeriksa user'
        };
      }
    } catch (e) {
      return {
        'exists': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ✅ GET CURRENT USER
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        return jsonDecode(userString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ CHECK LOGIN STATUS
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }
}