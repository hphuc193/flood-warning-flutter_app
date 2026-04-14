import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import các màn hình để gán cho 2 nút ở dưới cùng
// Nhớ sửa lại đường dẫn này cho khớp với dự án của bạn
// import '../evacuation_guide_screen.dart';
// import '../sos_setup_screen.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  // ─── Design tokens ──────────
  static const _bg = Color(0xFFF7F8FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _danger = Color(0xFFDC2626); // Đỏ khẩn cấp
  static const _dangerLight = Color(0xFFFEF2F2);
  static const _primary = Color(0xFF2563EB); // Xanh dương nút bấm

  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // 1. HEADER NỀN ĐỎ (Mức độ nghiêm trọng)
          _buildDangerHeader(context),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. BẢN ĐỒ THU NHỎ (Vùng ảnh hưởng)
                  const Text("VÙNG ẢNH HƯỞNG", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSecondary, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  _buildMapThumbnail(),
                  const SizedBox(height: 24),

                  // 3. BẢNG THÔNG TIN ĐỊNH LƯỢNG
                  const Text("DỰ BÁO TÁC ĐỘNG", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSecondary, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  _buildQuantitativeInfo(),
                  const SizedBox(height: 28),

                  // 4. DANH SÁCH HÀNH ĐỘNG ƯU TIÊN
                  const Text("HÀNH ĐỘNG KHUYẾN NGHỊ KHẨN CẤP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSecondary, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  _buildActionList(),
                  const SizedBox(height: 20), // Padding cho thanh cuộn
                ],
              ),
            ),
          ),

          // 5. HAI NÚT HÀNH ĐỘNG CHÍNH (Đáy màn hình)
          _buildBottomActions(context),
        ],
      ),
    );
  }

  // ─── Các thành phần UI ──────────────────────────────────────────────────

  Widget _buildDangerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 24, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: _danger,
        boxShadow: [BoxShadow(color: Color(0x40DC2626), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("CẢNH BÁO ĐỎ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.0)),
                    Text("Mức độ nghiêm trọng: RẤT CAO", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapThumbnail() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0), // Nền màu xám bản đồ giả lập
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        // Vẽ lưới (grid) giả lập bản đồ
        image: const DecorationImage(
          image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"), // Lưới mờ
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vùng ảnh hưởng ngập (Vòng tròn đỏ trong suốt)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: _danger.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: _danger.withOpacity(0.5), width: 2)),
          ),
          // Vị trí người dùng (Chấm xanh)
          Positioned(
            left: 100, // Đặt lệch ra khỏi tâm một chút để thấy vùng ngập đang tiến tới
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: _primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: _primary.withOpacity(0.5), blurRadius: 8)]),
            ),
          ),
          // Chú thích nhỏ trên bản đồ
          Positioned(
            bottom: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
              child: const Text("Khu vực: Quận 7, TP.HCM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuantitativeInfo() {
    return Row(
      children: [
        Expanded(child: _buildInfoCard(Icons.water_drop_rounded, "Lượng mưa", "180", "mm", Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard(Icons.waves_rounded, "Mức nước", "0.8 - 1.2", "mét", Colors.teal)),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, String unit, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 13, color: _textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _textPrimary)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 13, color: _textSecondary, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionList() {
    final actions = [
      "Ngắt toàn bộ cầu dao điện tầng trệt.",
      "Di chuyển tài sản, thiết bị điện tử lên tầng cao hoặc gác xép.",
      "Chuẩn bị sẵn balo khẩn cấp (nước, đồ ăn nhẹ, thuốc men, đèn pin).",
      "Sẵn sàng sơ tán theo lệnh của chính quyền địa phương."
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _dangerLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFECDD3))),
      child: Column(
        children: List.generate(actions.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Số thứ tự
                Container(
                  width: 24, height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _danger, shape: BoxShape.circle),
                  child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                // Nội dung
                Expanded(
                  child: Text(actions[index], style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.4, fontWeight: FontWeight.w500)),
                )
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16, left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(top: BorderSide(color: _border)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          // Nút Xem Hướng dẫn sơ tán
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.directions_run_rounded, size: 20),
              label: const Text("HƯỚNG DẪN SƠ TÁN", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const EvacuationGuideScreen()));
              },
            ),
          ),
          const SizedBox(width: 12),
          // Nút Gọi Cứu hộ (SOS)
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _surface,
                foregroundColor: _danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _danger, width: 2)),
                elevation: 0,
              ),
              icon: const Icon(Icons.sos_rounded, size: 20),
              label: const Text("GỌI CỨU HỘ", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              onPressed: () {
                // Điều hướng sang màn SOS hoặc gọi trực tiếp triggerSOS của bạn
              },
            ),
          ),
        ],
      ),
    );
  }
}