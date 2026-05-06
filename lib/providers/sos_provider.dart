import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/sos_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/services/api_service.dart';

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
  Future<bool> updateTemplate(String description, String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiService = ApiService();
      final response = await apiService.dio.post(
        '/sos/template',
        data: {
          'default_description': description,
          'contact_phone': phone,
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sos_default_desc', description);
        await prefs.setString('sos_contact_phone', phone);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Lỗi updateTemplate: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // HÀM KÍCH HOẠT SOS
  Future<void> triggerSOS(BuildContext context, String userId, String emergencyType) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Lấy tọa độ GPS
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );

      // 2. Kiểm tra trạng thái Internet hiện tại
      var connectivityResult = await (Connectivity().checkConnectivity());
      bool isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        //NẾU MẤT MẠNG -> MỞ NGAY APP TIN NHẮN (SMS)
        print("Trạng thái: Ngoại tuyến. Đang chuyển sang SMS...");
        await _fallbackToSms(userId, position.latitude, position.longitude, emergencyType);
      } else {
        //NẾU CÓ MẠNG -> GỌI API LÊN SERVER
        final prefs = await SharedPreferences.getInstance();
        final desc = prefs.getString('sos_default_desc') ?? "Cần cứu hộ khẩn cấp!";
        final phone = prefs.getString('sos_contact_phone');

        final apiService = ApiService();
        final response = await apiService.dio.post(
          '/sos/online',
          data: {
            'lat': position.latitude,
            'long': position.longitude,
            'emergency_type': emergencyType,
            'description': desc,
            'contact_phone': phone,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (response.statusCode == 201) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tín hiệu SOS đã được phát đi thành công!"), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      print("Lỗi triggerSOS: $e");
      // 3. SAFEGUARD TỐI THƯỢNG: Có mạng nhưng gọi API thất bại (ví dụ server sập) -> Rẽ nhánh qua SMS cứu mạng
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi kết nối Server. Đang chuyển sang gửi SMS..."), backgroundColor: Colors.orange),
        );
      }
      // Thử lấy vị trí cuối cùng được biết để gửi cho nhanh nếu lỗi API
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        await _fallbackToSms(userId, position.latitude, position.longitude, emergencyType);
      }
    }

    _isLoading = false;
    notifyListeners();
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