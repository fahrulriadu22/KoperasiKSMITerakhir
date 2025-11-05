import 'dart:io';
import 'package:http_parser/http_parser.dart';

class FileValidator {
  // ✅ VALIDASI FILE UNTUK UPLOAD - DIPERBAIKI
  static Future<Map<String, dynamic>> validateImageFile(String filePath) async {
    try {
      File file = File(filePath);
      
      // Check if file exists
      if (!await file.exists()) {
        return {
          'valid': false, 
          'message': 'File tidak ditemukan: $filePath',
          'error_code': 'FILE_NOT_FOUND'
        };
      }

      // Check file size (max 5MB)
      int fileSize = await file.length();
      if (fileSize == 0) {
        return {
          'valid': false, 
          'message': 'File kosong atau tidak dapat dibaca',
          'error_code': 'EMPTY_FILE'
        };
      }

      if (fileSize > 5 * 1024 * 1024) {
        return {
          'valid': false, 
          'message': 'Ukuran file terlalu besar (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB). Maksimal 5MB.',
          'error_code': 'FILE_TOO_LARGE',
          'file_size': fileSize
        };
      }

      // Check file extension - HANYA JPG/JPEG
      String extension = filePath.split('.').last.toLowerCase();
      if (extension != 'jpg' && extension != 'jpeg') {
        return {
          'valid': false, 
          'message': 'Format file .$extension tidak didukung. Hanya JPG/JPEG yang diperbolehkan.',
          'error_code': 'INVALID_EXTENSION',
          'extension': extension
        };
      }

      // Check MIME type dengan validasi yang lebih baik
      List<int> bytes = await file.readAsBytes();
      String mimeType = _getMimeType(bytes);
      if (mimeType != 'image/jpeg') {
        return {
          'valid': false, 
          'message': 'File harus berupa gambar JPEG yang valid. Terdeteksi: $mimeType',
          'error_code': 'INVALID_MIME_TYPE',
          'mime_type': mimeType
        };
      }

      return {
        'valid': true, 
        'message': 'File valid',
        'file_size': fileSize,
        'extension': extension,
        'mime_type': mimeType
      };
    } catch (e) {
      return {
        'valid': false, 
        'message': 'Error validasi file: ${e.toString()}',
        'error_code': 'VALIDATION_ERROR'
      };
    }
  }

  // ✅ DETEKSI MIME TYPE DARI BYTES - DIPERBAIKI
  static String _getMimeType(List<int> bytes) {
    if (bytes.length < 2) return 'unknown';
    
    // Check JPEG signature (FF D8 FF)
    if (bytes.length >= 3 && 
        bytes[0] == 0xFF && 
        bytes[1] == 0xD8 && 
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    
    // Check PNG signature
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    
    return 'unknown';
  }

  // ✅ VALIDASI UNTUK BUKTI TRANSFER - DIPERBAIKI
  static Future<Map<String, dynamic>> validateBuktiTransfer(String filePath) async {
    final result = await validateImageFile(filePath);
    if (!result['valid']) {
      return result;
    }

    // Additional validation for transfer proof
    try {
      File file = File(filePath);
      final fileSize = await file.length();
      
      if (fileSize < 10 * 1024) { // 10KB minimum untuk memastikan kualitas
        return {
          'valid': false,
          'message': 'Kualitas gambar terlalu rendah. Pastikan gambar jelas dan terbaca.',
          'error_code': 'LOW_QUALITY',
          'file_size': fileSize
        };
      }

      return {
        'valid': true,
        'message': 'Bukti transfer valid',
        'file_size': fileSize
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Error validasi bukti transfer: ${e.toString()}',
        'error_code': 'VALIDATION_ERROR'
      };
    }
  }

  // ✅ GET FILE INFO UNTUK DEBUG - DIPERBAIKI
  static Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      File file = File(filePath);
      final stat = await file.stat();
      final bytes = await file.readAsBytes();
      final mimeType = _getMimeType(bytes);
      
      return {
        'exists': await file.exists(),
        'size': stat.size,
        'size_kb': (stat.size / 1024).toStringAsFixed(2),
        'size_mb': (stat.size / 1024 / 1024).toStringAsFixed(2),
        'modified': stat.modified.toString(),
        'extension': filePath.split('.').last.toLowerCase(),
        'mime_type': mimeType,
        'path': filePath,
        'filename': filePath.split('/').last,
        'is_valid_jpeg': mimeType == 'image/jpeg',
        'needs_conversion': mimeType != 'image/jpeg'
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'exists': false
      };
    }
  }

  // ✅ METHOD BARU: Quick validation untuk UI
  static Future<bool> isFileValid(String filePath) async {
    final result = await validateImageFile(filePath);
    return result['valid'] == true;
  }

  // ✅ METHOD BARU: Get allowed extensions
  static List<String> getAllowedExtensions() {
    return ['jpg', 'jpeg'];
  }

  // ✅ METHOD BARU: Get max file size
  static int getMaxFileSize() {
    return 5 * 1024 * 1024; // 5MB
  }

  // ✅ METHOD BARU: Convert PNG to JPG jika diperlukan
  static Future<File?> convertToJpgIfNeeded(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final mimeType = _getMimeType(bytes);
      
      if (mimeType == 'image/jpeg') {
        // Already JPG, no conversion needed
        return originalFile;
      }
      
      // For PNG conversion, you would need image package
      // This is a placeholder - implement actual conversion if needed
      return originalFile;
    } catch (e) {
      return null;
    }
  }

  // ✅ METHOD BARU: Validate multiple files
  static Future<Map<String, dynamic>> validateMultipleFiles(List<String> filePaths) async {
    final results = <String, Map<String, dynamic>>{};
    bool allValid = true;
    String overallMessage = '';

    for (final filePath in filePaths) {
      final result = await validateImageFile(filePath);
      results[filePath] = result;
      
      if (!result['valid']) {
        allValid = false;
        overallMessage = result['message'];
        break; // Stop on first error
      }
    }

    return {
      'all_valid': allValid,
      'message': allValid ? 'Semua file valid' : overallMessage,
      'results': results,
      'valid_count': results.values.where((r) => r['valid'] == true).length,
      'invalid_count': results.values.where((r) => r['valid'] == false).length,
    };
  }
}