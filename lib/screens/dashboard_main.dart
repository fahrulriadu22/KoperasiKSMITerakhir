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
    return PageStorage.of(context)?.readState(context, identifier: ValueKey('nav_index')) as int? ?? 0;
  }
  
  set _selectedIndex(int value) {
    PageStorage.of(context)?.writeState(context, value, identifier: ValueKey('nav_index'));
    if (mounted) setState(() {});
  }

  late Map<String, dynamic> userData;
  final ApiService _apiService = ApiService();
  int _unreadNotifications = 0; // ✅ Untuk badge notifikasi

  @override
  void initState() {
    super.initState();
    userData = _safeCastMap(widget.user);
    _loadCurrentUser();
    _loadUnreadNotifications();
  }

  // ✅ Platform Detection Helper
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isWeb => kIsWeb;
  bool get _isLinux => !kIsWeb && Platform.isLinux;
  bool get _isMobile => _isAndroid || _isIOS;

  Future<void> _loadCurrentUser() async {
    final currentUser = await _apiService.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        userData = _safeCastMap(currentUser);
      });
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
          // ✅ Handle berbagai format field read_status
          final readStatus = item['read_status'] ?? item['is_read'] ?? '0';
          return readStatus == '0' || readStatus == 0 || readStatus == false;
        }).length;
        
        setState(() {
          _unreadNotifications = unreadCount;
        });
      } else {
        print('❌ Gagal load inbox: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
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

  Future<void> _refreshUserData() async {
    final currentUser = await _apiService.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        userData = _safeCastMap(currentUser);
      });
    }
    // ✅ Refresh juga notifikasi
    await _loadUnreadNotifications();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // ✅ Method untuk buka notifikasi - SIMPLE VERSION
  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _unreadNotifications > 0 
            ? 'Anda memiliki $_unreadNotifications pesan belum dibaca'
            : 'Tidak ada pesan baru'
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _unreadNotifications > 0 ? Colors.orange : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: GUNAKAN PAGESTORAGE BUCKET UNTUK SEMUA SCREEN
    final List<Widget> pages = [
      PageStorage(
        bucket: _storageBucket,
        key: const ValueKey('beranda'),
        child: DashboardScreen(user: userData),
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
        child: ProfileScreen(user: userData),
      ),
    ];

    return PageStorage(
      bucket: _storageBucket,
      child: Scaffold(
        appBar: _buildAppBar(), // ✅ Tambahkan AppBar dengan notifikasi
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: _buildUniversalBottomNav(),
      ),
    );
  }

  // ✅ APP BAR DENGAN NOTIFIKASI - VERSI SIMPLE COMPATIBLE
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.green[800],
      foregroundColor: Colors.white,
      elevation: 2,
      title: Text(
        _getAppBarTitle(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        // ✅ Icon Notifikasi dengan Badge - SIMPLE VERSION
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded),
              onPressed: _openNotifications,
              tooltip: _unreadNotifications > 0 
                ? '$_unreadNotifications pesan belum dibaca' 
                : 'Tidak ada notifikasi baru',
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
        
        // ✅ Refresh Button
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _refreshUserData,
          tooltip: 'Refresh Data',
        ),
      ],
    );
  }

  // ✅ Method untuk judul AppBar berdasarkan tab
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Beranda KSMI';
      case 1:
        return 'Riwayat Tabungan';
      case 2:
        return 'Riwayat Taqsith';
      case 3:
        return 'Profil Saya';
      default:
        return 'Koperasi KSMI';
    }
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
}