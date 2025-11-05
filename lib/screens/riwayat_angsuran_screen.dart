import 'package:flutter/material.dart';
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

class RiwayatAngsuranScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String? initialAngsuranType;
  
  const RiwayatAngsuranScreen({
    super.key, 
    required this.user,
    this.initialAngsuranType,
  });
  
  @override
  State<RiwayatAngsuranScreen> createState() => _RiwayatAngsuranScreenState();
}

class _RiwayatAngsuranScreenState extends State<RiwayatAngsuranScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _riwayatAngsuran = [];
  List<Map<String, dynamic>> _dataMaster = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late String _selectedAngsuranType;

  // ✅ Daftar jenis angsuran SYARIAH - HANYA SEMUA & TAQSITH YANG AKTIF
  final List<Map<String, dynamic>> _angsuranTypes = [
    {'id': 'semua', 'name': 'Semua', 'icon': Icons.all_inclusive, 'color': Colors.green, 'is_active': true},
    {'id': 'mudharabah', 'name': 'Mudharabah', 'icon': Icons.account_balance, 'color': Colors.green, 'is_active': false},
    {'id': 'murabahah', 'name': 'Murabahah', 'icon': Icons.shopping_cart, 'color': Colors.blue, 'is_active': false},
    {'id': 'musyarakah', 'name': 'Musyarakah', 'icon': Icons.handshake, 'color': Colors.orange, 'is_active': false},
    {'id': 'ijarah', 'name': 'Ijarah', 'icon': Icons.home_work, 'color': Colors.purple, 'is_active': false},
    {'id': 'qardh', 'name': 'Qardh Hasan', 'icon': Icons.volunteer_activism, 'color': Colors.teal, 'is_active': false},
    {'id': 'wakalah', 'name': 'Wakalah', 'icon': Icons.assignment, 'color': Colors.indigo, 'is_active': false},
    {'id': 'taqsith', 'name': 'Taqsith', 'icon': Icons.payments, 'color': Colors.deepPurple, 'is_active': true},
  ];

  @override
  void initState() {
    super.initState();
    
    // ✅ SET INITIAL VALUE BERDASARKAN PARAMETER
    _selectedAngsuranType = widget.initialAngsuranType ?? 'semua';
    
    _loadRiwayatAngsuran();
  }

// ✅ PERBAIKAN: Method untuk load data taqsith dari API getAlltaqsith
Future<void> _loadRiwayatAngsuran() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
  }

  try {
    print('🚀 Memulai load data taqsith dari getAlltaqsith API...');
    
    // ✅ PANGGIL API GETALLTAQSITH YANG BARU
    final result = await _apiService.getAlltaqsith();
    
    print('📊 Response getAlltaqsith: ${result['success']}');
    print('📊 Message: ${result['message']}');
    
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          final data = result['data'];
          final dataMaster = result['data_master'];
          
          // ✅ SIMPAN DATA MASTER
          if (dataMaster is List && dataMaster.isNotEmpty) {
            _dataMaster = List<Map<String, dynamic>>.from(dataMaster);
            print('✅ Berhasil load ${_dataMaster.length} data master');
          } else {
            _dataMaster = [];
            print('⚠️ Data master kosong');
          }
          
          // ✅ KONVERSI DATA TAQSITH DARI API
          if (data is List && data.isNotEmpty) {
            _riwayatAngsuran = _parseTaqsithData(data);
            print('✅ Berhasil load ${_riwayatAngsuran.length} data taqsith');
          } else {
            _riwayatAngsuran = [];
            print('⚠️ Data taqsith kosong atau bukan list');
          }
        } else {
          _riwayatAngsuran = [];
          _dataMaster = [];
          _hasError = true;
          _errorMessage = result['message'] ?? 'Gagal memuat data taqsith';
          print('❌ API Error: $_errorMessage');
        }
        _isLoading = false;
      });
    }
  } catch (e) {
    print('❌ Error loading taqsith: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Gagal memuat data: $e';
        _riwayatAngsuran = [];
        _dataMaster = [];
      });
    }
  }
}

  // ✅ PERBAIKAN: PARSING DATA TAQSITH DARI API GETALLTAQSITH
  List<Map<String, dynamic>> _parseTaqsithData(List<dynamic> apiData) {
    final List<Map<String, dynamic>> parsedData = [];
    
    for (var kreditItem in apiData) {
      try {
        if (kreditItem is Map<String, dynamic>) {
          final idKredit = kreditItem['id_kredit']?.toString();
          final namaBarang = kreditItem['nama_barang']?.toString() ?? 'Produk';
          final angsuranList = kreditItem['angsuran'];
          
          // ✅ CARI DATA MASTER UNTUK INFORMASI TAMBAHAN
          final masterData = _findMasterData(idKredit);
          final jangkaWaktu = masterData?['jangka_waktu']?.toString() ?? '18 Bulan';
          final statusMaster = masterData?['status']?.toString() ?? 'TEPAT WAKTU';
          final angsuranMaster = double.tryParse(masterData?['angsuran']?.toString() ?? '0') ?? 0;
          
          if (angsuranList is List && angsuranList.isNotEmpty) {
            for (var angsuranItem in angsuranList) {
              if (angsuranItem is Map<String, dynamic>) {
                // ✅ PARSE DATA DARI RESPONSE API TAQSITH
                final harga = double.tryParse(angsuranItem['harga']?.toString() ?? '0') ?? 0;
                final sisa = double.tryParse(angsuranItem['sisa']?.toString() ?? '0') ?? 0;
                final ke = int.tryParse(angsuranItem['ke']?.toString() ?? '0') ?? 0;
                final hargaBagiHasil = double.tryParse(angsuranItem['harga_bagi_hasil']?.toString() ?? '0') ?? 0;
                final sisaBagiHasil = double.tryParse(angsuranItem['sisa_bagi_hasil']?.toString() ?? '0') ?? 0;
                
                // ✅ TENTUKAN STATUS BERDASARKAN SISA
                String statusAngsuran = 'aktif';
                if (sisa <= 0) {
                  statusAngsuran = 'lunas';
                } else if (ke > 1) {
                  statusAngsuran = 'berjalan';
                }
                
                parsedData.add({
                  'id': '${angsuranItem['id_rujukan']}_${angsuranItem['ke']}',
                  'tanggal': angsuranItem['tanggal_buat']?.toString() ?? '',
                  'no_invoice': angsuranItem['inv_no']?.toString() ?? '',
                  'jumlah': harga,
                  'sisa_angsuran': sisa,
                  'ke': ke,
                  'id_kredit': idKredit,
                  'nama_barang': namaBarang,
                  'jenis': 'taqsith',
                  'keterangan': 'Angsuran Taqsith $namaBarang - Cicilan ke-$ke',
                  'status': statusAngsuran,
                  'harga_bagi_hasil': hargaBagiHasil,
                  'sisa_bagi_hasil': sisaBagiHasil,
                  'total_angsuran': angsuranMaster > 0 ? angsuranMaster * 18 : harga * 18,
                  'tenor': _extractTenor(jangkaWaktu),
                  'jangka_waktu': jangkaWaktu,
                  'status_master': statusMaster,
                  'angsuran_master': angsuranMaster,
                });
              }
            }
          } else {
            // ✅ JIKA TIDAK ADA ANGSURAN, TAMPILKAN DATA KREDIT SAJA
            print('⚠️ Tidak ada data angsuran untuk kredit $idKredit');
          }
        }
      } catch (e) {
        print('❌ Error parsing taqsith item: $e');
      }
    }
    
    // ✅ URUTKAN BERDASARKAN TANGGAL (TERBARU DIATAS)
    parsedData.sort((a, b) {
      final dateA = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });
    
    return parsedData;
  }

  // ✅ CARI DATA MASTER BERDASARKAN ID_KREDIT
  Map<String, dynamic>? _findMasterData(String? idKredit) {
    if (idKredit == null) return null;
    
    try {
      return _dataMaster.firstWhere(
        (master) => master['id_kredit']?.toString() == idKredit,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }

  // ✅ EKSTRAK TENOR DARI JANGKA_WAKTU
  String _extractTenor(String jangkaWaktu) {
    try {
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(jangkaWaktu);
      return match?.group(1) ?? '18';
    } catch (e) {
      return '18';
    }
  }

  // ✅ PERBAIKAN: Filter riwayat - HANYA TAQSITH YANG ADA DATANYA
  List<Map<String, dynamic>> get _filteredRiwayat {
    try {
      if (_selectedAngsuranType == 'semua') {
        return _riwayatAngsuran;
      }
      
      if (_selectedAngsuranType == 'taqsith') {
        return _riwayatAngsuran;
      }
      
      // ✅ UNTUK JENIS LAINNYA - KOSONG (BELUM TERINTEGRASI)
      return [];
    } catch (e) {
      print('❌ Error filtering: $e');
      return [];
    }
  }

  // ✅ PERBAIKAN: Get total angsuran
  double _getTotalAngsuran(String jenisId) {
    try {
      if (jenisId == 'semua') {
        return _riwayatAngsuran.fold(0.0, (sum, angsuran) {
          try {
            final jumlah = (angsuran['jumlah'] as num?)?.toDouble() ?? 0.0;
            return sum + jumlah;
          } catch (e) {
            return sum;
          }
        });
      }
      
      if (jenisId == 'taqsith') {
        return _riwayatAngsuran.fold(0.0, (sum, angsuran) {
          try {
            final jumlah = (angsuran['jumlah'] as num?)?.toDouble() ?? 0.0;
            return sum + jumlah;
          } catch (e) {
            return sum;
          }
        });
      }
      
      // ✅ UNTUK JENIS LAINNYA - 0 (BELUM TERINTEGRASI)
      return 0.0;
    } catch (e) {
      print('❌ Error calculating total: $e');
      return 0.0;
    }
  }

  // ✅ PERBAIKAN: Format currency
  String _formatCurrency(double amount) {
    try {
      if (amount == 0) return 'Rp 0';
      
      return 'Rp ${amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';
    } catch (e) {
      return 'Rp 0';
    }
  }

  // ✅ PERBAIKAN: Get status color
  Color _getStatusColor(String status) {
    try {
      final statusStr = status.toString().toLowerCase();
      switch (statusStr) {
        case 'lunas': 
        case 'tepat waktu':
        case 'completed':
        case 'paid':
        case 'selesai':
          return Colors.green;
        case 'aktif':
        case 'berjalan':
        case 'diproses':
        case 'pending':
          return Colors.blue;
        case 'tertunggak':
        case 'belum terbayar':
        case 'unpaid':
        case 'ditolak':
          return Colors.red;
        default: return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  // ✅ PERBAIKAN: Get angsuran color
  Color _getAngsuranColor(String jenis) {
    try {
      final jenisStr = jenis.toString().toLowerCase();
      switch (jenisStr) {
        case 'taqsith': return Colors.deepPurple;
        case 'mudharabah': return Colors.green;
        case 'murabahah': return Colors.blue;
        case 'musyarakah': return Colors.orange;
        case 'ijarah': return Colors.purple;
        case 'qardh': return Colors.teal;
        case 'wakalah': return Colors.indigo;
        default: return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  // ✅ PERBAIKAN: Get angsuran name
  String _getAngsuranName(String jenis) {
    try {
      final jenisStr = jenis.toString().toLowerCase();
      switch (jenisStr) {
        case 'taqsith': return 'Taqsith';
        case 'mudharabah': return 'Mudharabah';
        case 'murabahah': return 'Murabahah';
        case 'musyarakah': return 'Musyarakah';
        case 'ijarah': return 'Ijarah';
        case 'qardh': return 'Qardh Hasan';
        case 'wakalah': return 'Wakalah';
        default: return jenisStr.isNotEmpty ? jenisStr : 'Angsuran';
      }
    } catch (e) {
      return 'Angsuran';
    }
  }

  // ✅ PERBAIKAN: Format tanggal
  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    
    try {
      final dateTime = DateTime.parse(tanggal);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return tanggal.length > 10 ? tanggal.substring(0, 10) : tanggal;
    }
  }

  // ✅ PERBAIKAN: Tampilkan dialog detail
  void _showDetailAngsuran(Map<String, dynamic> angsuran) {
    try {
      final jumlah = (angsuran['jumlah'] as num?)?.toDouble() ?? 0;
      final jenis = angsuran['jenis']?.toString() ?? 'taqsith';
      final sisaAngsuran = (angsuran['sisa_angsuran'] as num?)?.toDouble() ?? 0;
      final totalAngsuran = (angsuran['total_angsuran'] as num?)?.toDouble() ?? (jumlah * 18);
      final tanggal = _formatTanggal(angsuran['tanggal']?.toString());
      final status = angsuran['status']?.toString() ?? 'aktif';
      final keterangan = angsuran['keterangan']?.toString() ?? 'Angsuran ${_getAngsuranName(jenis)}';
      final noInvoice = angsuran['no_invoice']?.toString() ?? '-';
      final tenor = angsuran['tenor']?.toString() ?? '18';
      final ke = angsuran['ke']?.toString() ?? '0';
      final namaBarang = angsuran['nama_barang']?.toString() ?? 'Handphone';
      final hargaBagiHasil = (angsuran['harga_bagi_hasil'] as num?)?.toDouble() ?? 0;
      final sisaBagiHasil = (angsuran['sisa_bagi_hasil'] as num?)?.toDouble() ?? 0;
      final jangkaWaktu = angsuran['jangka_waktu']?.toString() ?? '18 Bulan';
      final statusMaster = angsuran['status_master']?.toString() ?? 'TEPAT WAKTU';

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getAngsuranColor(jenis).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getAngsuranColor(jenis),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.payments,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getAngsuranName(jenis),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getAngsuranColor(jenis),
                              ),
                            ),
                            Text(
                              namaBarang,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // DETAIL ANGSURAN
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INFO UTAMA
                        const Text(
                          'Detail Pembiayaan Taqsith',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildDetailItem('Jenis Pembiayaan', _getAngsuranName(jenis)),
                        _buildDetailItem('No. Invoice', noInvoice),
                        _buildDetailItem('Produk', namaBarang),
                        _buildDetailItem('Keterangan', keterangan),
                        _buildDetailItem('Tanggal', tanggal),
                        _buildDetailItem('Angsuran Ke', '$ke dari $tenor'),
                        _buildDetailItem('Jangka Waktu', jangkaWaktu),
                        _buildDetailItem('Jumlah Angsuran', _formatCurrency(jumlah)),
                        _buildDetailItem('Bagi Hasil', _formatCurrency(hargaBagiHasil)),
                        _buildDetailItem('Total Pembiayaan', _formatCurrency(totalAngsuran)),
                        _buildDetailItem('Sisa Angsuran', _formatCurrency(sisaAngsuran)),
                        _buildDetailItem('Sisa Bagi Hasil', _formatCurrency(sisaBagiHasil)),
                        
                        const SizedBox(height: 16),
                        
                        // PROGRESS BAR
                        if (totalAngsuran > 0 && sisaAngsuran >= 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Progress Pelunasan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: totalAngsuran > 0 ? (totalAngsuran - sisaAngsuran) / totalAngsuran : 0,
                                backgroundColor: Colors.grey[300],
                                color: Colors.green,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalAngsuran > 0 
                                  ? '${((totalAngsuran - sisaAngsuran) / totalAngsuran * 100).toStringAsFixed(1)}% Terbayar'
                                  : '0% Terbayar',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // STATUS
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _getStatusColor(status)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: _getStatusColor(status),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Status Angsuran: ${status.toUpperCase()}',
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(statusMaster).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _getStatusColor(statusMaster)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: _getStatusColor(statusMaster),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Status Kredit: $statusMaster',
                                    style: TextStyle(
                                      color: _getStatusColor(statusMaster),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // TOMBOL TUTUP
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error showing detail: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Detail Angsuran'),
          content: const Text('Terjadi kesalahan saat menampilkan detail.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
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
            onPressed: _loadRiwayatAngsuran,
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
    final isTaqsithSelected = _selectedAngsuranType == 'taqsith';
    final isSemuaSelected = _selectedAngsuranType == 'semua';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTaqsithSelected || isSemuaSelected ? Icons.payments_outlined : Icons.build_circle_outlined,
            size: 80, 
            color: Colors.grey[400]
          ),
          const SizedBox(height: 16),
          Text(
            isTaqsithSelected || isSemuaSelected 
                ? 'Belum ada riwayat taqsith'
                : 'Fitur ${_getAngsuranName(_selectedAngsuranType)}',
            style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isTaqsithSelected || isSemuaSelected
                  ? 'Data riwayat pembiayaan akan muncul setelah Anda melakukan transaksi taqsith'
                  : 'Fitur ${_getAngsuranName(_selectedAngsuranType)} belum terintegrasi dengan API',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadRiwayatAngsuran,
            icon: const Icon(Icons.refresh),
            label: Text(isTaqsithSelected || isSemuaSelected ? 'Refresh Data' : 'Kembali ke Taqsith'),
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
    final totalSemuaAngsuran = _getTotalAngsuran('semua');
    final filteredCount = _filteredRiwayat.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Riwayat Pembiayaan Taqsith',
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
                onPressed: _loadRiwayatAngsuran,
                tooltip: 'Refresh Data',
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ✅ Header Info - Total Semua Angsuran
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
                  'Total Semua Pembiayaan Taqsith',
                  style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(totalSemuaAngsuran),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$filteredCount transaksi taqsith',
                  style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // ✅ Jenis Angsuran Syariah Filter
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
              itemCount: _angsuranTypes.length,
              itemBuilder: (context, index) {
                final type = _angsuranTypes[index];
                final isSelected = _selectedAngsuranType == type['id'];
                final isActive = type['is_active'] == true;
                final totalAngsuran = _getTotalAngsuran(type['id'] as String);

                return GestureDetector(
                  onTap: isActive ? () {
                    setState(() {
                      _selectedAngsuranType = type['id'] as String;
                    });
                  } : null,
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (type['color'] as Color).withOpacity(0.15)
                          : (isActive ? Colors.white : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? type['color'] as Color 
                            : (isActive ? Colors.grey[300]! : Colors.grey[400]!),
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
                        Stack(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: isActive ? type['color'] as Color : Colors.grey[400],
                              size: 24,
                            ),
                            if (!isActive)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? type['color'] as Color : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isActive ? _formatCurrency(totalAngsuran) : 'Coming Soon',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive 
                                ? (isSelected ? Colors.black87 : Colors.black54)
                                : Colors.grey[500],
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
                          'Memuat data pembiayaan taqsith...',
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
                            onRefresh: _loadRiwayatAngsuran,
                            color: Colors.green,
                            backgroundColor: Colors.white,
                            child: ListView.separated(
                              itemCount: _filteredRiwayat.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final angsuran = _filteredRiwayat[index];
                                final jumlah = (angsuran['jumlah'] as num?)?.toDouble() ?? 0;
                                final jenis = angsuran['jenis']?.toString() ?? 'taqsith';
                                final sisaAngsuran = (angsuran['sisa_angsuran'] as num?)?.toDouble() ?? 0;
                                final status = angsuran['status']?.toString() ?? 'aktif';
                                final keterangan = angsuran['keterangan']?.toString() ?? 'Angsuran ${_getAngsuranName(jenis)}';
                                final tanggal = _formatTanggal(angsuran['tanggal']?.toString());
                                final ke = angsuran['ke']?.toString() ?? '0';
                                final tenor = angsuran['tenor']?.toString() ?? '18';
                                final namaBarang = angsuran['nama_barang']?.toString() ?? 'Produk';
                                final hargaBagiHasil = (angsuran['harga_bagi_hasil'] as num?)?.toDouble() ?? 0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.green[100]!),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getAngsuranColor(jenis).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.payments,
                                        color: _getAngsuranColor(jenis),
                                        size: 20,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                namaBarang,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                keterangan,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getAngsuranColor(jenis).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: _getAngsuranColor(jenis)),
                                          ),
                                          child: Text(
                                            _getAngsuranName(jenis),
                                            style: TextStyle(
                                              color: _getAngsuranColor(jenis),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$tanggal • Invoice: ${angsuran['no_invoice']}'),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: _getStatusColor(status)),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  color: _getStatusColor(status),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Ke: $ke/$tenor',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (hargaBagiHasil > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Bagi Hasil: ${_formatCurrency(hargaBagiHasil)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatCurrency(jumlah),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (sisaAngsuran > 0)
                                          Text(
                                            'Sisa: ${_formatCurrency(sisaAngsuran)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (sisaAngsuran == 0)
                                          Text(
                                            'LUNAS',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      _showDetailAngsuran(angsuran);
                                    },
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