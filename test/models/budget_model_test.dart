import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/budget_model.dart';
import 'package:Weasly/models/transaction_model.dart';

void main() {
  group('BudgetModel Tests', () {
    test('BudgetModel defaults isAlertEnabled to true and alertThreshold to 80.0', () {
      final budget = BudgetModel(
        id: 'budget_1',
        categoryId: 'cat_food',
        categoryName: 'Foods & Drinks',
        categoryIcon: 'restaurant',
        categoryColorHex: '#D9553A',
        amount: 5000.0,
        periodType: BudgetPeriodType.monthly,
        startDate: DateTime(2026, 8, 1),
      );

      expect(budget.isAlertEnabled, isTrue);
      expect(budget.alertThreshold, 80.0);
    });

    test('BudgetModel toMap and fromMap serialize alert settings correctly', () {
      final budget = BudgetModel(
        id: 'budget_test',
        categoryId: 'cat_shopping',
        categoryName: 'Shopping',
        categoryIcon: 'shopping_bag',
        categoryColorHex: '#D94A6E',
        amount: 3000.0,
        periodType: BudgetPeriodType.weekly,
        startDate: DateTime(2026, 8, 1),
        isAlertEnabled: false,
        alertThreshold: 75.0,
      );

      final map = budget.toMap();
      expect(map['isAlertEnabled'], isFalse);
      expect(map['alertThreshold'], 75.0);

      final restored = BudgetModel.fromMap(map, 'budget_test');
      expect(restored.isAlertEnabled, isFalse);
      expect(restored.alertThreshold, 75.0);
      expect(restored.categoryName, 'Shopping');
      expect(restored.amount, 3000.0);
    });

    test('isDuplicateCategory detects duplicate budgets by categoryId or categoryName', () {
      final existing = [
        BudgetModel(
          id: 'b1',
          categoryId: 'cat_bills',
          categoryName: 'Bills & Utilities',
          categoryIcon: 'receipt',
          categoryColorHex: '#E08B03',
          amount: 4500.0,
          periodType: BudgetPeriodType.monthly,
          startDate: DateTime.now(),
        ),
      ];

      expect(BudgetModel.isDuplicateCategory('cat_bills', 'Bills & Utilities', existing), isTrue);
      expect(BudgetModel.isDuplicateCategory('cat_other', 'bills & utilities', existing), isTrue);
      expect(BudgetModel.isDuplicateCategory('cat_food', 'Foods & Drinks', existing), isFalse);
      expect(
        BudgetModel.isDuplicateCategory('cat_bills', 'Bills & Utilities', existing, excludeBudgetId: 'b1'),
        isFalse,
      );
      expect(BudgetModel.isDuplicateCategory('other_id', 'Food & Dining', [
        BudgetModel(
          id: 'b2',
          categoryId: 'food_dining',
          categoryName: 'Foods & Drinks',
          categoryIcon: 'restaurant',
          categoryColorHex: '#FB7140',
          amount: 700.0,
          periodType: BudgetPeriodType.monthly,
          startDate: DateTime.now(),
        ),
      ]), isTrue);
    });

    test('matchesTransactionCategory matches exact ID and falls back to sanitized category name for expenses', () {
      final budget = BudgetModel(
        id: 'budget_food',
        categoryId: 'food_dining',
        categoryName: 'Foods & Drinks',
        categoryIcon: 'restaurant',
        categoryColorHex: '#FB7140',
        amount: 700.0,
        periodType: BudgetPeriodType.monthly,
        startDate: DateTime(2026, 11, 1),
      );

      final exactMatchTx = TransactionModel(
        id: 'tx1',
        type: TransactionType.expense,
        amount: 105.0,
        categoryId: 'food_dining',
        categoryName: 'Foods & Drinks',
        categoryIcon: 'restaurant',
        categoryColorHex: '#FB7140',
        accountId: 'acc1',
        accountName: 'Cash',
        date: DateTime(2026, 11, 25),
      );

      final mismatchedIdSameNameTx = exactMatchTx.copyWith(
        id: 'tx2',
        categoryId: 'legacy_custom_food_id',
        categoryName: 'Food & Dining',
      );

      final mismatchedIdIncomeTx = exactMatchTx.copyWith(
        id: 'tx3',
        type: TransactionType.income,
        categoryId: 'other_id',
        categoryName: 'Foods & Drinks',
      );

      final differentCategoryTx = exactMatchTx.copyWith(
        id: 'tx4',
        categoryId: 'transportation',
        categoryName: 'Transportation',
      );

      expect(budget.matchesTransactionCategory(exactMatchTx), isTrue);
      expect(budget.matchesTransactionCategory(mismatchedIdSameNameTx), isTrue);
      expect(budget.matchesTransactionCategory(mismatchedIdIncomeTx), isFalse);
      expect(budget.matchesTransactionCategory(differentCategoryTx), isFalse);
    });

    test('getEffectivePeriodRange normalizes custom range to cover full start and end days', () {
      final budget = BudgetModel(
        id: 'budget_custom',
        categoryId: 'food_dining',
        categoryName: 'Foods & Drinks',
        categoryIcon: 'restaurant',
        categoryColorHex: '#FB7140',
        amount: 700.0,
        periodType: BudgetPeriodType.custom,
        startDate: DateTime(2026, 11, 1, 15, 30),
        endDate: DateTime(2026, 11, 27, 0, 0),
      );

      final (start, end) = budget.getEffectivePeriodRange();
      expect(start, equals(DateTime(2026, 11, 1, 0, 0, 0, 0)));
      expect(end, equals(DateTime(2026, 11, 27, 23, 59, 59, 999)));
    });
  });
}
