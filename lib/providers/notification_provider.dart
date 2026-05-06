import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

// MODEL
class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String type;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? 'Thông báo hệ thống',

      content: json['body'] ?? json['message'] ?? json['content'] ?? '',

      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']).toLocal(),
    );
  }
}

// PROVIDER
class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  // Phân trang
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  // 1. Lấy danh sách (Có hỗ trợ load more)
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _notifications.clear();
    }

    if (!_hasMore) return;

    _isLoading = true;
    if (refresh) notifyListeners(); // Chỉ báo loading toàn màn hình khi refresh

    try {
      final response = await _apiService.dio.get('/notifications?page=$_currentPage&limit=15');

      if (response.data['success'] == true) {
        final List data = response.data['data'];
        final meta = response.data['meta'];

        _unreadCount = meta['unread_count'] ?? 0;
        _totalPages = meta['total_pages'] ?? 1;

        final newItems = data.map((e) => NotificationModel.fromJson(e)).toList();
        _notifications.addAll(newItems);

        if (_currentPage >= _totalPages) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
      }
    } catch (e) {
      print("Lỗi fetch Notifications: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. Đánh dấu 1 thông báo là đã đọc
  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();

      try {
        await _apiService.dio.patch('/notifications/$id/read');
      } catch (e) {
        // Nếu lỗi thì rollback
        _notifications[index].isRead = false;
        _unreadCount++;
        notifyListeners();
      }
    }
  }

  // 3. Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;

    // Lưu lại trạng thái cũ để phòng hờ API lỗi thì trả về như cũ
    final previousStates = _notifications.map((n) => n.isRead).toList();
    final previousCount = _unreadCount;

    for (var n in _notifications) {
      n.isRead = true;
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      final response = await _apiService.dio.patch('/notifications/read-all');

      // Nếu Backend trả về success: false hoặc lỗi 500
      if (response.statusCode != 200 || response.data['success'] == false) {
        throw Exception("Server không xử lý được");
      }
    } catch (e) {
      print("Lỗi Mark all as read: $e");
      // Rollback: Phục hồi lại trạng thái chưa đọc nếu API thất bại
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i].isRead = previousStates[i];
      }
      _unreadCount = previousCount;
      notifyListeners();
    }
  }
}