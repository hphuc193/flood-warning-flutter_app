import 'package:flutter/material.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_profile_model.dart';

class ProfileProvider with ChangeNotifier {
  final UserRepository _repository = UserRepository();

  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.getProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(UserProfileModel updatedData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.updateProfile(updatedData);
      if (result != null) {
        _profile = result; // Cập nhật lại state local
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}