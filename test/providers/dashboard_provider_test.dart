import 'package:flutter_test/flutter_test.dart';
import 'package:weasly/providers/dashboard_provider.dart';

void main() {
  group('DashboardProvider & Period Logic Tests', () {
    final refDate = DateTime(2026, 8, 18, 14, 0); // Tuesday, August 18, 2026

    test('isDateInDashboardPeriod correctly classifies Today', () {
      final sameDay = DateTime(2026, 8, 18, 9, 30);
      final diffDay = DateTime(2026, 8, 17, 23, 59);

      expect(isDateInDashboardPeriod(sameDay, DashboardPeriod.today, refDate), isTrue);
      expect(isDateInDashboardPeriod(diffDay, DashboardPeriod.today, refDate), isFalse);
    });

    test('isDateInDashboardPeriod correctly classifies Week (Monday to Sunday)', () {
      final monday = DateTime(2026, 8, 17, 8, 0);
      final sunday = DateTime(2026, 8, 23, 22, 0);
      final nextMonday = DateTime(2026, 8, 24, 8, 0);

      expect(isDateInDashboardPeriod(monday, DashboardPeriod.week, refDate), isTrue);
      expect(isDateInDashboardPeriod(sunday, DashboardPeriod.week, refDate), isTrue);
      expect(isDateInDashboardPeriod(nextMonday, DashboardPeriod.week, refDate), isFalse);
    });

    test('isDateInDashboardPeriod correctly classifies Month', () {
      final inMonth = DateTime(2026, 8, 1, 10, 0);
      final outMonth = DateTime(2026, 7, 31, 23, 59);

      expect(isDateInDashboardPeriod(inMonth, DashboardPeriod.month, refDate), isTrue);
      expect(isDateInDashboardPeriod(outMonth, DashboardPeriod.month, refDate), isFalse);
    });

    test('PeriodSummary calculates percentages correctly', () {
      const summary = PeriodSummary(
        totalIncome: 1000.0,
        totalExpense: 500.0,
        netCashFlow: 500.0,
      );

      expect(summary.totalFlow, 1500.0);
      expect(summary.incomePercentage, closeTo(66.67, 0.01));
      expect(summary.expensePercentage, closeTo(33.33, 0.01));
    });

    test('PeriodSummary handles zero flow gracefully', () {
      const emptySummary = PeriodSummary(
        totalIncome: 0.0,
        totalExpense: 0.0,
        netCashFlow: 0.0,
      );

      expect(emptySummary.totalFlow, 0.0);
      expect(emptySummary.incomePercentage, 0.0);
      expect(emptySummary.expensePercentage, 0.0);
    });
  });
}
