import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/weather_forecast_model.dart';
import 'weather_detail_screen.dart';
import 'rainfall_history_screen.dart';

class WeatherMainScreen extends StatelessWidget {
  final WeatherForecastModel forecastData;

  const WeatherMainScreen({super.key, required this.forecastData});

  @override
  Widget build(BuildContext context) {
    // Gom dữ liệu theo ngày
    final groupedData = forecastData.groupDataByDate();
    final dates = groupedData.keys.toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(forecastData.city?.name ?? "Dự báo thời tiết"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- NÚT XEM LỊCH SỬ MƯA ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                elevation: 2,
                side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.history_outlined, size: 24),
              label: const Text(
                  "Xem lịch sử lượng mưa 30 ngày",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              onPressed: () {
                // Điều hướng sang màn hình lịch sử, truyền toạ độ từ CityInfo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RainfallHistoryScreen(
                      lat: forecastData.city?.lat ?? 10.7626, // Mặc định HCM nếu null
                      long: forecastData.city?.lon ?? 106.6602,
                      locationName: forecastData.city?.name ?? "Vị trí này",
                    ),
                  ),
                );
              },
            ),
          ),

          // --- DANH SÁCH DỰ BÁO CÁC NGÀY ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                String dateString = dates[index];
                List<WeatherItem> dailyItems = groupedData[dateString]!;

                // Tìm Max/Min temp của cả ngày
                double dayMaxTemp = dailyItems.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
                double dayMinTemp = dailyItems.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);

                // Lấy thông tin thời tiết đại diện (thường lấy mốc giữa trưa hoặc mốc đầu tiên)
                WeatherItem representativeItem = dailyItems[dailyItems.length ~/ 2];

                DateTime parsedDate = DateTime.parse(dateString);
                String formattedDate = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(parsedDate);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    leading: Image.network(
                      representativeItem.iconUrl,
                      width: 60,
                      height: 60,
                      errorBuilder: (c, e, s) => const Icon(Icons.wb_cloudy, size: 40),
                    ),
                    title: Text(
                      formattedDate.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      representativeItem.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${dayMaxTemp.round()}°C",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent),
                        ),
                        Text(
                          "${dayMinTemp.round()}°C",
                          style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
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
    );
  }
}