import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Lỗi kết nối server';
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      final response = await _apiService.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Đăng ký thất bại';
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/firebase-login', // Endpoint Backend của bạn (VD: /api/v1/auth/google)
        data: {
          'token': idToken, // Backend nhận key là 'token' hoặc 'idToken' tùy bạn đặt
        },
      );
      return response.data;
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> loginWithFacebook(String idToken) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/facebook-login', // Trỏ đúng vào route BE bạn vừa viết
        data: {
          'token': idToken // BE yêu cầu lấy "token" từ req.body
        },
      );
      return response.data;
    } on DioException catch (e) {
      // Bắt lỗi từ Backend trả về (Ví dụ: Lỗi 409 trùng Email)
      throw e.response?.data['message'] ?? 'Lỗi kết nối Server khi đăng nhập Facebook';
    }
  }
}