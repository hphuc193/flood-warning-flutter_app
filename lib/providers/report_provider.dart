import 'package:flutter/material.dart';
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
  bool _isFetchingMore = false; // Trạng thái đang tải trang tiếp theo

  // Biến quản lý phân trang & tìm kiếm
  int _currentPage = 1;
  bool _hasNextPage = true;
  int _totalItems = 0;
  String _currentSearch = '';
  String _currentStatus = '';

  // === CÁC BIẾN QUẢN LÝ BỘ LỌC MỚI ===
  String _currentCategory = '';
  String _currentSeverity = '';
  String _currentTimeRange = '';

  List<FloodReport> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  int get totalItems => _totalItems;

  // 1. Fetch data (Hỗ trợ reset từ đầu hoặc tải theo điều kiện)
  Future<void> fetchReports({
    bool reset = false,
    String search = '',
    String status = '',
    String category = '',   // Thêm param category
    String severity = '',   // Thêm param severity
    String timeRange = '',  // Thêm param timeRange
  }) async {
    if (reset) {
      _currentPage = 1;
      _hasNextPage = true;
      _currentSearch = search;
      _currentStatus = status;
      // Lưu lại trạng thái của các bộ lọc mới
      _currentCategory = category;
      _currentSeverity = severity;
      _currentTimeRange = timeRange;

      _isLoading = true;
      notifyListeners();
    }

    if (!_hasNextPage) return; // Nếu hết trang thì không gọi nữa

    try {
      final response = await _apiService.dio.get(
        '/reports',
        queryParameters: {
          'page': _currentPage,
          'limit': 15,
          'search': _currentSearch,
          'status': _currentStatus,
          // Truyền các param lọc mới xuống Backend
          'category': _currentCategory,
          'severity': _currentSeverity,
          'time_range': _currentTimeRange,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> listData = response.data['data'];
        final newItems = listData.map((e) => FloodReport.fromJson(e)).toList();

        if (reset) {
          _reports = newItems;
        } else {
          _reports.addAll(newItems); // Nối mảng khi phân trang
        }

        // Cập nhật Meta data
        final meta = response.data['meta'];
        _hasNextPage = meta['has_next'] ?? false;
        _totalItems = meta['total_items'] ?? _reports.length;
      }
    } catch (e) {
      print("Lỗi lấy danh sách báo cáo: $e");
    }

    _isLoading = false;
    _isFetchingMore = false;
    notifyListeners();
  }

  // Hàm gọi tải thêm trang tiếp theo khi cuộn xuống đáy
  Future<void> loadMoreReports() async {
    if (_isFetchingMore || !_hasNextPage || _isLoading) return;

    _isFetchingMore = true;
    _currentPage++;
    notifyListeners();

    await fetchReports();
  }

  // 2. Kích hoạt Socket lắng nghe real-time (ĐÃ MỞ LẠI THEO YÊU CẦU)
  void initRealtimeUpdates() {
    _socketService.initSocket();

    // Lắng nghe có báo cáo mới
    _socketService.onNewFloodReport((data) {
      try {
        final newReport = FloodReport.fromJson(data);
        if (!_reports.any((r) => r.id == newReport.id)) {
          // Báo cáo mới đẩy lên ĐẦU mảng (index 0)
          _reports.insert(0, newReport);
          _totalItems++;

          _notificationService.showNotification(
            id: newReport.id,
            title: '⚠️ CẢNH BÁO NGẬP MỚI!',
            body: 'Tại khu vực: ${newReport.description}. Hãy kiểm tra bản đồ ngay.',
          );

          notifyListeners();
        }
      } catch (e) {
        print("Lỗi parse data socket: $e");
      }
    });

    // Lắng nghe trạng thái VOTE real-time
    _socketService.socket.on('report_voted', (data) {
      final reportId = data['report_id'];
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index].upvotes = data['upvotes'];
        _reports[index].downvotes = data['downvotes'];
        notifyListeners();
      }
    });

    // Lắng nghe trạng thái DUYỆT (Verified/Rejected) real-time của Admin
    _socketService.socket.on('flood_verified', (data) {
      final reportId = data['id'];
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        // Có thể update nguyên model nếu hàm fromJson được setup chuẩn
        // hoặc update cục bộ status
        _reports[index] = FloodReport.fromJson(data);
        notifyListeners();
      }
    });
  }

  // 3. Tạo báo cáo (ĐÃ CẬP NHẬT ĐẦY ĐỦ THAM SỐ)
  Future<bool> createReport(
      double lat,
      double long,
      String desc,
      String category,
      int severity,
      List<String> images,
      BuildContext context
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _reportRepository.createReport(
          lat: lat,
          long: long,
          description: desc,
          category: category,
          severity: severity,
          imagePaths: images
      );
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

  // 4. Upvote / Downvote
  Future<void> voteReport(int reportId, String type) async {
    final reportIndex = _reports.indexWhere((r) => r.id == reportId);
    if (reportIndex == -1) return;

    final report = _reports[reportIndex];
    final oldVote = report.currentUserVote;
    final oldUpvotes = report.upvotes;
    final oldDownvotes = report.downvotes;

    // Optimistic UI Update
    if (oldVote == type) {
      report.currentUserVote = null;
      type == 'upvote' ? report.upvotes -= 1 : report.downvotes -= 1;
    } else {
      report.currentUserVote = type;
      if (type == 'upvote') {
        report.upvotes += 1;
        if (oldVote == 'downvote') report.downvotes -= 1;
      } else {
        report.downvotes += 1;
        if (oldVote == 'upvote') report.upvotes -= 1;
      }
    }
    notifyListeners();

    try {
      await _reportRepository.voteReport(reportId, type);
    } catch (e) {
      print("Lỗi vote: $e");
      report.currentUserVote = oldVote;
      report.upvotes = oldUpvotes;
      report.downvotes = oldDownvotes;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}