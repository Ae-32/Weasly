import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider managing the active bottom navigation tab index (0: Dashboard, 1: Transactions, 2: Budgets, 3: Accounts).
final homeNavIndexProvider = StateProvider<int>((ref) => 0);
