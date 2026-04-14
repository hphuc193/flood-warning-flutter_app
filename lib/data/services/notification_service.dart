import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

// Import ApiService (Đường dẫn có thể cần chỉnh lại nếu khác thư mục)
import 'api_service.dart';

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

  // === HÀM 1: HIỂN THỊ THÔNG BÁO LOCAL (SỬ DỤNG CHO SOCKET REAL-TIME) ===
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
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  // === HÀM 2: ĐỒNG BỘ DỮ LIỆU THIẾT BỊ LÊN BACKEND (FCM TOKEN + GPS) ===
  Future<void> updateDeviceTokenAndLocation() async {
    try {
      // 1. Xin quyền Notification từ Firebase
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('⚠️ Người dùng đã từ chối quyền nhận thông báo FCM.');
        // Không return ở đây vì vẫn muốn lấy GPS gửi lên (nếu có thể)
      }

      // 2. Lấy FCM Token từ thiết bị
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('❌ Không lấy được FCM Token');
        return;
      }

      // 3. Xin quyền và lấy Tọa độ GPS (Location)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Dịch vụ vị trí bị tắt.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Quyền vị trí bị từ chối.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Quyền vị trí bị từ chối vĩnh viễn.');
        return;
      }

      // Lấy tọa độ hiện tại với độ chính xác cao
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // 4. Lấy múi giờ (Timezone)
      String timezone = DateTime.now().timeZoneName;

      // 5. Gửi dữ liệu qua API POST /api/v1/users/device
      final ApiService apiService = ApiService();
      await apiService.dio.post(
          '/users/device', // Nhớ kiểm tra lại router bên Node.js có khớp không
          data: {
            "fcm_token": fcmToken,
            "lat": position.latitude,
            "long": position.longitude,
            "timezone": timezone
          }
      );

      print('✅ Đồng bộ FCM Token và Location lên Backend thành công!');

    } catch (e) {
      print('❌ Lỗi đồng bộ dữ liệu thiết bị: $e');
    }
  }
}