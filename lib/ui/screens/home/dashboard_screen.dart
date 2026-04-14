import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../providers/weather_provider.dart';
import '../../../providers/rainfall_provider.dart';
import '../../../data/models/weather_model.dart';
import '../../../data/models/weather_forecast_model.dart';

import '../weather/weather_location_list_screen.dart';
import '../weather/rainfall_history_screen.dart';
import '../../../data/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF7F8FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _accent = Color(0xFF2563EB);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _hasFetchedInitialData = false;

  double? _currentUV;
  bool _isLoadingUV = true;

  bool _isLoadingAI = true;
  List<FlSpot> _aiRiskSpots = [];
  List<DateTime> _aiChartTimes = [];
  Map<String, dynamic>? _aiSummary;

  // === THÊM BIẾN LƯU MỨC ĐỘ NGUY HIỂM TỪ BACKEND TRẢ VỀ ===
  String _currentRiskLevelString = "THẤP";
  // =========================================================

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
      final response = await apiService.dio.get('/forecast/$locationId'); // Đảm bảo khớp route BE của bạn

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

            // === CẬP NHẬT CHỮ NGUY HIỂM TỪ BE ===
            if (chartList.isNotEmpty) {
              _currentRiskLevelString = chartList[0]['risk_level']?.toString().toUpperCase() ?? "THẤP";
            }
            // =====================================

            _isLoadingAI = false;
          });
        }
      }
    } catch (e) {
      print("Lỗi fetch AI Forecast: $e");
      if (mounted) setState(() => _isLoadingAI = false);
    }
  }

  String _getUVLabel(double? uv) {
    if (uv == null) return "--";
    if (uv <= 2.9) return "Thấp";
    if (uv <= 5.9) return "TB";
    if (uv <= 7.9) return "Cao";
    if (uv <= 10.9) return "Rất cao";
    return "Nguy hiểm";
  }

  // === ĐỔI LOGIC MÀU SẮC THEO CHỮ TỪ BACKEND ===
  Color _getRiskColorByString(String levelStr) {
    if (levelStr.contains('CAO') || levelStr.contains('NGUY HIỂM')) return const Color(0xFFEF4444);
    if (levelStr.contains('TRUNG BÌNH') || levelStr.contains('VỪA')) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981); // THẤP, AN TOÀN -> Xanh lá
  }

  String _getRiskTextByString(String levelStr) {
    if (levelStr.contains('CAO') || levelStr.contains('NGUY HIỂM')) return "NGUY CƠ NGẬP LỤT CAO";
    if (levelStr.contains('TRUNG BÌNH') || levelStr.contains('VỪA')) return "CẢNH BÁO MỨC ĐỘ VỪA";
    return "TÌNH TRẠNG AN TOÀN";
  }
  // =============================================

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.currentWeather;
    final forecastData = weatherProvider.forecastData;

    final currentLoc = weatherProvider.currentLocation;
    final double currentLat = currentLoc['lat'] ?? 10.7626;
    final double currentLon = currentLoc['lon'] ?? 106.6602;

    if (weather != null && !_hasFetchedInitialData) {
      _hasFetchedInitialData = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<RainfallProvider>(context, listen: false).fetchRainfallHistory(currentLat, currentLon, days: 30);
        _fetchUVIndex(currentLat, currentLon);
        _fetchAIForecast();
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text("Tổng quan & Dự báo", style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: weather == null
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Truyền trực tiếp chuỗi mức độ rủi ro vào
              _buildRiskCard(weather, _currentRiskLevelString),
              const SizedBox(height: 20),

              _buildSectionTitle("CHỈ SỐ HIỆN TẠI"),
              const SizedBox(height: 10),
              _buildWeatherSummaryGrid(weather),

              const SizedBox(height: 16),

              _buildSectionTitle("DỰ BÁO NGUY CƠ THEO GIỜ (AI)"),
              const SizedBox(height: 10),
              _build24hRiskChart(),

              const SizedBox(height: 20),

              _buildSectionHeaderWithAction("DỰ BÁO 5 NGÀY TỚI", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherLocationListScreen()));
              }),
              const SizedBox(height: 10),
              _build5DayForecast(forecastData),

              const SizedBox(height: 20),

              _buildSectionHeaderWithAction("LỊCH SỬ LƯỢNG MƯA (30 NGÀY)", () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RainfallHistoryScreen(
                    lat: currentLat,
                    long: currentLon,
                    locationName: weather.city,
                  ),
                ));
              }),
              const SizedBox(height: 10),
              _buildRainfallHeatmap(),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _textSecondary),
    );
  }

  Widget _buildSectionHeaderWithAction(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(title),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              const Text("Xem chi tiết", style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              const Icon(CupertinoIcons.chevron_right, size: 14, color: _accent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(String iconUrl, double size) {
    final isSunny = iconUrl.contains('01d') || iconUrl.contains('01n');
    if (isSunny) {
      return Icon(Icons.wb_sunny_rounded, color: const Color(0xFFFF9500), size: size * 0.75);
    }
    return Image.network(
      iconUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Icon(Icons.wb_cloudy_rounded, size: size * 0.6, color: Colors.grey),
    );
  }

  // Nhận String thay vì double
  Widget _buildRiskCard(WeatherModel weather, String riskLevelStr) {
    final bgColor = _getRiskColorByString(riskLevelStr);

    String? peakTimeFormatted;
    String? maxWaterLevel;

    if (_aiSummary != null && _aiSummary!['t_peak'] != null) {
      DateTime parsedPeak = DateTime.parse(_aiSummary!['t_peak']).toLocal();
      peakTimeFormatted = DateFormat('HH:mm').format(parsedPeak);
      maxWaterLevel = _aiSummary!['h_max']?.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bgColor.withValues(alpha: 0.9), bgColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: bgColor.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.location_solid, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(weather.city, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.white),
            ],
          ),
          const SizedBox(height: 20),
          Text(_getRiskTextByString(riskLevelStr), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),

          if (peakTimeFormatted != null && maxWaterLevel != null)
            Row(
              children: [
                const Icon(CupertinoIcons.graph_square, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                    "Đỉnh lũ dự kiến: $maxWaterLevel cm lúc $peakTimeFormatted",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)
                ),
              ],
            )
          else if (_isLoadingAI)
            const Text("AI đang tính toán dữ liệu...", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))
          else
            const Text("Hệ thống cảnh báo dựa trên lượng mưa và triều cường. Vui lòng theo dõi sát sao.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildWeatherSummaryGrid(WeatherModel weather) {
    String uvDisplayText = _isLoadingUV
        ? "Đang tải..."
        : (_currentUV != null ? "${_getUVLabel(_currentUV)} (${_currentUV!.toStringAsFixed(1)})" : "--");

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(CupertinoIcons.thermometer, "Nhiệt độ", "${weather.temp.toStringAsFixed(1)}°C", const Color(0xFFFF9500)),
        _buildStatCard(CupertinoIcons.wind, "Sức gió", "${weather.windSpeed} m/s", const Color(0xFF30B0C7)),
        _buildStatCard(CupertinoIcons.drop_fill, "Độ ẩm", "${weather.humidity}%", const Color(0xFF2563EB)),
        _buildStatCard(CupertinoIcons.sun_max_fill, "Tia UV", uvDisplayText, const Color(0xFFE11D48)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
        ],
      ),
    );
  }

  // === BIỂU ĐỒ NÂNG CẤP TỰ ĐỘNG CO GIÃN TRỤC Y ===
  Widget _build24hRiskChart() {
    if (_isLoadingAI) {
      return Container(
        height: 220,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_aiRiskSpots.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
        child: const Center(child: Text("Hệ thống AI đang xử lý, chưa có dữ liệu.", style: TextStyle(color: _textSecondary))),
      );
    }

    // Tìm giá trị rủi ro cao nhất để set maxY cho trục Y
    double maxRiskScore = _aiRiskSpots.map((spot) => spot.y).reduce(max);
    // Đảm bảo tối thiểu là 10, nếu vượt 10 thì cộng thêm 20% khoảng trống bên trên cho đẹp
    double dynamicMaxY = maxRiskScore > 10 ? maxRiskScore + (maxRiskScore * 0.2) : 10;
    // Tính toán lại các mốc kẻ ngang (Interval)
    double leftInterval = (dynamicMaxY / 5).ceilToDouble();
    if (leftInterval <= 0) leftInterval = 2;

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 10, bottom: 10),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (_aiRiskSpots.length - 1).toDouble(),
          minY: 0,
          maxY: dynamicMaxY, // Áp dụng maxY động
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: leftInterval, // Kẻ đường ngang theo interval
              getDrawingHorizontalLine: (value) => FlLine(color: _border, strokeWidth: 1)
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
                            child: Text("${_aiChartTimes[index].hour}h", style: const TextStyle(color: _textSecondary, fontSize: 11))
                        );
                      }
                      return const SizedBox();
                    }
                )
            ),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    interval: leftInterval, // Thay đổi khoảng cách chữ bên trái
                    reservedSize: 28,
                    getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(color: _textSecondary, fontSize: 11))
                )
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _aiRiskSpots,
              isCurved: true,
              color: const Color(0xFF10B981),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF10B981).withValues(alpha: 0.4), const Color(0xFF10B981).withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build5DayForecast(WeatherForecastModel? forecastData) {
    if (forecastData == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final groupedData = forecastData.groupDataByDate();
    final dates = groupedData.keys.take(5).toList();

    return Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dates.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16, color: _border),
        itemBuilder: (context, index) {
          final dateString = dates[index];
          final dailyItems = groupedData[dateString]!;

          final dayMaxTemp = dailyItems.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
          final dayMinTemp = dailyItems.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);

          final representativeItem = dailyItems[dailyItems.length ~/ 2];
          final parsedDate = DateTime.parse(dateString);

          String dayLabel = index == 0 ? 'Hôm nay' : DateFormat('EEEE', 'vi').format(parsedDate);

          return ListTile(
            leading: SizedBox(
              width: 80,
              child: Text(dayLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textPrimary)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 30, height: 30,
                  child: _buildWeatherIcon(representativeItem.iconUrl, 30),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    representativeItem.description,
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Text("${dayMinTemp.round()}° / ${dayMaxTemp.round()}°", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textPrimary)),
          );
        },
      ),
    );
  }

  Color _heatmapColor(double v) {
    if (v == 0) return const Color(0xFFF1F5F9);
    if (v < 5) return const Color(0xFFC8D8F5);
    if (v < 15) return const Color(0xFF92B8F5);
    if (v < 30) return const Color(0xFF4A80E8);
    if (v < 60) return const Color(0xFF1A56DB);
    return const Color(0xFF0E3A9A);
  }

  Widget _buildRainfallHeatmap() {
    return Consumer<RainfallProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            height: 150,
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.historyData == null || provider.historyData!.dailyData.isEmpty) {
          return Container(
            height: 100,
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
            child: const Center(child: Text("Chưa có dữ liệu lịch sử lượng mưa.", style: TextStyle(color: _textSecondary))),
          );
        }

        final dailyList = provider.historyData!.dailyData;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: dailyList.length,
                itemBuilder: (context, index) {
                  final item = dailyList[index];
                  final rainAmount = item.precipitation;
                  final date = DateTime.parse(item.date);

                  return Tooltip(
                    message: "${DateFormat('dd/MM').format(date)}: ${rainAmount.toStringAsFixed(1)} mm",
                    child: Container(
                      decoration: BoxDecoration(
                          color: _heatmapColor(rainAmount),
                          borderRadius: BorderRadius.circular(4)
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 9,
                            color: rainAmount > 15 ? Colors.white : const Color(0xFF555555),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Ít", style: TextStyle(fontSize: 10, color: _textSecondary)),
                  const SizedBox(width: 4),
                  Container(width: 10, height: 10, color: const Color(0xFFF1F5F9)),
                  Container(width: 10, height: 10, color: const Color(0xFFC8D8F5)),
                  Container(width: 10, height: 10, color: const Color(0xFF92B8F5)),
                  Container(width: 10, height: 10, color: const Color(0xFF4A80E8)),
                  Container(width: 10, height: 10, color: const Color(0xFF1A56DB)),
                  const SizedBox(width: 4),
                  const Text("Nhiều", style: TextStyle(fontSize: 10, color: _textSecondary)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}