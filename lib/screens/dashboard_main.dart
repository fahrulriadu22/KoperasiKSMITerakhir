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
    _initializeData();
  }

  // ✅ Platform Detection Helper
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isWeb => kIsWeb;
  bool get _isLinux => !kIsWeb && Platform.isLinux;
  bool get _isMobile => _isAndroid || _isIOS;

  // ✅ INITIALIZE DATA DENGAN ERROR HANDLING
  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await Future.wait([
        _loadCurrentUser(),
        _loadUnreadNotifications(),
      ], eagerError: true);

    } catch (e) {
      print('❌ Error initializing dashboard data: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data dashboard. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = await _apiService.getCurrentUser();
      if (currentUser != null && currentUser is Map<String, dynamic>) {
        setState(() {
          userData = _safeCastMap(currentUser);
        });
      } else {
        throw Exception('Data user tidak valid');
      }
    } catch (e) {
      print('❌ Error loading current user: $e');
      rethrow;
    }
  }

  // ✅ PERBAIKAN: Load unread notifications dengan handle response baru
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
      } else {
        print('❌ Gagal load inbox: ${result['message']}');
        throw Exception(result['message'] ?? 'Gagal memuat notifikasi');
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _safeCastMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      return {};
    }
  }

  // ✅ REFRESH DATA DENGAN PULL TO REFRESH SUPPORT
  Future<void> _refreshUserData() async {
    try {
      await Future.wait([
        _loadCurrentUser(),
        _loadUnreadNotifications(),
      ]);
      
      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
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

  // ✅ BUILD METHOD WITH ERROR HANDLING
  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat Dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
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
                _errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    // ✅ FIX: GUNAKAN PAGESTORAGE BUCKET UNTUK SEMUA SCREEN
    final List<Widget> pages = [
      PageStorage(
        bucket: _storageBucket,
        key: const ValueKey('beranda'),
        child: RefreshIndicator(
          onRefresh: _refreshUserData,
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
}