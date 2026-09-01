import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/account_card.dart';
import '../../widgets/payday_countdown_card.dart';

import '../auth/logout_confirmation_modal.dart';
import '../auth/logout_success_screen.dart';
import '../settings/settings_screen.dart';

/// Account & Stashes screen matching exact Figma CSS export & redesign specifications.
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

  void _confirmDelete(BuildContext context, WidgetRef ref, AccountModel account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Stash', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppColors.textMuted)),
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
            child: Text('Delete', style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final paydayInfo = ref.watch(paydayCountdownProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row (Logo, Title, Subtitle, Action Buttons)
              _buildTopHeader(context, ref),

              // Content Canvas Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Payday Countdown Card Banner (Overlapping Weasly Mascot)
                    PaydayCountdownCard(paydayInfo: paydayInfo),
                    const SizedBox(height: 40),

                    // 3. Stashes Header Row ("Stashes" + "+ Add New Stash")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Stashes',
                          style: GoogleFonts.quicksand(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF211A16),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAccountDialog(context, ref),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_rounded, size: 16, color: AppColors.accentPrimary),
                              const SizedBox(width: 4),
                              Text(
                                'Add New Stash',
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4. Main White Card Container (Total Balance Summary + Stashes List)
                    _buildMainStashesCard(context, ref, accountsAsync, totalBalance, currencyFormatter),
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

  /// Top Header Bar matching exact Figma spec & screenshot layout
  Widget _buildTopHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 18.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Weasly App Logo Badge (Left) & Action Buttons (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Weasly App Logo Badge
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/Weasly_Logo.png'),
                    fit: BoxFit.cover,
                  ),
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
          const SizedBox(height: 16),

          // Title: "Account"
          Text(
            'Account',
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF211A16),
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Manage your stashes, balances, and savings.',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8A7F73),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.iconButtonBg,
          shape: BoxShape.circle,
          boxShadow: [
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

  /// Main Card holding Total Balance, Donut Chart, Mascot, and Stashes List
  Widget _buildMainStashesCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AccountModel>> accountsAsync,
    double totalBalance,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: accountsAsync.when(
        data: (accounts) {
          // Filter positive accounts (accounts with balance > 0)
          final positiveAccounts = accounts.where((a) => a.balance > 0).toList()
            ..sort((a, b) => b.balance.compareTo(a.balance));

          final sumPositive = positiveAccounts.fold(0.0, (sum, a) => sum + a.balance);

          // Calculate callout percentage labels for top positive accounts
          final p1 = sumPositive > 0 && positiveAccounts.isNotEmpty
              ? ((positiveAccounts[0].balance / sumPositive) * 100).toStringAsFixed(0)
              : null;
          final p2 = sumPositive > 0 && positiveAccounts.length > 1
              ? ((positiveAccounts[1].balance / sumPositive) * 100).toStringAsFixed(0)
              : null;
          final p3 = sumPositive > 0 && positiveAccounts.length > 2
              ? ((positiveAccounts[2].balance / sumPositive) * 100).toStringAsFixed(0)
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Balance & Donut Chart & Overlapping Mascot
              SizedBox(
                height: 210,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Balance & Subtitle & Donut Chart Column on Left
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF8A7F73),
                            ),
                          ),
                          const SizedBox(height: 2),
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
                          const SizedBox(height: 2),
                          Text(
                            'Across ${accounts.length} ${accounts.length == 1 ? 'Category' : 'Categories'}',
                            style: GoogleFonts.quicksand(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9A9998),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Donut Chart with Dynamic Segment Callout Badges
                          SizedBox(
                            width: 140,
                            height: 110,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 26,
                                      sections: positiveAccounts.isEmpty
                                          ? [
                                              PieChartSectionData(
                                                color: AppColors.accentPrimaryLight,
                                                value: 1,
                                                title: '',
                                                radius: 14,
                                              ),
                                            ]
                                          : List.generate(positiveAccounts.length, (index) {
                                              final acc = positiveAccounts[index];
                                              final colors = [
                                                const Color(0xFFEE4818),
                                                const Color(0xFFF59715),
                                                const Color(0xFFE05F03),
                                                const Color(0xFFF48423),
                                              ];
                                              return PieChartSectionData(
                                                color: colors[index % colors.length],
                                                value: acc.balance,
                                                title: '',
                                                radius: 14,
                                              );
                                            }),
                                    ),
                                  ),
                                ),

                                // Dynamic Callout Badges
                                if (p1 != null)
                                  Positioned(
                                    left: 2,
                                    top: 14,
                                    child: _buildBadge('$p1%', const Color(0xFFEE4818)),
                                  ),

                                if (p2 != null)
                                  Positioned(
                                    right: 6,
                                    top: 8,
                                    child: _buildBadge('$p2%', const Color(0xFFF59715)),
                                  ),

                                if (p3 != null)
                                  Positioned(
                                    right: 20,
                                    bottom: 2,
                                    child: _buildBadge('$p3%', const Color(0xFFE05F03)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Mascot Illustration on Right Side (Flipped horizontally to face left towards the text)
                    Positioned(
                      right: -14,
                      top: -20,
                      width: 260,
                      height: 260,
                      child: Transform.flip(
                        flipX: true,
                        child: Image.asset(
                          'assets/images/Weasly_Account_Stashes.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/Weasly_Account_TotalBalance.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
              const SizedBox(height: 12),

              // Stashes List Items
              if (accounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No stashes created yet.',
                          style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...accounts.map((acc) {
                  return AccountCard(
                    account: acc,
                    totalBalance: totalBalance,
                    onEdit: () => _showAccountDialog(context, ref, acc),
                    onDelete: () => _confirmDelete(context, ref, acc),
                  );
                }),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Text(
          'Error loading accounts: $err',
          style: GoogleFonts.quicksand(color: AppColors.stateError),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(205, 204, 204, 0.6),
            blurRadius: 4,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.amaranth(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
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
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Account Name
              Text('Account Name', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Cash Wallet, GCash'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter an account name' : null,
              ),
              const SizedBox(height: 16),

              // Account Type Selector Chips
              Text('Account Type', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                        Text(type.$2, style: GoogleFonts.quicksand()),
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
                Text('Starting Balance (₱)', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                          style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Note / Description
              Text('Note (Optional)', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                      : Text(isEdit ? 'Update Account' : 'Save Account', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
