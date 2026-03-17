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
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentTemplate();
  }

  Future<void> _loadCurrentTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _controller.text = prefs.getString('sos_default_desc') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Cài đặt Lời nhắn SOS"), backgroundColor: Colors.redAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lời nhắn này sẽ được gửi kèm tọa độ của bạn khi bạn bấm nút SOS Khẩn cấp.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Ví dụ: Nhà có 2 người già và 1 trẻ nhỏ. Cần cano sơ tán gấp.",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: sosProvider.isLoading ? null : () async {
                  bool success = await sosProvider.updateTemplate(_controller.text);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu lời nhắn mặc định!")));
                  }
                },
                child: sosProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("LƯU CẤU HÌNH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}