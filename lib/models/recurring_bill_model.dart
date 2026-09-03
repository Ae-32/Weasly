import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/default_categories.dart';

enum BillFrequency {
  weekly,
  monthly,
  yearly;

  String toMap() => name;

  String get displayName {
    switch (this) {
      case BillFrequency.weekly:
        return 'Weekly';
      case BillFrequency.monthly:
        return 'Monthly';
      case BillFrequency.yearly:
        return 'Yearly';
    }
  }

  static BillFrequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return BillFrequency.weekly;
      case 'yearly':
        return BillFrequency.yearly;
      case 'monthly':
      default:
        return BillFrequency.monthly;
    }
  }
}

class RecurringBillModel {
  final String id;
  final String name;
  final double amount;
  final BillFrequency frequency;
  final DateTime nextDueDate;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final String accountId;
  final String accountName;
  final int reminderDaysBefore;
  final bool isReminderEnabled;
  final DateTime? createdAt;

  const RecurringBillModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.accountId,
    required this.accountName,
    this.reminderDaysBefore = 1,
    this.isReminderEnabled = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'frequency': frequency.toMap(),
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColorHex': categoryColorHex,
      'accountId': accountId,
      'accountName': accountName,
      'reminderDaysBefore': reminderDaysBefore,
      'isReminderEnabled': isReminderEnabled,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory RecurringBillModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDueDate = DateTime.now();
    if (map['nextDueDate'] is Timestamp) {
      parsedDueDate = (map['nextDueDate'] as Timestamp).toDate();
    } else if (map['nextDueDate'] is String) {
      parsedDueDate = DateTime.tryParse(map['nextDueDate']) ?? DateTime.now();
    }

    DateTime? parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    }

    return RecurringBillModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: BillFrequency.fromString(map['frequency'] ?? 'monthly'),
      nextDueDate: parsedDueDate,
      categoryId: map['categoryId'] ?? '',
      categoryName: DefaultCategories.sanitizeCategoryName(map['categoryName'] ?? 'Bills & Utilities'),
      categoryIcon: map['categoryIcon'] ?? 'receipt_long',
      categoryColorHex: map['categoryColorHex'] ?? '#8E4E00',
      accountId: map['accountId'] ?? '',
      accountName: map['accountName'] ?? 'Main Account',
      reminderDaysBefore: map['reminderDaysBefore'] ?? 1,
      isReminderEnabled: map['isReminderEnabled'] ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  factory RecurringBillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RecurringBillModel.fromMap(data, doc.id);
  }

  RecurringBillModel copyWith({
    String? id,
    String? name,
    double? amount,
    BillFrequency? frequency,
    DateTime? nextDueDate,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColorHex,
    String? accountId,
    String? accountName,
    int? reminderDaysBefore,
    bool? isReminderEnabled,
    DateTime? createdAt,
  }) {
    return RecurringBillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculates the next due date after advancing one period cycle.
  DateTime calculateNextDueDate() {
    switch (frequency) {
      case BillFrequency.weekly:
        return nextDueDate.add(const Duration(days: 7));
      case BillFrequency.monthly:
        // Add 1 month preserving day of month where possible
        final year = nextDueDate.month == 12 ? nextDueDate.year + 1 : nextDueDate.year;
        final month = nextDueDate.month == 12 ? 1 : nextDueDate.month + 1;
        final lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
        final day = nextDueDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : nextDueDate.day;
        return DateTime(year, month, day, nextDueDate.hour, nextDueDate.minute);
      case BillFrequency.yearly:
        final year = nextDueDate.year + 1;
        final month = nextDueDate.month;
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = nextDueDate.day > lastDay ? lastDay : nextDueDate.day;
        return DateTime(year, month, day, nextDueDate.hour, nextDueDate.minute);
    }
  }

  /// Calculates days remaining until the next due date.
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return dueDateOnly.difference(today).inDays;
  }

  /// Returns true if the next due date has already passed.
  bool get isOverdue => daysUntilDue < 0;
}

