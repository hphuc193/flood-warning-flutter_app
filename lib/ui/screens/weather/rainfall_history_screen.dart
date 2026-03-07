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
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("Lịch sử mưa: ${widget.locationName}", style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Consumer<RainfallProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null || provider.historyData == null) {
            return Center(child: Text(provider.errorMessage ?? "Không có dữ liệu"));
          }

          final data = provider.historyData!;
          final dailyList = data.dailyData;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. CARDS TÓM TẮT (SUMMARY)
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard("Tổng 30 ngày", "${data.summary.totalRainfall} mm", Icons.water_drop, Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSummaryCard("Trung bình/ngày", "${data.summary.averageDaily} mm", Icons.analytics, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(
                  "Ngày mưa kỷ lục (${DateFormat('dd/MM/yyyy').format(DateTime.parse(data.summary.maxRainfallDate))})",
                  "${data.summary.maxRainfallAmount} mm",
                  Icons.warning_amber_rounded,
                  Colors.redAccent,
                  isFullWidth: true,
                ),

                const SizedBox(height: 30),

                // 2. BIỂU ĐỒ ĐƯỜNG (LINE CHART)
                const Text("Xu hướng lượng mưa 30 ngày qua", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  padding: const EdgeInsets.only(right: 20, left: 5, top: 20, bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 5, // Cứ 5 ngày hiện 1 nhãn để khỏi rối mắt
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < dailyList.length) {
                                DateTime date = DateTime.parse(dailyList[value.toInt()].date);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailyList.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.precipitation);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blueAccent.withOpacity(0.2), // Hiệu ứng đổ bóng mờ dưới đường
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. DANH SÁCH CHI TIẾT (Làm tiền đề cho HeatMap / Export sau này)
                const Text("Dữ liệu chi tiết", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dailyList.length,
                  itemBuilder: (context, index) {
                    final item = dailyList[dailyList.length - 1 - index]; // Đảo ngược để hiện ngày gần nhất lên đầu
                    final date = DateTime.parse(item.date);
                    final isRaining = item.precipitation > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isRaining ? Icons.water_drop : Icons.wb_sunny,
                          color: isRaining ? Colors.blue : Colors.orange,
                        ),
                        title: Text(DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date)),
                        trailing: Text("${item.precipitation} mm", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}