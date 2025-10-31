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

  const DashboardScreen({super.key, required this.user});

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

  @override
  void initState() {
    super.initState();
    // ✅ Initialize dengan semua menu aktif
    _activeMenuItems = List.from(_allMenuItems);
    // ✅ Load current user data dari session
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Load current user dari session management
  Future<void> _loadCurrentUser() async {
    // ✅ FIX: Pakai instance method, bukan static
    final user = await _apiService.getCurrentUser();
    setState(() {
      _currentUser = user ?? widget.user;
    });
  }

  // ✅ Fungsi untuk mendapatkan nilai dari user data berdasarkan key
  int _getUserValue(String key) {
    final userData = _currentUser ?? widget.user;
    final value = (userData[key] as num?)?.toInt() ?? 0;
    return value;
  }

  // ✅ Calculate total tabungan (semua simpanan kecuali angsuran)
  int _calculateTotalTabungan() {
    return _getUserValue('pokok') +
        _getUserValue('simpananWajib') +
        _getUserValue('sukarela') +
        _getUserValue('siTabung') +
        _getUserValue('simuna') +
        _getUserValue('taqsith');
  }

  // ✅ LOGOUT FUNCTION dengan session management
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
      // ✅ FIX: Pakai instance method, bukan static
      await _apiService.logout();
      
      // ✅ Navigate ke login screen dengan clear stack
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false
      );
    }
  }

  // ✅ REFRESH DATA FUNCTION
  Future<void> _refreshData() async {
    // Refresh user data dari session
    await _loadCurrentUser();
    
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
    final saldo = _getUserValue('saldo');
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
                  _buildTabunganDetailRow('Pokok', _getUserValue('pokok')),
                  _buildTabunganDetailRow('Wajib', _getUserValue('simpananWajib')),
                  _buildTabunganDetailRow('Sukarela', _getUserValue('sukarela')),
                  _buildTabunganDetailRow('SiTabung', _getUserValue('siTabung')),
                  _buildTabunganDetailRow('Simuna', _getUserValue('simuna')),
                  _buildTabunganDetailRow('Taqsith', _getUserValue('taqsith')),
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
    // ✅ SAFE CASTING untuk semua nilai
    final saldo = _getUserValue('saldo');
    final angsuran = _getUserValue('angsuran');
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
                // ✅ LANGSUNG KE TABUNGAN & ANGSURAN SECTION (PROFILE HEADER DIHAPUS)
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
                                            _getUserValue(menu.key),
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
                                            _getUserValue(menu.key),
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

                // INFO DEMO
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Koperasi KSMI - Versi Demo',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aplikasi simulasi untuk demonstrasi fitur koperasi digital',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
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