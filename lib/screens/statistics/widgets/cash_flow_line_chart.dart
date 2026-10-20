import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/financial_stats_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/chart_utils.dart';

class CashFlowLineChart extends StatelessWidget {
  final List<MonthlyCashFlowPoint> points;

  const CashFlowLineChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No data available for selected period',
            style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      );
    }

    double maxVal = 0.0;
    for (final p in points) {
      if (p.income > maxVal) maxVal = p.income;
      if (p.expense > maxVal) maxVal = p.expense;
    }

    final axisConfig = ChartAxisHelper.computeNiceYAxis(
      maxValue: maxVal,
      targetSteps: 4,
    );

    final incomeSpots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].income));
    final expenseSpots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].expense));

    return Column(
      children: [
        // Legend Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendItem('Income', AppColors.accentPrimary),
            const SizedBox(width: 16),
            _buildLegendItem('Expense', const Color(0xFFE8B381)),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: axisConfig.interval,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: Color(0xFFEDE0D9),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: axisConfig.interval,
                    getTitlesWidget: (value, meta) {
                      if (value < -0.01 || value > axisConfig.maxY + 0.01) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        formatCompactCurrency(value),
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedAlt,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < points.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            points[idx].monthLabel,
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (points.length - 1).toDouble().clamp(0, 100),
              minY: 0,
              maxY: axisConfig.maxY,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      final label = isIncome ? 'Income' : 'Expense';
                      final valFormatted = NumberFormat.currency(symbol: '₱').format(spot.y);
                      return LineTooltipItem(
                        '$label\n$valFormatted',
                        GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isIncome ? AppColors.accentPrimary : const Color(0xFFE8B381),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // Income Line
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  barWidth: 3,
                  color: AppColors.accentPrimary,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accentPrimary.withAlpha((0.15 * 255).round()),
                  ),
                ),
                // Expense Line
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  barWidth: 3,
                  color: const Color(0xFFE8B381),
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFFE8B381).withAlpha((0.15 * 255).round()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
