class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? description;
  final bool isCustom;
  final String? distanceKm;
  final String? province;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.description,
    this.isCustom = false,
    this.distanceKm,
    this.province,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json, {bool isCustom = false}) {
    return EmergencyContact(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      phone: json['phone_number'] ?? json['phone'] ?? '',
      description: json['relation'] ?? json['description'],
      isCustom: isCustom,
      distanceKm: json['distance_km']?.toString(),
      province: json['province'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'description': description,
    'isCustom': isCustom,
    'distance_km': distanceKm,
    'province': province,
  };
}