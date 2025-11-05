import 'package:flutter/material.dart';
import 'riwayat_tabungan_screen.dart';
import 'riwayat_angsuran_screen.dart';
import '../services/api_service.dart';
import '../services/test_notification.dart'; // ✅ IMPORT TEST NOTIFICATION

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

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onRefresh;

  const DashboardScreen({
    super.key, 
    required this.user,
    this.onRefresh,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ✅ List menu yang bisa ditampilkan dengan navigation target
  final List<MenuIcon> _allMenuItems = [
    MenuIcon('Pokok', Icons.account_balance, Colors.green, 'pokok', MenuType.tabungan),
    MenuIcon('Wajib', Icons.savings, Colors.orange, 'wajib', MenuType.tabungan),
    MenuIcon('Sukarela', Icons.volunteer_activism, Colors.red, 'sukarela', MenuType.tabungan),
    MenuIcon('SiTabung', Icons.account_balance_wallet, Colors.blue, 'sitabung', MenuType.tabungan),
    MenuIcon('Siumna', Icons.money, Colors.teal, 'siumna', MenuType.tabungan),
    MenuIcon('Siquna', Icons.handshake, Colors.purple, 'siquna', MenuType.tabungan),
    MenuIcon('Angsuran', Icons.payments, Colors.amber, 'angsuran', MenuType.angsuran),
    MenuIcon('Saldo', Icons.wallet, Colors.green[700]!, 'saldo', MenuType.saldo),
  ];

  // ✅ Menu yang aktif ditampilkan (default semua aktif)
  List<MenuIcon> _activeMenuItems = [];

  // ✅ Controller untuk scroll horizontal
  final ScrollController _scrollController = ScrollController();

  // ✅ Current user data dari session
  Map<String, dynamic>? _currentUser;

  // ✅ BUAT INSTANCE API SERVICE
  final ApiService _apiService = ApiService();

  // ✅ STATE UNTUK DATA SALDO DAN ANGSURAN DARI API
  Map<String, dynamic> _saldoData = {};
  Map<String, dynamic> _angsuranData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize dengan semua menu aktif
    _activeMenuItems = List.from(_allMenuItems);
    // ✅ Load current user data dari session
    _loadCurrentUser();
    // ✅ Load data saldo dan angsuran dari API
    _loadDataFromApi();
    // ✅ Load unread notifications
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Load current user dari session management
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user ?? widget.user;
        });
      }
    } catch (e) {
      print('❌ Error loading current user: $e');
      if (mounted) {
        setState(() {
          _currentUser = widget.user;
        });
      }
    }
  }

  // ✅ LOAD UNREAD NOTIFICATIONS
  Future<void> _loadUnreadNotifications() async {
    try {
      final result = await _apiService.getAllInbox();
      if (result['success'] == true) {
        final data = result['data'] ?? {};
        final inboxList = data['inbox'] ?? [];
        
        final unreadCount = inboxList.where((item) {
          final readStatus = item['read_status'] ?? item['is_read'] ?? '0';
          return readStatus == '0' || readStatus == 0 || readStatus == false;
        }).length;
        
        if (mounted) {
          setState(() {
            _unreadNotifications = unreadCount;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
    }
  }

// ✅ PERBAIKAN: LOAD DATA DENGAN STRUCTURE YANG SESUAI RIWAYAT_ANGSURAN_SCREEN
Future<void> _loadDataFromApi() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
  }

  try {
    print('🚀 Memulai load data dashboard dengan struktur taqsith...');

    // ✅ GUNAKAN METHOD YANG SAMA DENGAN RIWAYAT_ANGSURAN_SCREEN
    final dashboardResult = await _apiService.getDashboardDataRobust();
    
    if (dashboardResult['success'] == true) {
      print('✅ Dashboard data loaded successfully from: ${dashboardResult['source']}');
      final dashboardData = dashboardResult['data'] ?? {};
      
      // ✅ DEBUG DETAIL STRUCTURE
      print('📊 Dashboard data keys: ${dashboardData.keys}');
      
      if (mounted) {
        setState(() {
          // ✅ HANDLE DATA DENGAN STRUCTURE YANG SAMA DENGAN RIWAYAT_ANGSURAN
          _saldoData = dashboardData['saldo'] ?? {};
          _angsuranData = dashboardData['taqsith'] ?? {};
          
          // ✅ DEBUG NILAI DETAIL
          print('💰 Saldo data structure: $_saldoData');
          print('📈 Angsuran data structure: $_angsuranData');
          
          // ✅ CEK STRUKTUR KHUSUS UNTUK ANGSURAN
          if (_angsuranData.containsKey('data_master')) {
            print('🎯 Data master found in angsuran: ${_angsuranData['data_master']}');
          }
          if (_angsuranData.containsKey('total_angsuran')) {
            print('🎯 Total angsuran found: ${_angsuranData['total_angsuran']}');
          }
        });
      }
      
    } else {
      print('❌ Dashboard API Failed: ${dashboardResult['message']}');
      // ✅ FALLBACK: LOAD MANUAL DENGAN STRUCTURE TAQSITH
      await _loadTaqsithDataManual();
    }

  } catch (e) {
    print('❌ Error loading dashboard data: $e');
    // ✅ FALLBACK: LOAD MANUAL DENGAN STRUCTURE TAQSITH
    await _loadTaqsithDataManual();
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

// ✅ PERBAIKAN: LOAD MANUAL DATA DENGAN STRUCTURE TAQSITH
Future<void> _loadTaqsithDataManual() async {
  try {
    print('🔄 Fallback ke manual taqsith data loading...');
    
    // ✅ LOAD DATA TAQSITH SEPERTI DI RIWAYAT_ANGSURAN_SCREEN
    final taqsithResult = await _apiService.getAlltaqsith();
    
    if (taqsithResult['success'] == true) {
      print('✅ Manual Taqsith Success');
      final taqsithData = taqsithResult['data'];
      final dataMaster = taqsithResult['data_master'];
      
      // ✅ PROCESS DATA SEPERTI DI RIWAYAT_ANGSURAN_SCREEN
      double totalAngsuran = 0;
      
      // ✅ HITUNG DARI DATA MASTER (seperti di riwayat_angsuran_screen)
      if (dataMaster is List && dataMaster.isNotEmpty) {
        for (var master in dataMaster) {
          if (master is Map) {
            final angsuranValue = master['angsuran'] ?? 0;
            totalAngsuran += _parseValue(angsuranValue).toDouble();
          }
        }
      }
      
      // ✅ SIMPAN DENGAN STRUCTURE YANG SESUAI
      if (mounted) {
        setState(() {
          _angsuranData = {
            'total_angsuran': totalAngsuran,
            'data_master': dataMaster,
            'raw_taqsith': taqsithData,
          };
        });
      }
      
      print('✅ Manual taqsith loaded: $totalAngsuran');
    } else {
      print('❌ Manual Taqsith Failed: ${taqsithResult['message']}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = taqsithResult['message'] ?? 'Gagal memuat data taqsith';
        });
      }
    }
    
  } catch (e) {
    print('❌ Error manual taqsith load: $e');
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Gagal memuat data: $e';
      });
    }
  }
}

// ✅ PERBAIKAN: GET ANGSURAN VALUE DARI STRUCTURE YANG BENAR
int _getAngsuranValue() {
  try {
    print('🔍 Getting angsuran value from structure...');
    print('📊 Angsuran data structure: $_angsuranData');
    
    // ✅ CEK BERBAGAI STRUKTUR YANG MUNGKIN
    // 1. Structure dari getAlltaqsith API (seperti di riwayat_angsuran_screen)
    if (_angsuranData.containsKey('total_angsuran')) {
      final value = _angsuranData['total_angsuran'];
      print('✅ Found angsuran as total_angsuran: $value');
      return _parseValue(value);
    }
    
    // 2. Structure dari data master taqsith
    if (_angsuranData.containsKey('data_master')) {
      final dataMaster = _angsuranData['data_master'];
      if (dataMaster is List && dataMaster.isNotEmpty) {
        double total = 0;
        for (var item in dataMaster) {
          if (item is Map) {
            final angsuran = item['angsuran'] ?? 0;
            total += _parseValue(angsuran).toDouble();
          }
        }
        print('✅ Calculated angsuran from data_master: $total');
        return total.toInt();
      }
    }
    
    // 3. Structure langsung dari API response
    if (_angsuranData.containsKey('angsuran')) {
      final value = _angsuranData['angsuran'];
      print('✅ Found angsuran directly: $value');
      return _parseValue(value);
    }
    
    // 4. Cek berbagai kemungkinan key
    final possibleKeys = ['total_angsuran', 'angsuran', 'installment', 'cicilan', 'pembiayaan'];
    for (final key in possibleKeys) {
      if (_angsuranData.containsKey(key)) {
        final value = _angsuranData[key];
        print('✅ Found angsuran as $key: $value');
        return _parseValue(value);
      }
    }
    
    print('⚠️ No angsuran value found in structure');
    return 0;
    
  } catch (e) {
    print('❌ Error getting angsuran value: $e');
    return 0;
  }
}

// ✅ PERBAIKAN: FUNGSI UNTUK MENDAPATKAN NILAI DARI API DATA YANG BARU
int _getApiValue(String key, Map<String, dynamic> data) {
  try {
    if (data.isEmpty) return 0;
    
    print('🔍 Searching for key: $key in data structure');
    print('📁 Data structure: $data');
    
    // ✅ PRIORITAS: CEK DI ROOT LEVEL
    if (data.containsKey(key)) {
      final value = data[key];
      print('✅ Found $key in root: $value');
      return _parseValue(value);
    }
    
    // ✅ KHUSUS UNTUK ANGSURAN - CEK DI STRUCTURE YANG BARU
    if (key == 'angsuran') {
      // Jangan cari di saldoData, tapi di angsuranData yang terpisah
      print('🔍 Angsuran key detected - checking separate angsuran data');
      return _getAngsuranValue(); // Panggil fungsi khusus angsuran
    }
    
    // ✅ CEK BERBAGAI KEMUNGKINAN KEY NAMING
    final possibleKeys = _getPossibleKeys(key);
    for (final possibleKey in possibleKeys) {
      if (data.containsKey(possibleKey)) {
        final value = data[possibleKey];
        print('✅ Found $key as $possibleKey: $value');
        return _parseValue(value);
      }
    }
    
    print('❌ Key $key not found in data structure');
    return 0;
    
  } catch (e) {
    print('❌ Error getApiValue for $key: $e');
    return 0;
  }
}

// ✅ UPDATE: FUNGSI UNTUK MENDAPATKAN BERBAGAI KEMUNGKINAN KEY NAMING
List<String> _getPossibleKeys(String baseKey) {
  switch (baseKey) {
    case 'pokok':
      return ['pokok', 'simpananPokok', 'pokok_simpanan', 'simpanan_pokok', 'saldo_pokok'];
    case 'wajib':
      return ['wajib', 'simpananWajib', 'wajib_simpanan', 'simpanan_wajib', 'saldo_wajib'];
    case 'sukarela':
      return ['sukarela', 'simpananSukarela', 'sukarela_simpanan', 'simpanan_sukarela', 'saldo_sukarela'];
    case 'sitabung':
      return ['sitabung', 'sita', 'siTabung', 'sita_bung', 'saldo_sitabung', 'tabungan_sita'];
    case 'siumna':
      return ['siumna', 'simuna', 'simpananMuna', 'simuna_simpanan', 'saldo_siumna'];
    case 'siquna':
      return ['siquna', 'taqsith', 'taqshith', 'taqsiith', 'pembiayaan', 'saldo_siquna'];
    case 'saldo':
      return ['saldo', 'balance', 'total_saldo', 'total', 'jumlah_saldo', 'saldo_total'];
    case 'angsuran':
      return ['angsuran', 'installment', 'total_angsuran', 'taqsith_total', 'pembiayaan', 'cicilan'];
    default:
      return [baseKey];
  }
}

  // ✅ FUNGSI UNTUK PARSE VALUE DARI BERBAGAI TIPE DATA
  int _parseValue(dynamic value) {
    if (value == null) return 0;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Remove any non-numeric characters except decimal point
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned)?.toInt() ?? 0;
    }
    
    return 0;
  }

// ✅ PERBAIKAN: CALCULATE TOTAL TABUNGAN DARI DATA YANG SUDAH DINORMALISASI
int _calculateTotalTabungan() {
  try {
    // ✅ GUNAKAN KEY YANG SESUAI DENGAN RESPONSE API
    final pokok = _getApiValue('pokok', _saldoData);
    final wajib = _getApiValue('wajib', _saldoData);
    final sukarela = _getApiValue('sukarela', _saldoData);
    final sitabung = _getApiValue('sitabung', _saldoData);
    final siumna = _getApiValue('siumna', _saldoData);
    final siquna = _getApiValue('siquna', _saldoData);

    final total = pokok + wajib + sukarela + sitabung + siumna + siquna;

    print('''
    📊 Total Tabungan Calculation:
    - Pokok: $pokok
    - Wajib: $wajib  
    - Sukarela: $sukarela
    - SiTabung: $sitabung
    - Siumna: $siumna
    - Siquna: $siquna
    TOTAL: $total
    ''');

    return total;
  } catch (e) {
    print('❌ Error calculating total tabungan: $e');
    return 0;
  }
}

// ✅ PERBAIKAN: GET SALDO VALUE DENGAN LOGIC YANG LEBIH ROBUST
int _getSaldoValue() {
  try {
    // ✅ PRIORITAS 1: Ambil langsung dari saldoData
    final directSaldo = _getApiValue('saldo', _saldoData);
    if (directSaldo > 0) {
      print('✅ Using direct saldo value: $directSaldo');
      return directSaldo;
    }
    
    // ✅ PRIORITAS 2: Hitung dari total tabungan
    final calculatedTotal = _calculateTotalTabungan();
    if (calculatedTotal > 0) {
      print('✅ Using calculated total: $calculatedTotal');
      return calculatedTotal;
    }
    
    // ✅ PRIORITAS 3: Cek berbagai kemungkinan key
    final possibleKeys = ['total_saldo', 'balance', 'total', 'jumlah_saldo'];
    for (final key in possibleKeys) {
      final value = _getApiValue(key, _saldoData);
      if (value > 0) {
        print('✅ Found saldo as $key: $value');
        return value;
      }
    }
    
    print('⚠️ No saldo value found, returning 0');
    return 0;
    
  } catch (e) {
    print('❌ Error getting saldo value: $e');
    return 0;
  }
}

  // ✅ SHOW NOTIFICATIONS DIALOG
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications),
            SizedBox(width: 8),
            Text('Notifikasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_unreadNotifications > 0)
              Text(
                'Anda memiliki $_unreadNotifications pesan belum dibaca',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text('Tidak ada pesan baru'),
            const SizedBox(height: 16),
            const Text(
              'Fitur notifikasi lengkap akan segera hadir!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (_unreadNotifications > 0)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Membuka halaman notifikasi...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Lihat Semua'),
            ),
        ],
      ),
    );
  }

  // ✅ PERBAIKAN: LOGOUT FUNCTION YANG BENAR
  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _apiService.logout();
      
      // Tutup loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        if (result['success'] == true) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login', 
            (route) => false
          );
        } else {
          // Jika logout API gagal, tetap redirect ke login
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login', 
            (route) => false
          );
        }
      }
    }
  }

  // ✅ REFRESH DATA FUNCTION
  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    // Refresh user data dari session
    await _loadCurrentUser();
    // Refresh data dari API
    await _loadDataFromApi();
    // Refresh notifications
    await _loadUnreadNotifications();
    
    // ✅ Panggil callback jika ada
    widget.onRefresh?.call();
    
    if (mounted && !_hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

// ✅ PERBAIKAN: HANDLE MENU TAP DENGAN DATA YANG BENAR
void _handleMenuTap(MenuIcon menu, BuildContext context) {
  final userData = _currentUser ?? widget.user;
  
  print('🎯 Menu tapped: ${menu.title} - Type: ${menu.type}');
  
  switch (menu.type) {
    case MenuType.tabungan:
      _navigateToRiwayatTabungan(context, menu, userData);
      break;
    case MenuType.angsuran:
      _navigateToRiwayatAngsuran(context, userData);
      break;
    case MenuType.saldo:
      _showSaldoDetail(context);
      break;
  }
}

// ✅ PERBAIKAN: NAVIGASI KE RIWAYAT TABUNGAN DENGAN FILTER YANG BENAR
void _navigateToRiwayatTabungan(BuildContext context, MenuIcon menu, Map<String, dynamic> userData) {
  print('🚀 Navigating to RiwayatTabungan with type: ${menu.key}');
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RiwayatTabunganScreen(
        user: userData,
        initialTabunganType: menu.key,
      ),
    ),
  );
}

  // ✅ NAVIGASI KE RIWAYAT ANGSURAN
  void _navigateToRiwayatAngsuran(BuildContext context, Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiwayatAngsuranScreen(user: userData),
      ),
    );
  }

// ✅ PERBAIKAN: SHOW SALDO DETAIL DENGAN DATA YANG AKURAT
void _showSaldoDetail(BuildContext context) {
  final saldo = _getSaldoValue();
  final totalTabungan = _calculateTotalTabungan();
  final pokok = _getApiValue('pokok', _saldoData);
  final wajib = _getApiValue('wajib', _saldoData);
  final sukarela = _getApiValue('sukarela', _saldoData);
  final sitabung = _getApiValue('sitabung', _saldoData);
  final siumna = _getApiValue('siumna', _saldoData);
  final siquna = _getApiValue('siquna', _saldoData);
  final angsuran = _getAngsuranValue();

  print('''
  📋 Saldo Detail Dialog:
  - Saldo: $saldo
  - Total Tabungan: $totalTabungan
  - Pokok: $pokok
  - Wajib: $wajib
  - Sukarela: $sukarela
  - Sitabung: $sitabung
  - Siumna: $siumna
  - Siquna: $siquna
  - Angsuran: $angsuran
  ''');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.green[700]),
          const SizedBox(width: 8),
          const Text(
            'Detail Saldo & Tabungan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSaldoDetailItem('Saldo Tersedia', saldo, Colors.green),
          const SizedBox(height: 8),
          _buildSaldoDetailItem('Total Tabungan', totalTabungan, Colors.blue),
          _buildSaldoDetailItem('Total Angsuran', angsuran, Colors.amber),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Tabungan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                _buildTabunganDetailRow('Pokok', pokok),
                _buildTabunganDetailRow('Wajib', wajib),
                _buildTabunganDetailRow('Sukarela', sukarela),
                _buildTabunganDetailRow('SiTabung', sitabung),
                _buildTabunganDetailRow('Siumna', siumna),
                _buildTabunganDetailRow('Siquna', siquna),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data diperbarui: ${DateTime.now().toString().substring(0, 16)}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          if (_hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ $_errorMessage',
                style: const TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _refreshData();
          },
          child: const Text('Refresh'),
        ),
      ],
    ),
  );
}

  Widget _buildSaldoDetailItem(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTabunganDetailRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            _formatCurrency(value),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

// ✅ PERBAIKAN: FORMAT CURRENCY UNTUK NILAI BESAR
String _formatCurrency(int value) {
  try {
    if (value == 0) return 'Rp 0';
    
    if (value < 1000) {
      return 'Rp $value';
    } else if (value < 1000000) {
      final thousands = (value / 1000).toStringAsFixed(0);
      return 'Rp ${thousands}K';
    } else if (value < 1000000000) {
      final millions = (value / 1000000).toStringAsFixed(1);
      return 'Rp ${millions}Jt';
    } else {
      final billions = (value / 1000000000).toStringAsFixed(1);
      return 'Rp ${billions}M';
    }
  } catch (e) {
    return 'Rp 0';
  }
}

  // ✅ ERROR WIDGET
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
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
            onPressed: _refreshData,
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
  // ✅ DATA DARI API (bukan dari user data)
  final saldo = _getSaldoValue();
  final angsuran = _getAngsuranValue();
  final totalTabungan = _calculateTotalTabungan();
  final userData = _currentUser ?? widget.user;

  return Scaffold(
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Beranda KSMI',
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
          // ✅ NOTIFICATION BUTTON WITH BADGE
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0, right: 8.0),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: _showNotifications,
                  tooltip: 'Notifikasi',
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // ✅ TEST NOTIFICATION BUTTON (BARU)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0, right: 4.0),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report_outlined, size: 22),
              tooltip: 'Test Notifikasi',
              onSelected: (value) {
                _handleTestNotificationMenu(value);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'test_simple',
                  child: Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Test Notifikasi Sederhana'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'test_multiple',
                  child: Row(
                    children: [
                      Icon(Icons.notification_important, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Test Multiple Notifikasi'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'check_token',
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Cek FCM Token'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'check_permissions',
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.purple, size: 20),
                      SizedBox(width: 8),
                      Text('Cek Izin Notifikasi'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Hapus Semua Notifikasi'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'test_scenarios',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Text('Test Semua Scenario'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ REFRESH BUTTON
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0, right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh Data',
            ),
          ),
          
          // ✅ LOGOUT BUTTON
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0, right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
    ),
    backgroundColor: Colors.green[50],
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (_hasError)
                _buildErrorWidget()
              else if (_isLoading) 
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.green[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat data...',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else 
                Column(
                  children: [
                    // TOTAL TABUNGAN SECTION
                    InkWell(
                      onTap: () {
                        _navigateToRiwayatTabungan(context, _allMenuItems[0], userData);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.savings, color: Colors.blue[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Tabungan',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(totalTabungan),
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pokok + Wajib + Sukarela + SiTabung + Simuna + Taqsith',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: totalTabungan > 0 ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                totalTabungan > 0 ? 'Aktif' : 'Kosong',
                                style: TextStyle(
                                  color: totalTabungan > 0 ? Colors.blue[800] : Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue[700]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ANGSURAN SECTION
                    InkWell(
                      onTap: () {
                        _navigateToRiwayatAngsuran(context, userData);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payments, color: Colors.green[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Angsuran',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(angsuran),
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pembiayaan Taqsith Aktif',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: angsuran > 0 ? Colors.green[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                angsuran > 0 ? 'Aktif' : 'Tidak Ada',
                                style: TextStyle(
                                  color: angsuran > 0 ? Colors.green[800] : Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green[700]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // ✅ MENU UTAMA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Menu Utama',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          onTap: () {
                            _showEditMenuDialog(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 16, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // ✅ GRID MENU UTAMA
                    Container(
                      height: 200,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: (_activeMenuItems.length / 4).ceil(),
                        itemBuilder: (context, pageIndex) {
                          return Container(
                            width: MediaQuery.of(context).size.width - 32,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: List.generate(4, (index) {
                                      final itemIndex = pageIndex * 4 + index;
                                      if (itemIndex >= _activeMenuItems.length) {
                                        return Expanded(child: Container());
                                      }
                                      final menu = _activeMenuItems[itemIndex];
                                      return Expanded(
                                        child: _buildSmallMenuIcon(
                                          menu,
                                          menu.type == MenuType.angsuran 
                                              ? _getAngsuranValue() 
                                              : _getApiValue(menu.key, _saldoData),
                                          context,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Row(
                                    children: List.generate(4, (index) {
                                      final itemIndex = pageIndex * 4 + 4 + index;
                                      if (itemIndex >= _activeMenuItems.length) {
                                        return Expanded(child: Container());
                                      }
                                      final menu = _activeMenuItems[itemIndex];
                                      return Expanded(
                                        child: _buildSmallMenuIcon(
                                          menu,
                                          menu.type == MenuType.angsuran 
                                              ? _getAngsuranValue() 
                                              : _getApiValue(menu.key, _saldoData),
                                          context,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
  Widget _buildSmallMenuIcon(MenuIcon menu, int value, BuildContext context) {
    return GestureDetector(
      onTap: () {
        _handleMenuTap(menu, context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: menu.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: menu.color.withOpacity(0.3)),
              ),
              child: Icon(menu.icon, color: menu.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              menu.title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _formatCurrency(value),
              style: TextStyle(
                fontSize: 8,
                color: value > 0 ? Colors.green[700] : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

// ✅ METHOD UNTUK HANDLE TEST NOTIFICATION MENU (FINAL)
void _handleTestNotificationMenu(String value) async {
  try {
    // Initialize NotificationTester first
    if (!NotificationTester.isInitialized) {
      await NotificationTester.initialize();
    }

    switch (value) {
      case 'test_simple':
        await NotificationTester.quickTest(); // Gunakan method paling sederhana
        break;
      case 'test_multiple':
        await NotificationTester.testMultipleScenarios();
        break;
      case 'check_token':
        await NotificationTester.printFCMToken();
        break;
      case 'check_permissions':
        await NotificationTester.checkPermissions();
        break;
      case 'clear_all':
        await NotificationTester.clearAllNotifications();
        break;
      case 'test_scenarios':
        await NotificationTester.testMultipleScenarios();
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test $value completed'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ✅ TEST SIMPLE NOTIFICATION (DIPERBAIKI)
void _testSimpleNotification() async {
  try {
    await NotificationTester.testLocalNotification();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Test notifikasi berhasil dikirim!'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ✅ TEST MULTIPLE NOTIFICATIONS
void _testMultipleNotifications() {
  try {
    // Kirim beberapa notifikasi dengan delay
    for (int i = 1; i <= 3; i++) {
      Future.delayed(Duration(seconds: i * 2), () {
        NotificationTester.testLocalNotification();
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('3 test notifikasi akan dikirim dengan delay!'),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ✅ CHECK FCM TOKEN
void _checkFCMToken() {
  try {
    NotificationTester.printFCMToken();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cek FCM Token di console/log!'),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ✅ CHECK NOTIFICATION PERMISSIONS
void _checkNotificationPermissions() {
  try {
    NotificationTester.checkPermissions();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cek izin notifikasi di console/log!'),
        backgroundColor: Colors.purple[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ✅ CLEAR ALL NOTIFICATIONS
void _clearAllNotifications() {
  try {
    NotificationTester.clearAllNotifications();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Semua notifikasi dihapus!'),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ✅ TEST ALL SCENARIOS
void _testAllScenarios() {
  try {
    NotificationTester.testMultipleScenarios();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Testing semua scenario notifikasi!'),
        backgroundColor: Colors.teal[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

  // ✅ FUNGSI EDIT MENU
  void _showEditMenuDialog(BuildContext context) {
    List<MenuIcon> tempMenuItems = List.from(_activeMenuItems);
    
    for (var menu in _allMenuItems) {
      if (!tempMenuItems.any((item) => item.key == menu.key)) {
        tempMenuItems.add(menu);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Menu Utama'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pilih menu yang ingin ditampilkan:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allMenuItems.map((menu) {
                        final isActive = tempMenuItems.any((item) => item.key == menu.key);
                        return FilterChip(
                          label: Text(menu.title),
                          selected: isActive,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                if (!tempMenuItems.any((item) => item.key == menu.key)) {
                                  tempMenuItems.add(menu);
                                }
                              } else {
                                tempMenuItems.removeWhere((item) => item.key == menu.key);
                              }
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.green[100],
                          checkmarkColor: Colors.green[700],
                          labelStyle: TextStyle(
                            color: isActive ? Colors.green[700] : Colors.grey[700],
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${tempMenuItems.length} dari ${_allMenuItems.length} menu dipilih',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _activeMenuItems = List.from(tempMenuItems);
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menu berhasil diupdate (${_activeMenuItems.length} item)'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ✅ MODEL UNTUK MENU ICON DENGAN TYPE
class MenuIcon {
  final String title;
  final IconData icon;
  final Color color;
  final String key;
  final MenuType type;

  MenuIcon(this.title, this.icon, this.color, this.key, this.type);
}

// ✅ ENUM UNTUK JENIS MENU
enum MenuType {
  tabungan,
  angsuran,
  saldo,
}