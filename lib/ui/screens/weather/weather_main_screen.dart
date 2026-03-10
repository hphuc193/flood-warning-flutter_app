import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/weather_forecast_model.dart';
import 'weather_detail_screen.dart';
import 'rainfall_history_screen.dart';

class WeatherMainScreen extends StatelessWidget {
  final WeatherForecastModel forecastData;

  const WeatherMainScreen({super.key, required this.forecastData});

  // Map weather description keywords to gradient colors
  List<Color> _getCardGradient(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('mưa') || desc.contains('rain')) {
      return [const Color(0xFF4A90D9), const Color(0xFF1E3A5F)];
    } else if (desc.contains('nắng') || desc.contains('sunny') || desc.contains('clear')) {
      return [const Color(0xFFFFB347), const Color(0xFFFF6B35)];
    } else if (desc.contains('mây') || desc.contains('cloud')) {
      return [const Color(0xFF8EAED6), const Color(0xFF4A6FA5)];
    } else if (desc.contains('bão') || desc.contains('storm') || desc.contains('thunder')) {
      return [const Color(0xFF5C4B8A), const Color(0xFF1A1040)];
    } else if (desc.contains('tuyết') || desc.contains('snow')) {
      return [const Color(0xFFB8D4E8), const Color(0xFF6A9BC3)];
    } else if (desc.contains('sương') || desc.contains('fog') || desc.contains('mist')) {
      return [const Color(0xFFA8B8C8), const Color(0xFF5A6A7A)];
    }
    return [const Color(0xFF5B9BD5), const Color(0xFF2C5F8A)];
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = forecastData.groupDataByDate();
    final dates = groupedData.keys.toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2044),
              Color(0xFF1A3A6E),
              Color(0xFF0D1B3E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── CUSTOM APP BAR ──
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD580), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            forecastData.city?.name ?? "Dự báo thời tiết",
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "5-day forecast",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.55),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── NÚT XEM LỊCH SỬ MƯA ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RainfallHistoryScreen(
                          lat: forecastData.city?.lat ?? 10.7626,
                          long: forecastData.city?.lon ?? 106.6602,
                          locationName: forecastData.city?.name ?? "Vị trí này",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Xem lịch sử lượng mưa 30 ngày",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                      ],
                    ),
                  ),
                ),
              ),

              // ── DANH SÁCH DỰ BÁO ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final dateString = dates[index];
                    final dailyItems = groupedData[dateString]!;

                    final dayMaxTemp = dailyItems.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
                    final dayMinTemp = dailyItems.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);

                    final representativeItem = dailyItems[dailyItems.length ~/ 2];
                    final parsedDate = DateTime.parse(dateString);
                    final formattedDate = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(parsedDate);
                    final dayName = DateFormat('EEEE', 'vi').format(parsedDate);
                    final dayShort = DateFormat('dd/MM', 'vi').format(parsedDate);

                    final gradientColors = _getCardGradient(representativeItem.description);
                    final isToday = index == 0;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WeatherDetailScreen(
                              dateStr: formattedDate,
                              dailyData: dailyItems,
                            ),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200 + index * 50),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors.last.withOpacity(0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: isToday
                              ? Border.all(color: Colors.white.withOpacity(0.35), width: 1.5)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Background decorative circle
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 30,
                              bottom: -30,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                              ),
                            ),

                            // Card content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              child: Row(
                                children: [
                                  // Weather Icon with glow
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.1),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        representativeItem.iconUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.wb_cloudy_rounded,
                                          size: 36,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Date & description
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (isToday)
                                              Container(
                                                margin: const EdgeInsets.only(right: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.25),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  "HÔM NAY",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                            Text(
                                              dayName.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dayShort,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          representativeItem.description,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Temperature
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${dayMaxTemp.round()}°",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${dayMinTemp.round()}°",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white.withOpacity(0.45),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}