import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/transaction_model.dart';
import 'package:Weasly/utils/statistics_calculator.dart';

void main() {
  group('StatisticsCalculator Tests', () {
    final now = DateTime(2026, 9, 15);

    final mockTransactions = [
      TransactionModel(
        id: '1',
        type: TransactionType.income,
        amount: 50000.0,
        categoryId: 'cat_salary',
        categoryName: 'Salary',
        categoryIcon: 'work',
        categoryColorHex: '#4CAF50',
        accountId: 'acc1',
        accountName: 'Bank',
        date: DateTime(2026, 9, 1),
      ),
      TransactionModel(
        id: '2',
        type: TransactionType.expense,
        amount: 12000.0,
        categoryId: 'cat_food',
        categoryName: 'Food & Dining',
        categoryIcon: 'restaurant',
        categoryColorHex: '#FF9800',
        accountId: 'acc1',
        accountName: 'Bank',
        date: DateTime(2026, 9, 5), // Friday (weekday 5)
      ),
      TransactionModel(
        id: '3',
        type: TransactionType.expense,
        amount: 8000.0,
        categoryId: 'cat_bills',
        categoryName: 'Utilities',
        categoryIcon: 'receipt',
        categoryColorHex: '#2196F3',
        accountId: 'acc1',
        accountName: 'Bank',
        date: DateTime(2026, 9, 10),
      ),
      TransactionModel(
        id: '4',
        type: TransactionType.expense,
        amount: 5000.0,
        categoryId: 'cat_food',
        categoryName: 'Food & Dining',
        categoryIcon: 'restaurant',
        categoryColorHex: '#FF9800',
        accountId: 'acc1',
        accountName: 'Bank',
        date: DateTime(2026, 8, 20), // Last Month
      ),
    ];

    test('filterTransactions returns correct count for This Month', () {
      final filtered = StatisticsCalculator.filterTransactions(
        mockTransactions,
        StatsTimeRange.thisMonth,
        referenceDate: now,
      );

      expect(filtered.length, 3);
    });

    test('computeStats calculates income, expense, and net cash flow correctly', () {
      final stats = StatisticsCalculator.computeStats(
        mockTransactions,
        StatsTimeRange.thisMonth,
        referenceDate: now,
      );

      expect(stats.totalIncome, 50000.0);
      expect(stats.totalExpense, 20000.0); // 12000 + 8000
      expect(stats.netCashFlow, 30000.0);
      expect(stats.savingsRate, closeTo(60.0, 0.1));
      expect(stats.topSpendingCategory?.categoryName, 'Food & Dining');
      expect(stats.topSpendingCategory?.amount, 12000.0);
    });

    test('computeStats handles empty transaction list gracefully', () {
      final stats = StatisticsCalculator.computeStats(
        [],
        StatsTimeRange.thisMonth,
        referenceDate: now,
      );

      expect(stats.totalIncome, 0.0);
      expect(stats.totalExpense, 0.0);
      expect(stats.netCashFlow, 0.0);
      expect(stats.savingsRate, 0.0);
      expect(stats.topSpendingCategory, null);
      expect(stats.categoryBreakdown, isEmpty);
    });
  });
}
