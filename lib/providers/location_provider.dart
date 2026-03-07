import 'package:flutter/material.dart';
import '../data/repositories/location_repository.dart';
import '../data/models/saved_location_model.dart';

class LocationProvider with ChangeNotifier {
  final LocationRepository _repository = LocationRepository();

  List<SavedLocationModel> _locations = [];
  bool _isLoading = false;

  List<SavedLocationModel> get locations => _locations;
  bool get isLoading => _isLoading;

  Future<void> fetchLocations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _locations = await _repository.getSavedLocations();
    } catch (e) {
      print("Lỗi tải danh sách vị trí: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLocation(SavedLocationModel location) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newLoc = await _repository.addLocation(location);
      if (newLoc != null) {
        _locations.add(newLoc);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateLocation(int id, Map<String, dynamic> data) async {
    try {
      final updatedLoc = await _repository.updateLocation(id, data);
      if (updatedLoc != null) {
        // Cập nhật phần tử trong list
        final index = _locations.indexWhere((loc) => loc.id == id);
        if (index != -1) {
          _locations[index] = updatedLoc;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> deleteLocation(int id) async {
    try {
      final success = await _repository.deleteLocation(id);
      if (success) {
        _locations.removeWhere((loc) => loc.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }
}