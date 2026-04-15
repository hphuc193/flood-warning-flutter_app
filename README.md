# 🌊 Flood Warning System (FWS) - Mobile App

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Flood Warning System (FWS)** là ứng dụng di động thông minh hỗ trợ cảnh báo ngập lụt sớm dựa trên dữ liệu thời tiết thực tế và Trí tuệ Nhân tạo (AI). Ứng dụng giúp người dùng theo dõi tình hình thời tiết, dự báo rủi ro ngập lụt theo giờ, báo cáo các điểm ngập cục bộ và trang bị các kỹ năng ứng phó khẩn cấp.

> **Lưu ý:** Đây là mã nguồn phân hệ Mobile (Flutter) thuộc Đồ án Khóa luận Tốt nghiệp ngành Kỹ thuật Phần mềm.

---

## ✨ Tính năng nổi bật

### 🔐 1. Xác thực & Phân quyền (Authentication)
* Đăng nhập/Đăng ký tài khoản hệ thống (JWT Token).
* **Social Login:** Tích hợp đăng nhập nhanh qua **Google** và **Facebook** (OAuth2) bảo mật, chống trùng lặp tài khoản.
* Tự động gia hạn và duy trì phiên đăng nhập (Auto-login).

### 📊 2. Tổng quan & Dự báo (Dashboard & AI Forecast)
* **Chỉ số thời tiết Real-time:** Nhiệt độ, sức gió, độ ẩm, và chỉ số Tia UV (Open-Meteo API).
* **AI Flood Prediction:** Tích hợp mô hình AI dự báo rủi ro ngập lụt 24h tới. Biểu đồ trực quan tự động co giãn hiển thị đỉnh lũ và mức nước dự kiến.
* **Dự báo 5 ngày tới:** Tóm tắt tình hình thời tiết các ngày tiếp theo.
* **Bản đồ nhiệt (Heatmap):** Trực quan hóa lịch sử lượng mưa 30 ngày.

### 🗺️ 3. Báo cáo & Cộng đồng (Community Reports)
* Cho phép người dùng báo cáo các điểm ngập lụt (kèm hình ảnh, định vị GPS, mức độ nghiêm trọng).
* Hệ thống Upvote/Downvote xác thực thông tin từ cộng đồng.

### 🛡️ 4. Công cụ ứng phó khẩn cấp (Emergency Tools)
* Checklist chuẩn bị ứng phó bão lũ.
* Hướng dẫn sơ tán an toàn.
* Danh bạ khẩn cấp (Emergency Contacts).
* Cài đặt và kích hoạt tin nhắn SOS nhanh.

### 🔔 5. Push Notification (FCM)
* Đồng bộ Device Token (FCM) và vị trí người dùng lên Server.
* Nhận thông báo bản tin thời tiết tự động hằng ngày (CronJob) và cảnh báo lũ khẩn cấp.

---

## 🛠 Công nghệ & Thư viện sử dụng (Tech Stack)

* **Framework:** Flutter (Dart)
* **State Management:** `provider`
* **Network/API:** `dio` (kết hợp Interceptor tự động gắn Token)
* **Local Storage:** `flutter_secure_storage`, `shared_preferences`
* **Biểu đồ & UI:** `fl_chart`, `Maps_flutter`, Animation mượt mà.
* **Social Auth:** `firebase_auth`, `google_sign_in`, `facebook_auth`
* **Định vị & Thông báo:** `geolocator`, `firebase_messaging`
* **Bảo mật cấu hình:** `flutter_dotenv`

---

## 📂 Cấu trúc thư mục (Architecture)

Dự án áp dụng mô hình thiết kế chuẩn phân lớp, dễ dàng mở rộng:

```text
lib/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── providers/
├── ui/
│   ├── screens/
│   │   ├── alert/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── profile/
│   │   ├── weather/
│   │   ├── checklist_screen.dart
│   │   ├── emergency_contacts_screen.dart
│   │   ├── evacuation_guide_screen.dart
│   │   ├── sos_setup_screen.dart
│   │   └── splash_screen.dart
│   └── widgets/
└── main.dart
```

Chi tiết các phân hệ:

* `data/models/`: Các lớp mô hình hóa dữ liệu (User, Weather,...).
* `data/repositories/`: Logic giao tiếp API (AuthRepo, WeatherRepo,...).
* `data/services/`: Cấu hình core API (Dio), Notification, Location.
* `providers/`: Quản lý trạng thái (State Management) toàn ứng dụng.
* `ui/screens/alert/`: Màn hình cảnh báo và thông báo lũ lụt.
* `ui/screens/auth/`: Giao diện đăng nhập, đăng ký.
* `ui/screens/home/`: Giao diện Dashboard, bản đồ, báo cáo cộng đồng.
* `ui/screens/profile/`: Quản lý hồ sơ người dùng.
* `ui/screens/weather/`: Chi tiết thời tiết và bản đồ nhiệt.
* `ui/screens/checklist_screen.dart`: Checklist chuẩn bị ứng phó bão lũ.
* `ui/screens/emergency_contacts_screen.dart`: Danh bạ khẩn cấp.
* `ui/screens/evacuation_guide_screen.dart`: Hướng dẫn sơ tán an toàn.
* `ui/screens/sos_setup_screen.dart`: Cài đặt và kích hoạt tin nhắn SOS.
* `ui/screens/splash_screen.dart`: Màn hình khởi động (Splash Screen).
* `ui/widgets/`: Các widget dùng chung toàn ứng dụng.
* `main.dart`: Điểm khởi chạy (Entry point) của ứng dụng.

---

## 🚀 Hướng dẫn cài đặt & Khởi chạy (Getting Started)

### 1. Yêu cầu hệ thống (Prerequisites)
* Flutter SDK (v3.19.x hoặc mới nhất)
* Android Studio / VS Code
* Android SDK 36 (Yêu cầu bắt buộc từ thư viện Facebook Auth).

### 2. Clone mã nguồn

```bash
git clone https://github.com/your-username/flood_warning_mobile_v1.git
cd flood_warning_mobile_v1
```

### 3. Cài đặt các thư viện (Dependencies)

```bash
flutter pub get
```

### 4. Cấu hình biến môi trường và bảo mật (Quan trọng)

Bạn cần thiết lập 2 file sau để ứng dụng có thể hoạt động:

**a. Cấu hình `.env` (Biến môi trường API)**

Tạo file `.env` ở thư mục gốc. Copy nội dung từ `.env.example` và thay đổi domain Backend:

```
BASE_URL=http://YOUR_LOCAL_IP:3000/api/v1
```

**b. Cấu hình `secrets.xml` (Bảo mật Facebook OAuth)**

Vào thư mục: `android/app/src/main/res/values/`

Tạo file `secrets.xml` (file này cần đưa vào `.gitignore`):

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_APP_ID</string>
    <string name="facebook_client_token">YOUR_TOKEN</string>
    <string name="fb_login_protocol_scheme">fbYOUR_APP_ID</string>
</resources>
```

### 5. Kết nối Firebase

Đảm bảo bạn đã thêm file `google-services.json` vào thư mục `android/app/` (File này không được đưa lên Git).

### 6. Chạy ứng dụng

Kết nối thiết bị thật hoặc máy ảo (Emulator) và chạy lệnh:

```bash
flutter run
```

---

## 👨‍💻 Tác giả (Author)

* **Sinh viên thực hiện:** Lê Công Hoàng Phúc
* **Ngành:** Kỹ thuật Phần mềm (Software Engineering)
* **Trường:** Đại học Quản lý và Công nghệ TP.HCM (UMT)
* **Giảng viên Hướng dẫn:** ThS. Nguyễn Lê Hoàng Dũng