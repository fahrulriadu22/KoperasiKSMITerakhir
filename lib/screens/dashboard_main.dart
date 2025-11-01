import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import 'riwayat_tabungan_screen.dart';
import 'riwayat_angsuran_screen.dart';

// ✅ CUSTOM SHAPE UNTUK BOTTOM NAV DENGAN ATAS MELENGKUNG FULL WIDTH
class BottomNavShape extends ContinuousRectangleBorder {
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double curveHeight = 25.0;
    final double curveWidth = 50.0;
    
    return Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.top + curveHeight)
      ..quadraticBezierTo(
        rect.right, 
        rect.top,
        rect.right - curveWidth, 
        rect.top,
      )
      ..lineTo(rect.left + curveWidth, rect.top)
      ..quadraticBezierTo(
        rect.left, 
        rect.top,
        rect.left, 
        rect.top + curveHeight,
      )
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }
}

class DashboardMain extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardMain({Key? key, required this.user}) : super(key: key);

  @override
  State<DashboardMain> createState() => _DashboardMainState();
}

class _DashboardMainState extends State<DashboardMain> {
  // ✅ FIX: GUNAKAN PAGESTORAGE BUCKET UNTUK STATE PERSISTENCE
  final PageStorageBucket _storageBucket = PageStorageBucket();
  
  // ✅ FIX: PERSIST SELECTED INDEX DENGAN PAGESTORAGE
  int get _selectedIndex {
    return PageStorage.of(context)?.readState(context, identifier: const ValueKey('nav_index')) as int? ?? 0;
  }
  
  set _selectedIndex(int value) {
    PageStorage.of(context)?.writeState(context, value, identifier: const ValueKey('nav_index'));
    if (mounted) setState(() {});
  }

  late Map<String, dynamic> userData;
  final ApiService _apiService = ApiService();
  int _unreadNotifications = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    userData = _safeCastMap(widget.user);
    print('🚀 DashboardMain initialized with user: ${userData['username']}');
    print('📊 User data structure: ${userData.keys.toList()}');
    _initializeData();
  }

  // ✅ Platform Detection Helper
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isWeb => kIsWeb;
  bool get _isLinux => !kIsWeb && Platform.isLinux;
  bool get _isMobile => _isAndroid || _isIOS;

  // ✅ PERBAIKAN BESAR: INITIALIZE DATA DENGAN BETTER ERROR HANDLING
  Future<void> _initializeData() async {
    try {
      print('🔄 Starting dashboard initialization...');
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // ✅ PERBAIKAN: Gunakan timeout untuk mencegah hanging
      await Future.wait([
        _loadCurrentUser(),
        _loadUnreadNotifications(),
      ], eagerError: true).timeout(const Duration(seconds: 30));

      print('✅ Dashboard initialization completed successfully');

    } catch (e) {
      print('❌ Error initializing dashboard data: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // ✅ PERBAIKAN: Handle specific error types
      if (e.toString().contains('token_expired') || e.toString().contains('401')) {
        _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
        _showTokenExpiredDialog();
      } else if (e.toString().contains('timeout')) {
        _errorMessage = 'Timeout memuat data. Periksa koneksi internet Anda.';
      } else if (e.toString().contains('SocketException')) {
        _errorMessage = 'Tidak ada koneksi internet. Periksa koneksi Anda.';
      } else {
        _errorMessage = 'Gagal memuat data dashboard. Silakan coba lagi.';
      }

      setState(() {});
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('🏁 Dashboard loading state: $_isLoading');
      }
    }
  }

  // ✅ PERBAIKAN: Load current user dengan fallback ke data dari widget
  Future<void> _loadCurrentUser() async {
    try {
      print('👤 Loading current user from API...');
      final currentUser = await _apiService.getCurrentUser();
      
      if (currentUser != null && currentUser is Map<String, dynamic> && currentUser.isNotEmpty) {
        print('✅ User data loaded from API: ${currentUser['username']}');
        setState(() {
          userData = _safeCastMap(currentUser);
        });
      } else {
        print('⚠️ Using initial user data from widget');
        // Tetap gunakan data dari widget jika API gagal
        setState(() {
          userData = _safeCastMap(widget.user);
        });
      }
    } catch (e) {
      print('❌ Error loading current user: $e');
      // Fallback ke data dari widget
      setState(() {
        userData = _safeCastMap(widget.user);
      });
      throw e; // Re-throw untuk handling di level atas
    }
  }

  // ✅ PERBAIKAN: Load unread notifications dengan handle response baru
  Future<void> _loadUnreadNotifications() async {
    try {
      print('🔔 Loading unread notifications...');
      final result = await _apiService.getAllInbox();
      
      if (result['success'] == true) {
        final data = result['data'] ?? {};
        final inboxList = data['inbox'] ?? [];
        
        final unreadCount = inboxList.where((item) {
          final readStatus = item['read_status'] ?? item['is_read'] ?? '0';
          return readStatus == '0' || readStatus == 0 || readStatus == false;
        }).length;
        
        print('✅ Unread notifications: $unreadCount');
        setState(() {
          _unreadNotifications = unreadCount;
        });
      } else {
        print('❌ Gagal load inbox: ${result['message']}');
        // Jangan throw error untuk notifications, biarkan tetap 0
        setState(() {
          _unreadNotifications = 0;
        });
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      // Jangan throw error untuk notifications, biarkan tetap 0
      setState(() {
        _unreadNotifications = 0;
      });
    }
  }

  // ✅ PERBAIKAN: Token expired dialog
  void _showTokenExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesi Berakhir'),
        content: const Text('Sesi login Anda telah berakhir. Silakan login kembali.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              // Navigate to login screen
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Login Kembali'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _safeCastMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      print('⚠️ Invalid user data type: ${data.runtimeType}');
      return {'username': 'User', 'nama': 'User'};
    }
  }

  // ✅ PERBAIKAN: REFRESH DATA DENGAN BETTER ERROR HANDLING
  Future<void> _refreshUserData() async {
    try {
      print('🔄 Refreshing user data...');
      
      await Future.wait([
        _loadCurrentUser(),
        _loadUnreadNotifications(),
      ]);
      
      print('✅ User data refreshed successfully');
      
      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error refreshing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui data: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    print('📍 Navigation item tapped: $index');
    setState(() => _selectedIndex = index);
  }

  // ✅ Method untuk buka notifikasi - IMPROVED VERSION
  void _openNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifikasi'),
        content: Text(
          _unreadNotifications > 0 
            ? 'Anda memiliki $_unreadNotifications pesan belum dibaca'
            : 'Tidak ada pesan baru'
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
              child: const Text('Lihat'),
            ),
        ],
      ),
    );
  }

  // ✅ PERBAIKAN: BUILD METHOD WITH BETTER ERROR HANDLING
  @override
  Widget build(BuildContext context) {
    print('🏗️ Building DashboardMain - Loading: $_isLoading, Error: $_errorMessage');

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorScreen();
    }

    return _buildMainScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Koperasi KSMI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Menyiapkan dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selamat datang, ${userData['nama'] ?? 'User'}!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _initializeData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      // Fallback: langsung tampilkan dashboard dengan data yang ada
                      setState(() {
                        _errorMessage = '';
                        _isLoading = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Lanjutkan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    // ✅ PERBAIKAN: GUNAKAN PAGESTORAGE BUCKET UNTUK SEMUA SCREEN
    final List<Widget> pages = [
      PageStorage(
        bucket: _storageBucket,
        key: const ValueKey('beranda'),
        child: RefreshIndicator(
          onRefresh: _refreshUserData,
          color: Colors.green,
          backgroundColor: Colors.white,
          child: DashboardScreen(
            user: userData,
            onRefresh: _refreshUserData,
          ),
        ),
      ),
      PageStorage(
        bucket: _storageBucket,
        key: const ValueKey('tabungan'),
        child: RiwayatTabunganScreen(user: userData),
      ),
      PageStorage(
        bucket: _storageBucket,
        key: const ValueKey('taqsith'),
        child: RiwayatAngsuranScreen(user: userData),
      ),
      PageStorage(
        bucket: _storageBucket,
        key: const ValueKey('profil'),
        child: ProfileScreen(
          user: userData,
          onProfileUpdated: _refreshUserData,
        ),
      ),
    ];

    return PageStorage(
      bucket: _storageBucket,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: _buildUniversalBottomNav(),
      ),
    );
  }

  // ✅ UNIVERSAL BOTTOM NAVIGATION UNTUK SEMUA PLATFORM
  Widget _buildUniversalBottomNav() {
    if (_isWeb || _isLinux) {
      return _buildWebAndLinuxBottomNav();
    } else if (_isAndroid) {
      return _buildAndroidBottomNav();
    } else if (_isIOS) {
      return _buildIOSBottomNav();
    } else {
      return _buildDefaultBottomNav();
    }
  }

  // ✅ SOLUTION UNTUK WEB & LINUX (Tanpa System Navigation Bar)
  Widget _buildWebAndLinuxBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_rounded,
            label: 'Beranda',
            index: 0,
            platform: 'web_linux',
          ),
          _buildNavItem(
            icon: Icons.savings_rounded,
            label: 'Tabungan',
            index: 1,
            platform: 'web_linux',
          ),
          _buildNavItem(
            icon: Icons.payments_rounded,
            label: 'Taqsith',
            index: 2,
            platform: 'web_linux',
          ),
          _buildNavItem(
            icon: Icons.person_rounded,
            label: 'Profil',
            index: 3,
            platform: 'web_linux',
          ),
        ],
      ),
    );
  }

  // ✅ SOLUTION UNTUK ANDROID (Dengan System Navigation Bar Space)
  Widget _buildAndroidBottomNav() {
    final padding = MediaQuery.of(context).padding;
    final bottomPadding = padding.bottom;

    return Container(
      height: 68 + bottomPadding,
      child: Column(
        children: [
          Container(
            height: 68,
            child: Material(
              shape: BottomNavShape(),
              color: Colors.green[700],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Beranda',
                    index: 0,
                    platform: 'android',
                  ),
                  _buildNavItem(
                    icon: Icons.savings_rounded,
                    label: 'Tabungan',
                    index: 1,
                    platform: 'android',
                  ),
                  _buildNavItem(
                    icon: Icons.payments_rounded,
                    label: 'Taqsith',
                    index: 2,
                    platform: 'android',
                  ),
                  _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    index: 3,
                    platform: 'android',
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: bottomPadding,
            color: Colors.green[700],
          ),
        ],
      ),
    );
  }

  // ✅ SOLUTION UNTUK iOS (Standard dengan SafeArea)
  Widget _buildIOSBottomNav() {
    return SafeArea(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.green[700],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              index: 0,
              platform: 'ios',
            ),
            _buildNavItem(
              icon: Icons.savings_rounded,
              label: 'Tabungan',
              index: 1,
              platform: 'ios',
            ),
            _buildNavItem(
              icon: Icons.payments_rounded,
              label: 'Taqsith',
              index: 2,
              platform: 'ios',
            ),
            _buildNavItem(
              icon: Icons.person_rounded,
              label: 'Profil',
              index: 3,
              platform: 'ios',
            ),
          ],
        ),
      ),
    );
  }

  // ✅ DEFAULT FALLBACK
  Widget _buildDefaultBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.green[700],
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.6),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.savings_rounded),
          label: 'Tabungan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payments_rounded),
          label: 'Taqsith',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    );
  }

  // ✅ UNIVERSAL NAV ITEM BUILDER
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required String platform,
  }) {
    final isSelected = _selectedIndex == index;
    
    double iconSize;
    double fontSize;
    double verticalPadding;
    
    switch (platform) {
      case 'ios':
        iconSize = 24;
        fontSize = 11;
        verticalPadding = 8;
        break;
      case 'web_linux':
        iconSize = 22;
        fontSize = 10;
        verticalPadding = 6;
        break;
      case 'android':
      default:
        iconSize = 20;
        fontSize = 9;
        verticalPadding = 6;
        break;
    }
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(0),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ PUBLIC METHODS UNTUK EXTERNAL ACCESS
  void refreshUserData() {
    _refreshUserData();
  }

  void navigateToTab(int index) {
    if (index >= 0 && index < 4) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // ✅ GETTERS UNTUK ACCESS DATA
  Map<String, dynamic> get currentUser => userData;
  int get unreadNotificationsCount => _unreadNotifications;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    print('🧹 Disposing DashboardMain...');
    super.dispose();
  }
}