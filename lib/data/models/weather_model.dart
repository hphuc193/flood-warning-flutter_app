class WeatherModel {
  final double temp;
  final int humidity;
  final String description;
  final String iconUrl;
  final double windSpeed;
  final String city;

  WeatherModel({
    required this.temp,
    required this.humidity,
    required this.description,
    required this.iconUrl,
    required this.windSpeed,
    required this.city,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      // Xử lý an toàn cho kiểu số (int/double)
      temp: (json['temp'] as num).toDouble(),
      humidity: json['humidity'] as int,
      description: json['description'] ?? '',
      iconUrl: json['icon'] ?? '',
      windSpeed: (json['wind_speed'] as num).toDouble(),
      city: json['city'] ?? 'Unknown',
    );
  }
}