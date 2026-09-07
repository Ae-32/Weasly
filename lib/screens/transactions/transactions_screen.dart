import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/add_edit_transaction_modal.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/success_banner.dart';
import '../../widgets/weasly_app_header.dart';
import '../../widgets/app_toast.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext parentContext, TransactionModel tx) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Transaction',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This will automatically adjust your account balance.',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(transactionControllerProvider.notifier)
                  .deleteTransaction(tx);
              if (parentContext.mounted) {
                if (success) {
                  SuccessBanner.show(parentContext, 'Transaction deleted!');
                } else {
                  final err = ref.read(transactionControllerProvider).errorMessage;
                  if (err != null) {
                    AppToast.showError(parentContext, err);
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Groups transactions into date headers (Today, Yesterday, Oct 12, etc.)
  Map<String, List<TransactionModel>> _groupTransactionsByDate(
      List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFormatter = DateFormat('MMM dd, yyyy');

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      if (txDate == today) {
        label = 'Today';
      } else if (txDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = dateFormatter.format(tx.date);
      }

      if (!grouped.containsKey(label)) {
        grouped[label] = [];
      }
      grouped[label]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final selectedCategoryFilter = ref.watch(transactionCategoryFilterProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    final groupedMap = _groupTransactionsByDate(filteredTransactions);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(43, 36, 32, 0.08),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => AddEditTransactionModal.show(context),
          backgroundColor: AppColors.accentPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fixed Top Header Bar (Logo Badge & Action Buttons)
            const WeaslyAppHeader(),
            const SizedBox(height: 8),

            // 2. Fixed Page Title & Subtitle Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: GoogleFonts.quicksand(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF211A16),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review your recent activity',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A7F73),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Fixed Search & Filter Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Search Bar Input
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E1D8), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(43, 36, 32, 0.04),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(transactionSearchQueryProvider.notifier).state = val;
                      },
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        color: const Color(0xFF211A16),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: const Color(0xFF8A7F73),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8A7F73), size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF8A7F73), size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(transactionSearchQueryProvider.notifier).state = '';
                                },
                              )
                            : const Icon(Icons.tune_rounded, color: Color(0xFF8A7F73), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips Bar (Horizontal Scroll)
                  categoriesAsync.when(
                    data: (categories) {
                      return SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // All Filter Button
                            GestureDetector(
                              onTap: () {
                                ref.read(transactionCategoryFilterProvider.notifier).state = null;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selectedCategoryFilter == null
                                      ? const Color(0xFFD98A3D)
                                      : const Color(0xFFEDE0D9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    if (selectedCategoryFilter == null) ...[
                                      const Icon(Icons.check_rounded, size: 14, color: Color(0xFF512A00)),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      'All',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: selectedCategoryFilter == null
                                            ? const Color(0xFF512A00)
                                            : const Color(0xFF534438),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Dynamic Category Chips
                            ...categories.map((cat) {
                              final isSelected = selectedCategoryFilter == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(transactionCategoryFilterProvider.notifier).state =
                                        isSelected ? null : cat.id;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFD98A3D)
                                          : const Color(0xFFEDE0D9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isSelected) ...[
                                          const Icon(Icons.check_rounded, size: 14, color: Color(0xFF512A00)),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          cat.name,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.6,
                                            color: isSelected
                                                ? const Color(0xFF512A00)
                                                : const Color(0xFF534438),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Scrollable Transactions List Section
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: filteredTransactions.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/Weasly_NoTransaction.png',
                                width: 160,
                                height: 160,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet.',
                                style: GoogleFonts.quicksand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF211A16),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start stashing your activity by logging your first expense or income.',
                                style: GoogleFonts.quicksand(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...groupedMap.keys.map((dateLabel) {
                              final dateTxs = groupedMap[dateLabel]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Group Header
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                                    child: Text(
                                      dateLabel.toUpperCase(),
                                      style: GoogleFonts.quicksand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF8A7F73),
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),

                                  // Date Group Items
                                  ...dateTxs.map((tx) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: _buildTransactionCard(context, tx, currencyFormatter),
                                    );
                                  }),
                                ],
                              );
                            }),
                            const SizedBox(height: 80),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
);
  }

  /// Individual Transaction Card matching Figma CSS specs & redesign mockups
  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel tx,
    NumberFormat currencyFormatter,
  ) {
    final isIncome = tx.type == TransactionType.income;
    final timeStr = DateFormat('h:mm a').format(tx.date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D8).withValues(alpha: 0.5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => AddEditTransactionModal.show(context, transactionToEdit: tx),
          onLongPress: () => _confirmDelete(context, tx),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category Icon + Details
                Expanded(
                  child: Row(
                    children: [
                      // Icon Container (48x48)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFD8C2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CategoryIcon(
                            categoryName: tx.categoryName,
                            iconName: tx.categoryIcon,
                            color: AppColors.accentPrimary,
                            size: 20,
                            containerSize: 48,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Category/Time Subtitle Row
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.note != null && tx.note!.isNotEmpty
                                  ? tx.note!
                                  : tx.categoryName,
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF211A16),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Category Chip Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE0D9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tx.categoryName,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF534438),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Time / Account Subtitle
                                Text(
                                  timeStr,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF8A7F73),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  _formatTxAmount(tx, currencyFormatter),
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isIncome ? const Color(0xFF2B694E) : const Color(0xFF211A16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTxAmount(TransactionModel tx, NumberFormat formatter) {
    if (tx.type == TransactionType.income) {
      return '+${formatter.format(tx.amount)}';
    } else if (tx.type == TransactionType.expense) {
      return '-${formatter.format(tx.amount)}';
    } else {
      return '⇄ ${formatter.format(tx.amount)}';
    }
  }
}
