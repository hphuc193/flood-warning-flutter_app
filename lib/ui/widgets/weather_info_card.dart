import 'package:flutter/material.dart';
import '../../data/models/weather_model.dart';

class WeatherInfoCard extends StatelessWidget {
  final WeatherModel weather;

  const WeatherInfoCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        width: 160, // Kích thước gọn gàng
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dòng 1: Thành phố
            Text(
              weather.city,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Dòng 2: Icon + Nhiệt độ
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (weather.iconUrl.isNotEmpty)
                  Image.network(weather.iconUrl, width: 40, height: 40, errorBuilder: (_,__,___) => const Icon(Icons.wb_sunny)),
                const SizedBox(width: 8),
                Text(
                  "${weather.temp.toStringAsFixed(1)}°C",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
                ),
              ],
            ),

            // Dòng 3: Mô tả + Gió
            Text(
              weather.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            Text(
              "Gió: ${weather.windSpeed} m/s",
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}