import 'package:flutter/material.dart';
import 'riwayat_tabungan_screen.dart';
import 'riwayat_angsuran_screen.dart';
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
    MenuIcon('Wajib', Icons.savings, Colors.orange, 'simpananWajib', MenuType.tabungan),
    MenuIcon('Sukarela', Icons.volunteer_activism, Colors.red, 'sukarela', MenuType.tabungan),
    MenuIcon('SiTabung', Icons.account_balance_wallet, Colors.blue, 'siTabung', MenuType.tabungan),
    MenuIcon('Simuna', Icons.money, Colors.teal, 'simuna', MenuType.tabungan),
    MenuIcon('Taqsith', Icons.handshake, Colors.purple, 'taqsith', MenuType.tabungan),
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
    final user = await _apiService.getCurrentUser();
    setState(() {
      _currentUser = user ?? widget.user;
    });
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
        
        setState(() {
          _unreadNotifications = unreadCount;
        });
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
    }
  }

  // ✅ LOAD DATA SALDO DAN ANGSURAN DARI API - COMPATIBLE VERSION
  Future<void> _loadDataFromApi() async {
    try {
      setState(() => _isLoading = true);

      // ✅ LOAD SALDO DATA DARI API
      final saldoResult = await _apiService.getAllSaldo();
      if (saldoResult['success'] == true) {
        setState(() {
          _saldoData = saldoResult['data'] ?? {};
        });
      } else {
        print('❌ Gagal load saldo: ${saldoResult['message']}');
      }

      // ✅ LOAD ANGSURAN DATA DARI API
      final angsuranResult = await _apiService.getAllAngsuran();
      if (angsuranResult['success'] == true) {
        setState(() {
          _angsuranData = angsuranResult['data'] ?? {};
        });
      } else {
        print('❌ Gagal load angsuran: ${angsuranResult['message']}');
      }

    } catch (e) {
      print('❌ Error loading data from API: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Fungsi untuk mendapatkan nilai dari API data berdasarkan key
  int _getApiValue(String key, Map<String, dynamic> data) {
    try {
      // Coba berbagai format key yang mungkin
      if (data[key] != null) {
        final value = data[key];
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
      }

      // Coba nested structure
      if (data['data'] != null && data['data'][key] != null) {
        final value = data['data'][key];
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
      }

      return 0;
    } catch (e) {
      print('❌ Error getApiValue for $key: $e');
      return 0;
    }
  }

  // ✅ Calculate total tabungan dari API data
  int _calculateTotalTabungan() {
    return _getApiValue('pokok', _saldoData) +
        _getApiValue('simpananWajib', _saldoData) +
        _getApiValue('sukarela', _saldoData) +
        _getApiValue('siTabung', _saldoData) +
        _getApiValue('simuna', _saldoData) +
        _getApiValue('taqsith', _saldoData);
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
                // TODO: Navigate to notifications screen
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

  // ✅ LOGOUT FUNCTION dengan session management - COMPATIBLE
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
      await _apiService.logout();
      
      // ✅ Navigate ke login screen dengan clear stack
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false
      );
    }
  }

  // ✅ REFRESH DATA FUNCTION - COMPATIBLE
  Future<void> _refreshData() async {
    // Refresh user data dari session
    await _loadCurrentUser();
    // Refresh data dari API
    await _loadDataFromApi();
    // Refresh notifications
    await _loadUnreadNotifications();
    
    // ✅ Panggil callback jika ada
    widget.onRefresh?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data berhasil diperbarui'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ FUNGSI UNTUK HANDLE TAP PADA MENU ICON
  void _handleMenuTap(MenuIcon menu, BuildContext context) {
    final userData = _currentUser ?? widget.user;
    
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

  // ✅ NAVIGASI KE RIWAYAT TABUNGAN DENGAN FILTER
  void _navigateToRiwayatTabungan(BuildContext context, MenuIcon menu, Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiwayatTabunganScreen(
          user: userData,
          initialTabunganType: menu.key == 'siTabung' ? 'sita' : menu.key,
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

  // ✅ SHOW SALDO DETAIL DIALOG
  void _showSaldoDetail(BuildContext context) {
    final saldo = _getApiValue('saldo', _saldoData);
    final totalTabungan = _calculateTotalTabungan();

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
              'Detail Saldo',
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
                  _buildTabunganDetailRow('Pokok', _getApiValue('pokok', _saldoData)),
                  _buildTabunganDetailRow('Wajib', _getApiValue('simpananWajib', _saldoData)),
                  _buildTabunganDetailRow('Sukarela', _getApiValue('sukarela', _saldoData)),
                  _buildTabunganDetailRow('SiTabung', _getApiValue('siTabung', _saldoData)),
                  _buildTabunganDetailRow('Simuna', _getApiValue('simuna', _saldoData)),
                  _buildTabunganDetailRow('Taqsith', _getApiValue('taqsith', _saldoData)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
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
          'Rp ${value.toStringAsFixed(0)}',
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
            'Rp ${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ DATA DARI API (bukan dari user data)
    final saldo = _getApiValue('saldo', _saldoData);
    final angsuran = _getApiValue('angsuran', _angsuranData);
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
                if (_isLoading) 
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
                                      'Rp ${totalTabungan.toStringAsFixed(0)}',
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
                                      'Rp ${angsuran.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
                                            _getApiValue(menu.key, _saldoData),
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
                                            _getApiValue(menu.key, _saldoData),
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
              'Rp ${value.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 8,
                color: Colors.green[700],
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