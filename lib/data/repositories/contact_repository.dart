import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/contact_model.dart';

class ContactRepository {
  final ApiService _apiService = ApiService();

  // 1. Lấy toàn bộ danh bạ
  Future<Map<String, List<EmergencyContact>>?> getAllContacts() async {
    try {
      final response = await _apiService.dio.get('/emergency-contacts');
      if (response.data['success'] == true) {
        final Map<String, dynamic> data = response.data['data'];

        List<EmergencyContact> system = (data['system_contacts'] as List)
            .map((e) => EmergencyContact.fromJson(e))
            .toList();

        List<EmergencyContact> custom = (data['custom_contacts'] as List)
            .map((e) => EmergencyContact.fromJson(e, isCustom: true))
            .toList();

        return {'system': system, 'custom': custom};
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