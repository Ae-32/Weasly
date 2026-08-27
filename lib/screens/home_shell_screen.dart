import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'accounts/accounts_screen.dart';
import 'dashboard/dashboard_screen.dart';

import 'budgets/budgets_screen.dart';
import 'transactions/transactions_screen.dart';

/// Main container screen holding bottom navigation bar and page tabs.
class HomeShellScreen extends StatefulWidget {
  final int initialIndex;

  const HomeShellScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const TransactionsScreen(),
      const BudgetsScreen(),
      const AccountsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
