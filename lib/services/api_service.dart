import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApiService {
  // ✅ BASE URL KSMI REAL
  static const String baseUrl = 'http://demo.bsdeveloper.id/api';
  
  // ✅ DUAL API KEY SYSTEM
  static const String apiKeyMain = 'sw08c0wwg4okcoccgskosckc8ks0c4w8wg8w0wwg'; // Untuk auth, master, transaction
  static const String apiKeyNotification = 'o0gsogwsgg00sgwggw0kgswc444c0wko4440ogsg'; // Untuk notifikasi/inbox
  
  // ✅ DEVICE INFO
  String? _deviceId;
  String? _deviceToken;

  // ✅ INIT DEVICE INFO - FIXED VERSION
  Future<void> _initDeviceInfo() async {
    if (_deviceId != null) return;
    
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
        _deviceToken = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
        _deviceToken = 'ios_${iosInfo.identifierForVendor}';
      } else {
        _deviceId = '12341231313131';
        _deviceToken = '12341231313131';
      }
    } catch (e) {
      print('❌ Device info error: $e');
      _deviceId = '12341231313131';
      _deviceToken = '12341231313131';
    }
  }

  // ============ HEADERS ============

  // ✅ HEADERS FOR AUTH ENDPOINTS (Login, Register, Master Data)
  Future<Map<String, String>> getAuthHeaders() async {
    await _initDeviceInfo();
    return {
      'DEVICE-ID': _deviceId!,
      'DEVICE-TOKEN': _deviceToken!,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  // ✅ HEADERS FOR MAIN ENDPOINTS (Saldo, Angsuran, dll) - PAKAI API KEY MAIN
  Future<Map<String, String>> getProtectedHeaders() async {
    await _initDeviceInfo();
    return {
      'DEVICE-ID': _deviceId!,
      'x-api-key': apiKeyMain,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  // ✅ HEADERS FOR NOTIFICATION/INBOX ENDPOINTS - PAKAI API KEY NOTIFICATION
  Future<Map<String, String>> getInboxHeaders({bool withContentType = true}) async {
    await _initDeviceInfo();
    final headers = <String, String>{
      'DEVICE-ID': _deviceId!,
      'x-api-key': apiKeyNotification,
    };
    if (withContentType) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    return headers;
  }

  // ============ AUTH METHODS ============

  // ✅ CHECK LOGIN STATUS
  Future<bool> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userString = prefs.getString('user');
      
      print('🔐 Check Login Status:');
      print('   - Token exists: ${token != null}');
      print('   - User data exists: ${userString != null}');
      
      if (token != null && userString != null) {
        final userData = jsonDecode(userString);
        print('   - User data: $userData');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Check login status error: $e');
      return false;
    }
  }

  // ✅ LOGIN API
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/login/auth'),
        headers: headers,
        body: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
      );

      print('🔐 Login Response: ${response.statusCode}');
      print('🔐 Login Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('user', jsonEncode(data['user'] ?? {}));
          
          return {
            'success': true,
            'token': data['token'],
            'user': data['user'] ?? {},
            'message': 'Login berhasil'
          };
        } else if (data['data'] != null && data['data']['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['data']['token']);
          await prefs.setString('user', jsonEncode(data['data']['user'] ?? {}));
          
          return {
            'success': true,
            'token': data['data']['token'],
            'user': data['data']['user'] ?? {},
            'message': 'Login berhasil'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Token tidak ditemukan'
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ REGISTER USER
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final headers = await getAuthHeaders();
      
      print('📝 Register Data: $userData');
      
      final body = userData.entries
          .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
          .join('&');
      
      print('🔐 Register Headers: $headers');
      print('📤 Register Body: $body');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: headers,
        body: body,
      );

      print('📥 Register Response Status: ${response.statusCode}');
      print('📥 Register Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Registrasi berhasil',
            'data': data['data'] ?? {}
          };
        } else if (data['status'] == 'success') {
          return {
            'success': true,
            'message': data['message'] ?? 'Registrasi berhasil',
            'data': data['data'] ?? {}
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? data['error'] ?? 'Registrasi gagal',
            'error': true
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Terjadi kesalahan server: ${response.statusCode}',
          'error': true
        };
      }
    } catch (e) {
      print('❌ Register error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
        'error': true
      };
    }
  }

  // ============ PUSH NOTIFICATION METHODS ============

  // ✅ SAVE DEVICE TOKEN TO SERVER
  Future<bool> saveDeviceToken(String deviceToken) async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/saveDeviceToken'),
        headers: headers,
        body: 'device_token=${Uri.encodeComponent(deviceToken)}&device_type=${Platform.isAndroid ? 'android' : 'ios'}',
      );

      print('📱 Save Device Token Response: ${response.statusCode}');
      print('📱 Save Device Token Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true || data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('❌ Save device token error: $e');
      return false;
    }
  }

  // ✅ SEND PUSH NOTIFICATION (ADMIN SIDE)
  Future<Map<String, dynamic>> sendPushNotification({
    required String title,
    required String message,
    required String userId,
  }) async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/notification/send'),
        headers: headers,
        body: 'title=${Uri.encodeComponent(title)}&message=${Uri.encodeComponent(message)}&user_id=$userId',
      );

      print('📤 Send Push Notification Response: ${response.statusCode}');
      print('📤 Send Push Notification Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true || data['status'] == 'success',
          'message': data['message'] ?? 'Notification sent successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send notification: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Send push notification error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ============ PROFILE METHODS ============

  // ✅ UPDATE USER PROFILE
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final headers = await getProtectedHeaders();
      
      final body = profileData.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('&');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/updateProfile'),
        headers: headers,
        body: body,
      );

      print('🔧 Update Profile Response: ${response.statusCode}');
      print('🔧 Update Profile Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return true;
        } else if (data['status'] == 'success') {
          return true;
        } else if (data['message'] != null && data['message'].contains('berhasil')) {
          return true;
        }
        
        return data['success'] == true || data['status'] == 'success';
      }
    } catch (e) {
      print('❌ Update profile error: $e');
    }
    return false;
  }

  // ✅ METHOD OVERLOAD JIKA PERLU DENGAN USERNAME
  Future<bool> updateUserProfileWithUsername(String username, Map<String, dynamic> profileData) async {
    try {
      final headers = await getProtectedHeaders();
      
      final dataWithUsername = Map<String, dynamic>.from(profileData);
      dataWithUsername['username'] = username;
      
      final body = dataWithUsername.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('&');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/updateProfile'),
        headers: headers,
        body: body,
      );

      print('🔧 Update Profile Response: ${response.statusCode}');
      print('🔧 Update Profile Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true || data['status'] == 'success';
      }
    } catch (e) {
      print('❌ Update profile error: $e');
    }
    return false;
  }

  // ✅ UPDATE PHOTO (ALIAS FOR UPLOAD FOTO)
  Future<bool> updatePhoto(String type, String filePath) async {
    return await uploadFoto(type: type, filePath: filePath);
  }

  // ============ MASTER DATA METHODS ============

  // ✅ GET MASTER DATA
  Future<Map<String, dynamic>> getMasterData() async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/master/get'),
        headers: headers,
        body: '',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
          'message': 'Success get master data'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil master data',
          'data': {}
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'data': {}
      };
    }
  }

  // ✅ GET PROVINCE
  Future<Map<String, dynamic>> getProvince() async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/master/getProvince'),
        headers: headers,
        body: '',
      );

      print('📍 Get Province Response: ${response.statusCode}');
      print('📍 Get Province Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Success get province'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data province: ${response.statusCode}',
          'data': []
        };
      }
    } catch (e) {
      print('❌ Get province error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': []
      };
    }
  }

  // ✅ GET REGENCY
  Future<Map<String, dynamic>> getRegency(String idProvince) async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/master/getRegency'),
        headers: headers,
        body: 'id_province=$idProvince',
      );

      print('📍 Get Regency Response: ${response.statusCode}');
      print('📍 Get Regency Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Success get regency'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data regency: ${response.statusCode}',
          'data': []
        };
      }
    } catch (e) {
      print('❌ Get regency error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': []
      };
    }
  }

  // ============ TRANSACTION METHODS ============

  // ✅ GET ALL SALDO (TABUNGAN DATA)
  Future<Map<String, dynamic>> getAllSaldo() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllSaldo'),
        headers: headers,
        body: '',
      );

      print('💰 Get All Saldo Response: ${response.statusCode}');
      print('💰 Get All Saldo Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
          'message': data['message'] ?? 'Success get saldo'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data saldo: ${response.statusCode}',
          'data': {}
        };
      }
    } catch (e) {
      print('❌ Get all saldo error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': {}
      };
    }
  }

  // ✅ GET ALL ANGSURAN (TAQSITH DATA)
  Future<Map<String, dynamic>> getAllAngsuran() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllTaqsith'),
        headers: headers,
        body: '',
      );

      print('📊 Get All Angsuran Response: ${response.statusCode}');
      print('📊 Get All Angsuran Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
          'message': data['message'] ?? 'Success get angsuran'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data angsuran: ${response.statusCode}',
          'data': {}
        };
      }
    } catch (e) {
      print('❌ Get all angsuran error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': {}
      };
    }
  }

  // ✅ GET RIWAYAT TABUNGAN
  Future<List<dynamic>> getRiwayatTabungan() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getRiwayatTabungan'),
        headers: headers,
        body: '',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Get riwayat tabungan error: $e');
      return [];
    }
  }

  // ✅ GET RIWAYAT ANGSURAN
  Future<List<dynamic>> getRiwayatAngsuran() async {
    try {
      final headers = await getProtectedHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getRiwayatAngsuran'),
        headers: headers,
        body: '',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Get riwayat angsuran error: $e');
      return [];
    }
  }

  // ============ INBOX METHODS - DIPERBAIKI DENGAN API KEY NOTIFICATION ============

  // ✅ INSERT INBOX (Send notification) - PAKAI API KEY NOTIFICATION
  Future<Map<String, dynamic>> insertInbox({
    required String subject,
    required String keterangan,
    required String userId,
  }) async {
    try {
      final headers = await getInboxHeaders(withContentType: true);
      
      final body = 'subject=${Uri.encodeComponent(subject)}&keterangan=${Uri.encodeComponent(keterangan)}&user_id=${Uri.encodeComponent(userId)}';

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/InsertInbox'),
        headers: headers,
        body: body,
      );

      print('📥 Insert Inbox Response: ${response.statusCode}');
      print('📥 Insert Inbox Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true || data['status'] == 'success',
          'message': data['message'] ?? 'Notifikasi berhasil dikirim',
          'data': data['data'] ?? {}
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengirim notifikasi: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Insert inbox error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET ALL INBOX - PAKAI API KEY NOTIFICATION
  Future<Map<String, dynamic>> getAllInbox() async {
    try {
      final headers = await getInboxHeaders(withContentType: false);
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getAllinbox'),
        headers: headers,
      );

      print('📥 Get All Inbox Response: ${response.statusCode}');
      print('📥 Get All Inbox Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Success get inbox'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data inbox: ${response.statusCode}',
          'data': []
        };
      }
    } catch (e) {
      print('❌ Get all inbox error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': []
      };
    }
  }

  // ✅ GET INBOX READ (Mark as read single) - PAKAI API KEY NOTIFICATION
  Future<Map<String, dynamic>> getInboxRead(String idInbox) async {
    try {
      final headers = await getInboxHeaders(withContentType: true);
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getInboxRead'),
        headers: headers,
        body: 'id_inbox=$idInbox',
      );

      print('📥 Get Inbox Read Response: ${response.statusCode}');
      print('📥 Get Inbox Read Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true || data['status'] == 'success',
          'message': data['message'] ?? 'Inbox marked as read'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mark as read: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Get inbox read error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET INBOX READ ALL (Mark all as read) - PAKAI API KEY NOTIFICATION
  Future<Map<String, dynamic>> getInboxReadAll() async {
    try {
      final headers = await getInboxHeaders(withContentType: false);
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getInboxReadAll'),
        headers: headers,
      );

      print('📥 Get Inbox Read All Response: ${response.statusCode}');
      print('📥 Get Inbox Read All Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true || data['status'] == 'success',
          'message': data['message'] ?? 'All inbox marked as read'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mark all as read: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Get inbox read all error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET INBOX DELETED (Delete single inbox) - PAKAI API KEY NOTIFICATION
  Future<Map<String, dynamic>> getInboxDeleted(String idInbox) async {
    try {
      final headers = await getInboxHeaders(withContentType: true);
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getInboxDeleted'),
        headers: headers,
        body: 'id_inbox=$idInbox',
      );

      print('📥 Get Inbox Deleted Response: ${response.statusCode}');
      print('📥 Get Inbox Deleted Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true || data['status'] == 'success',
          'message': data['message'] ?? 'Inbox deleted successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal delete inbox: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Get inbox deleted error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET INBOX DELETED ALL (Delete all inbox) - PAKAI API KEY NOTIFICATION
  Future<Map<String, dynamic>> getInboxDeletedAll() async {
    try {
      final headers = await getInboxHeaders(withContentType: false);
      
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/getInboxDeletedAll'),
        headers: headers,
      );

      print('📥 Get Inbox Deleted All Response: ${response.statusCode}');
      print('📥 Get Inbox Deleted All Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true || data['status'] == 'success',
          'message': data['message'] ?? 'All inbox deleted successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal delete all inbox: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Get inbox deleted all error: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ============ DOKUMEN METHODS ============

  // ✅ UPLOAD FOTO (KTP, KK, etc)
  Future<bool> uploadFoto({
    required String type, // 'foto_ktp', 'foto_kk', 'foto_diri', 'foto_bukti'
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
      request.fields[type] = 'uploaded';
      request.files.add(await http.MultipartFile.fromPath(type, filePath));

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Upload $type error: $e');
      return false;
    }
  }

  // ✅ UPLOAD KTP (ALIAS FOR UPLOAD FOTO)
  Future<bool> updateKTP(String username, String filePath) async {
    return await uploadFoto(type: 'foto_ktp', filePath: filePath);
  }

  // ✅ UPLOAD KK (ALIAS FOR UPLOAD FOTO)
  Future<bool> updateKK(String username, String filePath) async {
    return await uploadFoto(type: 'foto_kk', filePath: filePath);
  }

  // ✅ UPLOAD BUKTI PEMBAYARAN
  Future<bool> uploadBuktiPembayaran(String filePath) async {
    return await uploadFoto(type: 'foto_bukti', filePath: filePath);
  }

  // ============ UTILITY METHODS ============

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
        return data['success'] == true;
      }
    } catch (e) {
      print('❌ Change password error: $e');
    }
    return false;
  }

  // ✅ CHECK USER EXIST
  Future<Map<String, dynamic>> checkUserExist(String username, String email) async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/checkUserExist'),
        headers: headers,
        body: 'username=${Uri.encodeComponent(username)}&email=${Uri.encodeComponent(email)}',
      );

      print('🔍 Check User Exist Response: ${response.statusCode}');
      print('🔍 Check User Exist Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['exists'] == true) {
          return {'exists': true, 'message': data['message'] ?? 'User sudah terdaftar'};
        } else if (data['available'] == true) {
          return {'exists': false, 'message': 'User tersedia'};
        } else if (data['success'] == false && data['message'] != null) {
          return {'exists': true, 'message': data['message']};
        } else {
          return {'exists': false, 'message': 'User tersedia'};
        }
      } else {
        return {
          'exists': false, 
          'message': 'Tidak dapat memeriksa user, silakan coba lagi'
        };
      }
    } catch (e) {
      print('❌ Check user exist error: $e');
      return {
        'exists': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ GET CURRENT USER FROM SESSION
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString != null) {
        return jsonDecode(userString);
      }
      return null;
    } catch (e) {
      print('❌ Get current user error: $e');
      return null;
    }
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  // ✅ CHECK AUTH STATUS
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }
}