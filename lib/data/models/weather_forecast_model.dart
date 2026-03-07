class WeatherForecastModel {
  final bool success;
  final CityInfo? city;
  final List<WeatherItem> data;

  WeatherForecastModel({required this.success, this.city, required this.data});

  factory WeatherForecastModel.fromJson(Map<String, dynamic> json) {
    return WeatherForecastModel(
      success: json['success'] ?? false,
      city: json['city'] != null ? CityInfo.fromJson(json['city']) : null,
      data: json['data'] != null
          ? (json['data'] as List).map((i) => WeatherItem.fromJson(i)).toList()
          : [],
    );
  }

  // Hàm gom nhóm 40 mốc 3h thành từng ngày (Dùng cho màn hình chính)
  Map<String, List<WeatherItem>> groupDataByDate() {
    Map<String, List<WeatherItem>> groupedData = {};
    for (var item in data) {
      String date = item.dtTxt.substring(0, 10); // Lấy "YYYY-MM-DD"
      if (!groupedData.containsKey(date)) {
        groupedData[date] = [];
      }
      groupedData[date]!.add(item);
    }
    return groupedData;
  }
}

class CityInfo {
  final String name;
  final double lat;
  final double lon;
  CityInfo({required this.name, required this.lat, required this.lon});

  factory CityInfo.fromJson(Map<String, dynamic> json) {
    final coord = json['coord'] ?? {};
    return CityInfo(
      name: json['name'] ?? "",
      lat: (coord['lat'] ?? 0).toDouble(),
      lon: (coord['lon'] ?? 0).toDouble(),
    );
  }
}

class WeatherItem {
  final double temp;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final String description;
  final String icon;
  final double windSpeed;
  final int visibility;
  final double pop; // Xác suất có mưa (0 - 1)
  final String dtTxt; // "2026-03-04 12:00:00"

  WeatherItem({
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.visibility,
    required this.pop,
    required this.dtTxt,
  });

  factory WeatherItem.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List?)?.isNotEmpty == true ? json['weather'][0] : {};
    final wind = json['wind'] ?? {};

    return WeatherItem(
      temp: (main['temp'] ?? 0).toDouble(),
      tempMin: (main['temp_min'] ?? 0).toDouble(),
      tempMax: (main['temp_max'] ?? 0).toDouble(),
      humidity: main['humidity'] ?? 0,
      description: weather['description'] ?? "Không có thông tin",
      icon: weather['icon'] ?? "01d",
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      visibility: json['visibility'] ?? 0,
      pop: (json['pop'] ?? 0).toDouble(),
      dtTxt: json['dt_txt'] ?? "",
    );
  }

  // Link lấy icon chuẩn từ OpenWeather
  String get iconUrl => "https://openweathermap.org/img/wn/$icon@2x.png";
}