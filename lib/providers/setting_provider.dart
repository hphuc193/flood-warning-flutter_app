import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/services/api_service.dart';
import '../data/services/hive_service.dart';

//MODEL
class SettingModel {
  String theme;
  bool notiPush;
  bool notiSms;
  bool notiEmail;
  bool dailyWeatherNoti;
  String timezone;

  SettingModel({
    required this.theme,
    required this.notiPush,
    required this.notiSms,
    required this.notiEmail,
    required this.dailyWeatherNoti,
    required this.timezone,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      theme: json['theme'] ?? 'system',
      notiPush: json['noti_push'] ?? true,
      notiSms: json['noti_sms'] ?? false,
      notiEmail: json['noti_email'] ?? false,
      dailyWeatherNoti: json['daily_weather_noti'] ?? true,
      timezone: json['timezone'] ?? 'Asia/Ho_Chi_Minh',
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'noti_push': notiPush,
    'noti_sms': notiSms,
    'noti_email': notiEmail,
    'daily_weather_noti': dailyWeatherNoti,
    'timezone': timezone,
  };
}

// PROVIDER
class SettingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final String _cacheKey = 'user_settings_cache';

  SettingModel? _settings;
  bool _isLoading = false;

  SettingModel? get settings => _settings;
  bool get isLoading => _isLoading;

  // 1. Lấy dữ liệu cài đặt (Hỗ trợ Offline)
  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();

    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        final response = await _apiService.dio.get('/settings');
        if (response.data['success'] == true) {
          _settings = SettingModel.fromJson(response.data['data']);
          // Lưu cache vào Hive
          await HiveService.dataBox.put(_cacheKey, jsonEncode(_settings!.toJson()));
        }
      } catch (e) {
        print("Lỗi fetch Settings: $e");
        _loadLocalData();
      }
    } else {
      _loadLocalData();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadLocalData() {
    final String? cached = HiveService.dataBox.get(_cacheKey);
    if (cached != null) {
      _settings = SettingModel.fromJson(jsonDecode(cached));
    }
  }

  // 2. Cập nhật cài đặt (Sử dụng Optimistic Update + Rollback)
  Future<void> updateSetting({
    String? theme,
    bool? notiPush,
    bool? notiSms,
    bool? notiEmail,
    bool? dailyWeatherNoti,
  }) async {
    if (_settings == null) return;

    // A. Lưu lại trạng thái cũ để Rollback nếu lỗi
    final oldSettings = SettingModel.fromJson(_settings!.toJson());

    // B. Cập nhật UI ngay lập tức
    if (theme != null) _settings!.theme = theme;
    if (notiPush != null) _settings!.notiPush = notiPush;
    if (notiSms != null) _settings!.notiSms = notiSms;
    if (notiEmail != null) _settings!.notiEmail = notiEmail;
    if (dailyWeatherNoti != null) _settings!.dailyWeatherNoti = dailyWeatherNoti;
    notifyListeners();

    // C. Gửi lên Server
    try {
      Map<String, dynamic> body = {};
      if (theme != null) body['theme'] = theme;
      if (notiPush != null) body['noti_push'] = notiPush;
      if (notiSms != null) body['noti_sms'] = notiSms;
      if (notiEmail != null) body['noti_email'] = notiEmail;
      if (dailyWeatherNoti != null) body['daily_weather_noti'] = dailyWeatherNoti;

      // Dùng PATCH hoặc PUT tùy thuộc vào Route khai báo ở Nodejs
      final response = await _apiService.dio.patch('/settings', data: body);

      if (response.data['success'] == true) {
        // Cập nhật Hive nếu API thành công
        await HiveService.dataBox.put(_cacheKey, jsonEncode(_settings!.toJson()));
      } else {
        throw Exception("API không thành công");
      }
    } catch (e) {
      print("Lỗi update Setting: $e");
      // D. Nếu lỗi, Rollback về trạng thái cũ
      _settings = oldSettings;
      notifyListeners();
    }
  }
}