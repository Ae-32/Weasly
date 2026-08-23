import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'accounts/accounts_screen.dart';
import 'dashboard/dashboard_screen.dart';

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

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF8A7F73)),
            const SizedBox(height: 16),
            Text(
              '$title Feature Coming Soon',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Will be implemented in the next unit.',
              style: TextStyle(color: Color(0xFF8A7F73)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      _buildPlaceholderTab('Transactions', Icons.receipt_long_rounded),
      _buildPlaceholderTab('Budgets', Icons.account_balance_wallet_rounded),
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
