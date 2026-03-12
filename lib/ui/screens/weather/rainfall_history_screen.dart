import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/rainfall_provider.dart';

class RainfallHistoryScreen extends StatefulWidget {
  final double lat;
  final double long;
  final String locationName;

  const RainfallHistoryScreen({
    super.key,
    required this.lat,
    required this.long,
    required this.locationName,
  });

  @override
  State<RainfallHistoryScreen> createState() => _RainfallHistoryScreenState();
}

class _RainfallHistoryScreenState extends State<RainfallHistoryScreen> {
  bool _showLineChart = false;

  static const Color _primaryBlue = Color(0xFF1A56DB);
  static const Color _lightBlue = Color(0xFF6B9EE8);
  static const Color _paleBue = Color(0xFFEBF2FF);
  static const Color _accentRed = Color(0xFFE8593C);
  static const Color _bgGray = Color(0xFFF4F6FA);
  static const Color _cardBorder = Color(0xFFE8EBF0);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF8A94A6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RainfallProvider>(context, listen: false)
          .fetchRainfallHistory(widget.lat, widget.long, days: 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: Consumer<RainfallProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              backgroundColor: _bgGray,
              body: Center(
                child: CircularProgressIndicator(color: _primaryBlue),
              ),
            );
          }

          if (provider.errorMessage != null || provider.historyData == null) {
            return Scaffold(
              backgroundColor: _bgGray,
              appBar: _buildAppBar(context),
              body: Center(
                child: Text(
                  provider.errorMessage ?? 'Không có dữ liệu',
                  style: const TextStyle(color: _textSecondary),
                ),
              ),
            );
          }

          final data = provider.historyData!;
          final dailyList = data.dailyData;
          final rainyDays = dailyList.where((d) => d.precipitation > 0).length;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, data, rainyDays),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRecordCard(data),
                      const SizedBox(height: 16),
                      _buildMainChartCard(dailyList, data.summary.averageDaily),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildDonutCard(dailyList)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildWeeklyBarCard(dailyList)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildHeatmapCard(dailyList),
                      const SizedBox(height: 16),
                      _buildDetailList(dailyList),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────── APP BAR ───────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _primaryBlue,
      title: Text(widget.locationName),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, dynamic data, int rainyDays) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử thời tiết',
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w400),
          ),
          Text(
            widget.locationName,
            style: const TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text('30 ngày',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withOpacity(0.9))),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: _primaryBlue,
          padding: const EdgeInsets.only(
              left: 16, right: 16, top: 100, bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                    'Tổng lượng mưa',
                    '${data.summary.totalRainfall}',
                    'mm'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroMetric(
                    'Trung bình/ngày',
                    '${data.summary.averageDaily}',
                    'mm/ngày'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroMetric(
                    'Ngày có mưa', '$rainyDays', '/ 30 ngày'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  height: 1)),
          const SizedBox(height: 2),
          Text(unit,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 10)),
        ],
      ),
    );
  }

  // ─────────────────────── KỶ LỤC CARD ───────────────────────

  Widget _buildRecordCard(dynamic data) {
    final recordDate = DateFormat('dd/MM/yyyy')
        .format(DateTime.parse(data.summary.maxRainfallDate));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F0),
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _accentRed, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accentRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngày mưa kỷ lục — $recordDate',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA04030),
                        fontWeight: FontWeight.w400)),
                Text('${data.summary.maxRainfallAmount} mm',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFC03020),
                        height: 1.3)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _accentRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _calcPercent(data.summary.maxRainfallAmount,
                      data.summary.averageDaily),
                  style:
                  const TextStyle(fontSize: 11, color: Colors.white),
                ),
                Text('vs tb',
                    style: TextStyle(
                        fontSize: 10, color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calcPercent(double max, double avg) {
    if (avg == 0) return '—';
    final pct = ((max - avg) / avg * 100).round();
    return '+$pct%';
  }

  // ─────────────────────── BIỂU ĐỒ CHÍNH ───────────────────────

  Widget _buildMainChartCard(List dailyList, double averageDaily) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lượng mưa 30 ngày',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MM/yyyy').format(DateTime.now()),
                    style: const TextStyle(
                        fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
              // Toggle cột / đường
              Container(
                decoration: BoxDecoration(
                  color: _bgGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _chartToggleBtn('Cột', !_showLineChart, () {
                      setState(() => _showLineChart = false);
                    }),
                    _chartToggleBtn('Đường', _showLineChart, () {
                      setState(() => _showLineChart = true);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _showLineChart
                ? _buildLineChart(dailyList, averageDaily)
                : _buildBarChart(dailyList, averageDaily),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _legendItem(color: _primaryBlue, label: 'Lượng mưa (mm)'),
              const SizedBox(width: 16),
              _legendItem(
                  color: _accentRed,
                  label: 'Trung bình',
                  isDash: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: active ? Colors.white : _textSecondary),
        ),
      ),
    );
  }

  Widget _buildBarChart(List dailyList, double averageDaily) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: dailyList
            .map((e) => e.precipitation as double)
            .reduce((a, b) => a > b ? a : b) *
            1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: _cardBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    fontSize: 10, color: _textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                // Chỉ hiện nhãn tại ngày 0, 5, 10, 15, 20, 25, 29
                const showAt = [0, 4, 9, 14, 19, 24, 29];
                if (!showAt.contains(idx) ||
                    idx < 0 ||
                    idx >= dailyList.length) {
                  return const SizedBox.shrink();
                }
                final date = DateTime.parse(dailyList[idx].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('dd/M').format(date),
                    style: const TextStyle(
                        fontSize: 9, color: _textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: dailyList.asMap().entries.map((e) {
          final v = e.value.precipitation as double;
          Color barColor;
          if (v > 50) {
            barColor = _accentRed;
          } else if (v > 20) {
            barColor = _primaryBlue;
          } else if (v > 0) {
            barColor = _lightBlue;
          } else {
            barColor = _paleBue;
          }
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: v,
                color: barColor,
                width: 6,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: averageDaily,
              color: _accentRed,
              strokeWidth: 1.5,
              dashArray: [5, 4],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List dailyList, double averageDaily) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: _cardBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    fontSize: 10, color: _textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                const showAt = [0, 4, 9, 14, 19, 24, 29];
                if (!showAt.contains(idx) ||
                    idx < 0 ||
                    idx >= dailyList.length) {
                  return const SizedBox.shrink();
                }
                final date = DateTime.parse(dailyList[idx].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('dd/M').format(date),
                    style: const TextStyle(
                        fontSize: 9, color: _textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: dailyList.asMap().entries.map((e) {
              return FlSpot(
                  e.key.toDouble(), e.value.precipitation as double);
            }).toList(),
            isCurved: true,
            color: _primaryBlue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _primaryBlue.withOpacity(0.08),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: averageDaily,
              color: _accentRed,
              strokeWidth: 1.5,
              dashArray: [5, 4],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── DONUT CARD ───────────────────────

  Widget _buildDonutCard(List dailyList) {
    final heavy = dailyList.where((d) => d.precipitation > 50).length;
    final medium = dailyList
        .where((d) => d.precipitation > 10 && d.precipitation <= 50)
        .length;
    final light = dailyList
        .where((d) => d.precipitation > 0 && d.precipitation <= 10)
        .length;
    final total = heavy + medium + light;

    double pct(int n) => total == 0 ? 0 : n / total * 100;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phân loại',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary)),
          const SizedBox(height: 2),
          const Text('Theo cường độ',
              style: TextStyle(fontSize: 10, color: _textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 28,
                sections: [
                  PieChartSectionData(
                    value: pct(heavy),
                    color: _primaryBlue,
                    radius: 20,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: pct(medium),
                    color: _lightBlue,
                    radius: 20,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: pct(light),
                    color: const Color(0xFFC8D8F5),
                    radius: 20,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _pieLegend(_primaryBlue, 'Nặng', '${pct(heavy).toStringAsFixed(0)}%'),
          const SizedBox(height: 3),
          _pieLegend(
              _lightBlue, 'Vừa', '${pct(medium).toStringAsFixed(0)}%'),
          const SizedBox(height: 3),
          _pieLegend(const Color(0xFFC8D8F5), 'Nhẹ',
              '${pct(light).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _pieLegend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style:
            const TextStyle(fontSize: 10, color: _textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _textPrimary)),
      ],
    );
  }

  // ─────────────────────── WEEKLY BAR CARD ───────────────────────

  Widget _buildWeeklyBarCard(List dailyList) {
    final weeks = <double>[0, 0, 0, 0];
    for (int i = 0; i < dailyList.length; i++) {
      final weekIdx = (i ~/ 7).clamp(0, 3);
      weeks[weekIdx] += dailyList[i].precipitation as double;
    }

    final maxWeek =
    weeks.reduce((a, b) => a > b ? a : b);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theo tuần',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary)),
          const SizedBox(height: 2),
          const Text('Tổng mm/tuần',
              style: TextStyle(fontSize: 10, color: _textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxWeek * 1.3,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: _cardBorder, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, meta) {
                        const labels = ['T1', 'T2', 'T3', 'T4'];
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(labels[idx],
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: _textSecondary)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: weeks.asMap().entries.map((e) {
                  final isMax = e.value == maxWeek;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color:
                        isMax ? _primaryBlue : const Color(0xFF92B8F5),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── HEATMAP ───────────────────────

  Widget _buildHeatmapCard(List dailyList) {
    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bản đồ nhiệt',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary)),
          const SizedBox(height: 2),
          const Text('Cường độ mưa theo ngày trong tháng',
              style: TextStyle(fontSize: 12, color: _textSecondary)),
          const SizedBox(height: 14),
          // Day-of-week headers
          Row(
            children: dayLabels
                .map((d) => Expanded(
              child: Center(
                child: Text(d,
                    style: const TextStyle(
                        fontSize: 9, color: _textSecondary)),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Grid cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1,
            ),
            itemCount: dailyList.length,
            itemBuilder: (context, index) {
              final item = dailyList[index];
              final v = item.precipitation as double;
              return Tooltip(
                message:
                '${DateFormat('dd/MM').format(DateTime.parse(item.date))}: $v mm',
                child: Container(
                  decoration: BoxDecoration(
                    color: _heatmapColor(v),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 9,
                        color: v > 15 ? Colors.white : const Color(0xFF555555),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Scale legend
          Row(
            children: [
              const Text('Ít',
                  style: TextStyle(fontSize: 10, color: _textSecondary)),
              const SizedBox(width: 6),
              ...const [
                Color(0xFFEBF2FF),
                Color(0xFFC8D8F5),
                Color(0xFF92B8F5),
                Color(0xFF4A80E8),
                Color(0xFF1A56DB),
                Color(0xFF0E3A9A),
              ].map((c) => Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
              const SizedBox(width: 6),
              const Text('Nhiều',
                  style: TextStyle(fontSize: 10, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Color _heatmapColor(double v) {
    if (v == 0) return const Color(0xFFF4F7FF);
    if (v < 5) return const Color(0xFFC8D8F5);
    if (v < 15) return const Color(0xFF92B8F5);
    if (v < 30) return const Color(0xFF4A80E8);
    if (v < 60) return const Color(0xFF1A56DB);
    return const Color(0xFF0E3A9A);
  }

  // ─────────────────────── DETAIL LIST ───────────────────────

  Widget _buildDetailList(List dailyList) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dữ liệu chi tiết',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary)),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyList.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFFF0F2F5),
            ),
            itemBuilder: (context, index) {
              // Đảo ngược: ngày gần nhất lên đầu
              final item = dailyList[dailyList.length - 1 - index];
              final date = DateTime.parse(item.date);
              final v = item.precipitation as double;
              final isRain = v > 0;
              final isHeavy = v > 50;

              final iconBg = isHeavy
                  ? const Color(0xFFFFF0EE)
                  : isRain
                  ? _paleBue
                  : const Color(0xFFFFFBF0);
              final iconColor = isHeavy
                  ? _accentRed
                  : isRain
                  ? _primaryBlue
                  : const Color(0xFFF59E0B);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isRain
                            ? Icons.water_drop_rounded
                            : Icons.wb_sunny_rounded,
                        color: iconColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isHeavy
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: _textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHeavy
                                ? 'Mưa rất nặng'
                                : isRain
                                ? 'Có mưa'
                                : 'Trời nắng',
                            style: const TextStyle(
                                fontSize: 11, color: _textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          v > 0 ? '$v' : '—',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isHeavy
                                ? _accentRed
                                : isRain
                                ? _primaryBlue
                                : _textSecondary,
                          ),
                        ),
                        if (v > 0)
                          const Text('mm',
                              style: TextStyle(
                                  fontSize: 10, color: _textSecondary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────── HELPERS ───────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 0.5),
      ),
      child: child,
    );
  }

  Widget _legendItem(
      {required Color color,
        required String label,
        bool isDash = false}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: isDash ? 3 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
            const TextStyle(fontSize: 11, color: _textSecondary)),
      ],
    );
  }
}