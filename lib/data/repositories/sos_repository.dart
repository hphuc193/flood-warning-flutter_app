import 'package:dio/dio.dart';
import '../services/api_service.dart';

class SosRepository {
  final ApiService _apiService = ApiService();

  // 1. Lưu cấu hình SOS mặc định
  Future<bool> saveSosTemplate(String description) async {
    try {
      final response = await _apiService.dio.post(
        '/sos/template',
        data: {"default_description": description},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi saveSosTemplate: $e");
      return false;
    }
  }

  // 2. Gửi tín hiệu SOS trực tiếp qua Internet
  Future<bool> sendSosOnline(double lat, double long, String emergencyType, String description) async {
    try {
      // Chuẩn hóa timestamp theo ISO 8601 (VD: 2026-03-18T04:11:00Z)
      String timestamp = DateTime.now().toUtc().toIso8601String();

      final response = await _apiService.dio.post(
        '/sos/online',
        data: {
          "lat": lat,
          "long": long,
          "emergency_type": emergencyType,
          "description": description,
          "timestamp": timestamp,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Lỗi sendSosOnline: $e");
      return false;
    }
  }
}