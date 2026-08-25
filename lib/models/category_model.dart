import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryType {
  expense,
  income,
  both;

  String toMap() => name;

  static CategoryType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return CategoryType.income;
      case 'both':
        return CategoryType.both;
      case 'expense':
      default:
        return CategoryType.expense;
    }
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final CategoryType type;
  final bool isDefault;
  final DateTime? createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.type,
    this.isDefault = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
      'type': type.toMap(),
      'isDefault': isDefault,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    }

    return CategoryModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      iconName: map['iconName'] ?? 'category',
      colorHex: map['colorHex'] ?? '#8E4E00',
      type: CategoryType.fromString(map['type'] ?? 'expense'),
      isDefault: map['isDefault'] ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel.fromMap(data, doc.id);
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    CategoryType? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
