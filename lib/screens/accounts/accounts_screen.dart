import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/account_card.dart';

import '../categories/categories_screen.dart';
import '../recurring_bills/recurring_bills_screen.dart';

/// Accounts overview screen matching design-reference/accounts_overview/code.html.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showAccountDialog(BuildContext context, WidgetRef ref, [AccountModel? accountToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AccountFormBottomSheet(accountToEdit: accountToEdit),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AccountModel account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stateError,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref.read(accountControllerProvider.notifier).deleteAccount(account.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${account.name}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDCC1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgBase, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/images/Weasly.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets_rounded,
                    size: 20,
                    color: Color(0xFF512A00),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Weasly',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecurringBillsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.event_repeat_rounded, color: AppColors.accentPrimary),
            tooltip: 'Recurring Bills',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.category_rounded, color: AppColors.accentPrimary),
            tooltip: 'Categories',
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Balance Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(totalBalance),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Header Row ("Your Stashes" + Add button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Your Stashes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAccountDialog(context, ref),
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: AppColors.accentPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Add',
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

              // Accounts List
              accountsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No accounts yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap + Add above to create your first stash.',
                            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: accounts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      return AccountCard(
                        account: acc,
                        onEdit: () => _showAccountDialog(context, ref, acc),
                        onDelete: () => _confirmDelete(context, ref, acc),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.stateError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Error loading accounts: $err',
                    style: const TextStyle(color: AppColors.stateError),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form Modal Bottom Sheet for Adding or Editing an Account.
class _AccountFormBottomSheet extends ConsumerStatefulWidget {
  final AccountModel? accountToEdit;

  const _AccountFormBottomSheet({this.accountToEdit});

  @override
  ConsumerState<_AccountFormBottomSheet> createState() => _AccountFormBottomSheetState();
}

class _AccountFormBottomSheetState extends ConsumerState<_AccountFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _noteController;
  String _selectedType = 'cash';

  final List<(String, String, IconData)> _accountTypes = const [
    ('cash', 'Cash', Icons.payments_rounded),
    ('gcash', 'GCash', Icons.phone_iphone_rounded),
    ('bank', 'Bank', Icons.account_balance_rounded),
    ('savings', 'Savings', Icons.savings_rounded),
    ('credit', 'Credit', Icons.credit_card_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.accountToEdit;
    _nameController = TextEditingController(text: acc?.name ?? '');
    _balanceController = TextEditingController(text: acc != null ? acc.balance.toStringAsFixed(2) : '');
    _noteController = TextEditingController(text: acc?.note ?? '');
    _selectedType = acc?.type ?? 'cash';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.accountToEdit != null;
    final balanceVal = isEdit
        ? widget.accountToEdit!.balance
        : (double.tryParse(_balanceController.text.trim()) ?? 0.0);

    final newAccount = AccountModel(
      id: isEdit ? widget.accountToEdit!.id : '',
      name: _nameController.text.trim(),
      type: _selectedType,
      balance: balanceVal,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      createdAt: widget.accountToEdit?.createdAt ?? DateTime.now(),
    );

    final notifier = ref.read(accountControllerProvider.notifier);
    final success = isEdit
        ? await notifier.updateAccount(newAccount)
        : await notifier.addAccount(newAccount);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.accountToEdit != null;
    final accountState = ref.watch(accountControllerProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Padding(
      padding: EdgeInsets.only(
        top: 24.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Stash' : 'New Stash',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Account Name
              const Text('Account Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Cash Wallet, GCash'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter an account name' : null,
              ),
              const SizedBox(height: 16),

              // Account Type Selector Chips
              const Text('Account Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _accountTypes.map((type) {
                  final isSelected = _selectedType == type.$1;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type.$3, size: 16, color: isSelected ? Colors.white : AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text(type.$2),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accentPrimary,
                    backgroundColor: AppColors.bgBase,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type.$1);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Balance handling: editable only when creating NEW account
              if (!isEdit) ...[
                const Text('Starting Balance (₱)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '0.00'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter a balance';
                    if (double.tryParse(val.trim()) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgBase,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Current Balance: ${currencyFormatter.format(widget.accountToEdit!.balance)}\nTo adjust balance, log an expense or income in Transactions.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Note / Description
              const Text('Note (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(hintText: 'e.g. Everyday spending'),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: accountState.isLoading ? null : _save,
                  child: accountState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(isEdit ? 'Update Account' : 'Save Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
