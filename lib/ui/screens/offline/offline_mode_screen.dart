import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../data/services/hive_service.dart';
import '../checklist_screen.dart';
import '../emergency_contacts_screen.dart';
import '../evacuation_guide_screen.dart';

class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  static const _bg = Color(0xFFF7F8FC);
  static const _textPrimary = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    // 1. ĐỌC DỮ LIỆU TỪ HIVE
    final Map<dynamic, dynamic>? offlineData = HiveService.dataBox.get('fws_essential_data');

    // 2. KHỞI TẠO CÁC BIẾN MẶC ĐỊNH
    String lastSyncText = "Chưa có dữ liệu";
    String riskLevelStr = "THẤP";
    String peakTimeText = "--:--";
    String maxWaterText = "--";
    int reportCount = 0;
    int sosCount = 0;

    // 3. BÓC TÁCH DỮ LIỆU JSON
    if (offlineData != null) {
      // Parse Thời gian đồng bộ
      if (offlineData['last_sync_time'] != null) {
        DateTime parsedTime = DateTime.parse(offlineData['last_sync_time']).toLocal();
        lastSyncText = DateFormat('HH:mm - dd/MM/yyyy').format(parsedTime);
      }

      // Parse Dự báo AI (Forecast)
      final forecast = offlineData['forecast'];
      if (forecast != null) {
        riskLevelStr = forecast['risk_level']?.toString().toUpperCase() ?? "THẤP";
        maxWaterText = forecast['h_max']?.toString() ?? "--";
        if (forecast['t_peak'] != null) {
          DateTime tPeak = DateTime.parse(forecast['t_peak']).toLocal();
          peakTimeText = DateFormat('HH:mm').format(tPeak);
        }
      }

      // Parse Số lượng Cảnh báo (Lịch sử 7 ngày)
      reportCount = (offlineData['reports'] as List?)?.length ?? 0;
      sosCount = (offlineData['sos_alerts'] as List?)?.length ?? 0;
    }

    // Xử lý màu sắc và Text cho Dự báo
    Color riskColor = const Color(0xFF10B981); // Mặc định xanh
    String riskTitle = "TÌNH TRẠNG AN TOÀN";
    if (riskLevelStr.contains('CAO') || riskLevelStr.contains('NGUY HIỂM')) {
      riskColor = const Color(0xFFEF4444);
      riskTitle = "NGUY CƠ NGẬP LỤT CAO";
    } else if (riskLevelStr.contains('TRUNG BÌNH') || riskLevelStr.contains('VỪA')) {
      riskColor = const Color(0xFFF59E0B);
      riskTitle = "CẢNH BÁO MỨC ĐỘ VỪA";
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Chế Độ Ngoại Tuyến", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView( // Thêm Scroll để không bị tràn màn hình nhỏ
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Info (Lần đồng bộ) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.cloud_download_fill, color: Colors.amber.shade700, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Dữ liệu đã được lưu sẵn", style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text("Lần đồng bộ: $lastSyncText", style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Thẻ Dự báo AI Offline ---
              const Text("DỰ BÁO NGẬP LỤT (KẾT QUẢ LƯU TẠM)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill, color: riskColor, size: 20),
                        const SizedBox(width: 8),
                        Text(riskTitle, style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.graph_square, color: Color(0xFF64748B), size: 16),
                        const SizedBox(width: 6),
                        Text(
                            "Mực nước cao nhất: $maxWaterText cm lúc $peakTimeText",
                            style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600)
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Thẻ Thống kê Lịch sử 7 ngày ---
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox("Báo cáo ngập", "$reportCount", CupertinoIcons.drop_fill, Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatBox("Tín hiệu SOS", "$sosCount", CupertinoIcons.waveform_path_badge_minus, Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- Menu Công cụ Khẩn cấp ---
              const Text("CÔNG CỤ KHẨN CẤP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
              const SizedBox(height: 12),

              _buildOfflineMenuCard(
                context,
                title: "Hướng dẫn sơ tán",
                subtitle: "Đọc quy tắc an toàn và các bước di tản",
                icon: CupertinoIcons.map_pin_ellipse,
                color: const Color(0xFFE11D48),
                targetScreen: const EvacuationGuideScreen(),
              ),
              const SizedBox(height: 12),
              _buildOfflineMenuCard(
                context,
                title: "Chuẩn bị ứng phó",
                subtitle: "Checklist hành trang khẩn cấp (Lưu Offline)",
                icon: CupertinoIcons.check_mark_circled_solid,
                color: const Color(0xFF059669),
                targetScreen: const ChecklistScreen(),
              ),
              const SizedBox(height: 12),
              _buildOfflineMenuCard(
                context,
                title: "Danh bạ khẩn cấp",
                subtitle: "Gọi điện/SMS trực tiếp không cần mạng 4G",
                icon: CupertinoIcons.phone_circle_fill,
                color: const Color(0xFF2563EB),
                targetScreen: const EmergencyContactsScreen(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hiển thị Box thống kê (Lịch sử 7 ngày)
  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // --- Widget Card Menu ---
  Widget _buildOfflineMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required Widget targetScreen}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}