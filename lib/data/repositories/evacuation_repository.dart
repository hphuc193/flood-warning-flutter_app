import 'package:dio/dio.dart';
import '../models/evacuation_guide_model.dart';
import '../services/api_service.dart';

class EvacuationRepository {
  final ApiService _apiService = ApiService();

  Future<List<EvacuationStep>?> getGuide() async {
    try {
      final response = await _apiService.dio.get('/evacuation/guide');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => EvacuationStep.fromJson(e)).toList();
      }
      return null;
    } catch (e) {
      print("Lỗi getEvacuationGuide: $e");
      throw e;
    }
  }
}