import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/recurring_bill_model.dart';
import '../../providers/recurring_bill_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/add_edit_recurring_bill_modal.dart';
import '../../widgets/recurring_bill_card.dart';
import '../../widgets/success_banner.dart';
import '../../widgets/app_toast.dart';

/// Full screen overview for managing recurring bills and subscriptions.
class RecurringBillsScreen extends ConsumerStatefulWidget {
  const RecurringBillsScreen({super.key});

  @override
  ConsumerState<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends ConsumerState<RecurringBillsScreen> {
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await NotificationService().arePermissionsGranted();
    if (mounted) {
      setState(() => _hasPermission = granted);
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await NotificationService().requestPermissions();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (granted) {
        SuccessBanner.show(context, 'Notification reminders enabled!');
      } else {
        AppToast.showWarning(context, 'Notification permission was declined.');
      }
    }
  }

  void _confirmDelete(BuildContext parentContext, RecurringBillModel bill) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Recurring Bill'),
        content: Text('Are you sure you want to delete "${bill.name}"? Scheduled reminders for this bill will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref.read(recurringBillControllerProvider.notifier).deleteBill(bill.id);
              if (success && parentContext.mounted) {
                SuccessBanner.show(parentContext, 'Bill deleted!');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markPaid(RecurringBillModel bill) async {
    final success = await ref.read(recurringBillControllerProvider.notifier).markPaidAndAdvance(bill);
    if (success && mounted) {
      SuccessBanner.show(context, 'Bill marked as paid!');
    }
  }

  double _calculateMonthlyTotal(List<RecurringBillModel> bills) {
    double total = 0.0;
    for (final bill in bills) {
      switch (bill.frequency) {
        case BillFrequency.weekly:
          total += bill.amount * 4.33;
          break;
        case BillFrequency.monthly:
          total += bill.amount;
          break;
        case BillFrequency.yearly:
          total += bill.amount / 12.0;
          break;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(recurringBillsStreamProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Recurring Bills',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => AddEditRecurringBillModal.show(context),
            icon: const Icon(Icons.add_rounded, color: AppColors.accentPrimary, size: 28),
            tooltip: 'Add Bill',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: billsAsync.when(
          data: (bills) {
            final monthlyTotal = _calculateMonthlyTotal(bills);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission Banner (if not granted)
                  if (!_hasPermission) ...[
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: colors.accentPrimaryLight,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppColors.accentPrimary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Bill Reminders',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Allow notifications so Weasly can remind you before your bills are due.',
                                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _requestPermissions,
                            child: const Text('Enable', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Monthly Total Commitment Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: colors.borderDefault),
                      boxShadow: [colors.cardBoxShadow],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Monthly Commitment',
                              style: TextStyle(fontSize: 13, color: colors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormatter.format(monthlyTotal),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.accentPrimaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_repeat_rounded,
                            color: AppColors.accentPrimary,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Subscriptions (${bills.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AddEditRecurringBillModal.show(context),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded, size: 18, color: AppColors.accentPrimary),
                            SizedBox(width: 4),
                            Text(
                              'Add Bill',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Empty State or List
                  if (bills.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderDefault),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_repeat_outlined, size: 48, color: colors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No recurring bills yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + Add Bill above to track your monthly subscriptions & due reminders.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: colors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => AddEditRecurringBillModal.show(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Your First Bill'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bills.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return RecurringBillCard(
                          bill: bill,
                          onEdit: () => AddEditRecurringBillModal.show(context, billToEdit: bill),
                          onDelete: () => _confirmDelete(context, bill),
                          onMarkPaid: () => _markPaid(bill),
                        );
                      },
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error loading recurring bills: $err',
                style: const TextStyle(color: AppColors.stateError),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
