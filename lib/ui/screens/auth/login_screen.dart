import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/network_sync_provider.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/hive_service.dart';

import '../home/main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const Color _primaryBlue = Color(0xFF1A56DB);
  static const Color _bgGray = Color(0xFFF4F6FA);
  static const Color _cardBorder = Color(0xFFE8EBF0);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF8A94A6);

  void _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.loginWithGoogle(context);
    if (success && mounted) {
      NotificationService().updateDeviceTokenAndLocation();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  void _handleFacebookLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.loginWithFacebook(context);
    if (success && mounted) {
      NotificationService().updateDeviceTokenAndLocation();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  // HIỂN THỊ BOTTOM SHEET KHÁCH VÃNG LAI
  void _showEmergencyGuestMode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _GuestEmergencyBottomSheet(), // Gọi sang Widget độc lập ở bên dưới
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOffline = context.watch<NetworkSyncProvider>().isOffline;

    return Scaffold(
      backgroundColor: _bgGray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO HEADER
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 48, bottom: 40, left: 24, right: 24),
              child: Column(
                children: [
                  Container(
                    width: 84, height: 84,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Image.asset(
                      'assets/logo-removebg.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.water_drop_rounded, size: 40, color: _primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Chào mừng trở lại', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('Đăng nhập để tiếp tục theo dõi thời tiết', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w400)),
                ],
              ),
            ),

            // FORM CARD
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cardBorder, width: 0.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOffline)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Expanded(child: Text("Không có kết nối mạng. Vui lòng kết nối để đăng nhập.", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),

                    const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _emailController, hint: 'example@email.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, isEnabled: !isOffline),

                    const SizedBox(height: 16),

                    const Text('Mật khẩu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      isEnabled: !isOffline,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: _textSecondary),
                        onPressed: isOffline ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: isOffline ? Colors.grey.shade400 : _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        onPressed: isOffline ? null : () async {
                          bool success = await authProvider.login(_emailController.text, _passwordController.text, context);
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công!')));
                            NotificationService().updateDeviceTokenAndLocation();
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
                          }
                        },
                        child: const Text('Đăng nhập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Expanded(child: Divider(color: _cardBorder, thickness: 1)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Hoặc', style: TextStyle(fontSize: 12, color: _textSecondary))),
                        const Expanded(child: Divider(color: _cardBorder, thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _cardBorder, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: isOffline ? Colors.grey.shade100 : Colors.white
                        ),
                        onPressed: isOffline || authProvider.isLoading ? null : _handleGoogleLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/google_logo.png', width: 22, height: 22, color: isOffline ? Colors.grey : null, errorBuilder: (_,__,___) => const Icon(Icons.g_mobiledata, color: Colors.red)),
                            const SizedBox(width: 10),
                            Text('Đăng nhập bằng Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isOffline ? Colors.grey : _textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _cardBorder, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: isOffline ? Colors.grey.shade100 : Colors.white
                        ),
                        onPressed: isOffline || authProvider.isLoading ? null : _handleFacebookLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/facebook_logo.png', width: 22, height: 22, color: isOffline ? Colors.grey : null, errorBuilder: (_,__,___) => const Icon(Icons.facebook, color: Colors.blue)),
                            const SizedBox(width: 10),
                            Text('Đăng nhập bằng Facebook', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isOffline ? Colors.grey : _textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // NÚT DÀNH CHO KHÁCH KHI OFFLINE
            if (isOffline)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: _showEmergencyGuestMode,
                  icon: const Icon(Icons.medical_services_rounded, color: Colors.white),
                  label: const Text("Chế độ sinh tồn khẩn cấp"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
              ),

            // ĐĂNG KÝ
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?', style: TextStyle(fontSize: 14, color: _textSecondary)),
                  TextButton(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: isOffline ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('Đăng ký ngay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isOffline ? Colors.grey : _primaryBlue)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, bool obscure = false, Widget? suffixIcon, bool isEnabled = true}) {
    return TextField(
      controller: controller, keyboardType: keyboardType, obscureText: obscure, enabled: isEnabled,
      style: TextStyle(fontSize: 14, color: isEnabled ? _textPrimary : Colors.grey),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: _textSecondary),
        prefixIcon: Icon(icon, size: 20, color: _textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isEnabled ? _bgGray : Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardBorder, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardBorder, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardBorder, width: 1)),
      ),
    );
  }
}


// STATEFUL WIDGET ĐỘC LẬP: XỬ LÝ CHẾ ĐỘ KHÁCH VÃNG LAI (BOTTOM SHEET)
class _GuestEmergencyBottomSheet extends StatefulWidget {
  const _GuestEmergencyBottomSheet();

  @override
  State<_GuestEmergencyBottomSheet> createState() => _GuestEmergencyBottomSheetState();
}

class _GuestEmergencyBottomSheetState extends State<_GuestEmergencyBottomSheet> {
  List<String> _checkedItems = [];
  final String _hiveKey = 'guest_offline_checklist';

  // Checklist Hardcode chuẩn sinh tồn
  final List<Map<String, String>> _hardcodedChecklist = [
    {"id": "item_1", "title": "Nước sạch (đủ dùng cho 3 ngày)"},
    {"id": "item_2", "title": "Thức ăn khô, đồ hộp, lương khô"},
    {"id": "item_3", "title": "Đèn pin và pin dự phòng"},
    {"id": "item_4", "title": "Sạc dự phòng điện thoại đã sạc đầy"},
    {"id": "item_5", "title": "Hộp sơ cứu y tế (băng gạc, thuốc men)"},
    {"id": "item_6", "title": "Giấy tờ tùy thân (để trong túi chống nước)"},
    {"id": "item_7", "title": "Áo phao, áo mưa, còi báo hiệu"},
  ];

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  void _loadChecklist() {
    // Đọc danh sách đã đánh dấu từ Hive
    final data = HiveService.dataBox.get(_hiveKey);
    if (data != null) {
      setState(() {
        _checkedItems = List<String>.from(data);
      });
    }
  }

  void _toggleItem(String id, bool? value) {
    setState(() {
      if (value == true) {
        _checkedItems.add(id);
      } else {
        _checkedItems.remove(id);
      }
    });
    // Cập nhật xuống Hive cục bộ lập tức
    HiveService.dataBox.put(_hiveKey, _checkedItems);
  }

  Future<void> _sendSOSGateway() async {
    // Lấy số điện thoại từ file .env, nếu không có thì mặc định
    String gatewayPhone = dotenv.env['GATEWAY_PHONE'] ?? "0123456789";

    // Cú pháp SMS mồi để người dùng điền thêm vị trí
    String message = "SOS_FLOOD: Toi dang gap nguy hiem va can cuu ho khan cap! Vi tri cua toi la: [Vui long dien vi tri cua ban]";

    final Uri url = Uri.parse('sms:$gatewayPhone?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể mở ứng dụng tin nhắn trên thiết bị này.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chiều cao tối đa bằng 85% màn hình để cuộn mượt
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.redAccent, size: 26),
                  SizedBox(width: 8),
                  Text("Chế độ sinh tồn khẩn cấp", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 16),

              // CÁC THÀNH PHẦN CUỘN
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. CALL TO ACTION: SMS GATEWAY
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Mất mạng? Nhắn tin cầu cứu ngay!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Nhấn nút dưới đây để gửi tin nhắn SMS (không cần 4G) về trạm điều phối với số ${dotenv.env['GATEWAY_PHONE'] ?? '0123456789'}.", style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _sendSOSGateway,
                                icon: const Icon(Icons.sms_failed_rounded, color: Colors.white),
                                label: const Text("GỬI SMS CẦU CỨU", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. CHECKLIST OFFLINE
                      const Row(
                        children: [
                          Icon(Icons.checklist_rounded, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 8),
                          Text("Checklist cần thiết (Lưu cục bộ):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tạo danh sách Checklist
                      ..._hardcodedChecklist.map((item) {
                        bool isChecked = _checkedItems.contains(item['id']);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.blueAccent,
                          title: Text(
                            item['title']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isChecked ? Colors.grey : Colors.black87,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          value: isChecked,
                          onChanged: (val) => _toggleItem(item['id']!, val),
                        );
                      }),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(),
                      ),

                      // 3. HOTLINE & QUY TẮC
                      const Text("HOTLINE QUỐC GIA:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      _buildHotlineRow("📞 112", "Tìm kiếm cứu nạn toàn quốc"),
                      _buildHotlineRow("📞 114", "Cứu hỏa, cứu hộ cứu nạn"),
                      _buildHotlineRow("📞 115", "Cấp cứu y tế"),

                      const SizedBox(height: 16),
                      const Text("QUY TẮC AN TOÀN KHI NGẬP LỤT:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      const Text("1. Ngắt toàn bộ cầu dao điện trong nhà.\n2. Di chuyển người già, trẻ em lên tầng cao.\n3. Tuyệt đối không đi qua dòng nước chảy xiết.\n4. Giữ ấm cơ thể, dùng đèn pin/còi báo hiệu.", style: TextStyle(height: 1.6, fontSize: 14)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotlineRow(String number, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
            child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Text(desc, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}