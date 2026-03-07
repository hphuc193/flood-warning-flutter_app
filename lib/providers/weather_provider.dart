import 'package:flutter/material.dart';
import '../data/repositories/weather_repository.dart';
import '../data/models/weather_model.dart';
import '../data/services/socket_service.dart';
import '../data/services/notification_service.dart';
import '../data/models/weather_forecast_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherRepository _repository = WeatherRepository();
  final SocketService _socketService = SocketService();
  final NotificationService _notificationService = NotificationService();

  // --- THỜI TIẾT HIỆN TẠI ---
  WeatherModel? _currentWeather;
  bool _isLoading = false;

  WeatherModel? get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;

  // --- DỰ BÁO THỜI TIẾT (5 NGÀY/3 GIỜ) ---
  // SỬA: Đổi từ List thành 1 object duy nhất
  WeatherForecastModel? _forecastData;
  bool _isForecastLoading = false;

  WeatherForecastModel? get forecastData => _forecastData;
  bool get isForecastLoading => _isForecastLoading;

  String _currentCityName = "Vị trí hiện tại";
  String get currentCityName => _currentCityName;

  // 1. Lấy thời tiết hiện tại từ API
  Future<void> fetchWeather(double lat, double long) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentWeather = await _repository.getCurrentWeather(lat, long);
    } catch (e) {
      print("Lỗi lấy thời tiết hiện tại: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. Dự báo thời tiết (5 ngày)
  Future<void> fetchForecast(double lat, double long, {String? cityName}) async {
    _isForecastLoading = true;

    if (cityName != null) {
      _currentCityName = cityName;
    } else {
      _currentCityName = "Vị trí hiện tại";
    }

    notifyListeners();

    try {
      // Repository giờ sẽ trả về 1 object WeatherForecastModel (từ hàm fromJson mới)
      _forecastData = await _repository.getWeatherForecast(lat, long);
    } catch (e) {
      print("Provider Forecast Error: $e");
    }

    _isForecastLoading = false;
    notifyListeners();
  }

  // 3. Lắng nghe Real-time (Mưa/Lũ)
  void initRealtimeWeatherAlerts() {
    _socketService.onWeatherUpdate((data) {
      try {
        final double rainfall = (data['rainfall'] as num).toDouble();

        if (rainfall > 100) {
          _notificationService.showNotification(
            id: 999,
            title: '🚨 CẢNH BÁO MƯA LỚN!',
            body: 'Lượng mưa đạt ${rainfall}mm. Nguy cơ ngập lụt cao!',
          );
        } else if (rainfall > 50) {
          _notificationService.showNotification(
            id: 998,
            title: '🌧️ Trời đang mưa to',
            body: 'Lượng mưa hiện tại: ${rainfall}mm.',
          );
        }

        print("Mưa: $rainfall mm - Đã xử lý cảnh báo");
      } catch (e) {
        print("Lỗi parse data weather socket: $e");
      }
    });
  }

  List<Map<String, dynamic>> _savedLocations = [];
  List<Map<String, dynamic>> get savedLocations => _savedLocations;

  // Lấy vị trí hiện tại của thiết bị (Mặc định tạm là HCM, bạn có thể thay bằng Geolocator sau)
  final Map<String, dynamic> _currentLocation = {
    'name': 'Vị trí hiện tại (TP.HCM)',
    'lat': 10.7626,
    'lon': 106.6602,
    'isCurrent': true, // Cờ đánh dấu đây là vị trí GPS
  };
  Map<String, dynamic> get currentLocation => _currentLocation;

  // Load danh sách đã lưu từ SharedPreferences
  Future<void> loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString('saved_locations');

    if (locationsJson != null) {
      List<dynamic> decoded = jsonDecode(locationsJson);
      _savedLocations = decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    notifyListeners();
  }

  // Thêm vị trí mới từ Map Picker
  Future<void> addLocation(String name, double lat, double lon) async {
    // Kiểm tra trùng lặp
    bool exists = _savedLocations.any((loc) => loc['lat'] == lat && loc['lon'] == lon);
    if (!exists) {
      _savedLocations.add({
        'name': name,
        'lat': lat,
        'lon': lon,
        'isCurrent': false,
      });
      await _saveToStorage();
      notifyListeners();
    }
  }

  // Xóa vị trí
  Future<void> removeLocation(int index) async {
    _savedLocations.removeAt(index);
    await _saveToStorage();
    notifyListeners();
  }

  // Lưu xuống Local Storage
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_locations', jsonEncode(_savedLocations));
  }
}