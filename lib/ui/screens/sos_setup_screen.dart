import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/sos_provider.dart';

class SosSetupScreen extends StatefulWidget {
  const SosSetupScreen({super.key});

  @override
  State<SosSetupScreen> createState() => _SosSetupScreenState();
}

class _SosSetupScreenState extends State<SosSetupScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentTemplate();
  }

  Future<void> _loadCurrentTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _descController.text = prefs.getString('sos_default_desc') ?? "";
      _phoneController.text = prefs.getString('sos_contact_phone') ?? "";
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt SOS Khẩn cấp", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Thông tin này sẽ được gửi kèm tọa độ của bạn đến lực lượng cứu hộ khi bạn bấm nút SOS trên Bản đồ.",
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)
            ),
            const SizedBox(height: 24),

            const Text("Số điện thoại liên hệ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone, // Bật bàn phím số
              decoration: InputDecoration(
                hintText: "VD: 0912345678",
                prefixIcon: const Icon(Icons.phone_android, color: Colors.redAccent),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text("Lời nhắn mặc định", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Ví dụ: Nhà có 2 người già và 1 trẻ nhỏ. Mực nước đang dâng cao, cần cano sơ tán gấp.",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: sosProvider.isLoading ? null : () async {
                  // Cập nhật Provider gọi hàm truyền cả 2 tham số
                  bool success = await sosProvider.updateTemplate(_descController.text, _phoneController.text);
                  if (success && mounted) {
                    FocusScope.of(context).unfocus(); // Đóng bàn phím
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đã lưu cấu hình SOS thành công!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        )
                    );
                  }
                },
                child: sosProvider.isLoading
                    ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text("LƯU CẤU HÌNH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }
}