import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../data/models/weather_model.dart';

class WeatherInfoCard extends StatelessWidget {
  final WeatherModel weather;

  const WeatherInfoCard({super.key, required this.weather});

  // 1. CHỌN ICON THEO THỜI TIẾT
  IconData _weatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('rain') || desc.contains('mưa')) return CupertinoIcons.cloud_rain_fill;
    if (desc.contains('thunder') || desc.contains('storm') || desc.contains('sấm')) return CupertinoIcons.cloud_bolt_fill;
    if (desc.contains('cloud') || desc.contains('mây')) return CupertinoIcons.cloud_fill;
    if (desc.contains('fog') || desc.contains('mist') || desc.contains('sương')) return CupertinoIcons.cloud_fog_fill;
    if (desc.contains('snow') || desc.contains('tuyết')) return CupertinoIcons.cloud_snow_fill;
    return CupertinoIcons.sun_max_fill;
  }

  // 2. TẠO GRADIENT NỀN SANG TRỌNG THEO THỜI TIẾT
  LinearGradient _weatherGradient(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('rain') || desc.contains('mưa')) {
      return const LinearGradient(
          colors: [Color(0xFF5C78A4), Color(0xFF233B62)], // Xanh xám u ám
          begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (desc.contains('thunder') || desc.contains('storm') || desc.contains('sấm')) {
      return const LinearGradient(
          colors: [Color(0xFF4B3E6A), Color(0xFF1B1429)], // Tím đen giông bão
          begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (desc.contains('cloud') || desc.contains('mây')) {
      return const LinearGradient(
          colors: [Color(0xFF8CA5B9), Color(0xFF5A7285)], // Xám mây
          begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (desc.contains('snow') || desc.contains('tuyết')) {
      return const LinearGradient(
          colors: [Color(0xFF90B5D6), Color(0xFF5582AA)], // Xanh tuyết lạnh
          begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    // Mặc định là Nắng/Quang mây
    return const LinearGradient(
        colors: [Color(0xFF62A2E8), Color(0xFF2670D2)], // Xanh da trời nắng đẹp
        begin: Alignment.topLeft, end: Alignment.bottomRight);
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _weatherIcon(weather.description);
    final gradient = _weatherGradient(weather.description);

    return Container(
      width: 320, // Độ rộng cố định cho Dialog nhìn cân đối
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28), // Bo góc cực lớn chuẩn iOS 16+
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        // Viền trắng siêu mỏng tạo hiệu ứng kính (Glassmorphism)
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Stack(
        children: [
          // Lớp trang trí mờ ảo ở background (tùy chọn cho đẹp)
          Positioned(
            right: -20,
            top: -20,
            child: Icon(iconData, size: 150, color: Colors.white.withOpacity(0.1)),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- DÒNG 1: TÊN THÀNH PHỐ ---
                Row(
                  children: [
                    const Icon(CupertinoIcons.location_solid, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weather.city,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- DÒNG 2: NHIỆT ĐỘ & ICON CẬN CẢNH ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nhiệt độ khổng lồ
                    Text(
                      "${weather.temp.toStringAsFixed(0)}°",
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        height: 1.0,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                    ),

                    // Icon thời tiết hiển thị to rõ
                    weather.iconUrl.isNotEmpty
                        ? Image.network(
                      weather.iconUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(iconData, color: Colors.white, size: 60),
                    )
                        : Icon(iconData, color: Colors.white, size: 60),
                  ],
                ),
                const SizedBox(height: 16),

                // --- DÒNG 3: MÔ TẢ & THÔNG SỐ (BADGES) ---
                Row(
                  children: [
                    // Badge Mô tả
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        _capitalize(weather.description),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Badge Gió
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.wind, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            "${weather.windSpeed} m/s",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm viết hoa chữ cái đầu cho mô tả đẹp hơn
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}