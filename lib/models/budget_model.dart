import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/default_categories.dart';

enum BudgetPeriodType {
  weekly,
  monthly,
  custom;

  String toMap() => name;

  static BudgetPeriodType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return BudgetPeriodType.weekly;
      case 'custom':
        return BudgetPeriodType.custom;
      case 'monthly':
      default:
        return BudgetPeriodType.monthly;
    }
  }
}

class BudgetModel {
  final String id;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final double amount;
  final BudgetPeriodType periodType;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final bool isAlertEnabled;
  final double alertThreshold;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.amount,
    required this.periodType,
    required this.startDate,
    this.endDate,
    this.createdAt,
    this.isAlertEnabled = true,
    this.alertThreshold = 80.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColorHex': categoryColorHex,
      'amount': amount,
      'periodType': periodType.toMap(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'isAlertEnabled': isAlertEnabled,
      'alertThreshold': alertThreshold,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedStartDate = DateTime.now();
    if (map['startDate'] is Timestamp) {
      parsedStartDate = (map['startDate'] as Timestamp).toDate();
    } else if (map['startDate'] is String) {
      parsedStartDate = DateTime.tryParse(map['startDate']) ?? DateTime.now();
    }

    DateTime? parsedEndDate;
    if (map['endDate'] is Timestamp) {
      parsedEndDate = (map['endDate'] as Timestamp).toDate();
    } else if (map['endDate'] is String) {
      parsedEndDate = DateTime.tryParse(map['endDate']);
    }

    DateTime? parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    }

    return BudgetModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      categoryId: map['categoryId'] ?? '',
      categoryName: DefaultCategories.sanitizeCategoryName(map['categoryName'] ?? 'Category'),
      categoryIcon: map['categoryIcon'] ?? 'shopping_cart',
      categoryColorHex: map['categoryColorHex'] ?? '#D9553A',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      periodType: BudgetPeriodType.fromString(map['periodType'] ?? 'monthly'),
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      createdAt: parsedCreatedAt,
      isAlertEnabled: map['isAlertEnabled'] as bool? ?? true,
      alertThreshold: (map['alertThreshold'] as num?)?.toDouble() ?? 80.0,
    );
  }

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BudgetModel.fromMap(data, doc.id);
  }

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColorHex,
    double? amount,
    BudgetPeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    bool? isAlertEnabled,
    double? alertThreshold,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      amount: amount ?? this.amount,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      isAlertEnabled: isAlertEnabled ?? this.isAlertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }

  /// Calculates the active start and end DateTime range for computing live transaction spending.
  (DateTime, DateTime) getEffectivePeriodRange([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();

    switch (periodType) {
      case BudgetPeriodType.weekly:
        // Week starting Monday 00:00:00 to Sunday 23:59:59.999
        final weekday = ref.weekday; // 1 = Mon, 7 = Sun
        final start = DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        return (start, end);

      case BudgetPeriodType.monthly:
        // Month starting 1st 00:00:00 to last day 23:59:59.999
        final start = DateTime(ref.year, ref.month, 1);
        final nextMonth = DateTime(ref.year, ref.month + 1, 1);
        final end = nextMonth.subtract(const Duration(milliseconds: 1));
        return (start, end);

      case BudgetPeriodType.custom:
        final start = startDate;
        final end = endDate ?? DateTime(ref.year, ref.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return (start, end);
    }
  }

  /// Checks if a budget for the given category already exists among existing budgets.
  static bool isDuplicateCategory(
    String categoryId,
    String categoryName,
    List<BudgetModel> existingBudgets, {
    String? excludeBudgetId,
  }) {
    final lowerName = categoryName.trim().toLowerCase();
    return existingBudgets.any((budget) {
      if (excludeBudgetId != null && budget.id == excludeBudgetId) {
        return false;
      }
      return budget.categoryId == categoryId ||
          budget.categoryName.trim().toLowerCase() == lowerName;
    });
  }
}
