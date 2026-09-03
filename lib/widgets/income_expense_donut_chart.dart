import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/chart_style_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import 'percentage_speech_bubble.dart';

/// Circular / Donut chart displaying the ratio of Income vs. Expense for the selected period
/// strictly styled per Figma CSS export.
class IncomeExpenseDonutChart extends ConsumerStatefulWidget {
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
  ConsumerState<IncomeExpenseDonutChart> createState() => _IncomeExpenseDonutChartState();
}

class _IncomeExpenseDonutChartState extends ConsumerState<IncomeExpenseDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final hasData = widget.summary.totalFlow > 0;
    final pieChartStyle = ref.watch(pieChartStyleProvider);
    final isInteractive = pieChartStyle == PieChartStyle.interactive;

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
              if (widget.periodToggle != null) ...[
                widget.periodToggle!,
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
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 12, bottom: 6),
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      return;
                                    }
                                    final idx = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    setState(() {
                                      _touchedIndex = idx;
                                    });
                                  },
                                ),
                                sectionsSpace: 3,
                                centerSpaceRadius: 38,
                                startDegreeOffset: -90,
                                sections: [
                                  PieChartSectionData(
                                    color: AppColors.accentPrimary,
                                    value: widget.summary.totalIncome > 0 ? widget.summary.totalIncome : 1.0,
                                    showTitle: false,
                                    radius: (isInteractive && _touchedIndex == 0) ? 20 : 15,
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFFE8B381),
                                    value: widget.summary.totalExpense > 0 ? widget.summary.totalExpense : 0.1,
                                    showTitle: false,
                                    radius: (isInteractive && _touchedIndex == 1) ? 20 : 15,
                                  ),
                                ],
                              ),
                            ),
                            if (isInteractive && _touchedIndex == 0)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Income',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    '${widget.summary.incomePercentage.round()}%',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentPrimary,
                                    ),
                                  ),
                                ],
                              )
                            else if (isInteractive && _touchedIndex == 1)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Expenses',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    '${widget.summary.expensePercentage.round()}%',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE8B381),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                widget.period.label,
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentPrimary,
                                ),
                              ),

                            // Floating Expense % Badge (When Bubble Style is Selected)
                            if (!isInteractive && widget.summary.totalExpense > 0)
                              Positioned(
                                left: 0,
                                top: 4,
                                child: PercentageSpeechBubble(
                                  text: '${widget.summary.expensePercentage.round()}%',
                                  backgroundColor: const Color(0xFFFCE9D6),
                                  textColor: const Color(0xFFC25814),
                                ),
                              ),

                            // Floating Income % Badge (When Bubble Style is Selected)
                            if (!isInteractive && widget.summary.totalIncome > 0)
                              Positioned(
                                right: 0,
                                top: 4,
                                child: PercentageSpeechBubble(
                                  text: '${widget.summary.incomePercentage.round()}%',
                                  backgroundColor: AppColors.accentPrimary,
                                  textColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),

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
                            amountText: currencyFormatter.format(widget.summary.totalIncome),
                            amountColor: AppColors.accentPrimary,
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
                            amountText: currencyFormatter.format(widget.summary.totalExpense),
                            amountColor: const Color(0xFFE8B381),
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
      ],
    );
  }
}
