import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class FileConverterService {
  static final FileConverterService _instance = FileConverterService._internal();
  factory FileConverterService() => _instance;
  FileConverterService._internal();

  // ✅ AUTO CONVERT KE JPG - DIPERBAIKI
  Future<File> convertToJpg(File originalFile) async {
    try {
      final originalPath = originalFile.path;
      final originalExtension = originalPath.split('.').last.toLowerCase();
      
      print('🔄 AUTO-CONVERT: .$originalExtension → .jpg');
      print('📁 Original: $originalPath');

      // ✅ Jika sudah JPG, return as is
      if (originalExtension == 'jpg' || originalExtension == 'jpeg') {
        print('✅ Already JPG, no conversion needed');
        return originalFile;
      }

      // ✅ Baca file sebagai bytes
      final bytes = await originalFile.readAsBytes();
      print('📊 File size: ${bytes.length} bytes');

      // ✅ Validasi ukuran file
      if (bytes.isEmpty) {
        throw Exception('File kosong atau tidak dapat dibaca');
      }

      if (bytes.length > 10 * 1024 * 1024) { // 10MB max
        throw Exception('Ukuran file terlalu besar (>10MB)');
      }

      // ✅ Decode image berdasarkan format
      img.Image? image;
      
      if (originalExtension == 'png') {
        image = img.decodePng(bytes);
        print('🎨 Decoding PNG...');
      } else {
        // Untuk format lain, coba decode sebagai image umum
        try {
          image = img.decodeImage(bytes);
          print('🎨 Decoding image...');
        } catch (e) {
          print('❌ Cannot decode image format .$originalExtension: $e');
          // Fallback: copy file dengan extension .jpg
          return _fallbackConvert(originalFile, 'jpg');
        }
      }

      if (image == null) {
        throw Exception('Gagal decode image - file mungkin corrupt');
      }

      // ✅ PERBAIKAN: Resize image jika terlalu besar (max 1200px)
      if (image.width > 1200 || image.height > 1200) {
        print('📐 Resizing image from ${image.width}x${image.height}');
        image = img.copyResize(image, width: 1200, height: 1200);
      }

      // ✅ Encode ke JPG dengan quality 85%
      final jpgBytes = img.encodeJpg(image, quality: 85);
      print('✅ Encoded to JPG: ${jpgBytes.length} bytes');

      // ✅ Validasi hasil encode
      if (jpgBytes.isEmpty) {
        throw Exception('Gagal encode ke JPG - hasil kosong');
      }

      // ✅ Simpan file JPG baru
      final newPath = originalPath.replaceAll(
        RegExp(r'\.[^\.]+$'), 
        '_converted_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );
      final newFile = File(newPath);
      await newFile.writeAsBytes(jpgBytes);

      print('💾 Saved converted file: $newPath (${jpgBytes.length} bytes)');
      
      return newFile;
    } catch (e) {
      print('❌ Auto-convert error: $e');
      // Fallback ke method sederhana
      return _fallbackConvert(originalFile, 'jpg');
    }
  }

  // ✅ FALLBACK CONVERT (jika image processing gagal) - DIPERBAIKI
  Future<File> _fallbackConvert(File originalFile, String newExtension) async {
    try {
      final originalPath = originalFile.path;
      final newPath = originalPath.replaceAll(
        RegExp(r'\.[^\.]+$'), 
        '_fallback_${DateTime.now().millisecondsSinceEpoch}.$newExtension'
      );
      
      print('🔄 Fallback convert: $originalPath → $newPath');
      
      // Copy file dengan nama baru
      final newFile = await originalFile.copy(newPath);
      
      // Validasi file hasil copy
      final newFileSize = await newFile.length();
      if (newFileSize == 0) {
        throw Exception('Fallback conversion failed - file kosong');
      }
      
      print('✅ Fallback conversion successful: $newPath');
      return newFile;
    } catch (e) {
      print('❌ Fallback conversion error: $e');
      rethrow;
    }
  }

  // ✅ VALIDATE & CONVERT IF NEEDED - DIPERBAIKI
  Future<File> validateAndConvert(File file, {String type = 'document'}) async {
    try {
      final path = file.path;
      final extension = path.split('.').last.toLowerCase();
      
      print('🔍 Validating file: .$extension');
      
      // ✅ Validasi file exists
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan: $path');
      }

      // ✅ Validasi ukuran file
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File kosong: $path');
      }

      if (fileSize > 10 * 1024 * 1024) { // 10MB max
        throw Exception('Ukuran file terlalu besar (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB). Maksimal 10MB.');
      }

      // ✅ Format yang langsung diizinkan
      if (extension == 'jpg' || extension == 'jpeg') {
        print('✅ Valid JPG file - ready for upload');
        return file;
      }
      
      // ✅ Format yang perlu di-convert
      if (['png', 'heic', 'heif', 'webp'].contains(extension)) {
        print('🔄 Converting .$extension to JPG...');
        return await convertToJpg(file);
      }
      
      // ❌ Format tidak didukung
      throw Exception('Format .$extension tidak didukung untuk $type. Gunakan JPG, PNG, atau HEIC.');
    } catch (e) {
      print('❌ File validation error: $e');
      rethrow;
    }
  }

  // ✅ GET FILE INFO - DIPERBAIKI
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      if (!await file.exists()) {
        return {
          'exists': false,
          'error': 'File tidak ditemukan'
        };
      }

      final stat = await file.stat();
      final path = file.path;
      final extension = path.split('.').last.toLowerCase();
      final filename = path.split('/').last;
      
      return {
        'exists': true,
        'path': path,
        'filename': filename,
        'extension': extension,
        'size': stat.size,
        'size_kb': (stat.size / 1024).toStringAsFixed(2),
        'size_mb': (stat.size / 1024 / 1024).toStringAsFixed(2),
        'modified': stat.modified,
        'needs_conversion': !['jpg', 'jpeg'].contains(extension),
      };
    } catch (e) {
      print('❌ Get file info error: $e');
      return {
        'exists': false,
        'error': e.toString()
      };
    }
  }

  // ✅ METHOD BARU: Clean up temporary files
  Future<void> cleanupTemporaryFiles({int maxAgeHours = 24}) async {
    try {
      final tempDir = Directory.systemTemp;
      final now = DateTime.now();
      final cutoffTime = now.subtract(Duration(hours: maxAgeHours));
      
      print('🧹 Cleaning up temporary files older than $maxAgeHours hours...');
      
      await for (var file in tempDir.list()) {
        if (file is File) {
          final stat = await file.stat();
          final filename = file.path.split('/').last;
          
          // Hapus file temporary yang mengandung '_converted_' atau '_fallback_'
          if (filename.contains('_converted_') || filename.contains('_fallback_')) {
            if (stat.modified.isBefore(cutoffTime)) {
              try {
                await file.delete();
                print('🗑️ Deleted old temp file: $filename');
              } catch (e) {
                print('⚠️ Failed to delete temp file: $filename - $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }

  // ✅ METHOD BARU: Check if file needs conversion
  bool needsConversion(File file) {
    final path = file.path;
    final extension = path.split('.').last.toLowerCase();
    return !['jpg', 'jpeg'].contains(extension);
  }

  // ✅ METHOD BARU: Get supported formats
  List<String> getSupportedFormats() {
    return ['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'];
  }

  // ✅ METHOD BARU: Get allowed extensions for upload (hanya JPG)
  List<String> getAllowedUploadFormats() {
    return ['jpg', 'jpeg'];
  }
}