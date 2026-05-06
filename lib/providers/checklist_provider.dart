import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/checklist_repository.dart';
import '../data/models/checklist_model.dart';
import '../data/services/hive_service.dart';

class ChecklistProvider with ChangeNotifier {
  final ChecklistRepository _repository = ChecklistRepository();
  final String _cacheKeyMaster = 'checklist_master_data';
  final String _cacheKeyCompleted = 'checklist_completed_items';

  List<ChecklistCategory> _categories = [];
  List<String> _completedItemIds = [];
  bool _isLoading = false;
  int _totalItems = 0;

  List<ChecklistCategory> get categories => _categories;
  List<String> get completedItemIds => _completedItemIds;
  bool get isLoading => _isLoading;

  // Tính phần trăm tiến độ
  double get progress {
    if (_totalItems == 0) return 0.0;
    return _completedItemIds.length / _totalItems;
  }

  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    // Kiểm tra mạng
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        final data = await _repository.getChecklists();
        if (data != null) {
          // Bóc tách dữ liệu
          _categories = (data['master_list'] as List).map((e) => ChecklistCategory.fromJson(e)).toList();
          _completedItemIds = List<String>.from(data['completed_items']);

          // Lưu cache vào Hive Box
          await HiveService.dataBox.put(_cacheKeyMaster, jsonEncode(data['master_list']));
          await HiveService.dataBox.put(_cacheKeyCompleted, _completedItemIds);
        }
      } catch (e) {
        _loadFromLocal(); // Lỗi API thì lấy từ Local
      }
    } else {
      _loadFromLocal(); // Mất mạng lấy từ Local
    }

    _calculateTotalItems();
    _isLoading = false;
    notifyListeners();
  }

  void _loadFromLocal() {
    final masterString = HiveService.dataBox.get(_cacheKeyMaster);
    if (masterString != null) {
      _categories = (jsonDecode(masterString) as List).map((e) => ChecklistCategory.fromJson(e)).toList();
    }
    // Lấy list String từ Hive, nếu null trả về []
    final completedData = HiveService.dataBox.get(_cacheKeyCompleted);
    if (completedData != null) {
      _completedItemIds = List<String>.from(completedData);
    } else {
      _completedItemIds = [];
    }
  }

  void _calculateTotalItems() {
    _totalItems = 0;
    for (var cat in _categories) {
      _totalItems += cat.items.length;
    }
  }

  // Hàm khi User tick/untick (Xử lý Offline Actions)
  void toggleItem(String itemId, bool isChecked) async {
    if (isChecked) {
      if (!_completedItemIds.contains(itemId)) _completedItemIds.add(itemId);
    } else {
      _completedItemIds.remove(itemId);
    }

    notifyListeners(); // Cập nhật thanh Progress Bar ngay lập tức

    // 1. Lưu mảng mới vào Local DB để ghi nhớ trạng thái
    await HiveService.dataBox.put(_cacheKeyCompleted, _completedItemIds);

    // 2. LOGIC MỚI: Đẩy vào Box chờ đồng bộ nếu đang Offline
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOffline = connectivityResult.contains(ConnectivityResult.none);
    if (isOffline) {
      // NetworkSyncProvider sẽ đọc key này để đẩy lên API /sync/offline-actions
      await HiveService.actionsBox.put('pending_checklists', _completedItemIds);
    }
  }

  // Hàm gọi API đồng bộ khi thoát màn hình
  Future<void> syncDataWithServer() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      // Có mạng mới đẩy lên Server
      await _repository.syncChecklists(_completedItemIds);

      // Xóa hàng đợi Offline vì đã được đồng bộ thành công
      await HiveService.actionsBox.delete('pending_checklists');

      _checkImportantReminders();
    }
  }

  void _checkImportantReminders() {
    List<String> missedImportant = [];
    for (var cat in _categories) {
      for (var item in cat.items) {
        if (item.isImportant && !_completedItemIds.contains(item.id)) {
          missedImportant.add(item.title);
        }
      }
    }

    if (missedImportant.isNotEmpty) {
      print("CẢNH BÁO: Còn ${missedImportant.length} mục quan trọng chưa chuẩn bị!");
    }
  }
}