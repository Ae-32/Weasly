import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/account_card.dart';
import '../../widgets/payday_countdown_card.dart';
import '../../widgets/percentage_speech_bubble.dart';
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
                                      startDegreeOffset: -90,
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

                                // Dynamic Clockwise Slice-Anchored Percentage Badges
                                ..._buildAccountPercentageBubbles(positiveAccounts, sumPositive),
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

  /// Dynamic Clockwise Slice-Anchored Percentage Badges for Accounts Pie Chart
  List<Widget> _buildAccountPercentageBubbles(
    List<AccountModel> positiveAccounts,
    double sumPositive,
  ) {
    if (sumPositive <= 0 || positiveAccounts.isEmpty) return [];

    final widgets = <Widget>[];
    double currentAngle = -90.0; // fl_chart startDegreeOffset (top center)

    final colors = [
      const Color(0xFFEE4818),
      const Color(0xFFF59715),
      const Color(0xFFE05F03),
      const Color(0xFFF48423),
    ];

    for (int i = 0; i < math.min(positiveAccounts.length, 3); i++) {
      final acc = positiveAccounts[i];
      final fraction = acc.balance / sumPositive;
      final pct = (fraction * 100).round();
      final angleSpan = fraction * 360.0;
      final midAngle = currentAngle + (angleSpan / 2.0);
      currentAngle += angleSpan;

      if (pct < 1) continue;

      final rad = midAngle * (math.pi / 180.0);
      const centerX = 70.0;
      const centerY = 55.0;
      const radius = 46.0;

      final targetX = centerX + radius * math.cos(rad);
      final targetY = centerY + radius * math.sin(rad);

      final normAngle = (midAngle % 360.0 + 360.0) % 360.0;
      double left;
      double top;

      if (normAngle >= 270 || normAngle < 0) {
        left = targetX - 4;
        top = targetY - 20;
      } else if (normAngle >= 0 && normAngle < 90) {
        left = targetX - 4;
        top = targetY - 4;
      } else if (normAngle >= 90 && normAngle < 180) {
        left = targetX - 28;
        top = targetY - 4;
      } else {
        left = targetX - 28;
        top = targetY - 20;
      }

      final color = colors[i % colors.length];

      widgets.add(
        Positioned(
          left: left,
          top: top,
          child: PercentageSpeechBubble(
            text: '$pct%',
            backgroundColor: color,
            textColor: Colors.white,
          ),
        ),
      );
    }

    return widgets;
  }
}

/// Data helper for rendering fixed account type options in the UI.
class _AccountTypeOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgOverlay;
  final String subtitle;

  const _AccountTypeOption({
    required this.key,
    required this.label,
    required this.icon,
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

  static const List<_AccountTypeOption> _availableTypes = [
    _AccountTypeOption(
      key: AccountModel.typeCash,
      label: AccountModel.nameCash,
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFEE4818),
      bgOverlay: Color(0xFFFCDED5),
      subtitle: 'Everyday cash',
    ),
    _AccountTypeOption(
      key: AccountModel.typeDigital,
      label: AccountModel.nameDigital,
      icon: Icons.phone_iphone_rounded,
      color: Color(0xFFE08B03),
      bgOverlay: Color(0xFFFCE9D6),
      subtitle: 'GCash, Maya, etc.',
    ),
    _AccountTypeOption(
      key: AccountModel.typeBank,
      label: AccountModel.nameBank,
      icon: Icons.account_balance_rounded,
      color: Color(0xFFF48423),
      bgOverlay: Color(0xFFFBE4D2),
      subtitle: 'Savings & salary',
    ),
    _AccountTypeOption(
      key: AccountModel.typeOther,
      label: 'Other',
      icon: Icons.more_horiz_rounded,
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

              // Account Type Selector Grid (Cards)
              Text(
                'Select Stash Type',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _availableTypes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.3,
                ),
                itemBuilder: (context, index) {
                  final option = _availableTypes[index];
                  final isSelected = _selectedType == option.key;
                  final isDuplicate = AccountModel.isDuplicateType(
                    option.key,
                    widget.existingAccounts,
                    excludeAccountId: widget.accountToEdit?.id,
                  );

                  return GestureDetector(
                    onTap: isDuplicate
                        ? null
                        : () {
                            setState(() {
                              _selectedType = option.key;
                            });
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDuplicate
                            ? const Color(0xFFF4F1ED)
                            : (isSelected ? option.bgOverlay : AppColors.bgSurface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDuplicate
                              ? const Color(0xFFE8E1D8)
                              : (isSelected ? option.color : AppColors.borderDefault),
                          width: isSelected && !isDuplicate ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isDuplicate
                                        ? AppColors.textMuted
                                        : (isSelected ? option.color : AppColors.textPrimary),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  isDuplicate ? 'Already added' : option.subtitle,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 10,
                                    fontWeight: isDuplicate ? FontWeight.w700 : FontWeight.w400,
                                    color: isDuplicate ? AppColors.stateError : AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Custom Name Input Field (Shown specifically when 'Other' is selected)
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
