import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_bill_model.dart';
import '../utils/app_colors.dart';
import '../utils/default_categories.dart';

/// Card widget for displaying a recurring bill, matching AccountCard visual tokens.
class RecurringBillCard extends StatelessWidget {
  final RecurringBillModel bill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkPaid;

  const RecurringBillCard({
    super.key,
    required this.bill,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final categoryColor = DefaultCategories.getColor(bill.categoryColorHex);
    final categoryIcon = DefaultCategories.getIcon(bill.categoryIcon);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(bill.nextDueDate.year, bill.nextDueDate.month, bill.nextDueDate.day);
    final daysRemaining = dueDateOnly.difference(today).inDays;

    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    if (daysRemaining < 0) {
      final daysAgo = daysRemaining.abs();
      statusText = 'Overdue by $daysAgo day${daysAgo > 1 ? 's' : ''}';
      statusBgColor = AppColors.stateError.withValues(alpha: 0.12);
      statusTextColor = AppColors.stateError;
    } else if (daysRemaining == 0) {
      statusText = 'Due Today';
      statusBgColor = AppColors.stateError.withValues(alpha: 0.12);
      statusTextColor = AppColors.stateError;
    } else if (daysRemaining <= 3) {
      statusText = 'Due in $daysRemaining day${daysRemaining > 1 ? 's' : ''}';
      statusBgColor = AppColors.stateWarning.withValues(alpha: 0.15);
      statusTextColor = const Color(0xFF8E6200);
    } else {
      statusText = 'Due ${DateFormat('MMM d, yyyy').format(bill.nextDueDate)}';
      statusBgColor = AppColors.bgBase;
      statusTextColor = AppColors.textMuted;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Icon Circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Bill Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bill.categoryName} • ${bill.accountName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // Frequency Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bill.frequency.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ),
                    // Due Date Status Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (daysRemaining <= 3) ...[
                            Icon(
                              daysRemaining <= 0 ? Icons.error_outline_rounded : Icons.access_time_rounded,
                              size: 12,
                              color: statusTextColor,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount & Action Menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter.format(bill.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_paid':
                      onMarkPaid();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_paid',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.stateSuccess),
                        SizedBox(width: 10),
                        Text('Mark Paid & Advance', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                        SizedBox(width: 10),
                        Text('Edit Bill', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.stateError),
                        SizedBox(width: 10),
                        Text('Delete Bill', style: TextStyle(fontSize: 14, color: AppColors.stateError)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
