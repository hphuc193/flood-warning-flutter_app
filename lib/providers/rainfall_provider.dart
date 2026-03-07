import 'package:flutter/material.dart';
import '../data/repositories/weather_repository.dart';
import '../data/models/rainfall_history_model.dart';

class RainfallProvider with ChangeNotifier {
  final WeatherRepository _repository = WeatherRepository();

  RainfallHistoryModel? _historyData;
  bool _isLoading = false;
  String? _errorMessage;

  RainfallHistoryModel? get historyData => _historyData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRainfallHistory(double lat, double long, {int days = 30}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _historyData = await _repository.getRainfallHistory(lat, long, days: days);
      if (_historyData == null) {
        _errorMessage = "Không có dữ liệu lịch sử cho khu vực này.";
      }
    } catch (e) {
      _errorMessage = "Lỗi tải dữ liệu: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}