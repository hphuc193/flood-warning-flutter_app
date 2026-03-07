class SavedLocationModel {
  final int? id; // ID có thể null khi mới tạo ở client chưa gửi lên server
  final int? userId;
  final String name;
  final double lat;
  final double long;
  final double radius; // Bán kính 1-10km
  final String priority; // high, medium, low
  final bool isActive; // Bật/tắt thông báo

  SavedLocationModel({
    this.id,
    this.userId,
    required this.name,
    required this.lat,
    required this.long,
    this.radius = 5.0, // Mặc định 5km
    this.priority = 'medium',
    this.isActive = true,
  });

  factory SavedLocationModel.fromJson(Map<String, dynamic> json) {
    return SavedLocationModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? 'Vị trí không tên',
      lat: (json['lat'] ?? 0).toDouble(),
      long: (json['long'] ?? 0).toDouble(),
      radius: (json['radius'] ?? 5).toDouble(),
      priority: json['priority'] ?? 'medium',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "lat": lat,
      "long": long,
      "radius": radius,
      "priority": priority,
      "is_active": isActive,
    };
  }
}