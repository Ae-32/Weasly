import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/balance_visibility_provider.dart';
import '../../providers/payday_provider.dart';
import '../../utils/app_colors.dart';


import '../../utils/default_categories.dart';
import '../../widgets/account_card.dart';
import '../../widgets/payday_countdown_card.dart';
import '../../widgets/payday_reminder_banner.dart';
import '../../widgets/success_banner.dart';
import '../../widgets/weasly_app_header.dart';

/// Account & Stashes screen matching exact Figma CSS export & redesign specifications.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showAccountDialog(BuildContext context, WidgetRef ref, [AccountModel? accountToEdit]) {
    final existingAccounts = ref.read(accountsStreamProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AccountFormBottomSheet(
        accountToEdit: accountToEdit,
        existingAccounts: existingAccounts,
      ),
    );
  }

  void _confirmDelete(BuildContext parentContext, WidgetRef ref, AccountModel account) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Stash', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref.read(accountControllerProvider.notifier).deleteAccount(account.id);
              if (success && parentContext.mounted) {
                SuccessBanner.show(parentContext, 'Stash deleted!');
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fixed Top Header Bar (Logo, Action Buttons)
            const WeaslyAppHeader(),

            // 2. Scrollable Content Canvas Container
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Scrollable Page Title & Subtitle
                      Text(
                        'Account',
                        style: GoogleFonts.quicksand(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF211A16),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your stashes, balances, and savings.',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8A7F73),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Payday Reminder Banner & Payday Countdown Card
                      const PaydayReminderBanner(),
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
                        Row(
                          children: [
                            if (accountsAsync.value != null &&
                                accountsAsync.value!.isNotEmpty &&
                                accountsAsync.value!.every((a) => a.balance == 0)) ...[
                              GestureDetector(
                                onTap: () async {
                                  await ref.read(accountControllerProvider.notifier).clearZeroBalanceAccounts();
                                  if (context.mounted) {
                                    SuccessBanner.show(context, 'Cleared empty stashes!');
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_sweep_rounded, size: 16, color: AppColors.stateError),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Clear Empty Stashes',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.stateError,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
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
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4. Main White Card Container (Total Balance Summary + Stashes List)
                    _buildMainStashesCard(context, ref, accountsAsync, totalBalance, currencyFormatter),
                    const SizedBox(height: 24),
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

  /// Main Card holding Total Balance, Donut Chart, Mascot, and Stashes List
  Widget _buildMainStashesCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AccountModel>> accountsAsync,
    double totalBalance,
    NumberFormat currencyFormatter,
  ) {
    final isBalanceHidden = ref.watch(balanceVisibilityProvider);
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
          if (accounts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
              child: Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/Weasly_Account_NoStashes.png',
                      height: 140,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/images/Weasly_NoTransaction.png', height: 140),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Stashes Created Yet',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start organizing your finances by adding your first stash (Cash, Digital, Bank, or Custom).',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showAccountDialog(context, ref),
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      label: Text(
                        'Add Your First Stash',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Filter positive accounts (accounts with balance > 0)
          final positiveAccounts = accounts.where((a) => a.balance > 0).toList()
            ..sort((a, b) => b.balance.compareTo(a.balance));

          final sumPositive = positiveAccounts.fold(0.0, (sum, a) => sum + a.balance);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Balance & Donut Chart & Overlapping Mascot
              SizedBox(
                height: 260,
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total Balance',
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF8A7F73),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    ref.read(balanceVisibilityProvider.notifier).toggle(),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0, vertical: 2.0),
                                  child: Icon(
                                    isBalanceHidden
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 18,
                                    color: const Color(0xFF8A7F73),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(opacity: animation, child: child),
                              child: Text(
                                isBalanceHidden
                                    ? '${currencyFormatter.currencySymbol} $kHiddenBalanceMask'
                                    : currencyFormatter.format(totalBalance),
                                key: ValueKey<bool>(isBalanceHidden),
                                style: GoogleFonts.quicksand(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Across ${accounts.length} ${accounts.length == 1 ? 'Stash' : 'Stashes'}',
                            style: GoogleFonts.quicksand(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9A9998),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Donut Chart with Dynamic Interactive Slices (Matching Spending Category Chart)
                          _StashDonutChart(
                            positiveAccounts: positiveAccounts,
                            sumPositive: sumPositive,
                            getAccountColor: _getAccountColor,
                          ),
                        ],
                      ),
                    ),


                    // Mascot Illustration on Right Side (Flipped horizontally to face left towards the text)
                    Positioned(
                      right: -40,
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
              ...accounts.map((acc) {
                return AccountCard(
                  account: acc,
                  totalBalance: totalBalance,
                  isBalanceHidden: isBalanceHidden,
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

  Color _getAccountColor(AccountModel account) {
    if (account.colorHex != null && account.colorHex!.isNotEmpty) {
      return DefaultCategories.getColor(account.colorHex!);
    }
    switch (account.type.toLowerCase()) {
      case 'gcash':
      case 'e-wallet':
      case 'ewallet':
      case 'digital':
      case 'digital_stash':
        return const Color(0xFFE08B03);
      case 'bank':
      case 'bank_wallet':
        return const Color(0xFFF48423);
      case 'savings':
        return const Color(0xFFE05F03);
      case 'credit':
        return AppColors.stateError;
      case 'other':
        return const Color(0xFF8A7F73);
      case 'cash':
      default:
        return const Color(0xFFEE4818);
    }
  }

}

/// Interactive Donut Chart for Stashes with slice pop-out or floating speech bubbles based on user setting
class _StashDonutChart extends ConsumerStatefulWidget {
  final List<AccountModel> positiveAccounts;
  final double sumPositive;
  final Color Function(AccountModel) getAccountColor;

  const _StashDonutChart({
    required this.positiveAccounts,
    required this.sumPositive,
    required this.getAccountColor,
  });

  @override
  ConsumerState<_StashDonutChart> createState() => _StashDonutChartState();
}

class _StashDonutChartState extends ConsumerState<_StashDonutChart> {
  int _touchedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeAcc = (widget.positiveAccounts.isNotEmpty &&
            _touchedIndex >= 0 &&
            _touchedIndex < widget.positiveAccounts.length)
        ? widget.positiveAccounts[_touchedIndex]
        : null;

    final activePct = (activeAcc != null && widget.sumPositive > 0)
        ? ((activeAcc.balance / widget.sumPositive) * 100).round()
        : 0;

    final activeColor = activeAcc != null
        ? widget.getAccountColor(activeAcc)
        : AppColors.accentPrimary;

    return SizedBox(
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
                  if (idx >= 0 && idx < widget.positiveAccounts.length) {
                    setState(() {
                      _touchedIndex = idx;
                    });
                  }
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
              sections: widget.positiveAccounts.isEmpty
                  ? [
                      PieChartSectionData(
                        color: AppColors.accentPrimaryLight,
                        value: 1,
                        title: '',
                        radius: 14,
                      ),
                    ]
                  : List.generate(widget.positiveAccounts.length, (index) {
                      final acc = widget.positiveAccounts[index];
                      final isTouched = index == _touchedIndex;
                      return PieChartSectionData(
                        color: widget.getAccountColor(acc),
                        value: acc.balance,
                        title: '',
                        radius: isTouched ? 18 : 14,
                      );
                    }),
            ),
          ),

          // Center Label (Active Account focus indicator or default 'Stashes')
          if (activeAcc == null)
            Text(
              'Stashes',
              style: GoogleFonts.quicksand(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accentPrimary,
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 52),
                  child: Text(
                    activeAcc.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '$activePct%',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: activeColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Data helper for rendering fixed account type options in the UI.
class _AccountTypeOption {
  final String key;
  final String label;
  final IconData icon;
  final String assetPath;
  final Color color;
  final Color bgOverlay;
  final String subtitle;

  const _AccountTypeOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.assetPath,
    required this.color,
    required this.bgOverlay,
    required this.subtitle,
  });
}

/// Form Modal Bottom Sheet for Adding or Editing an Account.
class _AccountFormBottomSheet extends ConsumerStatefulWidget {
  final AccountModel? accountToEdit;
  final List<AccountModel> existingAccounts;

  const _AccountFormBottomSheet({
    this.accountToEdit,
    this.existingAccounts = const [],
  });

  @override
  ConsumerState<_AccountFormBottomSheet> createState() => _AccountFormBottomSheetState();
}

class _AccountFormBottomSheetState extends ConsumerState<_AccountFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customNameController;
  late TextEditingController _balanceController;
  late TextEditingController _noteController;
  String _selectedType = AccountModel.typeCash;
  String _selectedColorHex = '8A7F73';

  static const List<String> _stashColorOptions = [
    '8A7F73', // Neutral Grey (Default)
    '2B506E', // Navy Blue
    '7C4DFF', // Deep Violet
    '00838F', // Teal Green
    '2E7D32', // Forest Green
    '1565C0', // Royal Blue
    'C20429', // Crimson Red
    'FB7140', // Coral Orange
    'F7C500', // Golden Yellow
    '623A97', // Rich Purple
    '05A789', // Emerald
    '009AC6', // Sky Blue
  ];

  static const List<_AccountTypeOption> _availableTypes = [
    _AccountTypeOption(
      key: AccountModel.typeCash,
      label: AccountModel.nameCash,
      icon: Icons.account_balance_wallet_rounded,
      assetPath: 'assets/Weasly_Icons/Cash_Stash.png',
      color: Color(0xFFEE4818),
      bgOverlay: Color(0xFFFCDED5),
      subtitle: 'Everyday cash',
    ),
    _AccountTypeOption(
      key: AccountModel.typeDigital,
      label: AccountModel.nameDigital,
      icon: Icons.phone_iphone_rounded,
      assetPath: 'assets/Weasly_Icons/Digital_Stash.png',
      color: Color(0xFFE08B03),
      bgOverlay: Color(0xFFFCE9D6),
      subtitle: 'GCash, Maya, etc.',
    ),
    _AccountTypeOption(
      key: AccountModel.typeBank,
      label: AccountModel.nameBank,
      icon: Icons.account_balance_rounded,
      assetPath: 'assets/Weasly_Icons/Bank_Stash.png',
      color: Color(0xFFF48423),
      bgOverlay: Color(0xFFFBE4D2),
      subtitle: 'Savings & salary',
    ),
    _AccountTypeOption(
      key: AccountModel.typeOther,
      label: 'Other',
      icon: Icons.more_horiz_rounded,
      assetPath: 'assets/Weasly_Icons/Other_Stash.png',
      color: Color(0xFF8A7F73),
      bgOverlay: Color(0xFFEDE0D9),
      subtitle: 'Crypto, custom stash',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.accountToEdit;
    _balanceController = TextEditingController(
      text: acc != null ? acc.balance.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: acc?.note ?? '');

    if (acc != null) {
      _selectedType = acc.type;
      _customNameController = TextEditingController(text: acc.name);
      if (acc.colorHex != null && acc.colorHex!.isNotEmpty) {
        _selectedColorHex = acc.colorHex!;
      }
    } else {
      _customNameController = TextEditingController();
      // Select the first non-duplicate account type option
      for (final option in _availableTypes) {
        if (!AccountModel.isDuplicateType(option.key, widget.existingAccounts)) {
          _selectedType = option.key;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
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

    final String finalName;
    if (_selectedType == AccountModel.typeOther) {
      finalName = _customNameController.text.trim();
    } else {
      final option = _availableTypes.firstWhere(
        (o) => o.key == _selectedType,
        orElse: () => _availableTypes.first,
      );
      finalName = option.label;
    }

    final newAccount = AccountModel(
      id: isEdit ? widget.accountToEdit!.id : '',
      name: finalName,
      type: _selectedType,
      balance: balanceVal,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      colorHex: _selectedType == AccountModel.typeOther ? _selectedColorHex : null,
      createdAt: widget.accountToEdit?.createdAt ?? DateTime.now(),
    );

    final notifier = ref.read(accountControllerProvider.notifier);
    final success = isEdit
        ? await notifier.updateAccount(newAccount)
        : await notifier.addAccount(newAccount);

    if (success && mounted) {
      SuccessBanner.show(
        context,
        isEdit ? 'Stash updated!' : 'Stash added!',
      );
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
              // Header
              Text(
                isEdit ? 'Edit Stash' : 'New Stash',
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Display Error Message if any
              if (accountState.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.stateError.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.stateError.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.stateError),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          accountState.errorMessage!,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.stateError,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Account Type Selector Custom Dropdown (Expands downwards)
              Text(
                'Select Stash Type',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final selectedOption = _availableTypes.firstWhere(
                    (o) => o.key == _selectedType,
                    orElse: () => _availableTypes.first,
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return PopupMenuButton<_AccountTypeOption>(
                        position: PopupMenuPosition.under,
                        color: AppColors.bgSurface,
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.borderDefault),
                        ),
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          maxHeight: 300,
                        ),
                        itemBuilder: (context) {
                          return _availableTypes.map((option) {
                            final isSelected = _selectedType == option.key;
                            final isDuplicate = AccountModel.isDuplicateType(
                              option.key,
                              widget.existingAccounts,
                              excludeAccountId: widget.accountToEdit?.id,
                            );

                            final isOtherOption = option.key == AccountModel.typeOther;
                            final optionColor = isOtherOption
                                ? Color(int.parse('FF$_selectedColorHex', radix: 16))
                                : option.color;
                            final optionBgOverlay = isOtherOption
                                ? Color.alphaBlend(optionColor.withValues(alpha: 0.15), Colors.white)
                                : option.bgOverlay;

                            Widget optionIconWidget;
                            if (isOtherOption) {
                              optionIconWidget = Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDuplicate ? const Color(0xFFE5DFD7) : optionBgOverlay,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    option.icon,
                                    size: 18,
                                    color: isDuplicate ? AppColors.textMuted : optionColor,
                                  ),
                                ),
                              );
                            } else {
                              optionIconWidget = Image.asset(
                                option.assetPath,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDuplicate
                                        ? const Color(0xFFE5DFD7)
                                        : (isSelected ? option.color : option.bgOverlay),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    size: 18,
                                    color: isDuplicate
                                        ? AppColors.textMuted
                                        : (isSelected ? Colors.white : option.color),
                                  ),
                                ),
                              );
                            }

                            return PopupMenuItem<_AccountTypeOption>(
                              value: option,
                              enabled: !isDuplicate,
                              height: 52,
                              child: Row(
                                children: [
                                  optionIconWidget,
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          option.label,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isDuplicate
                                                ? AppColors.textMuted
                                                : (isSelected ? optionColor : AppColors.textPrimary),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          isDuplicate ? 'Already added' : option.subtitle,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 10,
                                            fontWeight: isDuplicate ? FontWeight.w700 : FontWeight.w400,
                                            color: isDuplicate ? AppColors.stateError : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected && !isDuplicate)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: optionColor,
                                    ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        onSelected: (option) {
                          setState(() {
                            _selectedType = option.key;
                          });
                        },
                        child: Builder(
                          builder: (context) {
                            final isSelectedOther = selectedOption.key == AccountModel.typeOther;
                            final selectedColor = isSelectedOther
                                ? Color(int.parse('FF$_selectedColorHex', radix: 16))
                                : selectedOption.color;
                            final selectedBgOverlay = isSelectedOther
                                ? Color.alphaBlend(selectedColor.withValues(alpha: 0.15), Colors.white)
                                : selectedOption.bgOverlay;

                            Widget selectedIconWidget;
                            if (isSelectedOther) {
                              selectedIconWidget = Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: selectedBgOverlay,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    selectedOption.icon,
                                    size: 16,
                                    color: selectedColor,
                                  ),
                                ),
                              );
                            } else {
                              selectedIconWidget = Image.asset(
                                selectedOption.assetPath,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: selectedOption.bgOverlay,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    selectedOption.icon,
                                    size: 16,
                                    color: selectedOption.color,
                                  ),
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderDefault,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  selectedIconWidget,
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedOption.label,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Custom Name Input & Color Selector (Shown specifically when 'Other' is selected)
              if (_selectedType == AccountModel.typeOther) ...[
                Text(
                  'Stash Name',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _customNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Crypto Wallet, Piggy Bank',
                  ),
                  validator: (val) {
                    if (_selectedType == AccountModel.typeOther) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a name for this stash';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Color Selection Palette
                Text(
                  'Stash Color',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _stashColorOptions.map((hex) {
                    final color = DefaultCategories.getColor(hex);
                    final isSelected = _selectedColorHex.toLowerCase() == hex.toLowerCase();

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColorHex = hex;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.textPrimary : Colors.transparent,
                            width: isSelected ? 3.0 : 0.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Balance handling: editable only when creating NEW account
              if (!isEdit) ...[
                Text(
                  'Starting Balance (₱)',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
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
              Text(
                'Note (Optional)',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(hintText: 'e.g. Everyday spending, emergency fund'),
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
                      : Text(
                          isEdit ? 'Update Stash' : 'Save Stash',
                          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
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
