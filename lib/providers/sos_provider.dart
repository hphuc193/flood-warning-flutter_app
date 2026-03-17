import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/sos_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SosProvider with ChangeNotifier {
  final SosRepository _repository = SosRepository();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Lấy lời nhắn mặc định đã lưu offline
  Future<String> _getDefaultDescription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sos_default_desc') ?? "Tôi đang gặp nguy hiểm, cần hỗ trợ gấp!";
  }

  // Lưu lời nhắn (Gọi API + Lưu Local)
  Future<bool> updateTemplate(String description) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _repository.saveSosTemplate(description);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sos_default_desc', description);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // HÀM KÍCH HOẠT SOS (CORE LOGIC)
  Future<void> triggerSOS(BuildContext context, String userId, String emergencyType) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Lấy vị trí GPS độ chính xác cao
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String description = await _getDefaultDescription();

      // 2. Kiểm tra kết nối mạng
      var connectivityResult = await (Connectivity().checkConnectivity());
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (hasInternet) {
        // TRƯỜNG HỢP 1: CÓ INTERNET -> Gọi API
        bool success = await _repository.sendSosOnline(
            position.latitude,
            position.longitude,
            emergencyType,
            description
        );

        if (success && context.mounted) {
          _showDialog(context, "Thành công", "Tín hiệu SOS đã được gửi thẳng đến trung tâm cứu hộ!", Colors.green);
        } else {
          // Nếu API sập, fallback sang SMS
          await _fallbackToSms(userId, position.latitude, position.longitude, emergencyType);
        }
      } else {
        // TRƯỜNG HỢP 2: MẤT INTERNET -> Fallback mở SMS gửi đến Gateway
        await _fallbackToSms(userId, position.latitude, position.longitude, emergencyType);
      }
    } catch (e) {
      if (context.mounted) {
        _showDialog(context, "Lỗi GPS", "Không thể lấy vị trí. Hãy đảm bảo bạn đã bật GPS và cấp quyền.", Colors.red);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm tạo chuỗi chuẩn và mở ứng dụng SMS
  Future<void> _fallbackToSms(String userId, double lat, double lng, String type) async {
    String timestampMs = DateTime.now().millisecondsSinceEpoch.toString();
    String smsBody = "SOS|$userId|$lat|$lng|$type|$timestampMs";

    // Lấy số điện thoại từ file .env, nếu không có thì dùng số rỗng (fallback)
    String gatewayPhone = dotenv.env['GATEWAY_PHONE'] ?? "";

    final Uri smsUri = Uri.parse('sms:$gatewayPhone?body=${Uri.encodeComponent(smsBody)}');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print("Không thể mở ứng dụng SMS");
    }
  }

  void _showDialog(BuildContext context, String title, String content, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))
        ],
      ),
    );
  }
}