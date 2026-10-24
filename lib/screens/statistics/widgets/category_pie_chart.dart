import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/financial_stats_model.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/category_icon.dart';

/// Donut/Pie Chart widget for displaying monthly category expense breakdown,
/// styled identically to the Dashboard spending category chart.
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
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                  color: colors.iconButtonBg,
                ),
                child: Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 32,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No expense records found for this month',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    final activeIndex = (_touchedIndex >= 0 && _touchedIndex < widget.categories.length)
        ? _touchedIndex
        : 0;

    final focusCat = widget.categories.isNotEmpty ? widget.categories[activeIndex] : null;
    final focusPct = (focusCat != null && widget.totalExpense > 0)
        ? focusCat.percentage.round()
        : 0;
    final focusColor = focusCat != null ? focusCat.color : AppColors.accentPrimary;

    final hasMoreCategories = widget.categories.length > 4;
    final displayCategories = (_showAll || !hasMoreCategories)
        ? widget.categories
        : widget.categories.take(4).toList();

    return Column(
      children: [
        // Donut Chart & Category Summary Row
        Row(
          children: [
            Padding(
               padding: const EdgeInsets.only(left: 14, top: 10, bottom: 10),
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
                            if (idx >= 0 && idx < widget.categories.length) {
                              setState(() {
                                _touchedIndex = idx;
                              });
                            }
                          },
                        ),
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                        sections: List.generate(widget.categories.length, (index) {
                          final isTouched = index == activeIndex;
                          final cat = widget.categories[index];
                          return PieChartSectionData(
                            color: cat.color,
                            value: cat.amount,
                            title: '',
                            radius: isTouched ? 18 : 14,
                          );
                        }),
                      ),
                    ),
                    // Center Interactive Category Focus Indicator
                    if (focusCat != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 52),
                            child: Text(
                              focusCat.categoryName,
                              style: GoogleFonts.quicksand(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(
                            '$focusPct%',
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: focusColor,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending by Category',
                    style: GoogleFonts.quicksand(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormatter.format(widget.totalExpense),
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Across ${widget.categories.length} ${widget.categories.length == 1 ? 'Category' : 'Categories'}',
                    style: GoogleFonts.quicksand(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // View All button positioned directly on top of the divider line
        if (hasMoreCategories) ...[
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showAll = !_showAll;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  _showAll ? 'Show Less' : 'View All',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ),
          ),
        ] else
          const SizedBox(height: 4),

        Divider(height: 1, thickness: 0.5, color: colors.borderDefault),
        const SizedBox(height: 12),

        // Category Progress Bars List
        ...List.generate(displayCategories.length, (index) {
          final cat = displayCategories[index];
          final originalIndex = widget.categories.indexOf(cat);

          return GestureDetector(
            onTap: () {
              if (originalIndex != -1) {
                setState(() {
                  _touchedIndex = originalIndex;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CategoryIcon(
                        categoryName: cat.categoryName,
                        iconName: cat.iconName,
                        size: 26,
                        containerSize: 26,
                        color: cat.color,
                      ),
                      const SizedBox(width: 8),
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
                        currencyFormatter.format(cat.amount),
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cat.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: (cat.percentage / 100).clamp(0.0, 1.0),
                      backgroundColor: colors.iconButtonBg,
                      color: cat.color,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
