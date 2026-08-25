import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../../widgets/add_edit_transaction_modal.dart';

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

  void _confirmDelete(BuildContext context, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Transaction',
          style: TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this transaction? This will automatically adjust your account balance.',
          style: TextStyle(fontFamily: 'Quicksand'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(transactionControllerProvider.notifier)
                  .deleteTransaction(tx);
              if (context.mounted && !success) {
                final err = ref.read(transactionControllerProvider).errorMessage;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err, style: const TextStyle(fontFamily: 'Quicksand')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
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
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Transactions',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditTransactionModal.show(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.onPrimary),
        label: const Text(
          'Add Transaction',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
            color: AppColors.onPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input & Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(transactionSearchQueryProvider.notifier).state = val;
                    },
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 15,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(transactionSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Category Filter Chips Bar
                  categoriesAsync.when(
                    data: (categories) {
                      return SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // All Chip
                            ChoiceChip(
                              label: const Text('All'),
                              selected: selectedCategoryFilter == null,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.bgSurface,
                              labelStyle: TextStyle(
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.bold,
                                color: selectedCategoryFilter == null
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant,
                              ),
                              onSelected: (_) {
                                ref.read(transactionCategoryFilterProvider.notifier).state = null;
                              },
                            ),
                            const SizedBox(width: 8),

                            // Category Chips
                            ...categories.map((cat) {
                              final isSelected = selectedCategoryFilter == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.bgSurface,
                                  labelStyle: TextStyle(
                                    fontFamily: 'Quicksand',
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                  ),
                                  onSelected: (_) {
                                    ref.read(transactionCategoryFilterProvider.notifier).state =
                                        isSelected ? null : cat.id;
                                  },
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
            const SizedBox(height: 8),

            // Transactions List
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No transactions found',
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap + Add Transaction below to log your activity.',
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: groupedMap.keys.length,
                      itemBuilder: (context, dateIndex) {
                        final dateLabel = groupedMap.keys.elementAt(dateIndex);
                        final dateTxs = groupedMap[dateLabel]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Group Header
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                              child: Text(
                                dateLabel.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Quicksand',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),

                            // Date Group Items
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dateTxs.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, txIndex) {
                                final tx = dateTxs[txIndex];
                                final color = DefaultCategories.getColor(tx.categoryColorHex);
                                final iconData = DefaultCategories.getIcon(tx.categoryIcon);

                                return Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0,
                                  color: AppColors.bgSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: AppColors.borderDefault),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    onTap: () => AddEditTransactionModal.show(
                                      context,
                                      transactionToEdit: tx,
                                    ),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(iconData, color: color, size: 22),
                                    ),
                                    title: Text(
                                      tx.note != null && tx.note!.isNotEmpty
                                          ? tx.note!
                                          : tx.categoryName,
                                      style: const TextStyle(
                                        fontFamily: 'Quicksand',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tx.type == TransactionType.transfer
                                                ? '${tx.accountName} → ${tx.toAccountName ?? ''}'
                                                : tx.categoryName,
                                            style: const TextStyle(
                                              fontFamily: 'Quicksand',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          tx.accountName,
                                          style: const TextStyle(
                                            fontFamily: 'Quicksand',
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatTxAmount(tx, currencyFormatter),
                                          style: TextStyle(
                                            fontFamily: 'Quicksand',
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: _getTxAmountColor(tx.type),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                                          onPressed: () => _confirmDelete(context, tx),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
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

  Color _getTxAmountColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
      case TransactionType.transfer:
        return AppColors.accentSecondary; // Green #4E8C6E
      case TransactionType.expense:
        return AppColors.textPrimary;
    }
  }
}
