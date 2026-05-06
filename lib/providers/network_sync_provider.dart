// lib/providers/network_sync_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../data/services/hive_service.dart';
import '../data/services/api_service.dart';

class NetworkSyncProvider extends ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final ApiService _apiService = ApiService();

  NetworkSyncProvider() {
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool isNowOffline = results.contains(ConnectivityResult.none);

      // Nếu trạng thái thay đổi từ OFFLINE sang ONLINE
      if (_isOffline && !isNowOffline) {
        _isOffline = false;
        notifyListeners();
        _onNetworkRestored();
      } else if (isNowOffline && !_isOffline) {
        // Chuyển sang OFFLINE
        _isOffline = true;
        notifyListeners();
      }
    });
  }

  Future<void> _onNetworkRestored() async {
    // 1. Đẩy các thao tác lưu tạm (offline actions) lên Server
    await syncOfflineActionsToServer();
    // 2. Tải lại cục dữ liệu Offline mới nhất
    await fetchAndSaveOfflineData();
  }

  // Tải và lưu dữ liệu offline
  Future<void> fetchAndSaveOfflineData() async {
    if (_isOffline) return;

    try {
      final response = await _apiService.dio.get('/sync/offline-data');
      if (response.statusCode == 200 && response.data['success']) {
        // Lưu toàn bộ cục JSON vào Hive để truy xuất khi mất mạng
        await HiveService.dataBox.put('fws_essential_data', response.data['data']);
        print("Đã lưu trữ dữ liệu thiết yếu offline");
      }
    } catch (e) {
      print("Lỗi tải dữ liệu offline: $e");
    }
  }

  //Đồng bộ thao tác người dùng lên Server
  Future<void> syncOfflineActionsToServer() async {
    final actionsBox = HiveService.actionsBox;
    List<dynamic> pendingChecklists = actionsBox.get('pending_checklists', defaultValue: []);

    if (pendingChecklists.isEmpty) return;

    try {
      final response = await _apiService.dio.post(
        '/sync/offline-actions',
        data: { 'offline_checklist_updates': pendingChecklists },
      );

      if (response.statusCode == 200) {
        // Xóa queue sau khi đồng bộ thành công
        await actionsBox.delete('pending_checklists');
        print("Đã đồng bộ thao tác offline lên Server");
      }
    } catch (e) {
      print("Lỗi đồng bộ thao tác: $e");
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}