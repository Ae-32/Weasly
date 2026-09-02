import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import 'percentage_speech_bubble.dart';

/// Circular / Donut chart displaying the ratio of Income vs. Expense for the selected period
/// strictly styled per Figma CSS export.
class IncomeExpenseDonutChart extends StatelessWidget {
  final PeriodSummary summary;
  final DashboardPeriod period;
  final Widget? periodToggle;

  const IncomeExpenseDonutChart({
    super.key,
    required this.summary,
    required this.period,
    this.periodToggle,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final hasData = summary.totalFlow > 0;

    return Container(
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INCOME AND EXPENSES',
                style: GoogleFonts.quicksand(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMutedAlt,
                  letterSpacing: 0.5,
                ),
              ),
              if (periodToggle != null) ...[
                periodToggle!,
              ],
            ],
          ),
          const SizedBox(height: 16),

          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.donut_small_rounded, size: 44, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    Text(
                      'No transactions for this period.',
                      style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    // Donut Chart with Center Label & Floating Percentage Speech Bubble Callouts
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 34,
                              startDegreeOffset: -90,
                              sections: [
                                PieChartSectionData(
                                  color: AppColors.accentPrimary,
                                  value: summary.totalIncome > 0 ? summary.totalIncome : 1.0,
                                  showTitle: false,
                                  radius: 14,
                                ),
                                PieChartSectionData(
                                  color: const Color(0xFFE8B381),
                                  value: summary.totalExpense > 0 ? summary.totalExpense : 0.1,
                                  showTitle: false,
                                  radius: 14,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            period.label,
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPrimary,
                            ),
                          ),

                          // Floating Expense % Badge (Left - matching light peach expense slice)
                          if (summary.totalExpense > 0)
                            Positioned(
                              left: -4,
                              top: -2,
                              child: PercentageSpeechBubble(
                                text: '${summary.expensePercentage.round()}%',
                                backgroundColor: const Color(0xFFFCE9D6),
                                textColor: const Color(0xFFC25814),
                              ),
                            ),

                          // Floating Income % Badge (Right - matching dark orange income slice)
                          if (summary.totalIncome > 0)
                            Positioned(
                              right: -4,
                              top: -2,
                              child: PercentageSpeechBubble(
                                text: '${summary.incomePercentage.round()}%',
                                backgroundColor: AppColors.accentPrimary,
                                textColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Income & Expense Breakdown Rows
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Income Row
                          _buildBreakdownRow(
                            iconBg: const Color(0xFFFCE9D6),
                            iconColor: AppColors.accentPrimary,
                            isUp: true,
                            label: 'INCOME',
                            amountText: currencyFormatter.format(summary.totalIncome),
                            amountColor: AppColors.accentPrimary,
                            pctText: '${summary.incomePercentage.toStringAsFixed(0)}%',
                            pctColor: AppColors.accentPrimary,
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 0.5, color: AppColors.borderDefault),
                          const SizedBox(height: 12),
                          // Expense Row
                          _buildBreakdownRow(
                            iconBg: const Color(0xFFFCE9D6),
                            iconColor: const Color(0xFFE8B381),
                            isUp: false,
                            label: 'EXPENSES',
                            amountText: currencyFormatter.format(summary.totalExpense),
                            amountColor: const Color(0xFFE8B381),
                            pctText: '${summary.expensePercentage.toStringAsFixed(0)}%',
                            pctColor: const Color(0xFFE8B381),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'View Details',
                    style: GoogleFonts.quicksand(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required Color iconBg,
    required Color iconColor,
    required bool isUp,
    required String label,
    required String amountText,
    required Color amountColor,
    required String pctText,
    required Color pctColor,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMutedAlt,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amountText,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
        Text(
          pctText,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: pctColor,
          ),
        ),
      ],
    );
  }
}
