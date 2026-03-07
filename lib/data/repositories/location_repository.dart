import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/saved_location_model.dart';

class LocationRepository {
  final ApiService _apiService = ApiService();

  Future<List<SavedLocationModel>> getSavedLocations() async {
    try {
      final response = await _apiService.dio.get('/user-locations');
      if (response.data['success'] == true) {
        final List<dynamic> rawList = response.data['data'];
        return rawList.map((e) => SavedLocationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi get locations: $e");
      return [];
    }
  }

  Future<SavedLocationModel?> addLocation(SavedLocationModel location) async {
    try {
      final response = await _apiService.dio.post(
        '/user-locations',
        data: location.toJson(),
      );
      if (response.data['success'] == true) {
        return SavedLocationModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Lỗi add location: $e");
      throw Exception("Thêm vị trí thất bại");
    }
  }

  Future<SavedLocationModel?> updateLocation(int id, Map<String, dynamic> updateData) async {
    try {
      final response = await _apiService.dio.put(
        '/user-locations/$id',
        data: updateData,
      );
      if (response.data['success'] == true) {
        return SavedLocationModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Lỗi update location: $e");
      throw Exception("Cập nhật vị trí thất bại");
    }
  }

  Future<bool> deleteLocation(int id) async {
    try {
      final response = await _apiService.dio.delete('/user-locations/$id');
      return response.data['success'] == true;
    } catch (e) {
      print("Lỗi delete location: $e");
      return false;
    }
  }
}