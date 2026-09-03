import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/default_categories.dart';

enum TransactionType {
  expense,
  income,
  transfer;

  String toMap() => name;

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final String accountId;
  final String accountName;
  final String? toAccountId;
  final String? toAccountName;
  final DateTime date;
  final String? note;
  final DateTime? createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.accountId,
    required this.accountName,
    this.toAccountId,
    this.toAccountName,
    required this.date,
    this.note,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toMap(),
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColorHex': categoryColorHex,
      'accountId': accountId,
      'accountName': accountName,
      'toAccountId': toAccountId,
      'toAccountName': toAccountName,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date']) ?? DateTime.now();
    }

    DateTime? parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    }

    return TransactionModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      type: TransactionType.fromString(map['type'] ?? 'expense'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] ?? '',
      categoryName: DefaultCategories.sanitizeCategoryName(map['categoryName'] ?? 'Uncategorized'),
      categoryIcon: map['categoryIcon'] ?? 'category',
      categoryColorHex: map['categoryColorHex'] ?? '#8E4E00',
      accountId: map['accountId'] ?? '',
      accountName: map['accountName'] ?? 'Account',
      toAccountId: map['toAccountId'],
      toAccountName: map['toAccountName'],
      date: parsedDate,
      note: map['note'],
      createdAt: parsedCreatedAt,
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionModel.fromMap(data, doc.id);
  }

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColorHex,
    String? accountId,
    String? accountName,
    String? toAccountId,
    String? toAccountName,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      toAccountId: toAccountId ?? this.toAccountId,
      toAccountName: toAccountName ?? this.toAccountName,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
