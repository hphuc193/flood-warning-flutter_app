import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/report_provider.dart';
import '../../../providers/weather_provider.dart';
import 'map_screen.dart';
import 'report_list_screen.dart';
import 'create_report_screen.dart';
import '../profile/profile_screen.dart';
import '../weather/weather_main_screen.dart';
import '../weather/weather_location_list_screen.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const MapScreen(),
    const ReportListScreen(),
    const WeatherLocationListScreen(), // Wrapper xử lý logic cho màn thời tiết
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Nạp dữ liệu báo cáo
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      reportProvider.fetchReports();
      reportProvider.initRealtimeUpdates();

      // 2. Nạp dữ liệu thời tiết (Truyền mặc định toạ độ TP.HCM)
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      weatherProvider.fetchWeather(10.7626, 106.6602); // Thời tiết hiện tại (nếu cần cho Map)
      weatherProvider.fetchForecast(10.7626, 106.6602, cityName: "Hồ Chí Minh"); // Dự báo 5 ngày
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReportScreen()),
          );
        },
        child: const Icon(Icons.add_a_photo, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Tin tức',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Dự báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}