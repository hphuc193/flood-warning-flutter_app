class FloodReport {
  final int id;
  final double lat;
  final double long;
  final String description;
  final List<String> images;
  final String reporterName;
  final DateTime createdAt;

  final String status;
  int upvotes;
  int downvotes;
  String? currentUserVote;

  // === THÊM 2 TRƯỜNG NÀY ĐỂ FIX LỖI ===
  final String? category;
  final int? severity;
  // ====================================

  FloodReport({
    required this.id,
    required this.lat,
    required this.long,
    required this.description,
    required this.images,
    required this.reporterName,
    required this.createdAt,
    required this.status,
    this.upvotes = 0,
    this.downvotes = 0,
    this.currentUserVote,
    this.category, // Cập nhật constructor
    this.severity, // Cập nhật constructor
  });

  factory FloodReport.fromJson(Map<String, dynamic> json) {
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
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      reporterName: json['user']?['full_name'] ?? 'Ẩn danh',

      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at']).toLocal()
          : DateTime.now(),

      status: json['status'] ?? 'pending',
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      currentUserVote: json['current_user_vote'],

      // === MAP DỮ LIỆU TỪ JSON BACKEND TRẢ VỀ ===
      category: json['category'],
      severity: json['severity'] != null ? int.tryParse(json['severity'].toString()) : null,
      // ===========================================
    );
  }
}