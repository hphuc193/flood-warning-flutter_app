import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/user_profile_model.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

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

  Future<UserProfileModel?> updateProfile(UserProfileModel profile) async {
    try {
      final response = await _apiService.dio.put(
        '/users/profile',
        data: profile.toJson(),
      );
      if (response.data['success'] == true) {
        return UserProfileModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Lỗi update profile: $e");
      throw Exception("Cập nhật thông tin thất bại");
    }
  }
}