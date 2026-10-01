import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/financial_stats_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/default_categories.dart';

/// Donut/Pie Chart widget for displaying monthly category expense breakdown.
class CategoryPieChart extends StatefulWidget {
  final List<CategoryStatItem> categories;
  final double totalExpense;

  const CategoryPieChart({
    super.key,
    required this.categories,
    required this.totalExpense,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty || widget.totalExpense <= 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.iconButtonBg.withAlpha(120),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 32,
                  color: AppColors.textMutedAlt,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No expense records found for this month',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Donut Pie Chart Canvas
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  sections: List.generate(widget.categories.length, (i) {
                    final isTouched = i == _touchedIndex;
                    final item = widget.categories[i];
                    final radius = isTouched ? 32.0 : 26.0;

                    return PieChartSectionData(
                      color: item.color,
                      value: item.amount,
                      title: '',
                      radius: radius,
                    );
                  }),
                ),
              ),

              // Center Donut Details Overlay
              _buildCenterContent(currencyFormatter),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(color: AppColors.borderDefault, height: 1),
        const SizedBox(height: 16),

        // Category Breakdown Legend List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.categories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final cat = widget.categories[index];
            final isHighlighted = index == _touchedIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isHighlighted ? cat.color.withAlpha(25) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cat.color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        DefaultCategories.getIcon(cat.iconName),
                        size: 16,
                        color: cat.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category Name & Progress Bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.categoryName,
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(cat.amount),
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (cat.percentage / 100).clamp(0.0, 1.0),
                                  backgroundColor: AppColors.borderDefault.withAlpha(120),
                                  valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${cat.percentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCenterContent(NumberFormat currencyFormatter) {
    if (_touchedIndex >= 0 && _touchedIndex < widget.categories.length) {
      final touchedCat = widget.categories[_touchedIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            DefaultCategories.getIcon(touchedCat.iconName),
            size: 20,
            color: touchedCat.color,
          ),
          const SizedBox(height: 2),
          Text(
            touchedCat.categoryName,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            currencyFormatter.format(touchedCat.amount),
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${touchedCat.percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: touchedCat.color,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total Expense',
          style: GoogleFonts.quicksand(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMutedAlt,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          currencyFormatter.format(widget.totalExpense),
          style: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${widget.categories.length} Categories',
          style: GoogleFonts.quicksand(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.accentPrimary,
          ),
        ),
      ],
    );
  }
}
