import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/evacuation_repository.dart';
import '../data/models/evacuation_guide_model.dart';
import '../data/services/hive_service.dart';

class EvacuationProvider with ChangeNotifier {
  final EvacuationRepository _repository = EvacuationRepository();
  final String _cacheKey = 'evacuation_guide_data';

  List<EvacuationStep> _steps = [];
  bool _isLoading = false;
  bool _isOfflineMode = false;

  List<EvacuationStep> get steps => _steps;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;

  Future<void> fetchGuide() async {
    _isLoading = true;
    notifyListeners();

    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        final fetchedSteps = await _repository.getGuide();
        if (fetchedSteps != null) {
          _steps = fetchedSteps;
          _steps.sort((a, b) => a.step.compareTo(b.step)); // Sắp xếp theo thứ tự bước

          // Lưu Cache vào Hive (Data Box)
          await HiveService.dataBox.put(_cacheKey, jsonEncode(_steps.map((e) => e.toJson()).toList()));
          _isOfflineMode = false;
        }
      } catch (e) {
        _loadFromLocal();
      }
    } else {
      _loadFromLocal();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadFromLocal() {
    _isOfflineMode = true;
    // Đọc từ Hive cực kỳ nhanh
    final cachedString = HiveService.dataBox.get(_cacheKey);
    if (cachedString != null) {
      final List decoded = jsonDecode(cachedString);
      _steps = decoded.map((e) => EvacuationStep.fromJson(e)).toList();
    }
  }
}