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

  // ✅ GET MULTIPART HEADERS UNTUK UPLOAD FILE
  Future<Map<String, String>> getMultipartHeaders() async {
    try {
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
    } catch (e) {
      print('❌ Error getMultipartHeaders: $e');
      return {
        'DEVICE-ID': _deviceId,
        'DEVICE-TOKEN': _deviceToken,
      };
    }
  }

  // ✅ PERBAIKAN: UPLOAD FOTO DENGAN HANDLE RESPONSE YANG TIDAK LENGKAP
  Future<Map<String, dynamic>> uploadFoto({
    required String type,
    required String filePath,
  }) async {
    try {
      print('🚀 UPLOAD START: $type');
      
      // Validasi file
      File file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'File tidak ditemukan'};
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return {'success': false, 'message': 'Ukuran file terlalu besar. Maksimal 5MB.'};
      }

      // Get headers
      final headers = await getMultipartHeaders();
      
      // Create request
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/setPhoto')
      );
      request.headers.addAll(headers);

      // Add file - coba field name yang berbeda
      final possibleFieldNames = ['file', 'foto', 'photo', 'image', type];
      bool fileAdded = false;
      
      for (final fieldName in possibleFieldNames) {
        try {
          request.files.add(await http.MultipartFile.fromPath(
            fieldName,
            filePath,
          ));
          print('📤 Using field name: $fieldName');
          fileAdded = true;
          break;
        } catch (e) {
          print('❌ Failed with field $fieldName: $e');
        }
      }

      if (!fileAdded) {
        return {'success': false, 'message': 'Gagal menambahkan file ke request'};
      }

      // Add required fields
      request.fields['type'] = type;
      
      // Add user_id if available
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
      print('📤 File count: ${request.files.length}');

      // Send request
      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      
      print('📡 RESPONSE STATUS: ${response.statusCode}');
      print('📡 RESPONSE BODY: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        
        if (data['status'] == true) {
          print('✅ UPLOAD SUCCESS');
          
          // ✅ PERBAIKAN: Handle response tanpa file_path
          String fileUrl = '';
          
          // Cari file_path di berbagai kemungkinan key
          if (data['file_path'] != null) {
            fileUrl = data['file_path'].toString();
          } else if (data['file_url'] != null) {
            fileUrl = data['file_url'].toString();
          } else if (data['url'] != null) {
            fileUrl = data['url'].toString();
          } else if (data['image_url'] != null) {
            fileUrl = data['image_url'].toString();
          } else if (data['path'] != null) {
            fileUrl = data['path'].toString();
          }
          
          // Update local storage meskipun tidak ada file_path
          if (fileUrl.isNotEmpty) {
            await _updateUserPhoto(type, fileUrl);
          } else {
            // Jika tidak ada file_path, set flag bahwa upload berhasil
            await _updateUserPhoto(type, 'uploaded');
          }
          
          return {
            'success': true,
            'message': data['message'] ?? 'Upload berhasil',
            'file_path': fileUrl
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

  // ✅ UPDATE: Handle berbagai status upload
  Future<void> _updateUserPhoto(String type, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = jsonDecode(userString);
        
        // Simpan status upload
        userData[type] = status;
        
        await prefs.setString('user', jsonEncode(userData));
        print('✅ Local storage updated for $type: $status');
      }
    } catch (e) {
      print('❌ Error updating user photo locally: $e');
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

  // ✅ UPLOAD BUKTI TRANSFER
  Future<Map<String, dynamic>> uploadBuktiTransfer({
    required String transaksiId,
    required String filePath,
    required String jenisTransaksi,
  }) async {
    try {
      final headers = await getMultipartHeaders();
      
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
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/transaction/uploadBukti')
      );
      
      request.headers.addAll(headers);
      
      final fileExtension = filePath.toLowerCase().substring(filePath.lastIndexOf('.'));
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_transfer',
        filePath,
        filename: 'bukti_${jenisTransaksi}_${DateTime.now().millisecondsSinceEpoch}$fileExtension',
      ));

      request.fields['transaksi_id'] = transaksiId;
      request.fields['jenis_transaksi'] = jenisTransaksi;

      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Bukti transfer berhasil diupload',
            'file_path': data['file_path']
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
          'message': 'Upload bukti transfer gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ✅ METHOD LAINNYA...
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