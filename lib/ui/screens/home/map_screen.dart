import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../widgets/report_detail_modal.dart';
import '../../widgets/weather_info_card.dart';
import '../auth/login_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Chúng ta KHÔNG gọi fetchReports() ở đây nữa
      // Vì MainScreen đã lo việc đó rồi.

      // Chỉ thực hiện việc di chuyển camera về vị trí người dùng
      _moveToCurrentLocation();
    });
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);

      if (mounted) {
        final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
        weatherProvider.fetchWeather(position.latitude, position.longitude);

        // Kích hoạt lắng nghe cảnh báo mưa
        weatherProvider.initRealtimeWeatherAlerts();
      }

    } catch (e) {
      if (mounted) {
        // Chỉ hiện thông báo lỗi nhẹ nhàng
        print("Lỗi GPS: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      // Sử dụng Stack để xếp chồng các nút lên trên bản đồ
      body: Stack(
        children: [
          // 1. Lớp Bản đồ (Nằm dưới cùng)
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(10.762622, 106.660172), // HCM City
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flood_warning',
              ),

              // Hiển thị các điểm ngập
              MarkerLayer(
                markers: reportProvider.reports.map((report) {
                  return Marker(
                    point: LatLng(report.lat, report.long),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        // Hiển thị chi tiết
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ReportDetailModal(report: report),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3)
                                  )
                                ]
                            ),
                            child: const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
                          ),
                          ClipPath(
                            clipper: _TriangleClipper(),
                            child: Container(
                              width: 12,
                              height: 8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Widget Thời tiết
          if (weatherProvider.currentWeather != null)
            Positioned(
              top: 50, // Cách top an toàn
              left: 0,
              right: 0,
              child: Center( // Căn giữa
                child: WeatherInfoCard(weather: weatherProvider.currentWeather!),
              ),
            ),

          // 2. Nút GPS (Góc trên bên phải)
          Positioned(
            top: 50, // Cách top 50 để tránh thanh trạng thái
            right: 20,
            child: FloatingActionButton.small(
              heroTag: "btn_gps_map",
              backgroundColor: Colors.white,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // 3. Nút Logout (Góc trên bên trái - Thay thế cho AppBar)
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
                  ]
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.black87),
                onPressed: () {
                  // Xử lý đăng xuất
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())
                  );
                },
              ),
            ),
          ),

          // 4. Loading Indicator (Chỉ hiện khi chưa có dữ liệu lần đầu)
          if (reportProvider.isLoading && reportProvider.reports.isEmpty)
            const Center(
              child: CircularProgressIndicator(),
            )
        ],
      ),
    );
  }
}

// Class vẽ hình tam giác nhỏ dưới Marker
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}