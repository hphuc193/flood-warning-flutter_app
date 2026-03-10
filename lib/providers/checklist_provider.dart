import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/checklist_repository.dart';
import '../data/models/checklist_model.dart';

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
    bool hasInternet = connectivityResult != ConnectivityResult.none;

    final prefs = await SharedPreferences.getInstance();

    if (hasInternet) {
      try {
        final data = await _repository.getChecklists();
        if (data != null) {
          // Bóc tách dữ liệu
          _categories = (data['master_list'] as List).map((e) => ChecklistCategory.fromJson(e)).toList();
          _completedItemIds = List<String>.from(data['completed_items']);

          // Lưu cache cho lần offline sau
          await prefs.setString(_cacheKeyMaster, jsonEncode(data['master_list']));
          await prefs.setStringList(_cacheKeyCompleted, _completedItemIds);
        }
      } catch (e) {
        await _loadFromLocal(prefs); // Lỗi API thì lấy từ Local
      }
    } else {
      await _loadFromLocal(prefs); // Mất mạng lấy từ Local
    }

    _calculateTotalItems();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromLocal(SharedPreferences prefs) async {
    final masterString = prefs.getString(_cacheKeyMaster);
    if (masterString != null) {
      _categories = (jsonDecode(masterString) as List).map((e) => ChecklistCategory.fromJson(e)).toList();
    }
    _completedItemIds = prefs.getStringList(_cacheKeyCompleted) ?? [];
  }

  void _calculateTotalItems() {
    _totalItems = 0;
    for (var cat in _categories) {
      _totalItems += cat.items.length;
    }
  }

  // Hàm khi User tick/untick (Chỉ cập nhật Local State)
  void toggleItem(String itemId, bool isChecked) async {
    if (isChecked) {
      if (!_completedItemIds.contains(itemId)) _completedItemIds.add(itemId);
    } else {
      _completedItemIds.remove(itemId);
    }

    notifyListeners(); // Cập nhật thanh Progress Bar ngay lập tức

    // Lưu mảng mới vào Local DB
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cacheKeyCompleted, _completedItemIds);
  }

  // Hàm gọi API đồng bộ khi thoát màn hình
  Future<void> syncDataWithServer() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      // Có mạng mới đẩy lên
      await _repository.syncChecklists(_completedItemIds);

      // TODO: Logic Notification (Kiểm tra item isImportant chưa check)
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
      // Ở đây bạn gọi hàm của flutter_local_notifications để bắn Push
    }
  }
}