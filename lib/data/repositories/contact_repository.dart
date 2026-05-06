import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/contact_model.dart';

class ContactRepository {
  final ApiService _apiService = ApiService();

  // 1. Lấy toàn bộ danh bạ
  Future<Map<String, dynamic>?> getAllContacts({double? lat, double? long}) async {
    try {
      String url = '/emergency-contacts'; // Giữ nguyên endpoint cũ của bạn

      // Nếu có tọa độ GPS truyền vào, nối thêm vào URL làm Query Parameter
      if (lat != null && long != null) {
        url += '?lat=$lat&long=$long';
      }

      final response = await _apiService.dio.get(url);

      if (response.data['success'] == true) {
        // Thay vì parse từng cục ở đây, chúng ta trả về toàn bộ Map 'data'
        // Để cho ContactProvider tự do bóc tách 3 mảng (System, Local, Custom)
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print("Lỗi Repository getAllContacts: $e");
      rethrow;
    }
  }

  // 2. Thêm liên hệ cá nhân
  Future<EmergencyContact?> addCustomContact(String name, String phone, String? relation) async {
    try {
      final response = await _apiService.dio.post(
        '/emergency-contacts',
        data: {
          'name': name,
          'phone_number': phone,
          'relation': relation
        },
      );
      if (response.statusCode == 201) {
        return EmergencyContact.fromJson(response.data['data'], isCustom: true);
      }
      return null;
    } catch (e) {
      print("Lỗi Repository addCustomContact: $e");
      return null;
    }
  }

  // 3. Xóa liên hệ
  Future<bool> deleteCustomContact(String id) async {
    try {
      final response = await _apiService.dio.delete('/emergency-contacts/$id');
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi Repository deleteCustomContact: $e");
      return false;
    }
  }
}