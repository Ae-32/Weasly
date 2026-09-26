import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/financial_stats_model.dart';
import '../../providers/statistics_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/statistics_calculator.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/weasly_app_header.dart';
import 'widgets/cash_flow_line_chart.dart';
import 'widgets/day_of_week_chart.dart';

/// Full Financial Statistics & Analytics Screen
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRange = ref.watch(statisticsTimeRangeProvider);
    final stats = ref.watch(financialStatisticsProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final currencyFormatterShort = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Top Header Bar (Logo Badge & Action Buttons)
            const WeaslyAppHeader(),

            // Scrollable Analytics Canvas Container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scrollable Page Title & Subtitle Section
                    Text(
                      'Analytics Overview',
                      style: GoogleFonts.quicksand(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF211A16),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Insights, trends, and spending patterns.',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8A7F73),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Range Filter Bar
                    _buildTimeRangePicker(ref, activeRange),
                    const SizedBox(height: 16),

                    // Top KPI Metric Cards Grid
                    _buildKpiMetricsGrid(stats, currencyFormatter),
                    const SizedBox(height: 16),

                    // Cash Flow Line Chart Card
                    _buildCardWrapper(
                      title: 'CASH FLOW TREND (INCOME VS EXPENSE)',
                      child: CashFlowLineChart(points: stats.monthlyTrends),
                    ),
                    const SizedBox(height: 16),

                    // Spending by Category Card
                    _buildCategorySpendingCard(stats, currencyFormatterShort),
                    const SizedBox(height: 16),

                    // Day of Week Behavior Card
                    _buildCardWrapper(
                      title: 'SPENDING BY DAY OF WEEK',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identifies which days you tend to spend the most.',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMutedAlt,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DayOfWeekChart(days: stats.dayOfWeekSpending),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Segmented Time Range Chips Selector
  Widget _buildTimeRangePicker(WidgetRef ref, StatsTimeRange activeRange) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StatsTimeRange.values.map((range) {
          final isSelected = range == activeRange;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                range.label,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.accentPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.accentPrimary,
              backgroundColor: const Color(0xFFEDE0D9),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (selected) {
                if (selected) {
                  ref.read(statisticsTimeRangeProvider.notifier).state = range;
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// KPI Cards 2x2 Grid (Net Cash Flow, Savings Rate, Top Category, Total Expenses)
  Widget _buildKpiMetricsGrid(FinancialStatsModel stats, NumberFormat currencyFormatter) {
    final isNetPositive = stats.netCashFlow >= 0;

    return Column(
      children: [
        Row(
          children: [
            // Net Cash Flow Card
            Expanded(
              child: _buildMetricTile(
                title: 'Net Cash Flow',
                value: currencyFormatter.format(stats.netCashFlow),
                valueColor: isNetPositive ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                subtitle: isNetPositive ? 'Positive Cash Flow' : 'Negative Cash Flow',
                icon: isNetPositive ? Icons.trending_up : Icons.trending_down,
                iconColor: isNetPositive ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(width: 12),

            // Savings Rate Card
            Expanded(
              child: _buildMetricTile(
                title: 'Savings Rate',
                value: '${stats.savingsRate.toStringAsFixed(1)}%',
                valueColor: AppColors.accentPrimary,
                subtitle: 'Of Total Income',
                icon: Icons.savings_outlined,
                iconColor: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Top Category Card
            Expanded(
              child: _buildMetricTile(
                title: 'Top Category',
                value: stats.topSpendingCategory?.categoryName ?? 'None',
                valueColor: AppColors.textPrimary,
                subtitle: stats.topSpendingCategory != null
                    ? currencyFormatter.format(stats.topSpendingCategory!.amount)
                    : 'No expenses',
                iconWidget: stats.topSpendingCategory != null
                    ? CategoryIcon(
                        categoryName: stats.topSpendingCategory!.categoryName,
                        iconName: stats.topSpendingCategory!.iconName,
                        size: 18,
                        containerSize: 28,
                        color: stats.topSpendingCategory!.color,
                      )
                    : const Icon(Icons.category_outlined, size: 20, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 12),

            // Total Expense Card
            Expanded(
              child: _buildMetricTile(
                title: 'Total Expenses',
                value: currencyFormatter.format(stats.totalExpense),
                valueColor: AppColors.textPrimary,
                subtitle: '${stats.totalTransactionCount} Transactions',
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.textMutedAlt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color valueColor,
    required String subtitle,
    IconData? icon,
    Color? iconColor,
    Widget? iconWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMutedAlt,
                ),
              ),
              if (iconWidget != null)
                iconWidget
              else if (icon != null)
                Icon(icon, size: 20, color: iconColor ?? AppColors.accentPrimary),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.quicksand(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedAlt,
            ),
          ),
        ],
      ),
    );
  }

  /// Category Spending breakdown with progress bars
  Widget _buildCategorySpendingCard(FinancialStatsModel stats, NumberFormat currencyFormatterShort) {
    return _buildCardWrapper(
      title: 'EXPENSE BREAKDOWN BY CATEGORY',
      child: stats.categoryBreakdown.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No expense records found for this period.',
                  style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          : Column(
              children: stats.categoryBreakdown.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CategoryIcon(
                            categoryName: cat.categoryName,
                            iconName: cat.iconName,
                            size: 24,
                            containerSize: 26,
                            color: cat.color,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.categoryName,
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cat.color,
                              ),
                            ),
                          ),
                          Text(
                            '${cat.percentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMutedAlt,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currencyFormatterShort.format(cat.amount),
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cat.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (cat.percentage / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.accentPrimaryLight,
                          color: cat.color,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  /// Reusable Card Wrapper Widget
  Widget _buildCardWrapper({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedAlt,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
