import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ✅ CUSTOM SHAPE UNTUK APPBAR DENGAN TENGAH PENDEK & SAMPING IKUT MELENGKUNG KE DALEM
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
  late List<Map<String, dynamic>> _riwayatAngsuran;
  bool _isLoading = true;
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

  // ✅ Data detail angsuran untuk setiap jenis
  final Map<String, Map<String, dynamic>> _detailAngsuran = {
    'taqsith': {
      'nama_barang': 'Pembiayaan Umum Taqsith',
      'jangka_waktu': '12 bulan',
      'angsuran_perbulan': 350000,
      'total_pembiayaan': 4200000,
      'tanggal_mulai': '2024-01-01',
      'status': 'Aktif',
    },
    'mudharabah': {
      'nama_barang': 'Pembiayaan Usaha Ternak Ayam',
      'jangka_waktu': '12 bulan',
      'angsuran_perbulan': 250000,
      'total_pembiayaan': 3000000,
      'tanggal_mulai': '2023-10-01',
      'status': 'Aktif',
    },
    'murabahah': {
      'nama_barang': 'Mobil Toyota Avanza',
      'jangka_waktu': '24 bulan', 
      'angsuran_perbulan': 500000,
      'total_pembiayaan': 12000000,
      'tanggal_mulai': '2024-01-05',
      'status': 'Aktif',
    },
    'musyarakah': {
      'nama_barang': 'Kerjasama Usaha Cafe',
      'jangka_waktu': '18 bulan',
      'angsuran_perbulan': 300000,
      'total_pembiayaan': 5400000,
      'tanggal_mulai': '2023-12-10',
      'status': 'Aktif',
    },
    'ijarah': {
      'nama_barang': 'Sewa Ruko Usaha',
      'jangka_waktu': '12 bulan',
      'angsuran_perbulan': 1500000,
      'total_pembiayaan': 18000000,
      'tanggal_mulai': '2024-02-01',
      'status': 'Aktif',
    },
    'qardh': {
      'nama_barang': 'Pinjaman Kebajikan Pendidikan',
      'jangka_waktu': '10 bulan',
      'angsuran_perbulan': 200000,
      'total_pembiayaan': 2000000,
      'tanggal_mulai': '2024-01-15',
      'status': 'Aktif',
    },
    'wakalah': {
      'nama_barang': 'Pembiayaan Modal Kerja',
      'jangka_waktu': '8 bulan',
      'angsuran_perbulan': 750000,
      'total_pembiayaan': 6000000,
      'tanggal_mulai': '2024-03-01',
      'status': 'Aktif',
    },
  };

  @override
  void initState() {
    super.initState();
    
    // ✅ SET INITIAL VALUE BERDASARKAN PARAMETER
    _selectedAngsuranType = widget.initialAngsuranType ?? 'semua';
    
    _riwayatAngsuran = [];
    _loadRiwayatAngsuran();
  }

  // ✅ PERBAIKAN: Method jadi async dan handle Future properly
  Future<void> _loadRiwayatAngsuran() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ PERBAIKAN: Panggil method tanpa parameter dan await hasilnya
      final result = await _apiService.getRiwayatAngsuran();
      
      // ✅ PERBAIKAN: Convert List<dynamic> ke List<Map<String, dynamic>>
      setState(() {
        _riwayatAngsuran = List<Map<String, dynamic>>.from(result.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            return <String, dynamic>{};
          }
        }));
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading riwayat angsuran: $e');
      setState(() {
        _riwayatAngsuran = [];
        _isLoading = false;
      });
    }
  }

  // ✅ Filter riwayat berdasarkan jenis angsuran
  List<Map<String, dynamic>> get _filteredRiwayat {
    if (_selectedAngsuranType == 'semua') {
      return _riwayatAngsuran;
    }
    return _riwayatAngsuran.where((angsuran) {
      return angsuran['jenis_tabungan'] == _selectedAngsuranType;
    }).toList();
  }

  // ✅ Get total angsuran per jenis tabungan
  int _getTotalAngsuran(String jenisTabungan) {
    if (jenisTabungan == 'semua') {
      return _riwayatAngsuran.fold(0, (sum, angsuran) {
        final jumlah = (angsuran['jumlah'] as num?)?.toInt() ?? 0;
        return sum + jumlah;
      });
    }
    
    final filtered = _riwayatAngsuran.where((a) => a['jenis_tabungan'] == jenisTabungan);
    return filtered.fold(0, (sum, angsuran) {
      final jumlah = (angsuran['jumlah'] as num?)?.toInt() ?? 0;
      return sum + jumlah;
    });
  }

  // ✅ Get jumlah angsuran aktif per jenis
  int _getAngsuranAktif(String jenisTabungan) {
    if (jenisTabungan == 'semua') return 0;
    
    final filtered = _riwayatAngsuran.where((a) => 
      a['jenis_tabungan'] == jenisTabungan && a['status'] == 'Aktif'
    );
    if (filtered.isEmpty) return 0;
    
    final latest = filtered.reduce((a, b) {
      final dateA = DateTime.tryParse(a['tanggal']?.toString() ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['tanggal']?.toString() ?? '') ?? DateTime(2000);
      return dateA.isAfter(dateB) ? a : b;
    });
    
    return (latest['sisa_angsuran'] as num?)?.toInt() ?? 0;
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Lunas': return Colors.green;
      case 'Aktif': return Colors.blue;
      case 'Tertunggak': return Colors.red;
      case 'Pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Color _getAngsuranColor(String jenis) {
    switch (jenis) {
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

  String _getAngsuranName(String jenis) {
    switch (jenis) {
      case 'taqsith': return 'Taqsith';
      case 'mudharabah': return 'Mudharabah';
      case 'murabahah': return 'Murabahah';
      case 'musyarakah': return 'Musyarakah';
      case 'ijarah': return 'Ijarah';
      case 'qardh': return 'Qardh Hasan';
      case 'wakalah': return 'Wakalah';
      default: return 'Unknown';
    }
  }

  // ✅ FUNGSI UNTUK MENAMPILKAN DETAIL ANGSURAN
  void _showDetailAngsuran(String jenisAngsuran) {
    final detail = _detailAngsuran[jenisAngsuran];
    if (detail == null) return;

    // Filter riwayat untuk jenis angsuran tertentu
    final riwayatJenis = _riwayatAngsuran
        .where((a) => a['jenis_tabungan'] == jenisAngsuran)
        .toList();

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
                  color: _getAngsuranColor(jenisAngsuran).withOpacity(0.1),
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
                        color: _getAngsuranColor(jenisAngsuran),
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
                            _getAngsuranName(jenisAngsuran),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getAngsuranColor(jenisAngsuran),
                            ),
                          ),
                          Text(
                            detail['nama_barang'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
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
                        'Detail Pembiayaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDetailItem('Nama Barang/Jasa', detail['nama_barang'] ?? ''),
                      _buildDetailItem('Jangka Waktu', detail['jangka_waktu'] ?? ''),
                      _buildDetailItem('Angsuran per Bulan', _formatCurrency(detail['angsuran_perbulan'] ?? 0)),
                      _buildDetailItem('Total Pembiayaan', _formatCurrency(detail['total_pembiayaan'] ?? 0)),
                      _buildDetailItem('Tanggal Mulai', detail['tanggal_mulai'] ?? ''),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(detail['status'] ?? '').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(detail['status'] ?? '')),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: _getStatusColor(detail['status'] ?? ''),
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Status: ${detail['status'] ?? ''}',
                              style: TextStyle(
                                color: _getStatusColor(detail['status'] ?? ''),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // RIWAYAT ANGSURAN
                      Text(
                        'Riwayat ${_getAngsuranName(jenisAngsuran)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (riwayatJenis.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Belum ada riwayat angsuran',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // HEADER TABLE
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'No',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Tanggal',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Angsuran',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Sisa',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // DATA TABLE
                              ...riwayatJenis.asMap().entries.map((entry) {
                                final index = entry.key;
                                final angsuran = entry.value;
                                final jumlah = (angsuran['jumlah'] as num?)?.toInt() ?? 0;
                                final sisaAngsuran = (angsuran['sisa_angsuran'] as num?)?.toInt() ?? 0;
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    color: index.isEven ? Colors.white : Colors.grey[50],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          angsuran['tanggal']?.toString() ?? '',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          _formatCurrency(jumlah),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          _formatCurrency(sisaAngsuran),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: sisaAngsuran > 0 ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  @override
  Widget build(BuildContext context) {
    final totalSemuaAngsuran = _angsuranTypes
        .where((type) => type['id'] != 'semua')
        .map((type) => _getTotalAngsuran(type['id']))
        .fold(0, (sum, angsuran) => sum + angsuran);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Taqsith',
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
                  '${_filteredRiwayat.length} angsuran',
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
                final totalAngsuran = type['id'] == 'semua' 
                    ? totalSemuaAngsuran 
                    : _getTotalAngsuran(type['id']);
                final angsuranAktif = type['id'] == 'semua' ? 0 : _getAngsuranAktif(type['id']);

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
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(totalAngsuran),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (angsuranAktif > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Aktif: ${_formatCurrency(angsuranAktif)}',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                : _filteredRiwayat.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada taqsith',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pilih jenis pembiayaan syariah untuk melihat riwayat',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadRiwayatAngsuran();
                        },
                        color: Colors.green,
                        backgroundColor: Colors.white,
                        child: ListView.builder(
                          itemCount: _filteredRiwayat.length,
                          itemBuilder: (context, index) {
                            final angsuran = _filteredRiwayat[index];
                            final jumlah = (angsuran['jumlah'] as num?)?.toInt() ?? 0;
                            final jenisTabungan = angsuran['jenis_tabungan']?.toString() ?? '';
                            final sisaAngsuran = (angsuran['sisa_angsuran'] as num?)?.toInt() ?? 0;

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
                                        angsuran['keterangan']?.toString() ?? 'Angsuran ${_getAngsuranName(jenisTabungan)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                                    Text(angsuran['tanggal']?.toString() ?? ''),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(angsuran['status']?.toString() ?? '').withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: _getStatusColor(angsuran['status']?.toString() ?? '')),
                                          ),
                                          child: Text(
                                            angsuran['status']?.toString() ?? 'Pending',
                                            style: TextStyle(
                                              color: _getStatusColor(angsuran['status']?.toString() ?? ''),
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
                                  _showDetailAngsuran(jenisTabungan);
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