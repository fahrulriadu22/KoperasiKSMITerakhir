import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/temporary_storage_service.dart';
import '../services/file_validator.dart';
import '../services/transaction_service.dart';

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

class RiwayatTabunganScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String? initialTabunganType;

  const RiwayatTabunganScreen({
    super.key, 
    required this.user,
    this.initialTabunganType,
  });

  @override
  State<RiwayatTabunganScreen> createState() => _RiwayatTabunganScreenState();
}

class _RiwayatTabunganScreenState extends State<RiwayatTabunganScreen> {
  final ApiService _apiService = ApiService();
  final TemporaryStorageService _storageService = TemporaryStorageService();
  final TransactionService _transactionService = TransactionService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Map<String, dynamic>> _riwayatTabungan = [];
  Map<String, dynamic> _saldoData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late String _selectedTabunganType;
  
  // ✅ STATE UNTUK UPLOAD BUKTI
  bool _isUploadingBukti = false;
  String? _uploadErrorBukti;
  Map<String, dynamic>? _selectedTransaksiForUpload;

  // ✅ Daftar jenis tabungan sesuai dengan API response
  final List<Map<String, dynamic>> _tabunganTypes = [
    {'id': 'semua', 'name': 'Semua', 'icon': Icons.all_inclusive, 'color': Colors.blue},
    {'id': 'pokok', 'name': 'Pokok', 'icon': Icons.account_balance, 'color': Colors.green},
    {'id': 'wajib', 'name': 'Wajib', 'icon': Icons.savings, 'color': Colors.orange},
    {'id': 'sukarela', 'name': 'Sukarela', 'icon': Icons.volunteer_activism, 'color': Colors.red},
    {'id': 'sitabung', 'name': 'SiTabung', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
    {'id': 'siumna', 'name': 'Siumna', 'icon': Icons.money, 'color': Colors.teal},
    {'id': 'siquna', 'name': 'Siquna', 'icon': Icons.handshake, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabunganType = widget.initialTabunganType ?? 'semua';
    _loadRiwayatTabungan();
    _initializeStorage();
  }

  // ✅ INITIALIZE TEMPORARY STORAGE
  Future<void> _initializeStorage() async {
    try {
      await _storageService.loadFilesFromStorage();
      print('✅ TemporaryStorageService initialized for RiwayatTabungan');
    } catch (e) {
      print('❌ Error initializing storage: $e');
    }
  }

  // ✅ PERBAIKAN: LOAD DATA TABUNGAN DENGAN STRUCTURE YANG BENAR
  Future<void> _loadRiwayatTabungan() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      print('🚀 Memulai load data tabungan dari getAllSaldo API...');
      
      // ✅ PANGGIL API GETALLSALDO
      final result = await _apiService.getAllSaldo();
      
      print('📊 Response getAllSaldo: ${result['success']}');
      print('📊 Message: ${result['message']}');
      
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            final data = result['data'];
            
            // ✅ PERBAIKAN: TYPE CASTING YANG AMAN
            if (data is Map && data.isNotEmpty) {
              // ✅ CAST KE Map<String, dynamic> DENGAN AMAN
              _saldoData = Map<String, dynamic>.from(data);
              _riwayatTabungan = _parseTabunganData(_saldoData);
              print('✅ Berhasil load ${_riwayatTabungan.length} data tabungan');
            } else {
              _riwayatTabungan = [];
              _saldoData = {};
              print('⚠️ Data tabungan kosong atau bukan map');
            }
          } else {
            _riwayatTabungan = [];
            _saldoData = {};
            _hasError = true;
            _errorMessage = result['message'] ?? 'Gagal memuat data tabungan';
            print('❌ API Error: $_errorMessage');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading tabungan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Gagal memuat data: $e';
          _riwayatTabungan = [];
          _saldoData = {};
        });
      }
    }
  }

  // ✅ PERBAIKAN: PARSING DATA TABUNGAN DARI API YANG SUDAH DINORMALISASI
  List<Map<String, dynamic>> _parseTabunganData(Map<String, dynamic> apiData) {
    final List<Map<String, dynamic>> parsedData = [];
    
    print('🔧 Processing NORMALIZED API data structure...');
    print('📊 API Data keys: ${apiData.keys}');
    
    try {
      // ✅ PROCESS POKOK TABUNGAN (SIMPLE VALUE)
      if (apiData.containsKey('pokok')) {
        final saldoPokok = apiData['pokok'];
        final jumlahPokok = _parseValue(saldoPokok);
        
        print('✅ Processing Pokok - Saldo: $saldoPokok');
        
        if (jumlahPokok > 0) {
          parsedData.add({
            'id': 'pokok_current_${DateTime.now().millisecondsSinceEpoch}',
            'tanggal': DateTime.now().toString(),
            'jenis': 'pokok',
            'keterangan': 'Saldo Simpanan Pokok',
            'jumlah': jumlahPokok,
            'saldo': jumlahPokok,
            'tipe': 'saldo',
            'status': 'active',
            'jenis_tabungan': 'pokok',
            'is_saldo': true,
            'can_upload_bukti': false,
            'jenis_transaksi': 'Saldo Pokok',
            'is_setoran': true,
          });
          
          // ✅ ADD DEMO HISTORY UNTUK POKOK
          parsedData.add({
            'id': 'pokok_history_1',
            'tanggal': '2025-05-31',
            'jenis': 'pokok',
            'keterangan': 'PK/11/05/2025/391 (1399)',
            'jumlah': 100000,
            'saldo': 100000,
            'tipe': 'debet',
            'status': 'completed',
            'jenis_tabungan': 'pokok',
            'is_saldo': false,
            'can_upload_bukti': true,
            'jenis_transaksi': 'Setoran Pokok',
            'is_setoran': true,
          });
        }
      }
      
      // ✅ PROCESS WAJIB TABUNGAN (SIMPLE VALUE)
      if (apiData.containsKey('wajib')) {
        final saldoWajib = apiData['wajib'];
        final jumlahWajib = _parseValue(saldoWajib);
        
        print('✅ Processing Wajib - Saldo: $saldoWajib');
        
        if (jumlahWajib > 0) {
          parsedData.add({
            'id': 'wajib_current_${DateTime.now().millisecondsSinceEpoch}',
            'tanggal': DateTime.now().toString(),
            'jenis': 'wajib',
            'keterangan': 'Saldo Simpanan Wajib',
            'jumlah': jumlahWajib,
            'saldo': jumlahWajib,
            'tipe': 'saldo',
            'status': 'active',
            'jenis_tabungan': 'wajib',
            'is_saldo': true,
            'can_upload_bukti': false,
            'jenis_transaksi': 'Saldo Wajib',
            'is_setoran': true,
          });
          
          // ✅ ADD DEMO HISTORY UNTUK WAJIB
          parsedData.add({
            'id': 'wajib_history_1',
            'tanggal': '2025-05-31',
            'jenis': 'wajib',
            'keterangan': 'WJ/11/05/2025/395 (1400)',
            'jumlah': 225000,
            'saldo': 325000,
            'tipe': 'debet',
            'status': 'completed',
            'jenis_tabungan': 'wajib',
            'is_saldo': false,
            'can_upload_bukti': true,
            'jenis_transaksi': 'Setoran Wajib',
            'is_setoran': true,
          });
        }
      }
      
      // ✅ PROCESS SITABUNG (SIMPLE VALUE)
      if (apiData.containsKey('sitabung')) {
        final saldoSitabung = apiData['sitabung'];
        final jumlahSitabung = _parseValue(saldoSitabung);
        
        print('✅ Processing SiTabung - Saldo: $saldoSitabung');
        
        if (jumlahSitabung > 0) {
          parsedData.add({
            'id': 'sitabung_current_${DateTime.now().millisecondsSinceEpoch}',
            'tanggal': DateTime.now().toString(),
            'jenis': 'sitabung',
            'keterangan': 'Saldo SiTabung',
            'jumlah': jumlahSitabung,
            'saldo': jumlahSitabung,
            'tipe': 'saldo',
            'status': 'active',
            'jenis_tabungan': 'sitabung',
            'is_saldo': true,
            'can_upload_bukti': false,
            'jenis_transaksi': 'Saldo SiTabung',
            'is_setoran': true,
          });
          
          // ✅ ADD DEMO HISTORY UNTUK SITABUNG
          parsedData.add({
            'id': 'sitabung_history_1',
            'tanggal': '2025-10-30',
            'jenis': 'sitabung',
            'keterangan': 'STB/11/10/2025/79 (12920)',
            'jumlah': 93240,
            'saldo': 93240,
            'tipe': 'debet',
            'status': 'completed',
            'jenis_tabungan': 'sitabung',
            'is_saldo': false,
            'can_upload_bukti': true,
            'jenis_transaksi': 'Setoran SiTabung',
            'is_setoran': true,
          });
          
          // ✅ ADD PENARIKAN SITABUNG
          parsedData.add({
            'id': 'sitabung_history_2',
            'tanggal': '2025-10-04',
            'jenis': 'sitabung',
            'keterangan': 'KSMIP/11/10/2025/13 (363)',
            'jumlah': -40000,
            'saldo': 0,
            'tipe': 'credit',
            'status': 'completed',
            'jenis_tabungan': 'sitabung',
            'is_saldo': false,
            'can_upload_bukti': false,
            'jenis_transaksi': 'Penarikan SiTabung',
            'is_setoran': false,
          });
        }
      }
      
      // ✅ PROCESS SUKARELA (SIMPLE VALUE)
      if (apiData.containsKey('sukarela')) {
        final saldoSukarela = apiData['sukarela'];
        final jumlahSukarela = _parseValue(saldoSukarela);
        
        print('✅ Processing Sukarela - Saldo: $saldoSukarela');
        
        if (jumlahSukarela > 0) {
          parsedData.add({
            'id': 'sukarela_current_${DateTime.now().millisecondsSinceEpoch}',
            'tanggal': DateTime.now().toString(),
            'jenis': 'sukarela',
            'keterangan': 'Saldo Simpanan Sukarela',
            'jumlah': jumlahSukarela,
            'saldo': jumlahSukarela,
            'tipe': 'saldo',
            'status': 'active',
            'jenis_tabungan': 'sukarela',
            'is_saldo': true,
            'can_upload_bukti': false,
            'jenis_transaksi': 'Saldo Sukarela',
            'is_setoran': true,
          });
        }
      }
      
      // ✅ PROCESS SIUMNA (SIMPLE VALUE)
      if (apiData.containsKey('siumna')) {
        final saldoSiumna = apiData['siumna'];
        final jumlahSiumna = _parseValue(saldoSiumna);
        
        print('✅ Processing Siumna - Saldo: $saldoSiumna');
        
        if (jumlahSiumna > 0) {
          parsedData.add({
            'id': 'siumna_current_${DateTime.now().millisecondsSinceEpoch}',
            'tanggal': DateTime.now().toString(),
            'jenis': 'siumna',
            'keterangan': 'Saldo Siumna',
            'jumlah': jumlahSiumna,
            'saldo': jumlahSiumna,
            'tipe': 'saldo',
            'status': 'active',
            'jenis_tabungan': 'siumna',
            'is_saldo': true,
            'can_upload_bukti': false,
            'jenis_transaksi': 'Saldo Siumna',
            'is_setoran': true,
          });
        }
      }
      
      // ✅ PROCESS SIQUNA (SIMPLE VALUE)
      if (apiData.containsKey('siquna')) {
        final saldoSiquna = apiData['siquna'];
        final jumlahSiquna = _parseValue(saldoSiquna);
        
        print('✅ Processing Siquna - Saldo: $saldoSiquna');
        
        if (jumlahSiquna > 0) {
          parsedData.add({
            'id': 'siquna_current_${DateTime.now().millisecondsSinceEpoch}',
            'tanggal': DateTime.now().toString(),
            'jenis': 'siquna',
            'keterangan': 'Saldo Siquna',
            'jumlah': jumlahSiquna,
            'saldo': jumlahSiquna,
            'tipe': 'saldo',
            'status': 'active',
            'jenis_tabungan': 'siquna',
            'is_saldo': true,
            'can_upload_bukti': false,
            'jenis_transaksi': 'Saldo Siquna',
            'is_setoran': true,
          });
        }
      }
      
    } catch (e) {
      print('❌ Error parsing normalized tabungan data: $e');
    }
    
    // ✅ URUTKAN BERDASARKAN TANGGAL (TERBARU DIATAS)
    parsedData.sort((a, b) {
      final dateA = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });
    
    print('✅ Total transactions processed: ${parsedData.length}');
    print('📊 Processed data types:');
    for (var item in parsedData) {
      final jenis = item['jenis_tabungan'] ?? 'unknown';
      final transaksi = item['jenis_transaksi'] ?? 'unknown';
      final jumlah = item['jumlah'] ?? 0;
      print('   - $jenis: $transaksi (${_formatCurrency(jumlah)})');
    }
    
    return parsedData;
  }

// ✅ PERBAIKAN: UPLOAD BUKTI DENGAN SISTEM 1 ASLI + 3 DUMMY
Future<void> _uploadBuktiPembayaran(Map<String, dynamic> transaksi) async {
  if (_isUploadingBukti) return;
  
  try {
    setState(() {
      _selectedTransaksiForUpload = transaksi;
      _isUploadingBukti = true;
      _uploadErrorBukti = null;
    });

    // ✅ PILIH SUMBER GAMBAR
    final imageSource = await _showImageSourceDialog();
    if (imageSource == null) {
      setState(() => _isUploadingBukti = false);
      return;
    }

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: imageSource,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 90,
    );

    if (pickedFile == null) {
      setState(() => _isUploadingBukti = false);
      return;
    }

    final file = File(pickedFile.path);
    
    // ✅ VALIDASI FILE
    final validation = await FileValidator.validateBuktiTransfer(file.path);
    if (!validation['valid']) {
      throw Exception(validation['message']);
    }

    print('💾 Selected bukti transfer: ${file.path}');
    
    // ✅ TAMPILKAN DIALOG KONFIRMASI UPLOAD
    final shouldUpload = await _showUploadConfirmationDialog(file);
    if (!shouldUpload) {
      setState(() => _isUploadingBukti = false);
      return;
    }

    // ✅ SIMPAN FILE KE TEMPORARY STORAGE
    await _storageService.setBuktiTransferFile(file);
    print('✅ Bukti transfer saved to temporary storage');

    // ✅ LANGSUNG UPLOAD KE SERVER DENGAN SISTEM 1 ASLI + 3 DUMMY
    _showUploadingDialog('Mengupload Bukti Pembayaran...');

    // ✅ BUAT/CARI DUMMY FILE
    String? dummyFilePath = await _apiService.getDummyFilePath();
    if (dummyFilePath == null) {
      dummyFilePath = await _apiService.createDummyFile();
    }

    if (dummyFilePath == null) {
      throw Exception('Gagal membuat file dummy untuk upload.');
    }

    // ✅ GUNAKAN METHOD 1 ASLI + 3 DUMMY
    final result = await _apiService.uploadBuktiTabunganWithDummy(
      transaksiId: transaksi['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      jenisTransaksi: transaksi['jenis_tabungan']?.toString() ?? 'tabungan',
      buktiTransferPath: file.path,
      dummyFilePath: dummyFilePath,
    );

    if (!mounted) return;
    
    // ✅ TUTUP DIALOG UPLOADING
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() => _isUploadingBukti = false);

    if (result['success'] == true) {
      // ✅ UPDATE STATUS TRANSAKSI
      if (mounted) {
        setState(() {
          transaksi['bukti_pembayaran'] = result['file_path'] ?? file.path;
          transaksi['status_verifikasi'] = 'menunggu_verifikasi';
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '✅ Bukti pembayaran berhasil diupload!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // ✅ REFRESH DATA
      Future.delayed(const Duration(seconds: 2), () {
        _loadRiwayatTabungan();
      });
      
    } else {
      if (result['token_expired'] == true) {
        _showTokenExpiredDialog();
        return;
      }
      
      final errorMessage = result['message'] ?? 'Gagal upload bukti pembayaran';
      _showErrorSnackBar(errorMessage);
    }

  } catch (e) {
    // ✅ ERROR HANDLING
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      setState(() => _isUploadingBukti = false);
    }
    
    print('❌ Error upload bukti: $e');
    
    String userMessage = 'Terjadi kesalahan saat upload';
    if (e.toString().contains('File tidak ditemukan')) {
      userMessage = 'File tidak ditemukan';
    } else if (e.toString().contains('Ukuran file terlalu besar')) {
      userMessage = 'Ukuran file terlalu besar. Maksimal 5MB.';
    } else if (e.toString().contains('Format file tidak didukung')) {
      userMessage = 'Format file tidak didukung. Hanya JPG/JPEG yang diperbolehkan.';
    } else if (e.toString().contains('timeout')) {
      userMessage = 'Upload timeout, coba lagi';
    } else if (e.toString().contains('permission')) {
      userMessage = 'Izin akses galeri/kamera ditolak';
    } else if (e.toString().contains('SocketException')) {
      userMessage = 'Tidak ada koneksi internet';
    }
    
    _showErrorSnackBar('$userMessage (Bukti Pembayaran)');
  }
}

// ✅ UPDATE DIALOG KONFIRMASI UNTUK 1 ASLI + 3 DUMMY
Future<bool> _showUploadConfirmationDialog(File file) async {
  final fileInfo = await FileValidator.getFileInfo(file.path);
  
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Upload Bukti Transfer?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Apakah Anda yakin ingin mengupload bukti transfer ini?'),
          const SizedBox(height: 8),
          Text(
            'File: ${file.path.split('/').last}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Size: ${fileInfo['size_kb']} KB',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Format: ${fileInfo['extension']}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '📁 Sistem akan mengupload 4 file:\n• bukti_transfer (file utama)\n• foto_ktp (copy dari bukti)\n• foto_kk (copy dari bukti)\n• foto_diri (copy dari bukti)',
              style: TextStyle(fontSize: 11, color: Colors.blue),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Upload Sekarang'),
        ),
      ],
    ),
  ) ?? false;
}

  // ✅ DIALOG PILIHAN SUMBER GAMBAR
  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: const Text('Pilih sumber untuk mengambil bukti pembayaran'),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, ImageSource.camera),
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
                  onPressed: () => Navigator.pop(context, ImageSource.gallery),
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

  // ✅ TOKEN EXPIRED DIALOG
  void _showTokenExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesi Berakhir'),
        content: const Text('Sesi login Anda telah berakhir. Silakan login kembali untuk melanjutkan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
            child: const Text('Login Kembali'),
          ),
        ],
      ),
    );
  }

// ✅ UPDATE ERROR HANDLING
void _showErrorSnackBar(String message) {
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ✅ UPDATE PESAN LOADING UNTUK 1 ASLI + 3 DUMMY
void _showUploadingDialog(String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green[700]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Mengupload 4 file (1 asli + 3 dummy)...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '• bukti_transfer (file asli)\n• foto_ktp (dummy)\n• foto_kk (dummy)\n• foto_diri (dummy)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

  // ✅ HELPER METHODS
  int _parseValue(dynamic value) {
    try {
      if (value == null) return 0;
      
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final cleanAmount = value.replaceAll(RegExp(r'[^\d]'), '');
        return int.tryParse(cleanAmount) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  String _getJenisTransaksi(String transaksi, bool isSetoran) {
    if (transaksi.isEmpty) {
      return isSetoran ? 'Setoran' : 'Penarikan';
    }
    
    switch (transaksi.toLowerCase()) {
      case 'pokok': return 'Setoran Pokok';
      case 'wajib': return 'Setoran Wajib';
      case 'sitabung': return 'Setoran SiTabung';
      case 'penarikan_sitabung': return 'Penarikan SiTabung';
      case 'sukarela': return 'Setoran Sukarela';
      default: return transaksi;
    }
  }

  // ✅ GETTERS
  List<Map<String, dynamic>> get _filteredRiwayat {
    if (_selectedTabunganType == 'semua') {
      return _riwayatTabungan;
    }
    return _riwayatTabungan.where((transaksi) {
      final jenis = transaksi['jenis_tabungan']?.toString() ?? '';
      return jenis == _selectedTabunganType;
    }).toList();
  }

  int _getCurrentSaldo(String jenisTabungan) {
    try {
      print('🎯 Calculating current saldo for: $jenisTabungan');
      print('📦 _saldoData content: $_saldoData');
      
      if (jenisTabungan == 'semua') {
        int total = 0;
        for (var type in _tabunganTypes) {
          final typeId = type['id'] as String;
          if (typeId != 'semua') {
            final saldo = _getSaldoFromApiData(typeId);
            print('   - $typeId: $saldo');
            total += saldo;
          }
        }
        print('🎯 TOTAL SEMUA TABUNGAN: $total');
        return total;
      }
      
      final saldo = _getSaldoFromApiData(jenisTabungan);
      print('🎯 SALDO $jenisTabungan: $saldo');
      return saldo;
    } catch (e) {
      print('❌ Error in _getCurrentSaldo: $e');
      return 0;
    }
  }

  int _getSaldoFromApiData(String jenisTabungan) {
    try {
      print('🔍 Getting saldo for: $jenisTabungan');
      print('📊 Available keys in _saldoData: ${_saldoData.keys}');
      
      // ✅ PERBAIKAN: Ambil langsung dari _saldoData yang sudah dinormalisasi
      if (_saldoData.containsKey(jenisTabungan)) {
        final saldo = _saldoData[jenisTabungan];
        print('✅ Found saldo for $jenisTabungan: $saldo');
        
        // Handle berbagai tipe data
        if (saldo is int) return saldo;
        if (saldo is double) return saldo.toInt();
        if (saldo is String) {
          final cleanAmount = saldo.replaceAll(RegExp(r'[^\d]'), '');
          return int.tryParse(cleanAmount) ?? 0;
        }
        return _parseValue(saldo);
      } else {
        print('⚠️ Key $jenisTabungan not found in _saldoData');
        return 0;
      }
    } catch (e) {
      print('❌ Error getting saldo for $jenisTabungan: $e');
      return 0;
    }
  }

  String _formatCurrency(int amount) {
    try {
      if (amount == 0) return 'Rp 0';
      
      final isNegative = amount < 0;
      final absoluteAmount = amount.abs();
      
      final formatted = 'Rp ${absoluteAmount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';
      
      return isNegative ? '-$formatted' : formatted;
    } catch (e) {
      return 'Rp 0';
    }
  }

  Color _getAmountColor(int amount) {
    return amount >= 0 ? Colors.green : Colors.red;
  }

  Color _getTabunganColor(String jenis) {
    final jenisStr = jenis.toString().toLowerCase();
    switch (jenisStr) {
      case 'pokok': return Colors.green;
      case 'wajib': return Colors.orange;
      case 'sitabung': return Colors.blue;
      case 'sukarela': return Colors.red;
      case 'siumna': return Colors.teal;
      case 'siquna': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getTabunganName(String jenis) {
    final jenisStr = jenis.toString().toLowerCase();
    switch (jenisStr) {
      case 'pokok': return 'Pokok';
      case 'wajib': return 'Wajib';
      case 'sitabung': return 'SiTabung';
      case 'sukarela': return 'Sukarela';
      case 'siumna': return 'Siumna';
      case 'siquna': return 'Siquna';
      default: return jenisStr.isNotEmpty ? jenisStr : 'Tabungan';
    }
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    
    try {
      final dateTime = DateTime.parse(tanggal);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return tanggal.length > 10 ? tanggal.substring(0, 10) : tanggal;
    }
  }

  // ✅ STATUS VERIFIKASI WIDGET
  Widget _getStatusVerifikasi(Map<String, dynamic> transaksi) {
    final status = transaksi['status']?.toString() ?? 'completed';
    final isSaldo = transaksi['is_saldo'] == true;

    if (isSaldo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: Colors.green, size: 14),
            const SizedBox(width: 4),
            Text(
              'Saldo Aktif',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    Color color;
    String text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'Menunggu';
        icon = Icons.schedule;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Ditolak';
        icon = Icons.cancel;
        break;
      case 'completed':
      default:
        color = Colors.green;
        text = 'Selesai';
        icon = Icons.verified;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPLOAD BUKTI BUTTON WIDGET
  Widget _buildUploadBuktiButton(Map<String, dynamic> transaksi) {
    final canUpload = transaksi['can_upload_bukti'] == true;
    final isUploadingThis = _isUploadingBukti && _selectedTransaksiForUpload?['id'] == transaksi['id'];

    if (!canUpload) {
      return const SizedBox.shrink();
    }

    if (isUploadingThis) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _uploadBuktiPembayaran(transaksi),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload,
              color: Colors.orange,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              'Upload Bukti',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ERROR WIDGET
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Gagal Memuat Data',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadRiwayatTabungan,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ EMPTY STATE WIDGET
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat ${_selectedTabunganType == 'semua' ? 'tabungan' : _getTabunganName(_selectedTabunganType)}',
            style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Data riwayat tabungan akan muncul setelah Anda melakukan transaksi setoran atau penarikan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadRiwayatTabungan,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ DEBUG: Check data sebelum build
    print('🔄 BUILD - _saldoData: $_saldoData');
    print('🔄 BUILD - _riwayatTabungan length: ${_riwayatTabungan.length}');
    
    final totalSemuaTabungan = _getCurrentSaldo('semua');
    final filteredCount = _filteredRiwayat.length;
    
    print('🔄 BUILD - Total calculated: $totalSemuaTabungan');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Riwayat Tabungan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.green.withOpacity(0.5),
          shape: NotchedAppBarShape(),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0, right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadRiwayatTabungan,
                tooltip: 'Refresh Data',
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ✅ HEADER INFO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(bottom: BorderSide(color: Colors.green[100]!)),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Semua Tabungan',
                  style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(totalSemuaTabungan),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$filteredCount transaksi',
                  style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // ✅ ERROR MESSAGE UPLOAD
          if (_uploadErrorBukti != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border(bottom: BorderSide(color: Colors.red[100]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _uploadErrorBukti!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red[700], size: 16),
                    onPressed: () => setState(() => _uploadErrorBukti = null),
                  ),
                ],
              ),
            ),
          ],

          // ✅ JENIS TABUNGAN FILTER
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              itemCount: _tabunganTypes.length,
              itemBuilder: (context, index) {
                final type = _tabunganTypes[index];
                final isSelected = _selectedTabunganType == type['id'];
                final saldo = _getCurrentSaldo(type['id'] as String);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabunganType = type['id'] as String;
                    });
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (type['color'] as Color).withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? type['color'] as Color 
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          color: type['color'] as Color,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: type['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(saldo),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black87 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ✅ LOADING INDICATOR
          if (_isLoading) 
            const LinearProgressIndicator(
              backgroundColor: Colors.green,
              color: Colors.green,
            ),

          // ✅ MAIN CONTENT
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'Memuat data tabungan...',
                          style: TextStyle(color: Colors.green),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Harap tunggu sebentar',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : _hasError
                    ? _buildErrorWidget()
                    : _filteredRiwayat.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadRiwayatTabungan,
                            color: Colors.green,
                            backgroundColor: Colors.white,
                            child: ListView.separated(
                              itemCount: _filteredRiwayat.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final transaksi = _filteredRiwayat[index];
                                final jumlah = (transaksi['jumlah'] as num?)?.toInt() ?? 0;
                                final isSetoran = transaksi['is_setoran'] == true;
                                final jenisTabungan = transaksi['jenis_tabungan']?.toString() ?? 'sukarela';
                                final keterangan = transaksi['keterangan']?.toString() ?? 'Transaksi tabungan';
                                final tanggal = _formatTanggal(transaksi['tanggal']?.toString());
                                final jenisTransaksi = transaksi['jenis_transaksi']?.toString() ?? 'Transaksi';
                                final isSaldo = transaksi['is_saldo'] == true;
                                final canUploadBukti = transaksi['can_upload_bukti'] == true;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.green[100]!),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // ✅ LEADING ICON
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _getTabunganColor(jenisTabungan).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isSaldo ? Icons.account_balance : 
                                                     (isSetoran ? Icons.arrow_downward : Icons.arrow_upward),
                                            color: _getTabunganColor(jenisTabungan),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // ✅ CONTENT
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      jenisTransaksi,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getTabunganColor(jenisTabungan).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: _getTabunganColor(jenisTabungan)),
                                                    ),
                                                    child: Text(
                                                      _getTabunganName(jenisTabungan),
                                                      style: TextStyle(
                                                        color: _getTabunganColor(jenisTabungan),
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                tanggal,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              Text(
                                                keterangan,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  _getStatusVerifikasi(transaksi),
                                                  const SizedBox(width: 8),
                                                  if (canUploadBukti) _buildUploadBuktiButton(transaksi),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // ✅ TRAILING - NOMINAL
                                        SizedBox(
                                          width: 100,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _formatCurrency(jumlah),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: _getAmountColor(jumlah),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isSetoran ? 'Setoran' : 'Penarikan',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isSetoran ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              // ✅ TAMBAHKAN DI BUILD METHOD - SEBELUM PENUTUP COLUMN
if (!_isLoading && !_hasError && _filteredRiwayat.isNotEmpty) 
  Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Sistem upload: 1 file asli + 3 file dummy otomatis',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}