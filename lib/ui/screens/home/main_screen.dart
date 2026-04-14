import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/report_provider.dart';
import '../../../providers/weather_provider.dart';
import 'map_screen.dart';
import 'report_list_screen.dart';
import 'create_report_screen.dart';
import '../profile/profile_screen.dart';
import '../weather/weather_main_screen.dart';
import '../weather/weather_location_list_screen.dart';
import 'dashboard_screen.dart';
import '../../../data/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  int _selectedIndex = 0;
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  // ĐÃ SỬA LẠI THỨ TỰ CHO KHỚP VỚI THANH ĐIỀU HƯỚNG BÊN DƯỚI
  late final List<Widget> _pages = [
    const DashboardScreen(),    // Index 0: Tổng Quan
    const MapScreen(),          // Index 1: Bản đồ
    const ReportListScreen(),   // Index 2: Tin tức (Danh sách báo cáo)
    const ProfileScreen(),      // Index 3: Hồ sơ
  ];

  @override
  void initState() {
    super.initState();

    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportProvider =
      Provider.of<ReportProvider>(context, listen: false);
      reportProvider.fetchReports();
      reportProvider.initRealtimeUpdates();

      final weatherProvider =
      Provider.of<WeatherProvider>(context, listen: false);
      weatherProvider.fetchWeather(10.7626, 106.6602);
      weatherProvider.fetchForecast(10.7626, 106.6602,
          cityName: "Hồ Chí Minh");
    });

    // Gọi hàm đồng bộ dữ liệu thiết bị ngầm ở background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.updateDeviceTokenAndLocation();
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        floatingActionButton: _buildFAB(context),
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _fabAnimController.forward(),
      onTapUp: (_) {
        _fabAnimController.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateReportScreen()),
        );
      },
      onTapCancel: () => _fabAnimController.reverse(),
      child: ScaleTransition(
        scale: _fabScaleAnim,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withOpacity(0.45),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFFE53935).withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_a_photo_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Row(
          children: [
            // CÁC INDEX NÀY ĐÃ ĐƯỢC MAP ĐÚNG VỚI MẢNG _PAGES PHÍA TRÊN
            _navItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Tổng Quan'),
            _navItem(1, Icons.map_rounded, Icons.map_outlined, 'Bản đồ'),
            const SizedBox(width: 72), // Chỗ trống cho FAB
            _navItem(2, Icons.article_rounded, Icons.article_outlined, 'Tin tức'),
            _navItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Hồ sơ'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    const activeColor = Color(0xFFE53935);
    const inactiveColor = Color(0xFFB0B8C1);
    const activeBg = Color(0xFFFFF0F0);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}