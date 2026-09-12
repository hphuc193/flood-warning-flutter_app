import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../providers/network_sync_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../widgets/offline_banner.dart';

import '../../../providers/weather_provider.dart';
import '../../../providers/rainfall_provider.dart';
import '../../../data/models/weather_model.dart';
import '../../../data/models/weather_forecast_model.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../data/services/socket_service.dart';

import '../weather/weather_location_list_screen.dart';
import '../weather/rainfall_history_screen.dart';
import '../../../data/services/api_service.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // ============================================================
  // VISUAL DESIGN LANGUAGE — Premium Soft-Minimal / Tonal Blue
  // ============================================================

  static const _bg = Color(0xFFF3F5FB);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceTint = Color(0xFFF8FAFE);
  static const _textPrimary = Color(0xFF1A2436);
  static const _textSecondary = Color(0xFF7C88A0);
  static const _textOnAccent = Color(0xFFFFFFFF);
  static const _accentAnchor = Color(0xFF33509E);
  static const _accentDeep = Color(0xFF3E5FBE);
  static const _accentMedium = Color(0xFF6E8FE0);
  static const _accentSoft = Color(0xFFB7C7F2);
  static const _accentTint = Color(0xFFEAF0FE);
  static const _accentMist = Color(0xFFF4F7FE);
  static const _greentMist = Color(0xFF78D978);
  static const _ambient = Color(0xFF4A5C82);
  static const _riskHigh = Color(0xFFD97878);
  static const _riskHighSoft = Color(0xFFFCF1F1);
  static const _riskMedium = Color(0xFFCB9A56);
  static const _riskMediumSoft = Color(0xFFFCF6EB);

  static const double _headerImageHeight = 210.0;
  static const double _heroOverlap = 46.0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _hasFetchedInitialData = false;

  double? _currentUV;
  bool _isLoadingUV = true;

  bool _isLoadingAI = true;
  List<FlSpot> _aiRiskSpots = [];
  List<DateTime> _aiChartTimes = [];
  Map<String, dynamic>? _aiSummary;

  String _currentRiskLevelString = "THẤP";

  int? _touchedRiskIndex;
  int? _touchedRainIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    SocketService().initSocket();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

    SocketService().onNewFloodReport((data) {
      print('🔔 Cập nhật UI từ Socket: Có báo cáo mới');
      notifProvider.fetchNotifications(refresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cộng đồng vừa báo cáo một điểm ngập mới!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('💌 Nhận Push FCM Foreground: ${message.notification?.title}');
      notifProvider.fetchNotifications(refresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.title ?? 'Bạn có thông báo mới!'),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _fetchUVIndex(double lat, double lon) async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=uv_index');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _currentUV = data['current']['uv_index']?.toDouble();
            _isLoadingUV = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingUV = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUV = false);
    }
  }

  Future<void> _fetchAIForecast() async {
    try {
      int locationId = 1;
      final apiService = ApiService();
      final response = await apiService.dio.get('/ai/forecast/$locationId');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final chartList = data['forecast_chart'] as List;

        List<FlSpot> spots = [];
        List<DateTime> times = [];

        for (int i = 0; i < chartList.length; i++) {
          DateTime time = DateTime.parse(chartList[i]['time']).toLocal();
          double risk = (chartList[i]['risk_score'] as num).toDouble();
          spots.add(FlSpot(i.toDouble(), risk));
          times.add(time);
        }

        if (mounted) {
          setState(() {
            _aiSummary = data['timeline_summary'];
            _aiRiskSpots = spots;
            _aiChartTimes = times;

            if (chartList.isNotEmpty) {
              _currentRiskLevelString = chartList[0]['risk_level']?.toString().toUpperCase() ?? "THẤP";
            }

            _isLoadingAI = false;
          });
        }
      }
    } catch (e) {
      print("Lỗi fetch AI Forecast: $e");
      if (mounted) setState(() => _isLoadingAI = false);
    }
  }

  Future<void> _onRefresh() async {
    final isOffline = Provider.of<NetworkSyncProvider>(context, listen: false).isOffline;
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể làm mới dữ liệu khi mất mạng!")),
      );
      return;
    }

    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final currentLoc = weatherProvider.currentLocation;
    final double currentLat = currentLoc['lat'] ?? 10.7626;
    final double currentLon = currentLoc['lon'] ?? 106.6602;

    setState(() {
      _isLoadingUV = true;
      _isLoadingAI = true;
    });

    await Future.wait([
      Provider.of<RainfallProvider>(context, listen: false).fetchRainfallHistory(currentLat, currentLon, days: 30),
      _fetchUVIndex(currentLat, currentLon),
      _fetchAIForecast(),
    ]);
  }

  String _getUVLabel(double? uv) {
    if (uv == null) return "--";
    if (uv <= 2.9) return "Thấp";
    if (uv <= 5.9) return "TB";
    if (uv <= 7.9) return "Cao";
    if (uv <= 10.9) return "Rất cao";
    return "Nguy hiểm";
  }

  Color _getRiskColorByString(String levelStr) {
    if (levelStr.contains('CAO') || levelStr.contains('NGUY HIỂM')) return _riskHigh;
    if (levelStr.contains('TRUNG BÌNH') || levelStr.contains('VỪA')) return _riskMedium;
    return _accentDeep;
  }

  String _getRiskTextByString(String levelStr) {
    if (levelStr.contains('CAO') || levelStr.contains('NGUY HIỂM')) return "NGUY CƠ NGẬP LỤT CAO";
    if (levelStr.contains('TRUNG BÌNH') || levelStr.contains('VỪA')) return "CẢNH BÁO MỨC ĐỘ VỪA";
    return "TÌNH TRẠNG AN TOÀN";
  }

  List<BoxShadow> _elevatedShadow({double strength = 1.0}) => [
    BoxShadow(
      color: _ambient.withValues(alpha: 0.055 * strength),
      blurRadius: 30 * strength,
      offset: Offset(0, 12 * strength),
    ),
  ];

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: _textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final isOffline = context.watch<NetworkSyncProvider>().isOffline;
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final weather = weatherProvider.currentWeather;
    final forecastData = weatherProvider.forecastData;
    final currentLoc = weatherProvider.currentLocation;
    final double currentLat = currentLoc['lat'] ?? 10.7626;
    final double currentLon = currentLoc['lon'] ?? 106.6602;

    if (weather != null && !_hasFetchedInitialData) {
      _hasFetchedInitialData = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isOffline) {
          Provider.of<RainfallProvider>(context, listen: false)
              .fetchRainfallHistory(currentLat, currentLon, days: 30);
          _fetchUVIndex(currentLat, currentLon);
          _fetchAIForecast();
        }
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          if (isOffline) const SafeArea(bottom: false, child: OfflineBanner()),
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: _buildPhotoHeader(context, isOffline, notifProvider, weather),
                ),
                Positioned(
                  top: _headerImageHeight - _heroOverlap,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: weather == null
                      ? Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surface,
                        shape: BoxShape.circle,
                        boxShadow: _elevatedShadow(),
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.1,
                        color: _accentMedium,
                      ),
                    ),
                  )
                      : FadeTransition(
                    opacity: _fadeAnim,
                    child: RefreshIndicator(
                      color: _accentDeep,
                      backgroundColor: _surface,
                      onRefresh: _onRefresh,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroWeatherCard(weather),
                            const SizedBox(height: 14),
                            _buildRiskCard(weather, _currentRiskLevelString),
                            const SizedBox(height: 26),
                            _buildSectionHeaderWithAction(
                              title: "DỰ BÁO THỜI TIẾT 5 NGÀY",
                              isDisabled: isOffline,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WeatherLocationListScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _build5DayForecast(forecastData),
                            const SizedBox(height: 26),

                            // ==========================================
                            // ĐƯỢC ĐƯA LÊN TRÊN: LƯỢNG MƯA 30 NGÀY
                            // ==========================================
                            _buildSectionHeaderWithAction(
                              title: "LƯỢNG MƯA · 30 NGÀY",
                              isDisabled: isOffline,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RainfallHistoryScreen(
                                      lat: currentLat,
                                      long: currentLon,
                                      locationName: weather.city,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildRainfallChart(),
                            const SizedBox(height: 26),

                            // ==========================================
                            // ĐƯỢC CHUYỂN XUỐNG DƯỚI: AI FLOOD FORECAST
                            // ==========================================
                            _buildAIForecastSection(),
                            const SizedBox(height: 110),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoHeader(
      BuildContext context,
      bool isOffline,
      NotificationProvider notifProvider,
      WeatherModel? weather,
      ) {
    return SizedBox(
      height: _headerImageHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            child: Image.asset(
              'assets/CT2.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentDeep, _accentMedium],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accentAnchor.withValues(alpha: 0.32),
                      _accentAnchor.withValues(alpha: 0.06),
                      _bg,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            top: !isOffline,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WeatherLocationListScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.location_solid, color: _accentAnchor, size: 13),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      weather?.city ?? "Đang định vị...",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _accentAnchor,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(CupertinoIcons.chevron_down, color: Colors.white, size: 11),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 42,
                        height: 42,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                  );
                                },
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(CupertinoIcons.bell, color: _accentAnchor, size: 19),
                                ),
                              ),
                              if (notifProvider.unreadCount > 0)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                      decoration: BoxDecoration(
                                        color: _riskHigh,
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(color: Colors.white, width: 1.6),
                                      ),
                                      child: Text(
                                        notifProvider.unreadCount > 99 ? '99+' : '${notifProvider.unreadCount}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "DASHBOARD",
                      style: TextStyle(
                        color: _accentAnchor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    "Weather & Flood AI",
                    style: TextStyle(
                      color: _accentTint,
                      fontSize: 22,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      shadows: [Shadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 2))],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithAction({
    required String title,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    final actionColor = isDisabled ? _textSecondary : _accentDeep;
    return Row(
      children: [
        Expanded(child: _buildSectionTitle(title)),
        GestureDetector(
          onTap: isDisabled
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Tính năng này cần kết nối mạng."),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
              : onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Xem chi tiết",
                style: TextStyle(
                  color: actionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(CupertinoIcons.chevron_right, size: 11, color: actionColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(String iconCode, double size) {
    String assetPath = 'assets/sun.png'; // Fallback an toàn

    if (iconCode.contains('01')) {
      assetPath = 'assets/sun.png';
    } else if (iconCode.contains('02')) {
      assetPath = 'assets/clouds-and-sun.png';
    } else if (iconCode.contains('03') || iconCode.contains('04') || iconCode.contains('50')) {
      assetPath = 'assets/cloudy.png';
    } else if (iconCode.contains('09') || iconCode.contains('10') || iconCode.contains('11')) {
      assetPath = 'assets/heavy-rain.png';
    } else if (iconCode.contains('13')) {
      assetPath = 'assets/snow.png';
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          iconCode.contains('http') ? iconCode : 'https://openweathermap.org/img/wn/$iconCode@2x.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Icon(
            Icons.wb_cloudy_rounded,
            size: size * 0.6,
            color: _accentMedium,
          ),
        );
      },
    );
  }

  Widget _buildHeroWeatherCard(WeatherModel weather) {
    final uvDisplayText = _isLoadingUV
        ? "…"
        : (_currentUV != null ? _currentUV!.toStringAsFixed(1) : "--");
    final uvSubLabel = _isLoadingUV ? "" : _getUVLabel(_currentUV);

    // Sửa lỗi: Lấy đúng thuộc tính iconUrl từ WeatherModel
    final iconCode = weather.iconUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), _accentMist, _accentTint],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _accentDeep.withValues(alpha: 0.13),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _accentMedium.withValues(alpha: 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildWeatherIcon(iconCode, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weather.temp.toStringAsFixed(0),
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 40,
                                height: 0.95,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 3, top: 4),
                              child: Text(
                                "°C",
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Điều kiện hiện tại",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentDeep.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.sparkles, color: _accentDeep, size: 9),
                              SizedBox(width: 4),
                              Text(
                                "With AI",
                                style: TextStyle(
                                  color: _accentDeep,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatRow(CupertinoIcons.thermometer, "Nhiệt độ", "${weather.temp.toStringAsFixed(1)}°"),
                  _buildStatRow(CupertinoIcons.wind, "Sức gió", "${weather.windSpeed} m/s"),
                  _buildStatRow(CupertinoIcons.drop_fill, "Độ ẩm", "${weather.humidity}%"),
                  _buildStatRow(
                    CupertinoIcons.sun_max_fill,
                    "Tia UV",
                    uvDisplayText,
                    subLabel: uvSubLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, {String? subLabel}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _accentMist,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 14, color: _accentDeep),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subLabel != null && subLabel.isNotEmpty ? "$label · $subLabel" : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskCard(WeatherModel weather, String riskLevelStr) {
    final riskColor = _getRiskColorByString(riskLevelStr);
    final isHighRisk = riskColor == _riskHigh;
    final isMediumRisk = riskColor == _riskMedium;

    String? peakTimeFormatted;
    String? maxWaterLevel;

    if (_aiSummary != null && _aiSummary!['t_peak'] != null) {
      DateTime parsedPeak = DateTime.parse(_aiSummary!['t_peak']).toLocal();
      peakTimeFormatted = DateFormat('HH:mm').format(parsedPeak);
      maxWaterLevel = _aiSummary!['h_max']?.toString();
    }

    final stateColor = isHighRisk ? _riskHigh : (isMediumRisk ? _riskMedium : _greentMist);
    final stateSoft = isHighRisk ? _riskHighSoft : (isMediumRisk ? _riskMediumSoft : _accentMist);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        color: stateSoft,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _elevatedShadow(strength: 0.55),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              CupertinoIcons.bell_solid,
              color: stateColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRiskTextByString(riskLevelStr),
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                if (peakTimeFormatted != null && maxWaterLevel != null)
                  Text(
                    "Đỉnh lũ dự kiến: $maxWaterLevel cm lúc $peakTimeFormatted",
                    style: TextStyle(
                      color: stateColor.withValues(alpha: 0.82),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (_isLoadingAI)
                  Text(
                    "AI đang tính toán dữ liệu...",
                    style: TextStyle(color: stateColor.withValues(alpha: 0.82), fontSize: 10.5),
                  )
                else
                  Text(
                    "Theo dõi lượng mưa và triều cường.",
                    style: TextStyle(color: stateColor.withValues(alpha: 0.82), fontSize: 10.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              riskLevelStr.toUpperCase(),
              style: TextStyle(
                color: stateColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build5DayForecast(WeatherForecastModel? forecastData) {
    if (forecastData == null) {
      return Container(
        height: 148,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: _elevatedShadow(),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.2, color: _accentMedium),
        ),
      );
    }

    final groupedData = forecastData.groupDataByDate();
    final dates = groupedData.keys.take(5).toList();

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final dateString = dates[index];
          final dailyItems = groupedData[dateString]!;
          final dayMaxTemp = dailyItems.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
          final dayMinTemp = dailyItems.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);
          final representativeItem = dailyItems[dailyItems.length ~/ 2];
          final parsedDate = DateTime.parse(dateString);
          final dayLabel = index == 0 ? 'Hôm nay' : DateFormat('EEE', 'vi').format(parsedDate);
          final isToday = index == 0;

          return Container(
            width: 92,
            padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                colors: [_accentTint, _accentMist],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isToday ? null : _surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: _elevatedShadow(strength: 0.75),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isToday ? _accentDeep : _textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: _buildWeatherIcon(representativeItem.iconUrl, 32)),
                ),
                const SizedBox(height: 9),
                Text(
                  "${dayMaxTemp.round()}°",
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "${dayMinTemp.round()}°",
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAIForecastSection() {
    final lineColor = _getRiskColorByString(_currentRiskLevelString);
    final currentScore = _aiRiskSpots.isNotEmpty ? _aiRiskSpots.first.y : null;

    String? peakTimeLabel;
    String? peakScoreLabel;
    if (_aiSummary != null && _aiSummary!['t_peak'] != null) {
      try {
        final peakTime = DateTime.parse(_aiSummary!['t_peak']).toLocal();
        peakTimeLabel = DateFormat('HH:mm').format(peakTime);
      } catch (_) {}
      if (_aiSummary!['h_max'] != null) {
        peakScoreLabel = _aiSummary!['h_max'].toString();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_surface, _accentMist],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: _elevatedShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _accentTint,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(CupertinoIcons.waveform_path_ecg, color: _accentDeep, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dự báo ngập lụt bằng AI",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _touchedRiskIndex != null &&
                          _touchedRiskIndex! >= 0 &&
                          _touchedRiskIndex! < _aiChartTimes.length
                          ? "${_aiChartTimes[_touchedRiskIndex!].hour}h · Chỉ số ${_aiRiskSpots[_touchedRiskIndex!].y.toStringAsFixed(1)}"
                          : "Chỉ số nguy cơ theo giờ · 24H tới",
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_isLoadingAI && currentScore != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAiSummaryChip(
                    icon: CupertinoIcons.gauge,
                    label: "Chỉ số hiện tại",
                    value: currentScore.toStringAsFixed(1),
                    color: lineColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAiSummaryChip(
                    icon: CupertinoIcons.flag_fill,
                    label: "Đỉnh dự kiến",
                    value: peakTimeLabel != null && peakScoreLabel != null
                        ? "$peakScoreLabel cm · $peakTimeLabel"
                        : "Đang tính toán",
                    color: lineColor,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _build24hRiskChart(lineColor),
        ],
      ),
    );
  }

  Widget _buildAiSummaryChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 8.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textPrimary, fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build24hRiskChart(Color lineColor) {
    if (_isLoadingAI) {
      return const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator(color: _accentMedium)),
      );
    }

    if (_aiRiskSpots.isEmpty) {
      return const SizedBox(
        height: 190,
        child: Center(child: Text("Dữ liệu đang được đồng bộ...", style: TextStyle(color: _textSecondary))),
      );
    }

    double maxRiskScore = _aiRiskSpots.map((spot) => spot.y).reduce(max);
    double dynamicMaxY = maxRiskScore > 10 ? maxRiskScore + (maxRiskScore * 0.25) : 10;
    double leftInterval = (dynamicMaxY / 4).ceilToDouble();
    if (leftInterval <= 0) leftInterval = 2;

    int? peakIndex;
    if (_aiSummary != null && _aiSummary!['t_peak'] != null) {
      try {
        final peakTime = DateTime.parse(_aiSummary!['t_peak']).toLocal();
        for (int i = 0; i < _aiChartTimes.length; i++) {
          final t = _aiChartTimes[i];
          if (t.year == peakTime.year && t.month == peakTime.month && t.day == peakTime.day && t.hour == peakTime.hour) {
            peakIndex = i;
            break;
          }
        }
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 14, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 176,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (_aiRiskSpots.length - 1).toDouble(),
            minY: 0,
            maxY: dynamicMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: leftInterval,
              getDrawingHorizontalLine: (value) => FlLine(
                color: _accentSoft.withValues(alpha: 0.25),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 4,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < _aiChartTimes.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "${_aiChartTimes[index].hour}h",
                          style: const TextStyle(color: _textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: leftInterval,
                  reservedSize: 28,
                  getTitlesWidget: (v, m) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(color: _textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => _accentAnchor.withValues(alpha: 0.94),
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((s) {
                    final idx = s.x.toInt();
                    final hourLabel = (idx >= 0 && idx < _aiChartTimes.length) ? "${_aiChartTimes[idx].hour}h" : "";
                    return LineTooltipItem(
                      "$hourLabel\n",
                      const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      children: [
                        TextSpan(
                          text: "Chỉ số ${s.y.toStringAsFixed(1)}",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.lineBarSpots == null ||
                    response.lineBarSpots!.isEmpty) {
                  setState(() => _touchedRiskIndex = null);
                  return;
                }
                setState(() => _touchedRiskIndex = response.lineBarSpots!.first.x.toInt());
              },
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((_) {
                  return TouchedSpotIndicatorData(
                    FlLine(color: lineColor.withValues(alpha: 0.35), strokeWidth: 2, dashArray: [4, 4]),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 5.5,
                        color: lineColor,
                        strokeWidth: 3,
                        strokeColor: Colors.white,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _aiRiskSpots,
                isCurved: false,
                gradient: LinearGradient(
                  colors: [_accentMedium, lineColor],
                ),
                barWidth: 2.6,
                isStrokeCapRound: true,
                preventCurveOverShooting: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    final isPeak = peakIndex != null && spot.x.toInt() == peakIndex;
                    return FlDotCirclePainter(
                      radius: isPeak ? 5.5 : 2.4,
                      color: isPeak ? lineColor : _accentMedium,
                      strokeWidth: isPeak ? 2.5 : 0,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      _accentMedium.withValues(alpha: 0.24),
                      _accentMedium.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _heatmapColor(double v) {
    if (v == 0) return const Color(0xFFF2F6FD);
    if (v < 5) return const Color(0xFFDCE7FA);
    if (v < 15) return const Color(0xFFBDD0F4);
    if (v < 30) return const Color(0xFF8FAAE4);
    if (v < 60) return const Color(0xFF6285D4);
    return _accentDeep;
  }

  Widget _buildRainfallChart() {
    return Consumer<RainfallProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            height: 190,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: _elevatedShadow(),
            ),
            child: const Center(child: CircularProgressIndicator(color: _accentMedium)),
          );
        }

        if (provider.historyData == null || provider.historyData!.dailyData.isEmpty) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: _elevatedShadow(),
            ),
            child: const Center(child: Text("Dữ liệu đang được đồng bộ...", style: TextStyle(color: _textSecondary))),
          );
        }

        final dailyList = provider.historyData!.dailyData;

        final totalRain = dailyList.fold<double>(0, (sum, item) => sum + item.precipitation);
        final maxItem = dailyList.reduce((a, b) => a.precipitation >= b.precipitation ? a : b);
        final maxDateLabel = DateFormat('dd/MM').format(DateTime.parse(maxItem.date));

        double chartMaxY = maxItem.precipitation <= 0 ? 10 : maxItem.precipitation * 1.25;

        const double barSlot = 26;
        final double chartWidth = max(dailyList.length * barSlot, 300);

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: _elevatedShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildRainSummaryChip(
                      icon: CupertinoIcons.drop_fill,
                      label: "Tổng lượng mưa",
                      value: "${totalRain.toStringAsFixed(0)} mm",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRainSummaryChip(
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      label: "Ngày mưa nhiều nhất",
                      value: "${maxItem.precipitation.toStringAsFixed(0)} mm · $maxDateLabel",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 168,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  reverse: true,
                  child: SizedBox(
                    width: chartWidth,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: chartMaxY,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: chartMaxY / 4,
                          getDrawingHorizontalLine: (value) => FlLine(color: _accentTint, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= dailyList.length) return const SizedBox();
                                if (idx % 5 != 0 && idx != dailyList.length - 1) return const SizedBox();
                                final d = DateTime.parse(dailyList[idx].date);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    DateFormat('d/M').format(d),
                                    style: const TextStyle(color: _textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => _accentAnchor.withValues(alpha: 0.92),
                            tooltipRoundedRadius: 12,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final d = DateTime.parse(dailyList[group.x.toInt()].date);
                              return BarTooltipItem(
                                "${DateFormat('dd/MM').format(d)}\n",
                                const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(
                                    text: "${rod.toY.toStringAsFixed(1)} mm",
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              );
                            },
                          ),
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.spot == null) {
                              setState(() => _touchedRainIndex = null);
                              return;
                            }
                            setState(() => _touchedRainIndex = response.spot!.touchedBarGroupIndex);
                          },
                        ),
                        barGroups: List.generate(dailyList.length, (index) {
                          final item = dailyList[index];
                          final isTouched = _touchedRainIndex == index;
                          final baseColor = _heatmapColor(item.precipitation);
                          final barColor = item.precipitation == 0 ? _accentTint : baseColor;

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: item.precipitation,
                                width: isTouched ? 12 : 9,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [barColor.withValues(alpha: 0.55), barColor],
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: chartMaxY,
                                  color: _accentMist,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Ít", style: TextStyle(fontSize: 10, color: _textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  _legendDot(const Color(0xFFF2F6FD)),
                  _legendDot(const Color(0xFFDCE7FA)),
                  _legendDot(const Color(0xFFBDD0F4)),
                  _legendDot(const Color(0xFF8FAAE4)),
                  _legendDot(const Color(0xFF6285D4)),
                  const SizedBox(width: 6),
                  const Text("Nhiều", style: TextStyle(fontSize: 10, color: _textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRainSummaryChip({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _accentMist,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: _accentDeep),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 8.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textPrimary, fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
    width: 11,
    height: 11,
    margin: const EdgeInsets.symmetric(horizontal: 1.5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
  );
}