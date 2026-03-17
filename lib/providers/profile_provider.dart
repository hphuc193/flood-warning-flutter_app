import 'dart:io';
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

  // 1. Lấy thông tin profile (Giữ nguyên)
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

  // 2. Cập nhật thông tin (Logic mới tách biệt Text và File)
  Future<bool> updateProfileData({
    required String fullName,
    required String phoneNumber,
    File? avatarFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool isSuccess = true;

    try {
      // BƯỚC A: Nếu có người dùng có chọn ảnh mới -> Gọi API upload ảnh trước
      if (avatarFile != null) {
        bool avatarUploaded = await _repository.uploadAvatar(avatarFile);
        if (!avatarUploaded) {
          _errorMessage = "Quá trình tải ảnh đại diện lên máy chủ thất bại.";
          isSuccess = false;
        }
      }

      // BƯỚC B: Tiếp tục gọi API cập nhật thông tin chữ (Text)
      if (isSuccess) {
        bool textUpdated = await _repository.updateTextProfile(fullName, phoneNumber);
        if (!textUpdated) {
          _errorMessage = "Quá trình cập nhật thông tin cá nhân thất bại.";
          isSuccess = false;
        }
      }

      // BƯỚC C: Nếu cả 2 bước trên thành công, gọi lại API getProfile
      // để kéo dữ liệu mới nhất (chứa link avatar mới) từ Backend về và cập nhật UI.
      if (isSuccess) {
        // Ta không tự gán _profile ở đây nữa mà để hàm fetchProfile() làm việc đó
        // Lưu ý: Không dùng await fetchProfile() trực tiếp ở đây để tránh trùng lặp _isLoading
        // Ta sẽ tự lấy và gán để UI không bị giật
        final updatedProfile = await _repository.getProfile();
        if (updatedProfile != null) {
          _profile = updatedProfile;
        }
      }

    } catch (e) {
      _errorMessage = e.toString();
      isSuccess = false;
    }

    _isLoading = false;
    notifyListeners();

    return isSuccess;
  }
}