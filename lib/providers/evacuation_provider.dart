import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/evacuation_repository.dart';
import '../data/models/evacuation_guide_model.dart';

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
    bool hasInternet = connectivityResult != ConnectivityResult.none;
    final prefs = await SharedPreferences.getInstance();

    if (hasInternet) {
      try {
        final fetchedSteps = await _repository.getGuide();
        if (fetchedSteps != null) {
          _steps = fetchedSteps;
          _steps.sort((a, b) => a.step.compareTo(b.step)); // Sắp xếp theo thứ tự bước

          // Lưu Cache dạng String JSON
          await prefs.setString(_cacheKey, jsonEncode(_steps.map((e) => e.toJson()).toList()));
          _isOfflineMode = false;
        }
      } catch (e) {
        await _loadFromLocal(prefs);
      }
    } else {
      await _loadFromLocal(prefs);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromLocal(SharedPreferences prefs) async {
    _isOfflineMode = true;
    final cachedString = prefs.getString(_cacheKey);
    if (cachedString != null) {
      final List decoded = jsonDecode(cachedString);
      _steps = decoded.map((e) => EvacuationStep.fromJson(e)).toList();
    }
  }
}