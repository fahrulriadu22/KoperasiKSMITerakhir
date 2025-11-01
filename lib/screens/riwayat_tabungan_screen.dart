import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _riwayatTabungan = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late String _selectedTabunganType;

  // ✅ Daftar jenis tabungan
  final List<Map<String, dynamic>> _tabunganTypes = [
    {'id': 'semua', 'name': 'Semua', 'icon': Icons.all_inclusive, 'color': Colors.blue},
    {'id': 'pokok', 'name': 'Pokok', 'icon': Icons.account_balance, 'color': Colors.green},
    {'id': 'wajib', 'name': 'Wajib', 'icon': Icons.savings, 'color': Colors.orange},
    {'id': 'wajib_khusus', 'name': 'Wajib Khusus', 'icon': Icons.verified_user, 'color': Colors.purple},
    {'id': 'sita', 'name': 'SiTabung', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
    {'id': 'sukarela', 'name': 'Sukarela', 'icon': Icons.volunteer_activism, 'color': Colors.red},
    {'id': 'simuna', 'name': 'Simuna', 'icon': Icons.money, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabunganType = widget.initialTabunganType ?? 'semua';
    _loadRiwayatTabungan();
  }

  // ✅ PERBAIKAN: Method untuk load data dengan integrasi API yang benar
  Future<void> _loadRiwayatTabungan() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      // ✅ PERBAIKAN: Gunakan method getAllSaldo dari ApiService
      final result = await _apiService.getAllSaldo();
      
      if (mounted) {
        setState(() {
          // ✅ PERBAIKAN: Handle response dari getAllSaldo
          if (result['success'] == true && result['data'] != null) {
            final data = result['data'];
            
            if (data is Map<String, dynamic>) {
              // Konversi data map ke list riwayat
              _riwayatTabungan = _convertSaldoToRiwayat(data);
            } else if (data is List) {
              // Jika data sudah berupa list
              _riwayatTabungan = data.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  return _createDefaultTransaction();
                }
              }).toList();
            } else {
              _riwayatTabungan = [];
            }
          } else {
            _riwayatTabungan = [];
            _hasError = true;
            _errorMessage = result['message'] ?? 'Gagal memuat data tabungan';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading riwayat tabungan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Gagal memuat data: $e';
          _riwayatTabungan = [];
        });
      }
    }
  }

  // ✅ METHOD: Konversi data saldo ke format riwayat transaksi
  List<Map<String, dynamic>> _convertSaldoToRiwayat(Map<String, dynamic> saldoData) {
    final List<Map<String, dynamic>> riwayat = [];
    
    // Tambahkan data untuk setiap jenis tabungan
    _tabunganTypes.where((type) => type['id'] != 'semua').forEach((type) {
      final jenis = type['id'] as String;
      final saldo = (saldoData[jenis] as num?)?.toInt() ?? 0;
      
      if (saldo > 0) {
        riwayat.add({
          'id': '$jenis-${DateTime.now().millisecondsSinceEpoch}',
          'jenis_transaksi': 'Saldo ${type['name']}',
          'jumlah': saldo,
          'tanggal': DateTime.now().toString(),
          'jenis_tabungan': jenis,
          'keterangan': 'Saldo ${type['name']}',
          'status_verifikasi': 'terverifikasi',
          'bukti_pembayaran': null,
          'is_saldo': true, // Flag untuk membedakan saldo dengan transaksi
        });
      }
    });
    
    return riwayat;
  }

  // ✅ METHOD: Create default transaction
  Map<String, dynamic> _createDefaultTransaction() {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'jenis_transaksi': 'Transaksi Tabungan',
      'jumlah': 0,
      'tanggal': DateTime.now().toString(),
      'jenis_tabungan': 'sukarela',
      'keterangan': 'Transaksi tabungan',
      'status_verifikasi': 'belum_upload',
      'bukti_pembayaran': null,
    };
  }

  // ✅ PERBAIKAN: Filter riwayat berdasarkan jenis tabungan dengan safety check
  List<Map<String, dynamic>> get _filteredRiwayat {
    if (_selectedTabunganType == 'semua') {
      return _riwayatTabungan;
    }
    return _riwayatTabungan.where((transaksi) {
      final jenis = transaksi['jenis_tabungan']?.toString() ?? 'sukarela';
      return jenis == _selectedTabunganType;
    }).toList();
  }

  // ✅ PERBAIKAN: Get total saldo dengan safety check
  int _getTotalSaldo(String jenisTabungan) {
    try {
      if (jenisTabungan == 'semua') {
        return _riwayatTabungan.fold(0, (sum, transaksi) {
          final jumlah = (transaksi['jumlah'] as num?)?.toInt() ?? 0;
          return sum + jumlah;
        });
      }
      
      final filtered = _riwayatTabungan.where((t) => 
        (t['jenis_tabungan']?.toString() ?? '') == jenisTabungan
      );
      return filtered.fold(0, (sum, transaksi) {
        final jumlah = (transaksi['jumlah'] as num?)?.toInt() ?? 0;
        return sum + jumlah;
      });
    } catch (e) {
      print('Error calculating total: $e');
      return 0;
    }
  }

  // ✅ PERBAIKAN: Format currency dengan safety
  String _formatCurrency(int amount) {
    try {
      return 'Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';
    } catch (e) {
      return 'Rp 0';
    }
  }

  // ✅ PERBAIKAN: Get amount color dengan safety
  Color _getAmountColor(int amount) {
    return amount >= 0 ? Colors.green : Colors.red;
  }

  // ✅ PERBAIKAN: Get tabungan color dengan default
  Color _getTabunganColor(String jenis) {
    final jenisStr = jenis.toString().toLowerCase();
    switch (jenisStr) {
      case 'pokok': return Colors.green;
      case 'wajib': return Colors.orange;
      case 'wajib_khusus': return Colors.purple;
      case 'sita': return Colors.blue;
      case 'sukarela': return Colors.red;
      case 'simuna': return Colors.teal;
      default: return Colors.grey;
    }
  }

  // ✅ PERBAIKAN: Get tabungan name dengan default
  String _getTabunganName(String jenis) {
    final jenisStr = jenis.toString().toLowerCase();
    switch (jenisStr) {
      case 'pokok': return 'Pokok';
      case 'wajib': return 'Wajib';
      case 'wajib_khusus': return 'Wajib Khusus';
      case 'sita': return 'SiTabung';
      case 'sukarela': return 'Sukarela';
      case 'simuna': return 'Simuna';
      default: return jenisStr.isNotEmpty ? jenisStr : 'Tabungan';
    }
  }

  // ✅ PERBAIKAN: Format tanggal dengan safety
  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    
    try {
      final dateTime = DateTime.parse(tanggal);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return tanggal;
    }
  }

  // ✅ PERBAIKAN: Upload bukti pembayaran dengan error handling
  Future<void> _uploadBuktiPembayaran(Map<String, dynamic> transaksi) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        _showUploadingDialog('Mengupload Bukti Pembayaran...');

        // ✅ PERBAIKAN: Gunakan method uploadFoto dari ApiService
        final success = await _apiService.uploadFoto(
          type: 'bukti_pembayaran',
          filePath: pickedFile.path,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close dialog

        if (success) {
          // Update local data dengan path bukti
          if (mounted) {
            setState(() {
              transaksi['bukti_pembayaran'] = pickedFile.path;
              transaksi['status_verifikasi'] = 'menunggu';
            });
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bukti pembayaran berhasil diupload ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload bukti pembayaran'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error uploading bukti: $e');
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ PERBAIKAN: Preview bukti pembayaran dengan safety check
  void _showBuktiPreview(String? imagePath, String title) {
    if (imagePath == null || imagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pembayaran belum diupload'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if file exists
    final file = File(imagePath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File bukti tidak ditemukan'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // IMAGE
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  width: 300,
                  height: 400,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 300,
                      height: 400,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 50, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text(
                            'Gagal memuat gambar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // ACTIONS
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ PERBAIKAN: Uploading dialog
  void _showUploadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
          ],
        ),
      ),
    );
  }

  // ✅ PERBAIKAN: Get status verifikasi dengan safety check
  Widget _getStatusVerifikasi(Map<String, dynamic> transaksi) {
    final status = transaksi['status_verifikasi']?.toString() ?? 'belum_upload';
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

    switch (status) {
      case 'terverifikasi':
        color = Colors.green;
        text = 'Terverifikasi';
        icon = Icons.verified;
        break;
      case 'ditolak':
        color = Colors.red;
        text = 'Ditolak';
        icon = Icons.cancel;
        break;
      case 'menunggu':
        color = Colors.orange;
        text = 'Menunggu Verifikasi';
        icon = Icons.pending;
        break;
      default:
        color = Colors.grey;
        text = 'Belum Upload Bukti';
        icon = Icons.upload;
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

  // ✅ PERBAIKAN: Build error widget
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

  // ✅ PERBAIKAN: Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat tabungan',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
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
    final totalSemuaTabungan = _getTotalSaldo('semua');
    final filteredCount = _filteredRiwayat.length;

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
          // ✅ Header Info - Total Semua Tabungan
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

          // ✅ Jenis Tabungan Filter
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
                final saldo = _getTotalSaldo(type['id'] as String);

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

          // ✅ Loading Indicator
          if (_isLoading) 
            const LinearProgressIndicator(
              backgroundColor: Colors.green,
              color: Colors.green,
            ),

          // ✅ Riwayat List
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
                                final isSetoran = jumlah >= 0;
                                final jenisTabungan = transaksi['jenis_tabungan']?.toString() ?? 'sukarela';
                                final hasBukti = transaksi['bukti_pembayaran'] != null && 
                                             transaksi['bukti_pembayaran'].toString().isNotEmpty;
                                final keterangan = transaksi['keterangan']?.toString() ?? 'Transaksi tabungan';
                                final tanggal = _formatTanggal(transaksi['tanggal']?.toString());
                                final jenisTransaksi = transaksi['jenis_transaksi']?.toString() ?? 'Transaksi';
                                final isSaldo = transaksi['is_saldo'] == true;

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
                                              _getStatusVerifikasi(transaksi),
                                            ],
                                          ),
                                        ),
                                        
                                        // ✅ TRAILING - NOMINAL & BUKTI
                                        SizedBox(
                                          width: 80,
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
                                              const SizedBox(height: 6),
                                              
                                              // ✅ ICON BUKTI PEMBAYARAN (hanya untuk setoran non-saldo)
                                              if (isSetoran && jumlah > 0 && !isSaldo)
                                                Tooltip(
                                                  message: hasBukti ? 'Lihat Bukti' : 'Upload Bukti',
                                                  child: GestureDetector(
                                                    onTap: hasBukti
                                                        ? () => _showBuktiPreview(
                                                            transaksi['bukti_pembayaran'],
                                                            'Bukti Pembayaran - ${_getTabunganName(jenisTabungan)}'
                                                          )
                                                        : () => _uploadBuktiPembayaran(transaksi),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: hasBukti ? Colors.blue[50] : Colors.green[50],
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: hasBukti ? Colors.blue[300]! : Colors.green[300]!,
                                                        ),
                                                      ),
                                                      child: Icon(
                                                        hasBukti ? Icons.receipt : Icons.receipt_long,
                                                        size: 18,
                                                        color: hasBukti ? Colors.blue : Colors.green,
                                                      ),
                                                    ),
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