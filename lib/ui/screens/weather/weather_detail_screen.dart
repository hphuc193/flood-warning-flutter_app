import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/weather_forecast_model.dart';

class WeatherDetailScreen extends StatelessWidget {
  final String dateStr;
  final List<WeatherItem> dailyData;

  const WeatherDetailScreen({
    super.key,
    required this.dateStr,
    required this.dailyData,
  });

  @override
  Widget build(BuildContext context) {
    // Tính toán thông số chung của ngày
    double maxTemp = dailyData.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
    double minTemp = dailyData.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);
    double avgHumidity = dailyData.map((e) => e.humidity).reduce((a, b) => a + b) / dailyData.length;
    double avgPop = dailyData.map((e) => e.pop).reduce((a, b) => a + b) / dailyData.length;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("Chi tiết: $dateStr", style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER CHUNG
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMainStat("Cao nhất", "${maxTemp.toStringAsFixed(1)}°C", Icons.arrow_upward, Colors.red[200]!),
                      _buildMainStat("Thấp nhất", "${minTemp.toStringAsFixed(1)}°C", Icons.arrow_downward, Colors.lightBlue[200]!),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Độ ẩm TB: ${avgHumidity.round()}%  |  Khả năng mưa TB: ${(avgPop * 100).round()}%",
                    style: const TextStyle(color: Colors.white70),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. TIMELINE THEO GIỜ (MỖI 3 TIẾNG)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Dự báo theo khung giờ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: dailyData.length,
                itemBuilder: (context, index) {
                  final item = dailyData[index];
                  // Parse giờ từ chuỗi "2026-03-04 12:00:00"
                  final time = item.dtTxt.substring(11, 16);

                  return Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        Image.network(item.iconUrl, height: 50, errorBuilder: (_,__,___) => const Icon(Icons.error)),
                        Text("${item.temp.round()}°C", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.water_drop, size: 12, color: Colors.blue),
                            Text("${(item.pop * 100).round()}%", style: const TextStyle(fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 3. THÔNG TIN CHI TIẾT TỪNG MỐC GIỜ
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Chi tiết các mốc thời gian", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(), // Tắt cuộn để cuộn chung với SingleChildScrollView
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: dailyData.length,
              itemBuilder: (context, index) {
                final item = dailyData[index];
                final time = item.dtTxt.substring(11, 16);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: const Icon(Icons.access_time),
                    title: Text("Khung giờ: $time", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.description),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 15,
                          children: [
                            _detailRow(Icons.thermostat, "Cảm giác như", "${item.temp.round()}°C"),
                            _detailRow(Icons.air, "Gió", "${item.windSpeed} m/s"),
                            _detailRow(Icons.visibility, "Tầm nhìn", "${item.visibility / 1000} km"),
                            _detailRow(Icons.water_drop_outlined, "Độ ẩm", "${item.humidity}%"),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMainStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}