import 'package:dio/dio.dart';
import '../services/api_service.dart';

class ReportRepository {
  final ApiService _apiService = ApiService();

  Future<bool> createReport({
    required double lat,
    required double long,
    required String description,
    required List<String> imagePaths, // Danh sách đường dẫn file ảnh trong máy
  }) async {
    try {
      // 1. Tạo FormData
      FormData formData = FormData.fromMap({
        'lat': lat,
        'long': long,
        'description': description,
      });

      // 2. Duyệt qua danh sách ảnh và add vào FormData
      for (String path in imagePaths) {
        formData.files.add(MapEntry(
          'images', // Tên field này phải khớp với backend (upload.array('images'))
          await MultipartFile.fromFile(path, filename: path.split('/').last),
        ));
      }

      // 3. Gửi Request
      final response = await _apiService.dio.post(
        '/reports',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data', // Bắt buộc
          },
        ),
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Lỗi khi gửi báo cáo';
    }
  }
}