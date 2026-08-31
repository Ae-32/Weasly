import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/budget_service.dart';
import '../utils/app_colors.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

/// Provider exposing the BudgetService instance.
final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService();
});

/// Real-time stream of all budgets for the current logged-in user.
final budgetsStreamProvider = StreamProvider<List<BudgetModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid ?? '';

  if (userId.isEmpty) {
    return Stream.value([]);
  }

  final service = ref.watch(budgetServiceProvider);
  return service.getBudgetsStream(userId);
});

/// Status classification for a budget based on current spending percentage.
enum BudgetStatus {
  safe,
  nearingLimit,
  overBudget;

  String get label {
    switch (this) {
      case BudgetStatus.nearingLimit:
        return 'Nearing limit';
      case BudgetStatus.overBudget:
        return 'Over budget';
      case BudgetStatus.safe:
        return 'On track';
    }
  }

  Color get color {
    switch (this) {
      case BudgetStatus.nearingLimit:
        return AppColors.stateWarning; // Amber #C5942C
      case BudgetStatus.overBudget:
        return AppColors.stateError; // Red #D64545
      case BudgetStatus.safe:
        return AppColors.accentSecondary; // Green #2B694E
    }
  }
}

/// Wrapper data class uniting a BudgetModel with its dynamically computed spending.
class BudgetWithSpent {
  final BudgetModel budget;
  final double spentAmount;

  const BudgetWithSpent({
    required this.budget,
    required this.spentAmount,
  });

  /// Percentage of budget spent (e.g. 75.5 for 75.5%).
  double get spentPercentage {
    if (budget.amount <= 0) return 0.0;
    return (spentAmount / budget.amount) * 100;
  }

  /// Progress ratio clamped for linear indicator bar (0.0 to 1.0).
  double get progressRatio {
    if (budget.amount <= 0) return 0.0;
    final ratio = spentAmount / budget.amount;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  /// Budget status based on thresholds: below alert threshold safe, >= alert threshold nearing limit, >= 100% over budget.
  BudgetStatus get status {
    final pct = spentPercentage;
    if (pct >= 100.0) {
      return BudgetStatus.overBudget;
    } else if (pct >= budget.alertThreshold) {
      return BudgetStatus.nearingLimit;
    } else {
      return BudgetStatus.safe;
    }
  }
}

/// Provider dynamically aggregating transactions to compute live spent amounts for all user budgets.
final budgetsWithSpentProvider = Provider<List<BudgetWithSpent>>((ref) {
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  final transactions = transactionsAsync.value ?? [];

  return budgetsAsync.when(
    data: (budgets) {
      return budgets.map((budget) {
        final (startDate, endDate) = budget.getEffectivePeriodRange();

        // Sum expense transactions in this category within the budget's period
        final double spentAmount = transactions.where((tx) {
          if (tx.type != TransactionType.expense) return false;
          if (tx.categoryId != budget.categoryId) return false;
          final isAfterStart = tx.date.isAfter(startDate) || tx.date.isAtSameMomentAs(startDate);
          final isBeforeEnd = tx.date.isBefore(endDate) || tx.date.isAtSameMomentAs(endDate);
          return isAfterStart && isBeforeEnd;
        }).fold(0.0, (sum, tx) => sum + tx.amount);

        return BudgetWithSpent(
          budget: budget,
          spentAmount: spentAmount,
        );
      }).toList();
    },
    loading: () => [],
    error: (err, stack) => [],
  );
});

/// UI Controller State for Budget Mutations.
class BudgetState {
  final bool isLoading;
  final String? errorMessage;

  const BudgetState({
    this.isLoading = false,
    this.errorMessage,
  });

  BudgetState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller managing Add, Update, and Delete actions for budgets.
class BudgetController extends StateNotifier<BudgetState> {
  final BudgetService _service;
  final Ref _ref;

  BudgetController(this._service, this._ref) : super(const BudgetState());

  String _getUserId() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw const BudgetException("User is not authenticated.");
    }
    return user.uid;
  }

  Future<bool> addBudget(BudgetModel budget) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.addBudget(userId, budget);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateBudget(BudgetModel budget) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.updateBudget(userId, budget);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteBudget(String budgetId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.deleteBudget(userId, budgetId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final budgetControllerProvider =
    StateNotifierProvider<BudgetController, BudgetState>((ref) {
  final service = ref.watch(budgetServiceProvider);
  return BudgetController(service, ref);
});
