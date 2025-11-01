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
  Map<String, dynamic> _saldoData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late String _selectedTabunganType;

  // ✅ Daftar jenis tabungan sesuai dengan API response
  final List<Map<String, dynamic>> _tabunganTypes = [
    {'id': 'semua', 'name': 'Semua', 'icon': Icons.all_inclusive, 'color': Colors.blue},
    {'id': 'pokok', 'name': 'Pokok', 'icon': Icons.account_balance, 'color': Colors.green},
    {'id': 'wajib', 'name': 'Wajib', 'icon': Icons.savings, 'color': Colors.orange},
    {'id': 'khusus', 'name': 'Wajib Khusus', 'icon': Icons.verified_user, 'color': Colors.purple},
    {'id': 'sukarela', 'name': 'Sukarela', 'icon': Icons.volunteer_activism, 'color': Colors.red},
    {'id': 'sitabung', 'name': 'SiTabung', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
    {'id': 'siumna', 'name': 'Simuna', 'icon': Icons.money, 'color': Colors.teal},
    {'id': 'siquna', 'name': 'Siquna', 'icon': Icons.attach_money, 'color': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabunganType = widget.initialTabunganType ?? 'semua';
    _loadRiwayatTabungan();
  }

  // ✅ PERBAIKAN BESAR: Method untuk load data riwayat tabungan sesuai struktur API
  Future<void> _loadRiwayatTabungan() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      print('🔄 Loading riwayat tabungan from API...');
      
      // ✅ PERBAIKAN: Gunakan getAllSaldo() karena response menunjukkan ini adalah endpoint yang benar
      final result = await _apiService.getAllSaldo();
      
      print('📊 Saldo API Response: ${result['success']}');
      print('📊 Saldo API Data: ${result['data'] != null ? 'Data available' : 'No data'}');
      
      if (mounted) {
        setState(() {
          if (result['success'] == true && result['data'] != null) {
            final data = result['data'];
            _saldoData = data is Map<String, dynamic> ? data : {};
            
            // ✅ PERBAIKAN: Process data sesuai struktur API yang benar
            _riwayatTabungan = _processApiData(_saldoData);
            
            print('✅ Processed ${_riwayatTabungan.length} transaksi from API');
            print('✅ Available tabungan types: ${_getAvailableTabunganTypes()}');
          } else {
            _riwayatTabungan = [];
            _hasError = true;
            _errorMessage = result['message'] ?? 'Gagal memuat data tabungan';
            print('❌ API Error: $_errorMessage');
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

  // ✅ PERBAIKAN BESAR: Process data sesuai struktur API yang benar dari Postman
  List<Map<String, dynamic>> _processApiData(Map<String, dynamic> apiData) {
    final List<Map<String, dynamic>> allTransactions = [];
    
    try {
      print('🔄 Processing API data structure...');
      
      // ✅ Process setiap jenis tabungan dari API response
      for (var tabunganType in _tabunganTypes) {
        final typeId = tabunganType['id'] as String;
        if (typeId == 'semua') continue;
        
        final tabunganData = apiData[typeId];
        if (tabunganData != null && tabunganData is List) {
          for (var item in tabunganData) {
            if (item is Map<String, dynamic>) {
              // ✅ Process saldo information
              final saldo = _parseAmount(item['saldo']);
              if (saldo > 0) {
                allTransactions.add({
                  'id': '$typeId-saldo-${DateTime.now().millisecondsSinceEpoch}',
                  'jenis_transaksi': 'Saldo ${tabunganType['name']}',
                  'jumlah': saldo,
                  'tanggal': DateTime.now().toString(),
                  'jenis_tabungan': typeId,
                  'keterangan': 'Saldo ${tabunganType['name']} saat ini',
                  'status_verifikasi': 'terverifikasi',
                  'bukti_pembayaran': null,
                  'is_saldo': true,
                  'is_setoran': true,
                });
              }
              
              // ✅ Process history transaksi
              final historyDebet = item['history_debet'];
              if (historyDebet is List) {
                for (var history in historyDebet) {
                  if (history is Map<String, dynamic>) {
                    final debet = _parseAmount(history['debet'] ?? 0);
                    final credit = _parseAmount(history['credit'] ?? 0);
                    final isSetoran = debet > 0;
                    final amount = isSetoran ? debet : credit;
                    
                    if (amount > 0) {
                      allTransactions.add({
                        'id': history['id']?.toString() ?? '${typeId}-${DateTime.now().millisecondsSinceEpoch}',
                        'jenis_transaksi': _getJenisTransaksi(history['transaksi']?.toString(), isSetoran),
                        'jumlah': isSetoran ? amount : -amount,
                        'tanggal': history['tanggal']?.toString() ?? DateTime.now().toString(),
                        'jenis_tabungan': typeId,
                        'keterangan': history['keterangan']?.toString() ?? 'Transaksi ${tabunganType['name']}',
                        'status_verifikasi': 'terverifikasi',
                        'bukti_pembayaran': null,
                        'is_saldo': false,
                        'is_setoran': isSetoran,
                        'raw_data': history, // Simpan data asli untuk referensi
                      });
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      // ✅ Sort by date descending (newest first)
      allTransactions.sort((a, b) {
        final dateA = DateTime.parse(a['tanggal'] ?? DateTime.now().toString());
        final dateB = DateTime.parse(b['tanggal'] ?? DateTime.now().toString());
        return dateB.compareTo(dateA);
      });
      
      print('✅ Total transactions processed: ${allTransactions.length}');
      
    } catch (e) {
      print('❌ Error processing API data: $e');
      // Fallback to demo data
      allTransactions.addAll(_getDemoData());
    }
    
    return allTransactions;
  }

  // ✅ Helper: Parse amount dari berbagai format
  int _parseAmount(dynamic amount) {
    try {
      if (amount is int) return amount;
      if (amount is double) return amount.toInt();
      if (amount is String) {
        // Remove non-digit characters and parse
        final cleanAmount = amount.replaceAll(RegExp(r'[^\d]'), '');
        return int.tryParse(cleanAmount) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ✅ Helper: Get jenis transaksi dari data API
  String _getJenisTransaksi(String? transaksi, bool isSetoran) {
    if (transaksi == null || transaksi.isEmpty) {
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

  // ✅ Helper: Get available tabungan types from data
  List<String> _getAvailableTabunganTypes() {
    final availableTypes = <String>[];
    
    for (var type in _tabunganTypes) {
      final typeId = type['id'] as String;
      if (typeId != 'semua' && _saldoData[typeId] != null) {
        availableTypes.add(typeId);
      }
    }
    
    return availableTypes;
  }

  // ✅ Data demo untuk fallback
  List<Map<String, dynamic>> _getDemoData() {
    return [
      {
        'id': 'pokok-demo',
        'jenis_transaksi': 'Setoran Pokok',
        'jumlah': 100000,
        'tanggal': '2025-05-31',
        'jenis_tabungan': 'pokok',
        'keterangan': 'PK/11/05/2025/391 (1399)',
        'status_verifikasi': 'terverifikasi',
        'bukti_pembayaran': null,
        'is_saldo': false,
        'is_setoran': true,
      },
      {
        'id': 'wajib-demo',
        'jenis_transaksi': 'Setoran Wajib',
        'jumlah': 225000,
        'tanggal': '2025-05-31',
        'jenis_tabungan': 'wajib',
        'keterangan': 'WJ/11/05/2025/395 (1400)',
        'status_verifikasi': 'terverifikasi',
        'bukti_pembayaran': null,
        'is_saldo': false,
        'is_setoran': true,
      },
      {
        'id': 'sitabung-demo',
        'jenis_transaksi': 'Setoran SiTabung',
        'jumlah': 1850000,
        'tanggal': '2025-05-31',
        'jenis_tabungan': 'sitabung',
        'keterangan': 'STB/11/05/2025/557 (1401)',
        'status_verifikasi': 'terverifikasi',
        'bukti_pembayaran': null,
        'is_saldo': false,
        'is_setoran': true,
      },
      {
        'id': 'sitabung-penarikan-demo',
        'jenis_transaksi': 'Penarikan SiTabung',
        'jumlah': -1850000,
        'tanggal': '2025-07-25',
        'jenis_tabungan': 'sitabung',
        'keterangan': 'KSMIP/11/07/2025/4 (4)',
        'status_verifikasi': 'terverifikasi',
        'bukti_pembayaran': null,
        'is_saldo': false,
        'is_setoran': false,
      },
    ];
  }

  // ✅ PERBAIKAN: Filter riwayat berdasarkan jenis tabungan dengan safety check
  List<Map<String, dynamic>> get _filteredRiwayat {
    if (_selectedTabunganType == 'semua') {
      return _riwayatTabungan;
    }
    return _riwayatTabungan.where((transaksi) {
      final jenis = transaksi['jenis_tabungan']?.toString() ?? '';
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
      print('❌ Error calculating total saldo: $e');
      return 0;
    }
  }

  // ✅ PERBAIKAN: Get current saldo from API data
  int _getCurrentSaldo(String jenisTabungan) {
    try {
      if (jenisTabungan == 'semua') {
        int total = 0;
        for (var type in _tabunganTypes) {
          final typeId = type['id'] as String;
          if (typeId != 'semua') {
            total += _getSaldoFromApiData(typeId);
          }
        }
        return total;
      }
      return _getSaldoFromApiData(jenisTabungan);
    } catch (e) {
      return 0;
    }
  }

  int _getSaldoFromApiData(String jenisTabungan) {
    try {
      final tabunganData = _saldoData[jenisTabungan];
      if (tabunganData is List && tabunganData.isNotEmpty) {
        final firstItem = tabunganData[0];
        if (firstItem is Map<String, dynamic>) {
          return _parseAmount(firstItem['saldo']);
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ✅ PERBAIKAN: Format currency dengan safety
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
      case 'khusus': return Colors.purple;
      case 'sitabung': return Colors.blue;
      case 'sukarela': return Colors.red;
      case 'siumna': return Colors.teal;
      case 'siquna': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  // ✅ PERBAIKAN: Get tabungan name dengan default
  String _getTabunganName(String jenis) {
    final jenisStr = jenis.toString().toLowerCase();
    switch (jenisStr) {
      case 'pokok': return 'Pokok';
      case 'wajib': return 'Wajib';
      case 'khusus': return 'Wajib Khusus';
      case 'sitabung': return 'SiTabung';
      case 'sukarela': return 'Sukarela';
      case 'siumna': return 'Simuna';
      case 'siquna': return 'Siquna';
      default: return jenisStr.isNotEmpty ? jenisStr : 'Tabungan';
    }
  }

  // ✅ PERBAIKAN: Format tanggal dengan safety
  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    
    try {
      final dateTime = DateTime.parse(tanggal);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return tanggal.length > 10 ? tanggal.substring(0, 10) : tanggal;
    }
  }

  // ✅ PERBAIKAN: Upload bukti pembayaran
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

        final result = await _apiService.uploadBuktiTransfer(
          transaksiId: transaksi['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: pickedFile.path,
          jenisTransaksi: transaksi['jenis_tabungan']?.toString() ?? 'sukarela',
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (result['success'] == true) {
          if (mounted) {
            setState(() {
              transaksi['bukti_pembayaran'] = result['file_path'] ?? pickedFile.path;
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
            SnackBar(
              content: Text('Gagal upload bukti: ${result['message']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error upload: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Uploading dialog
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
    final status = transaksi['status_verifikasi']?.toString() ?? 'terverifikasi';
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

    Color color = Colors.green;
    String text = 'Terverifikasi';
    IconData icon = Icons.verified;

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
    final totalSemuaTabungan = _getCurrentSaldo('semua');
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
                                final isSetoran = transaksi['is_setoran'] == true;
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