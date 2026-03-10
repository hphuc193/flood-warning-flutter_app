import 'package:dio/dio.dart';
import '../services/api_service.dart'; // Đảm bảo đã import ApiService của bạn

class ChecklistRepository {
  final ApiService _apiService = ApiService();

  // Gọi API lấy dữ liệu
  Future<Map<String, dynamic>?> getChecklists() async {
    try {
      final response = await _apiService.dio.get('/checklists');
      if (response.data['success'] == true) {
        return response.data['data']; // Trả về block 'data'
      }
      return null;
    } catch (e) {
      print("Lỗi getChecklists: $e");
      throw e;
    }
  }

  // Gọi API đồng bộ (POST sync)
  Future<bool> syncChecklists(List<String> completedItems) async {
    try {
      final response = await _apiService.dio.post(
        '/checklists/sync',
        data: {'completed_items': completedItems},
      );
      return response.data['success'] == true;
    } catch (e) {
      print("Lỗi syncChecklists: $e");
      return false;
    }
  }
}