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
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late String _selectedAngsuranType;

  // ✅ Daftar jenis angsuran SYARIAH
  final List<Map<String, dynamic>> _angsuranTypes = [
    {'id': 'semua', 'name': 'Semua', 'icon': Icons.all_inclusive, 'color': Colors.green},
    {'id': 'mudharabah', 'name': 'Mudharabah', 'icon': Icons.account_balance, 'color': Colors.green},
    {'id': 'murabahah', 'name': 'Murabahah', 'icon': Icons.shopping_cart, 'color': Colors.blue},
    {'id': 'musyarakah', 'name': 'Musyarakah', 'icon': Icons.handshake, 'color': Colors.orange},
    {'id': 'ijarah', 'name': 'Ijarah', 'icon': Icons.home_work, 'color': Colors.purple},
    {'id': 'qardh', 'name': 'Qardh Hasan', 'icon': Icons.volunteer_activism, 'color': Colors.teal},
    {'id': 'wakalah', 'name': 'Wakalah', 'icon': Icons.assignment, 'color': Colors.indigo},
    {'id': 'taqsith', 'name': 'Taqsith', 'icon': Icons.handshake, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    
    // ✅ SET INITIAL VALUE BERDASARKAN PARAMETER
    _selectedAngsuranType = widget.initialAngsuranType ?? 'semua';
    
    _loadRiwayatAngsuran();
  }

  // ✅ PERBAIKAN: Method untuk load data dengan error handling yang lebih baik
  Future<void> _loadRiwayatAngsuran() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      // ✅ PERBAIKAN: Gunakan method yang benar dari ApiService
      final result = await _apiService.getRiwayatAngsuran();
      
      if (mounted) {
        setState(() {
          // ✅ PERBAIKAN: Handle berbagai format response
          if (result is List) {
            _riwayatAngsuran = result.map((item) {
              if (item is Map<String, dynamic>) {
                return item;
              } else if (item is Map) {
                return Map<String, dynamic>.from(item);
              } else {
                return <String, dynamic>{
                  'id': item.toString(),
                  'keterangan': 'Angsuran',
                  'jumlah': 0,
                  'tanggal': DateTime.now().toString(),
                  'status': 'Pending',
                  'jenis_tabungan': 'taqsith'
                };
              }
            }).toList();
          } else {
            _riwayatAngsuran = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading riwayat angsuran: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Gagal memuat data: $e';
          _riwayatAngsuran = [];
        });
      }
    }
  }

  // ✅ PERBAIKAN: Filter riwayat berdasarkan jenis angsuran dengan safety check
  List<Map<String, dynamic>> get _filteredRiwayat {
    if (_selectedAngsuranType == 'semua') {
      return _riwayatAngsuran;
    }
    return _riwayatAngsuran.where((angsuran) {
      final jenis = angsuran['jenis_tabungan']?.toString() ?? 'taqsith';
      return jenis == _selectedAngsuranType;
    }).toList();
  }

  // ✅ PERBAIKAN: Get total angsuran dengan safety check
  int _getTotalAngsuran(String jenisTabungan) {
    try {
      if (jenisTabungan == 'semua') {
        return _riwayatAngsuran.fold(0, (sum, angsuran) {
          final jumlah = (angsuran['jumlah'] as num?)?.toInt() ?? 0;
          return sum + jumlah;
        });
      }
      
      final filtered = _riwayatAngsuran.where((a) => 
        (a['jenis_tabungan']?.toString() ?? '') == jenisTabungan
      );
      return filtered.fold(0, (sum, angsuran) {
        final jumlah = (angsuran['jumlah'] as num?)?.toInt() ?? 0;
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

  // ✅ PERBAIKAN: Get status color dengan default
  Color _getStatusColor(String status) {
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'lunas': return Colors.green;
      case 'aktif': return Colors.blue;
      case 'tertunggak': return Colors.red;
      case 'pending': return Colors.orange;
      case 'selesai': return Colors.green;
      default: return Colors.grey;
    }
  }

  // ✅ PERBAIKAN: Get angsuran color dengan default
  Color _getAngsuranColor(String jenis) {
    final jenisStr = jenis.toString().toLowerCase();
    switch (jenisStr) {
      case 'taqsith': return Colors.purple;
      case 'mudharabah': return Colors.green;
      case 'murabahah': return Colors.blue;
      case 'musyarakah': return Colors.orange;
      case 'ijarah': return Colors.purple;
      case 'qardh': return Colors.teal;
      case 'wakalah': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  // ✅ PERBAIKAN: Get angsuran name dengan default
  String _getAngsuranName(String jenis) {
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
  }

  // ✅ PERBAIKAN: Tampilkan dialog detail dengan data real
  void _showDetailAngsuran(Map<String, dynamic> angsuran) {
    final jumlah = (angsuran['jumlah'] as num?)?.toInt() ?? 0;
    final jenisTabungan = angsuran['jenis_tabungan']?.toString() ?? 'taqsith';
    final sisaAngsuran = (angsuran['sisa_angsuran'] as num?)?.toInt() ?? 0;
    final tanggal = angsuran['tanggal']?.toString() ?? '';
    final status = angsuran['status']?.toString() ?? 'Pending';
    final keterangan = angsuran['keterangan']?.toString() ?? 'Angsuran ${_getAngsuranName(jenisTabungan)}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getAngsuranColor(jenisTabungan).withOpacity(0.1),
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
                        color: _getAngsuranColor(jenisTabungan),
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
                            _getAngsuranName(jenisTabungan),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getAngsuranColor(jenisTabungan),
                            ),
                          ),
                          Text(
                            keterangan,
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
                        'Detail Angsuran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailItem('Jenis Pembiayaan', _getAngsuranName(jenisTabungan)),
                      _buildDetailItem('Keterangan', keterangan),
                      _buildDetailItem('Tanggal', tanggal),
                      _buildDetailItem('Jumlah Angsuran', _formatCurrency(jumlah)),
                      _buildDetailItem('Sisa Angsuran', _formatCurrency(sisaAngsuran)),
                      
                      const SizedBox(height: 16),
                      
                      // STATUS
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
                              'Status: $status',
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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

  @override
  Widget build(BuildContext context) {
    final totalSemuaAngsuran = _getTotalAngsuran('semua');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Riwayat Taqsith',
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
                  'Total Semua Taqsith',
                  style: TextStyle(fontSize: 16, color: Colors.green),
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
                  '${_filteredRiwayat.length} transaksi',
                  style: TextStyle(color: Colors.green[600]),
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
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              itemCount: _angsuranTypes.length,
              itemBuilder: (context, index) {
                final type = _angsuranTypes[index];
                final isSelected = _selectedAngsuranType == type['id'];
                final totalAngsuran = _getTotalAngsuran(type['id'] as String);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAngsuranType = type['id'] as String;
                    });
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (type['color'] as Color).withOpacity(0.2)
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
                          color: Colors.black.withOpacity(0.1),
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
                          _formatCurrency(totalAngsuran),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(
                backgroundColor: Colors.green,
                color: Colors.green,
              ),
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
                          'Memuat data taqsith...',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  )
                : _hasError
                    ? _buildErrorWidget()
                    : _filteredRiwayat.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payments, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada riwayat taqsith',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Data akan muncul setelah melakukan pembiayaan',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadRiwayatAngsuran,
                            color: Colors.green,
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              itemCount: _filteredRiwayat.length,
                              itemBuilder: (context, index) {
                                final angsuran = _filteredRiwayat[index];
                                final jumlah = (angsuran['jumlah'] as num?)?.toInt() ?? 0;
                                final jenisTabungan = angsuran['jenis_tabungan']?.toString() ?? 'taqsith';
                                final sisaAngsuran = (angsuran['sisa_angsuran'] as num?)?.toInt() ?? 0;
                                final status = angsuran['status']?.toString() ?? 'Pending';
                                final keterangan = angsuran['keterangan']?.toString() ?? 'Angsuran ${_getAngsuranName(jenisTabungan)}';
                                final tanggal = angsuran['tanggal']?.toString() ?? '';

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
                                        color: _getAngsuranColor(jenisTabungan).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.payments,
                                        color: _getAngsuranColor(jenisTabungan),
                                        size: 20,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            keterangan,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getAngsuranColor(jenisTabungan).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: _getAngsuranColor(jenisTabungan)),
                                          ),
                                          child: Text(
                                            _getAngsuranName(jenisTabungan),
                                            style: TextStyle(
                                              color: _getAngsuranColor(jenisTabungan),
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
                                        Text(tanggal),
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
                                          ],
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
                                        if (sisaAngsuran == 0 && status.toLowerCase() == 'lunas')
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