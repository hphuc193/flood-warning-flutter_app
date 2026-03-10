import 'dart:convert';

class ChecklistItem {
  final String id;
  final String title;
  final bool isImportant;

  ChecklistItem({required this.id, required this.title, this.isImportant = false});

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      title: json['title'],
      isImportant: json['is_important'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'is_important': isImportant};
}

class ChecklistCategory {
  final String category;
  final String categoryName;
  final List<ChecklistItem> items;

  ChecklistCategory({required this.category, required this.categoryName, required this.items});

  factory ChecklistCategory.fromJson(Map<String, dynamic> json) {
    return ChecklistCategory(
      category: json['category'],
      categoryName: json['category_name'],
      items: (json['items'] as List).map((e) => ChecklistItem.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'category_name': categoryName,
    'items': items.map((e) => e.toJson()).toList(),
  };
}