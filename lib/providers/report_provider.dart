import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../data/services/api_service.dart';
import '../data/services/socket_service.dart';
import '../data/models/flood_report_model.dart';
import '../data/repositories/report_repository.dart';
import '../data/services/notification_service.dart';

class ReportProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final ReportRepository _reportRepository = ReportRepository();
  final NotificationService _notificationService = NotificationService();

  List<FloodReport> _reports = [];
  bool _isLoading = false;

  List<FloodReport> get reports => _reports;
  bool get isLoading => _isLoading;

  // 1. Fetch data ban đầu
  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/reports');
      if (response.data['success'] == true) {
        final List<dynamic> listData = response.data['data'];
        _reports = listData.map((e) => FloodReport.fromJson(e)).toList();
      }
    } catch (e) {
      print("Lỗi lấy danh sách báo cáo: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. Kích hoạt Socket lắng nghe real-time
  void initRealtimeUpdates() {
    _socketService.initSocket();

    _socketService.onNewFloodReport((data) {
      // Khi server bắn data mới về, parse thành Model và add vào list
      try {
        final newReport = FloodReport.fromJson(data);
        // Kiểm tra xem report này có trùng với cái đã có không (tránh duplicate)
        if (!_reports.any((r) => r.id == newReport.id)) {
          _reports.add(newReport); // Thêm vào danh sách (để hiện lên UI)

          // --- THÊM ĐOẠN NÀY: BẮN THÔNG BÁO ---
          _notificationService.showNotification(
            id: newReport.id,
            title: '⚠️ CẢNH BÁO NGẬP MỚI!',
            body: 'Tại khu vực: ${newReport.description}. Hãy kiểm tra bản đồ ngay.',
          );
          // ------------------------------------

          notifyListeners();
        }
      } catch (e) {
        print("Lỗi parse data socket: $e");
      }
    });
  }

  Future<bool> createReport(double lat, double long, String desc, List<String> images, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _reportRepository.createReport(
          lat: lat,
          long: long,
          description: desc,
          imagePaths: images
      );

      // Thành công thì fetch lại data hoặc đợi socket bắn về
      // Ở đây ta đợi socket cho chuẩn realtime
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      return false;
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}