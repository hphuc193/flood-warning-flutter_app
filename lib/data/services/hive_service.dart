// lib/data/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String offlineDataBox = 'offline_data_box';
  static const String offlineActionsBox = 'offline_actions_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Mở Box chứa dữ liệu tổng (cảnh báo, hướng dẫn, danh bạ...)
    await Hive.openBox(offlineDataBox);

    // Mở Box chứa các thao tác người dùng làm khi mất mạng (VD: check checklist)
    await Hive.openBox(offlineActionsBox);
  }

  // Tiện ích lấy Box
  static Box get dataBox => Hive.box(offlineDataBox);
  static Box get actionsBox => Hive.box(offlineActionsBox);
}