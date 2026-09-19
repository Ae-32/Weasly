import 'package:intl/intl.dart';
import '../models/financial_stats_model.dart';
import '../models/transaction_model.dart';
import '../utils/default_categories.dart';

enum StatsTimeRange {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  yearToDate,
  allTime;

  String get label {
    switch (this) {
      case StatsTimeRange.thisMonth:
        return 'This Month';
      case StatsTimeRange.lastMonth:
        return 'Last Month';
      case StatsTimeRange.last3Months:
        return '3 Months';
      case StatsTimeRange.last6Months:
        return '6 Months';
      case StatsTimeRange.yearToDate:
        return 'Year to Date';
      case StatsTimeRange.allTime:
        return 'All Time';
    }
  }
}

class StatisticsCalculator {
  /// Filters transactions based on the selected time range relative to a reference date.
  static List<TransactionModel> filterTransactions(
    List<TransactionModel> transactions,
    StatsTimeRange timeRange, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    return transactions.where((tx) {
      final txDate = tx.date;
      switch (timeRange) {
        case StatsTimeRange.thisMonth:
          return txDate.year == now.year && txDate.month == now.month;

        case StatsTimeRange.lastMonth:
          final lastMonthDate = DateTime(now.year, now.month - 1, 1);
          return txDate.year == lastMonthDate.year && txDate.month == lastMonthDate.month;

        case StatsTimeRange.last3Months:
          final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
          final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          return txDate.isAfter(threeMonthsAgo.subtract(const Duration(seconds: 1))) &&
              txDate.isBefore(endOfCurrentMonth);

        case StatsTimeRange.last6Months:
          final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
          final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          return txDate.isAfter(sixMonthsAgo.subtract(const Duration(seconds: 1))) &&
              txDate.isBefore(endOfCurrentMonth);

        case StatsTimeRange.yearToDate:
          return txDate.year == now.year && txDate.isBefore(now.add(const Duration(days: 1)));

        case StatsTimeRange.allTime:
          return true;
      }
    }).toList();
  }

  /// Calculates complete financial statistics from a given list of transactions.
  static FinancialStatsModel computeStats(
    List<TransactionModel> transactions,
    StatsTimeRange timeRange, {
    DateTime? referenceDate,
  }) {
    final filtered = filterTransactions(transactions, timeRange, referenceDate: referenceDate);

    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final tx in filtered) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    final netCashFlow = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100).clamp(0.0, 100.0) : 0.0;

    // 1. Category Breakdown
    final Map<String, ({String name, String icon, String colorHex, double total})> categoryMap = {};

    for (final tx in filtered) {
      if (tx.type == TransactionType.expense) {
        final key = tx.categoryId.isNotEmpty ? tx.categoryId : tx.categoryName;
        if (categoryMap.containsKey(key)) {
          final curr = categoryMap[key]!;
          categoryMap[key] = (
            name: curr.name,
            icon: curr.icon,
            colorHex: curr.colorHex,
            total: curr.total + tx.amount,
          );
        } else {
          categoryMap[key] = (
            name: tx.categoryName,
            icon: tx.categoryIcon,
            colorHex: tx.categoryColorHex,
            total: tx.amount,
          );
        }
      }
    }

    final List<CategoryStatItem> categoryBreakdown = [];
    categoryMap.forEach((id, data) {
      final pct = totalExpense > 0 ? (data.total / totalExpense) * 100 : 0.0;
      final color = DefaultCategories.getCategoryColorByName(data.name, data.colorHex);

      categoryBreakdown.add(CategoryStatItem(
        categoryId: id,
        categoryName: data.name,
        iconName: data.icon,
        colorHex: data.colorHex,
        color: color,
        amount: data.total,
        percentage: pct,
      ));
    });

    categoryBreakdown.sort((a, b) => b.amount.compareTo(a.amount));
    final topCategory = categoryBreakdown.isNotEmpty ? categoryBreakdown.first : null;

    // 2. Monthly Trends (Cash Flow Points)
    final monthlyTrends = _computeMonthlyTrends(filtered, timeRange, referenceDate: referenceDate);

    // 3. Day of Week Spending Behavior
    final dayOfWeekSpending = _computeDayOfWeekSpending(filtered);

    return FinancialStatsModel(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashFlow: netCashFlow,
      savingsRate: savingsRate,
      topSpendingCategory: topCategory,
      categoryBreakdown: categoryBreakdown,
      monthlyTrends: monthlyTrends,
      dayOfWeekSpending: dayOfWeekSpending,
      totalTransactionCount: filtered.length,
    );
  }

  static List<MonthlyCashFlowPoint> _computeMonthlyTrends(
    List<TransactionModel> transactions,
    StatsTimeRange timeRange, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    int monthCount = 6;

    if (timeRange == StatsTimeRange.last3Months) {
      monthCount = 3;
    } else if (timeRange == StatsTimeRange.thisMonth || timeRange == StatsTimeRange.lastMonth) {
      monthCount = 4; // Show surrounding 4 months for context line chart
    } else if (timeRange == StatsTimeRange.yearToDate) {
      monthCount = now.month;
    } else if (timeRange == StatsTimeRange.last6Months) {
      monthCount = 6;
    } else {
      monthCount = 6;
    }

    final List<MonthlyCashFlowPoint> points = [];

    for (int i = monthCount - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthLabel = DateFormat('MMM').format(targetDate);

      double inc = 0.0;
      double exp = 0.0;

      for (final tx in transactions) {
        if (tx.date.year == targetDate.year && tx.date.month == targetDate.month) {
          if (tx.type == TransactionType.income) {
            inc += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            exp += tx.amount;
          }
        }
      }

      points.add(MonthlyCashFlowPoint(
        monthLabel: monthLabel,
        yearMonth: targetDate,
        income: inc,
        expense: exp,
      ));
    }

    return points;
  }

  static List<DayOfWeekStat> _computeDayOfWeekSpending(List<TransactionModel> transactions) {
    // Weekday 1 (Mon) to 7 (Sun)
    final Map<int, double> dayTotals = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0};

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final day = tx.date.weekday;
        dayTotals[day] = (dayTotals[day] ?? 0.0) + tx.amount;
      }
    }

    const dayLabels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    return List.generate(7, (index) {
      final weekday = index + 1;
      return DayOfWeekStat(
        dayName: dayLabels[weekday]!,
        weekday: weekday,
        totalExpense: dayTotals[weekday] ?? 0.0,
      );
    });
  }
}
