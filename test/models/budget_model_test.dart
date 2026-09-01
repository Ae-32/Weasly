import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/budget_model.dart';

void main() {
  group('BudgetModel Tests', () {
    test('BudgetModel defaults isAlertEnabled to true and alertThreshold to 80.0', () {
      final budget = BudgetModel(
        id: 'budget_1',
        categoryId: 'cat_food',
        categoryName: 'Food & Dining',
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
  });
}
