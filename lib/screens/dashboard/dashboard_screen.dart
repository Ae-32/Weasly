import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/recurring_bill_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/home_nav_provider.dart';
import '../../providers/recurring_bill_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../auth/logout_confirmation_modal.dart';
import '../auth/logout_success_screen.dart';
import '../../widgets/income_expense_donut_chart.dart';
import '../recurring_bills/recurring_bills_screen.dart';
import '../settings/settings_screen.dart';

/// Full live Dashboard screen matching exact Figma CSS export & redesign-v2 specifications
/// with large overlapping mascot illustrations that break container boundaries.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await LogoutConfirmationModal.show(context);
    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LogoutSuccessScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature coming soon!'),
        backgroundColor: AppColors.accentPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final recurringBillsAsync = ref.watch(recurringBillsStreamProvider);
    final budgetsWithSpent = ref.watch(budgetsWithSpentProvider);

    // Dashboard Redesign Providers
    final activePeriod = ref.watch(dashboardPeriodProvider);
    final periodTransactions = ref.watch(periodTransactionsProvider);
    final periodSummary = ref.watch(periodSummaryProvider);
    final mascotInsight = ref.watch(mascotInsightProvider);

    final user = authState.value;
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final currencyFormatterShort = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    final now = DateTime.now();
    final dateHeader = DateFormat('EEEE - MMMM d, yyyy').format(now).toUpperCase();
    final greetingPrefix = _getGreetingPrefix();
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'Ae';

    // Warning / Over budget alerts
    final warningBudgets = budgetsWithSpent
        .where((b) => b.status == BudgetStatus.nearingLimit || b.status == BudgetStatus.overBudget)
        .take(2)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Bar & Mascot Insight Speech Bubble (Overlapping Band)
              _buildTopHeaderBanner(
                context: context,
                ref: ref,
                dateHeader: dateHeader,
                greetingText: '$greetingPrefix, $userName!',
                mascotInsight: mascotInsight,
              ),

              // Content Canvas Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Total Balance Summary Card (Overlapping Top-Right Mascot)
                    _buildTotalBalanceCard(totalBalance, currencyFormatter),
                    const SizedBox(height: 20),

                    // 3. Income and Expenses Card (with Period Toggle)
                    IncomeExpenseDonutChart(
                      summary: periodSummary,
                      period: activePeriod,
                      periodToggle: _buildPeriodToggleBar(ref, activePeriod),
                    ),
                    const SizedBox(height: 16),

                    // 4. Spending by Category Card
                    _buildCategorySpendingSection(
                      context,
                      ref,
                      periodTransactions,
                      activePeriod,
                      currencyFormatterShort,
                    ),
                    const SizedBox(height: 16),

                    // Budget Alerts (Hidden if no budgets in warning/over state)
                    if (warningBudgets.isNotEmpty) ...[
                      _buildBudgetAlertsSection(context, ref, warningBudgets, currencyFormatter),
                      const SizedBox(height: 16),
                    ],

                    // 6. Recent Transactions List
                    _buildRecentTransactionsSection(
                      context,
                      ref,
                      periodTransactions,
                      activePeriod,
                      currencyFormatter,
                    ),
                    const SizedBox(height: 20),

                    // Upcoming Bills Preview Section
                    _buildRecurringBillsSection(context, ref, recurringBillsAsync, currencyFormatter),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Header Bar + Orange Background Accent Band + Mascot Insight Bubble (Figma Spec)
  Widget _buildTopHeaderBanner({
    required BuildContext context,
    required WidgetRef ref,
    required String dateHeader,
    required String greetingText,
    required String mascotInsight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Row with Action Buttons
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 20.0, top: 12.0, bottom: 4.0),
          child: Row(
            children: [
              // Weasly App Logo Badge (image 3 in Figma spec)
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/Weasly_Logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Date & Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateHeader,
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFBBB6B4),
                        letterSpacing: -0.64,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      greetingText,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF211A16),
                        letterSpacing: -0.64,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons Row (Notification, Settings, Logout)
              Row(
                children: [
                  _buildHeaderIconButton(
                    icon: Icons.notifications_rounded,
                    onTap: () => _showComingSoonSnackBar(context, 'Notifications'),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    icon: Icons.settings_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    icon: Icons.logout_rounded,
                    onTap: () => _handleLogout(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Stack with Orange Band, Overlapping Mascot, and Speech Bubble
        SizedBox(
          height: 135,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Orange Background Band (Rectangle 1)
              Positioned(
                left: 0,
                right: 0,
                top: 80,
                height: 60,
                child: Container(
                  color: AppColors.accentPrimary,
                ),
              ),

              // Pointer Tail for Speech Bubble
              Positioned(
                left: 106,
                top: 40,
                child: CustomPaint(
                  size: const Size(12, 18),
                  painter: _SpeechBubblePointerPainter(),
                ),
              ),

              // Speech Bubble Container (Union / Rectangle 2)
              Positioned(
                left: 116,
                right: 20,
                top: 10,
                height: 93,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC25814), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(43, 36, 32, 0.06),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weasly',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
                          letterSpacing: -0.64,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          mascotInsight,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mascot Illustration on Left - Overlapping Band & Speech Bubble & Extending Below!
              Positioned(
                left: -4,
                top: 0,
                width: 145,
                height: 146,
                child: Image.asset(
                  'assets/images/Weasly_Dashboard_Welcome.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Circular Action Button at Top Right
  Widget _buildHeaderIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.iconButtonBg,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(43, 36, 32, 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.accentPrimary),
      ),
    );
  }

  /// Total Balance Summary Card (Overlapping Mascot Top-Right Corner)
  Widget _buildTotalBalanceCard(double totalBalance, NumberFormat currencyFormatter) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // White Card Container
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currencyFormatter.format(totalBalance),
                          style: GoogleFonts.quicksand(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Across 3 Categories',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9A9998),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 100), // Reserved space for overlapping mascot
              ],
            ),
          ),

          // Overlapping Mascot Illustration on Top-Right Corner (Flipped to face text)
          Positioned(
            right: -6,
            top: -40,
            width: 145,
            height: 146,
            child: Image.asset(
              'assets/images/Weasly_Dashboard_TotalBalance.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented period toggle pill (Day | Week | Month)
  Widget _buildPeriodToggleBar(WidgetRef ref, DashboardPeriod activePeriod) {
    return Container(
      width: 108,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.accentPrimaryLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: DashboardPeriod.values.map((period) {
          final isSelected = period == activePeriod;
          final label = period == DashboardPeriod.today ? 'Day' : period.label;

          return GestureDetector(
            onTap: () {
              ref.read(dashboardPeriodProvider.notifier).state = period;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.accentPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Budget Alerts Warning Highlight Section
  Widget _buildBudgetAlertsSection(
    BuildContext context,
    WidgetRef ref,
    List<BudgetWithSpent> warningBudgets,
    NumberFormat currencyFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Alerts',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(homeNavIndexProvider.notifier).state = 2; // Switch to Budgets tab
              },
              child: Text(
                'View Budgets',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...warningBudgets.map((item) {
          final isOver = item.status == BudgetStatus.overBudget;
          final statusColor = item.status.color;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isOver ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.budget.categoryName,
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            item.status.label,
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currencyFormatter.format(item.spentAmount)} spent of ${currencyFormatter.format(item.budget.amount)}',
                        style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Section - Spending by Category Card (Figma Spec)
  Widget _buildCategorySpendingSection(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
    DashboardPeriod activePeriod,
    NumberFormat currencyFormatterShort,
  ) {
    final periodExpenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();

    if (periodExpenses.isEmpty) {
      return _buildCardWrapper(
        title: 'SPENDING BY CATEGORY',
        actionWidget: _buildPeriodToggleBar(ref, activePeriod),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
            child: Text(
              'No expenses logged for this period.',
              style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    // Group expenses by category
    final Map<String, _CategoryExpenseAggregate> categoryMap = {};
    double totalExpensePeriod = 0.0;

    for (final tx in periodExpenses) {
      totalExpensePeriod += tx.amount;
      if (categoryMap.containsKey(tx.categoryId)) {
        categoryMap[tx.categoryId]!.total += tx.amount;
      } else {
        categoryMap[tx.categoryId] = _CategoryExpenseAggregate(
          id: tx.categoryId,
          name: tx.categoryName,
          iconName: tx.categoryIcon,
          colorHex: tx.categoryColorHex,
          total: tx.amount,
        );
      }
    }

    final sortedCategories = categoryMap.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return _buildCardWrapper(
      title: 'SPENDING BY CATEGORY',
      actionWidget: _buildPeriodToggleBar(ref, activePeriod),
      child: Column(
        children: [
          // Donut Chart & Category Summary Row
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    sections: List.generate(sortedCategories.length, (index) {
                      final cat = sortedCategories[index];
                      final color = DefaultCategories.getCategoryColorByName(cat.name, cat.colorHex);
                      return PieChartSectionData(
                        color: color,
                        value: cat.total,
                        title: '',
                        radius: 16,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending by Category',
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMutedAlt,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatterShort.format(totalExpensePeriod),
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Across ${sortedCategories.length} ${sortedCategories.length == 1 ? 'Category' : 'Categories'}',
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMutedAlt,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Progress Bars List
          ...sortedCategories.take(4).map((cat) {
            final pct = (cat.total / totalExpensePeriod) * 100;
            final catColor = DefaultCategories.getCategoryColorByName(cat.name, cat.colorHex);
            final icon = DefaultCategories.getIcon(cat.iconName);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(icon, size: 14, color: catColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: catColor,
                          ),
                        ),
                      ),
                      Text(
                        currencyFormatterShort.format(cat.total),
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.accentPrimaryLight,
                      color: catColor,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Section - Recent Transactions (Figma Spec)
  Widget _buildRecentTransactionsSection(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
    DashboardPeriod activePeriod,
    NumberFormat currencyFormatter,
  ) {
    final recentList = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayTxs = recentList.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(homeNavIndexProvider.notifier).state = 1; // Switch to Transactions tab
              },
              child: Text(
                'See All',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
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
          child: displayTxs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No recent transactions.',
                      style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textMuted),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(displayTxs.length, (index) {
                    final tx = displayTxs[index];
                    final isIncome = tx.type == TransactionType.income;
                    final icon = DefaultCategories.getIcon(tx.categoryIcon);
                    final prefix = isIncome ? '+' : (tx.type == TransactionType.transfer ? '⇄ ' : '-');
                    final amountColor = isIncome ? AppColors.accentPrimary : AppColors.textPrimary;

                    return Column(
                      children: [
                        if (index > 0)
                          const Divider(height: 16, thickness: 0.5, color: AppColors.borderDefault),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.bgBase,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, size: 20, color: const Color(0xFF534438)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.categoryName,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx.accountName,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$prefix${currencyFormatter.format(tx.amount)}',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: amountColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  /// Section - Upcoming Bills Preview
  Widget _buildRecurringBillsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RecurringBillModel>> billsAsync,
    NumberFormat currencyFormatter,
  ) {
    return _buildCardWrapper(
      title: 'Upcoming Bills',
      actionText: 'View All',
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const RecurringBillsScreen()),
        );
      },
      child: billsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No recurring bills added.',
                  style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            );
          }

          final sortedBills = List<RecurringBillModel>.from(bills)
            ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
          final upcomingList = sortedBills.take(3).toList();
          final dateFormatter = DateFormat('MMM dd');

          return Column(
            children: upcomingList.map((bill) {
              final daysLeft = bill.daysUntilDue;

              final Color badgeColor;
              final String urgencyText;

              if (bill.isOverdue) {
                badgeColor = AppColors.stateError;
                urgencyText = 'Overdue';
              } else if (daysLeft == 0) {
                badgeColor = AppColors.stateWarning;
                urgencyText = 'Due Today';
              } else if (daysLeft <= 3) {
                badgeColor = AppColors.stateWarning;
                urgencyText = 'Due in $daysLeft ${daysLeft == 1 ? "day" : "days"}';
              } else {
                badgeColor = AppColors.accentPrimary;
                urgencyText = 'Due ${dateFormatter.format(bill.nextDueDate)}';
              }

              final icon = DefaultCategories.getIcon(bill.categoryIcon);
              final iconColor = DefaultCategories.getCategoryColorByName(bill.categoryName, bill.categoryColorHex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.name,
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  urgencyText,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                bill.frequency.displayName,
                                style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(bill.amount),
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Text(
          'Error loading bills: $err',
          style: GoogleFonts.quicksand(color: AppColors.stateError),
        ),
      ),
    );
  }

  /// Reusable Card Wrapper Widget
  Widget _buildCardWrapper({
    required String title,
    String? actionText,
    VoidCallback? onAction,
    Widget? actionWidget,
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
              if (actionWidget != null)
                actionWidget
              else if (actionText != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    actionText,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: onAction != null ? AppColors.accentPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CategoryExpenseAggregate {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  double total;

  _CategoryExpenseAggregate({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.total,
  });
}

class _SpeechBubblePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = AppColors.bgSurface
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFC25814)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

