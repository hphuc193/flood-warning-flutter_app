import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    // 1. Cấu hình cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Icon mặc định của app

    // 2. Cấu hình cho iOS (nếu cần sau này)
    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings();

    // 3. Khởi tạo
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      // SỬA LỖI Ở ĐÂY: Thêm định danh 'settings:'
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng bấm vào thông báo (Ví dụ: mở màn hình chi tiết)
        print("User clicked notification: ${response.payload}");
      },
    );

    // 4. Xin quyền Notification (Android 13+)
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // Hàm hiển thị thông báo
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'flood_warning_channel', // Id kênh
      'Flood Alerts', // Tên kênh hiển thị trong cài đặt
      channelDescription: 'Thông báo cảnh báo ngập lụt',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      // SỬA LỖI Ở ĐÂY: Chuyển toàn bộ thành tham số có tên (named parameters)
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}