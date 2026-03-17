import 'dart:io';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/user_profile_model.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

  // 1. Lấy thông tin người dùng (Giữ nguyên)
  Future<UserProfileModel?> getProfile() async {
    try {
      final response = await _apiService.dio.get('/users/profile');
      if (response.data['success'] == true) {
        return UserProfileModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Lỗi get profile: $e");
      throw Exception("Không thể lấy thông tin người dùng");
    }
  }

  // 2. API Cập nhật thông tin văn bản (Tên, Số điện thoại) theo chuẩn Swagger mới
  Future<bool> updateTextProfile(String fullName, String phoneNumber) async {
    try {
      final response = await _apiService.dio.put(
        '/users/profile',
        data: {
          "full_name": fullName,     // Map đúng key của backend
          "phone_number": phoneNumber, // Map đúng key của backend
        },
      );
      return response.statusCode == 200; // Trả về true nếu thành công
    } catch (e) {
      print("Lỗi updateTextProfile: $e");
      return false;
    }
  }

  // 3. API Upload Ảnh Đại Diện (Multipart Form-Data)
  Future<bool> uploadAvatar(File imageFile) async {
    try {
      // Lấy tên file gốc từ đường dẫn
      String fileName = imageFile.path.split('/').last;

      // Khởi tạo FormData chuẩn multipart/form-data
      FormData formData = FormData.fromMap({
        "avatar": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // Bắn API PATCH theo chuẩn backend
      final response = await _apiService.dio.patch(
        '/users/profile/avatar',
        data: formData,
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi uploadAvatar: $e");
      return false;
    }
  }
}