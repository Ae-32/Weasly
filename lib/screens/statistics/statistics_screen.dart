import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/financial_stats_model.dart';
import '../../providers/statistics_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/weasly_app_header.dart';
import 'widgets/cash_flow_line_chart.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/day_of_week_chart.dart';
import 'widgets/month_selector_header.dart';

/// Full Financial Statistics & Analytics Screen with Month-by-Month Spending Pie Chart
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(financialStatisticsProvider);
    final insights = ref.watch(analyticsInsightMessagesProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

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
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Insights, trends, and past month spending patterns.',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Month-by-Month Selector Header
                    const MonthSelectorHeader(),
                    const SizedBox(height: 16),

                    // Monthly Summary KPI Cards Grid
                    _buildSummaryKpiGrid(stats, currencyFormatter),
                    const SizedBox(height: 16),

                    // Category Spending Pie Chart Card
                    _buildCardWrapper(
                      title: 'SPENDING BY CATEGORY',
                      child: CategoryPieChart(
                        categories: stats.categoryBreakdown,
                        totalExpense: stats.totalExpense,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cash Flow Line Chart Card
                    _buildCardWrapper(
                      title: 'CASH FLOW TREND (INCOME VS EXPENSE)',
                      child: CashFlowLineChart(points: stats.monthlyTrends),
                    ),
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
                    const SizedBox(height: 16),

                    // Mascot Insights Section
                    if (insights.isNotEmpty)
                      _buildCardWrapper(
                        title: 'WEASLY MASCOT INSIGHTS',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: insights.map((msg) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentPrimaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: AppColors.accentPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      msg,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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

  /// Summary KPI cards grid showing month metrics
  Widget _buildSummaryKpiGrid(FinancialStatsModel stats, NumberFormat currencyFormatter) {
    final momChange = stats.monthOverMonthChangePct;
    final hasPrevExpense = stats.previousMonthExpense > 0;

    return Row(
      children: [
        // Total Expense Card
        Expanded(
          child: _buildKpiCard(
            title: 'TOTAL EXPENSE',
            value: currencyFormatter.format(stats.totalExpense),
            valueColor: AppColors.accentPrimary,
            badge: hasPrevExpense
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: momChange > 0
                          ? AppColors.stateError.withAlpha(25)
                          : AppColors.stateSuccess.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          momChange > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 10,
                          color: momChange > 0 ? AppColors.stateError : AppColors.stateSuccess,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${momChange.abs().toStringAsFixed(1)}%',
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: momChange > 0 ? AppColors.stateError : AppColors.stateSuccess,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // Total Income Card
        Expanded(
          child: _buildKpiCard(
            title: 'TOTAL INCOME',
            value: currencyFormatter.format(stats.totalIncome),
            valueColor: AppColors.accentSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color valueColor,
    Widget? badge,
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
            offset: Offset(0, 2),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMutedAlt,
                  letterSpacing: 0.5,
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
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
