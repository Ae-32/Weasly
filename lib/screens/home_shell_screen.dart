import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_nav_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'accounts/accounts_screen.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';

/// Main container screen holding bottom navigation bar and page tabs.
class HomeShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeShellScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeNavIndexProvider.notifier).state = widget.initialIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeNavIndexProvider);

    final pages = [
      const DashboardScreen(),
      const TransactionsScreen(),
      const BudgetsScreen(),
      const AccountsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}

