# 🌊 Flood Warning System (FWS) - Mobile App

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Flood Warning System (FWS)** is an intelligent mobile application that provides early flood warnings based on real-time weather data and Artificial Intelligence (AI). The app helps users monitor weather conditions, predict hourly flood risks, report local flooding spots, and equip themselves with emergency response skills.

> **Note:** This is the source code for the Mobile subsystem (Flutter), part of a Software Engineering Graduation Thesis project.

---

## ✨ Key Features

### 🔐 1. Authentication & Authorization
* User registration and login with JWT Token.
* **Social Login:** Fast and secure login via **Google** and **Facebook** (OAuth2), with duplicate account prevention.
* Auto token refresh and session persistence (Auto-login).

### 📊 2. Dashboard & AI Forecast
* **Real-time Weather Metrics:** Temperature, wind speed, humidity, and UV Index (Open-Meteo API).
* **AI Flood Prediction:** Integrated AI model forecasting flood risk for the next 24 hours. Auto-scaling charts display expected flood peaks and water levels.
* **5-Day Forecast:** Summary of upcoming weather conditions for the next five days.
* **Heatmap:** Visual representation of 30-day rainfall history.

### 🗺️ 3. Community Reports
* Allows users to report flooding spots (with photos, GPS location, and severity level).
* Upvote/Downvote system for community-based information verification.

### 🛡️ 4. Emergency Tools
* Storm and flood preparedness checklist.
* Safe evacuation guidelines.
* Emergency Contacts directory.
* Quick SOS message setup and activation.

### 🔔 5. Push Notifications (FCM)
* Syncs Device Token (FCM) and user location to the server.
* Receives automated daily weather bulletins (CronJob) and emergency flood alerts.

---

## 🛠 Tech Stack

* **Framework:** Flutter (Dart)
* **State Management:** `provider`
* **Network/API:** `dio` (with automatic Token Interceptor)
* **Local Storage:** `flutter_secure_storage`, `shared_preferences`
* **Charts & UI:** `fl_chart`, `Maps_flutter`, smooth animations.
* **Social Auth:** `firebase_auth`, `google_sign_in`, `facebook_auth`
* **Location & Notifications:** `geolocator`, `firebase_messaging`
* **Config Security:** `flutter_dotenv`

---

## 📂 Project Structure (Architecture)

The project follows a standard layered architecture for easy scalability:

```text
lib/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── providers/
├── screens/
│   ├── auth/
│   ├── home/
│   └── profile/
├── utils/
└── main.dart
```

Layer details:

* `data/models/`: Data model classes (User, Weather, etc.).
* `data/repositories/`: API communication logic (AuthRepo, WeatherRepo, etc.).
* `data/services/`: Core API configuration (Dio), Notification, and Location services.
* `providers/`: App-wide State Management.
* `screens/auth/`: Login and registration screens.
* `screens/home/`: Dashboard, map, and community report screens.
* `screens/profile/`: Profile management, Checklist, SOS, and emergency contacts.
* `utils/`: Shared utility functions (date formatting, colors, etc.).
* `main.dart`: Application entry point.

---

## 🚀 Getting Started

### 1. Prerequisites
* Flutter SDK (v3.19.x or later)
* Android Studio / VS Code
* Android SDK 36 (required by the Facebook Auth library).

### 2. Clone the Repository

```bash
git clone https://github.com/your-username/flood_warning_mobile_v1.git
cd flood_warning_mobile_v1
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Environment & Security Configuration (Important)

You need to set up the following 2 files for the app to run correctly:

**a. Configure `.env` (API Environment Variables)**

Create a `.env` file in the root directory. Copy the content from `.env.example` and update the backend domain:

```
BASE_URL=http://YOUR_LOCAL_IP:3000/api/v1
```

**b. Configure `secrets.xml` (Facebook OAuth Security)**

Navigate to: `android/app/src/main/res/values/`

Create a `secrets.xml` file (this file should be added to `.gitignore`):

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_APP_ID</string>
    <string name="facebook_client_token">YOUR_TOKEN</string>
    <string name="fb_login_protocol_scheme">fbYOUR_APP_ID</string>
</resources>
```

### 5. Connect Firebase

Make sure you have added the `google-services.json` file to the `android/app/` directory (this file must NOT be committed to Git).

### 6. Run the App

Connect a physical device or emulator and run:

```bash
flutter run
```

---

## 👨‍💻 Author

* **Student:** Le Cong Hoang Phuc
* **Major:** Software Engineering
* **University:** University of Management and Technology Ho Chi Minh City (UMT)
* **Supervisor:** MSc. Nguyen Le Hoang Dung