class FloodReport {
  final int id;
  final double lat;
  final double long;
  final String description;
  final List<String> images;
  final String reporterName;
  final DateTime createdAt;

  FloodReport({
    required this.id,
    required this.lat,
    required this.long,
    required this.description,
    required this.images,
    required this.reporterName,
    required this.createdAt,
  });

  factory FloodReport.fromJson(Map<String, dynamic> json) {
    // Xử lý parsing an toàn cho lat/long (đôi khi server trả về String)
    double parseDouble(dynamic value) {
      if (value is String) return double.parse(value);
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return FloodReport(
      id: json['id'] ?? 0,
      lat: parseDouble(json['lat']),
      long: parseDouble(json['long']),
      description: json['description'] ?? '',
      // Giả sử server trả về mảng link ảnh hoặc string
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      reporterName: json['user']?['full_name'] ?? 'Ẩn danh',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}