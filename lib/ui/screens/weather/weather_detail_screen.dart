import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/weather_forecast_model.dart';

class WeatherDetailScreen extends StatelessWidget {
  final String dateStr;
  final List<WeatherItem> dailyData;

  const WeatherDetailScreen({
    super.key,
    required this.dateStr,
    required this.dailyData,
  });

  List<String> get _timeLabels =>
      dailyData.map((e) => e.dtTxt.substring(11, 16)).toList();

  @override
  Widget build(BuildContext context) {
    double maxTemp = dailyData.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
    double minTemp = dailyData.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);
    double avgHumidity = dailyData.map((e) => e.humidity).reduce((a, b) => a + b) / dailyData.length;
    double avgPop = dailyData.map((e) => e.pop).reduce((a, b) => a + b) / dailyData.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1E3D), Color(0xFF0F2A50), Color(0xFF081628)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── CUSTOM APP BAR ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Georgia',
                            ),
                          ),
                          Text(
                            "Chi tiết thời tiết",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      _HeroSummaryCard(
                        maxTemp: maxTemp,
                        minTemp: minTemp,
                        avgHumidity: avgHumidity,
                        avgPop: avgPop,
                        representativeItem: dailyData[dailyData.length ~/ 2],
                      ),
                      const SizedBox(height: 20),

                      // Icon timeline
                      _SectionCard(
                        title: "Biểu tượng & Mưa",
                        icon: Icons.wb_cloudy_rounded,
                        accentColor: const Color(0xFF42A5F5),
                        child: _IconTimelineRow(data: dailyData, timeLabels: _timeLabels),
                      ),
                      const SizedBox(height: 14),

                      // Temperature — LINE CHART
                      _SectionCard(
                        title: "Nhiệt độ (°C)",
                        icon: Icons.thermostat_rounded,
                        accentColor: const Color(0xFFFF6B6B),
                        child: _TemperatureLineChart(data: dailyData, timeLabels: _timeLabels),
                      ),
                      const SizedBox(height: 14),

                      // Humidity & Rain — DUAL AREA CHART
                      _SectionCard(
                        title: "Độ ẩm & Khả năng mưa",
                        icon: Icons.water_drop_rounded,
                        accentColor: const Color(0xFF4FC3F7),
                        child: _HumidityRainAreaChart(data: dailyData, timeLabels: _timeLabels),
                      ),
                      const SizedBox(height: 14),

                      // Wind — RADIAL GAUGE ROW
                      _SectionCard(
                        title: "Tốc độ gió (m/s)",
                        icon: Icons.air_rounded,
                        accentColor: const Color(0xFF80CBC4),
                        child: _WindGaugeRow(data: dailyData, timeLabels: _timeLabels),
                      ),
                      const SizedBox(height: 14),

                      // Visibility — HORIZONTAL BAR CHART
                      _SectionCard(
                        title: "Tầm nhìn (km)",
                        icon: Icons.visibility_rounded,
                        accentColor: const Color(0xFFCE93D8),
                        child: _VisibilityHorizontalBars(data: dailyData, timeLabels: _timeLabels),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HERO SUMMARY CARD
// ════════════════════════════════════════════════════════════
class _HeroSummaryCard extends StatelessWidget {
  final double maxTemp, minTemp, avgHumidity, avgPop;
  final WeatherItem representativeItem;

  const _HeroSummaryCard({
    required this.maxTemp,
    required this.minTemp,
    required this.avgHumidity,
    required this.avgPop,
    required this.representativeItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: ClipOval(
                  child: Image.network(
                    representativeItem.iconUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.wb_cloudy_rounded, color: Colors.white70, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      representativeItem.description,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TempBadge(label: "CAO", value: "${maxTemp.toStringAsFixed(1)}°", color: const Color(0xFFFF8A80)),
                        const SizedBox(width: 10),
                        _TempBadge(label: "THẤP", value: "${minTemp.toStringAsFixed(1)}°", color: const Color(0xFF80D8FF)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(icon: Icons.water_drop_rounded, label: "Độ ẩm TB", value: "${avgHumidity.round()}%", color: const Color(0xFF4FC3F7)),
              _StatChip(icon: Icons.umbrella_rounded, label: "Xác suất mưa", value: "${(avgPop * 100).round()}%", color: const Color(0xFF90CAF9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TempBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _TempBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          const SizedBox(width: 5),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SECTION WRAPPER CARD
// ════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ICON TIMELINE ROW
// ════════════════════════════════════════════════════════════
class _IconTimelineRow extends StatelessWidget {
  final List<WeatherItem> data;
  final List<String> timeLabels;

  const _IconTimelineRow({required this.data, required this.timeLabels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, i) {
          final item = data[i];
          final isNoon = timeLabels[i] == "12:00";
          return Container(
            width: 76,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isNoon ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.07),
              border: isNoon ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(timeLabels[i],
                    style: TextStyle(
                      color: isNoon ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: isNoon ? FontWeight.bold : FontWeight.normal,
                    )),
                const SizedBox(height: 4),
                Image.network(item.iconUrl, width: 40, height: 40,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.wb_cloudy_outlined, color: Colors.white54, size: 32)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.water_drop, size: 10, color: Color(0xFF64B5F6)),
                    const SizedBox(width: 2),
                    Text("${(item.pop * 100).round()}%",
                        style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 11)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  1. TEMPERATURE — LINE CHART với area fill (fl_chart)
// ════════════════════════════════════════════════════════════
class _TemperatureLineChart extends StatelessWidget {
  final List<WeatherItem> data;
  final List<String> timeLabels;

  const _TemperatureLineChart({required this.data, required this.timeLabels});

  @override
  Widget build(BuildContext context) {
    final temps = data.map((e) => e.temp).toList();
    final minY = (temps.reduce((a, b) => a < b ? a : b) - 2).floorToDouble();
    final maxY = (temps.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), temps[i]));

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white.withOpacity(0.08), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) =>
                    Text("${v.round()}°", style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.round();
                  if (i < 0 || i >= timeLabels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(timeLabels[i], style: const TextStyle(color: Colors.white38, fontSize: 9)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFFFF6B6B),
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFFFF6B6B),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B6B).withOpacity(0.35),
                    const Color(0xFFFF6B6B).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A3A6E),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                "${s.y.toStringAsFixed(1)}°C",
                const TextStyle(color: Color(0xFFFF8A80), fontWeight: FontWeight.bold),
              ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  2. HUMIDITY & RAIN — DUAL AREA CHART (fl_chart)
// ════════════════════════════════════════════════════════════
class _HumidityRainAreaChart extends StatelessWidget {
  final List<WeatherItem> data;
  final List<String> timeLabels;

  const _HumidityRainAreaChart({required this.data, required this.timeLabels});

  @override
  Widget build(BuildContext context) {
    final humiditySpots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].humidity.toDouble()));
    final rainSpots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].pop * 100));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: const Color(0xFF29B6F6), label: "Độ ẩm (%)"),
            const SizedBox(width: 16),
            _LegendDot(color: const Color(0xFF80DEEA), label: "Khả năng mưa (%)", dashed: true),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.white.withOpacity(0.07), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) =>
                        Text("${v.round()}%", style: const TextStyle(color: Colors.white38, fontSize: 9)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.round();
                      if (i < 0 || i >= timeLabels.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(timeLabels[i], style: const TextStyle(color: Colors.white38, fontSize: 9)),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: humiditySpots,
                  isCurved: true,
                  curveSmoothness: 0.4,
                  color: const Color(0xFF29B6F6),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF29B6F6).withOpacity(0.3),
                        const Color(0xFF29B6F6).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: rainSpots,
                  isCurved: true,
                  curveSmoothness: 0.4,
                  color: const Color(0xFF80DEEA),
                  barWidth: 2,
                  dashArray: [6, 3],
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF80DEEA).withOpacity(0.15),
                        const Color(0xFF80DEEA).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1A3A6E),
                  getTooltipItems: (spots) {
                    final labels = ["Độ ẩm", "Mưa"];
                    final colors = [const Color(0xFF29B6F6), const Color(0xFF80DEEA)];
                    return spots.asMap().entries.map((e) => LineTooltipItem(
                      "${labels[e.key]}: ${e.value.y.round()}%",
                      TextStyle(color: colors[e.key], fontWeight: FontWeight.bold, fontSize: 12),
                    )).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: dashed ? 18 : 10,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  3. WIND — RADIAL GAUGE ROW (fl_chart PieChart as half-gauge)
// ════════════════════════════════════════════════════════════
class _WindGaugeRow extends StatelessWidget {
  final List<WeatherItem> data;
  final List<String> timeLabels;

  const _WindGaugeRow({required this.data, required this.timeLabels});

  Color _windColor(double speed) {
    if (speed < 2) return const Color(0xFF80CBC4);
    if (speed < 5) return const Color(0xFF4DB6AC);
    if (speed < 9) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    final maxWind = data.map((e) => e.windSpeed).reduce((a, b) => a > b ? a : b);
    final clampMax = maxWind < 5 ? 10.0 : maxWind * 1.3;

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, i) {
          final speed = data[i].windSpeed;
          final fraction = (speed / clampMax).clamp(0.0, 1.0);
          final color = _windColor(speed);

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                Text(timeLabels[i], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: 180,
                          sectionsSpace: 0,
                          centerSpaceRadius: 20,
                          sections: [
                            PieChartSectionData(
                              value: fraction,
                              color: color,
                              radius: 10,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: 1 - fraction,
                              color: Colors.white.withOpacity(0.08),
                              radius: 10,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        speed.toStringAsFixed(1),
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text("m/s", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  4. VISIBILITY — HORIZONTAL BAR CHART (custom painted)
// ════════════════════════════════════════════════════════════
class _VisibilityHorizontalBars extends StatelessWidget {
  final List<WeatherItem> data;
  final List<String> timeLabels;

  const _VisibilityHorizontalBars({required this.data, required this.timeLabels});

  @override
  Widget build(BuildContext context) {
    final maxVis = data.map((e) => e.visibility / 1000).reduce((a, b) => a > b ? a : b);
    final clampMax = (maxVis * 1.15).ceilToDouble();

    return Column(
      children: List.generate(data.length, (i) {
        final km = data[i].visibility / 1000;
        final frac = (km / clampMax).clamp(0.0, 1.0);
        final isGood = km >= 8;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(timeLabels[i], style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: frac,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: isGood
                                ? [const Color(0xFFCE93D8), const Color(0xFF8E24AA)]
                                : [const Color(0xFF9E9E9E), const Color(0xFF616161)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isGood ? const Color(0xFFBA68C8) : Colors.grey).withOpacity(0.3),
                              blurRadius: 6,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  "${km.toStringAsFixed(1)} km",
                  style: TextStyle(
                    color: isGood ? const Color(0xFFCE93D8) : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}