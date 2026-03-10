class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? description;
  final bool isCustom;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.description,
    this.isCustom = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json, {bool isCustom = false}) {
    return EmergencyContact(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      // Hỗ trợ cả 2 key đề phòng Backend trả về lộn xộn
      phone: json['phone_number'] ?? json['phone'] ?? '',
      description: json['relation'] ?? json['description'],
      isCustom: isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'description': description, 'isCustom': isCustom
  };
}