import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../screens/offline/offline_mode_screen.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Chuyển hướng sang màn hình Chế độ Ngoại tuyến
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfflineModeScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        color: Colors.amber.shade700,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mất kết nối mạng",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Chạm vào đây để mở Công cụ Ngoại tuyến",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right_circle_fill, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}