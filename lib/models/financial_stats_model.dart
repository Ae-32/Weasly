import 'package:flutter/material.dart';

/// Represents spending breakdown for a single category.
class CategoryStatItem {
  final String categoryId;
  final String categoryName;
  final String iconName;
  final String colorHex;
  final Color color;
  final double amount;
  final double percentage;

  const CategoryStatItem({
    required this.categoryId,
    required this.categoryName,
    required this.iconName,
    required this.colorHex,
    required this.color,
    required this.amount,
    required this.percentage,
  });
}

/// Represents monthly data point for Cash Flow line chart.
class MonthlyCashFlowPoint {
  final String monthLabel; // e.g. "Jan", "Feb"
  final DateTime yearMonth;
  final double income;
  final double expense;

  const MonthlyCashFlowPoint({
    required this.monthLabel,
    required this.yearMonth,
    required this.income,
    required this.expense,
  });
}

/// Represents day of week spending metrics.
class DayOfWeekStat {
  final String dayName; // "Mon", "Tue", etc.
  final int weekday; // 1 to 7
  final double totalExpense;

  const DayOfWeekStat({
    required this.dayName,
    required this.weekday,
    required this.totalExpense,
  });
}

/// Comprehensive container model for financial statistics.
class FinancialStatsModel {
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double savingsRate; // Percentage 0-100%
  final CategoryStatItem? topSpendingCategory;
  final List<CategoryStatItem> categoryBreakdown;
  final List<MonthlyCashFlowPoint> monthlyTrends;
  final List<DayOfWeekStat> dayOfWeekSpending;
  final int totalTransactionCount;
  final double previousMonthExpense;
  final double monthOverMonthChangePct;
  final DateTime selectedMonth;

  const FinancialStatsModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.savingsRate,
    this.topSpendingCategory,
    required this.categoryBreakdown,
    required this.monthlyTrends,
    required this.dayOfWeekSpending,
    required this.totalTransactionCount,
    this.previousMonthExpense = 0.0,
    this.monthOverMonthChangePct = 0.0,
    required this.selectedMonth,
  });

  factory FinancialStatsModel.empty() {
    return FinancialStatsModel(
      totalIncome: 0.0,
      totalExpense: 0.0,
      netCashFlow: 0.0,
      savingsRate: 0.0,
      topSpendingCategory: null,
      categoryBreakdown: [],
      monthlyTrends: [],
      dayOfWeekSpending: [],
      totalTransactionCount: 0,
      previousMonthExpense: 0.0,
      monthOverMonthChangePct: 0.0,
      selectedMonth: DateTime.now(),
    );
  }
}
