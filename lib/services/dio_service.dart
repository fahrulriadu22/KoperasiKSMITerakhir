import 'dart:io';
import 'dart:convert'; // ✅ TAMBAH INI
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        final userData = jsonDecode(userString); // ✅ SEKARANG SUDAH BISA
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

  // ✅ UPLOAD BUKTI TRANSFER DENGAN DIO
  Future<Map<String, dynamic>> uploadBuktiTransferWithDio({
    required String transaksiId,
    required String filePath,
    required String jenisTransaksi,
  }) async {
    try {
      print('🚀 DIO UPLOAD BUKTI TRANSFER START');
      print('📁 Transaksi ID: $transaksiId');
      print('📁 Jenis: $jenisTransaksi');
      print('📁 File path: $filePath');
      
      final headers = await _getHeaders();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return {'success': false, 'message': 'File bukti transfer tidak ditemukan'};
      }

      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return {'success': false, 'message': 'Ukuran file terlalu besar. Maksimal 5MB.'};
      }

      // ✅ BUAT FORM DATA DENGAN DIO
      FormData formData = FormData.fromMap({
        'transaksi_id': transaksiId,
        'jenis_transaksi': jenisTransaksi,
        'bukti_transfer': await MultipartFile.fromFile(
          filePath,
          filename: 'bukti_${jenisTransaksi}_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
      }

      print('📤 DIO Bukti Headers: $headers');
      print('📤 DIO Bukti Form data fields: ${formData.fields}');

      // ✅ KIRIM DENGAN DIO
      final response = await dio.post(
        '/transaction/uploadBukti',
        data: formData,
        options: Options(headers: headers),
      );

      print('📡 DIO Bukti Response: ${response.statusCode}');
      print('📡 DIO Bukti Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
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
      } else {
        return {
          'success': false,
          'message': 'Server error ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ DIO BUKTI UPLOAD ERROR: $e');
      if (e is DioException) {
        print('❌ DIO Bukti Error Response: ${e.response?.data}');
        print('❌ DIO Bukti Error Status: ${e.response?.statusCode}');
        return {
          'success': false,
          'message': 'Upload bukti error: ${e.response?.data?['message'] ?? e.message}'
        };
      }
      return {
        'success': false,
        'message': 'Upload bukti error: $e'
      };
    }
  }

  // ✅ TEST CONNECTION
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await dio.get(
        '/',
        options: Options(
          headers: await _getHeaders(),
        ),
      );
      
      return {
        'success': true,
        'status_code': response.statusCode,
        'message': 'Connection successful'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: $e'
      };
    }
  }
}