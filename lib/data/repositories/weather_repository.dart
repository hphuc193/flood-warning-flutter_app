import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/weather_model.dart';
import '../models/weather_forecast_model.dart';
import '../models/rainfall_history_model.dart';

class WeatherRepository {
  final ApiService _apiService = ApiService();

  // 1. LẤY THỜI TIẾT HIỆN TẠI (Giữ nguyên)
  Future<WeatherModel?> getCurrentWeather(double lat, double long) async {
    try {
      print("🚀 Gửi API Weather: Lat=$lat, Long=$long");

      final response = await _apiService.dio.get(
        '/weather/current',
        queryParameters: {
          'lat': lat,
          'long': long,
        },
      );

      if (response.data['success'] == true) {
        return WeatherModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print("❌ Lỗi API Status: ${e.response?.statusCode}");
      print("❌ Server báo lỗi: ${e.response?.data}");
      return null;
    } catch (e) {
      print("Lỗi lạ: $e");
      return null;
    }
  }

  // 2. LẤY DỰ BÁO THỜI TIẾT 5 NGÀY (ĐÃ SỬA CHUẨN)
  Future<WeatherForecastModel?> getWeatherForecast(double lat, double long) async {
    try {
      print("🚀 Gửi API Forecast: Lat=$lat, Long=$long");

      final response = await _apiService.dio.get(
        '/weather/forecast',
        queryParameters: {
          'lat': lat,
          'long': long,
        },
      );

      if (response.data['success'] == true) {
        // --- ĐÃ SỬA Ở ĐÂY ---
        // Truyền nguyên toàn bộ response.data vào Model.
        // Model mới sẽ tự động parse 'city', 'success' và danh sách 'data' bên trong.
        return WeatherForecastModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print("❌ Lỗi API Forecast Status: ${e.response?.statusCode}");
      print("❌ Server báo lỗi Forecast: ${e.response?.data}");
      return null;
    } catch (e) {
      print("Lỗi lấy dự báo: $e");
      return null; // Trả về null thay vì []
    }
  }
  //rainfall history
  Future<RainfallHistoryModel?> getRainfallHistory(double lat, double long, {int days = 30}) async {
    try {
      final response = await _apiService.dio.get(
        '/weather/rainfall-history',
        queryParameters: {
          'lat': lat,
          'long': long,
          'days': days,
        },
      );

      if (response.data['success'] == true) {
        return RainfallHistoryModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Lỗi lấy lịch sử lượng mưa: $e");
      return null;
    }
  }
}