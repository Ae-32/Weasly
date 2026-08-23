import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a financial account (Cash, GCash, Bank, etc.) in Weasly.
class AccountModel {
  final String id;
  final String name;
  final String type; // 'cash', 'gcash', 'bank', 'savings', 'credit'
  final double balance;
  final String? note;
  final String? colorHex;
  final DateTime createdAt;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.note,
    this.colorHex,
    required this.createdAt,
  });

  /// Factory constructor to create an AccountModel from a Firestore document.
  factory AccountModel.fromMap(Map<String, dynamic> map, String docId) {
    return AccountModel(
      id: docId,
      name: map['name'] ?? 'Unnamed Account',
      type: map['type'] ?? 'cash',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      note: map['note'],
      colorHex: map['colorHex'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts AccountModel to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'note': note,
      'colorHex': colorHex,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copy method for creating updated instances.
  AccountModel copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? note,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      note: note ?? this.note,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
