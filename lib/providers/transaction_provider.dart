import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart';

/// Provider exposing the TransactionService instance.
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

/// Real-time stream of all transactions for the current logged-in user.
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid ?? '';

  if (userId.isEmpty) {
    return Stream.value([]);
  }

  final service = ref.watch(transactionServiceProvider);
  return service.getTransactionsStream(userId);
});

/// State providers for UI filtering on the Transactions screen.
final transactionCategoryFilterProvider = StateProvider<String?>((ref) => null);
final transactionAccountFilterProvider = StateProvider<String?>((ref) => null);
final transactionTypeFilterProvider = StateProvider<TransactionType?>((ref) => null);
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');

/// Computed provider returning the filtered transactions list based on active search & category/account filters.
final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final categoryFilter = ref.watch(transactionCategoryFilterProvider);
  final accountFilter = ref.watch(transactionAccountFilterProvider);
  final typeFilter = ref.watch(transactionTypeFilterProvider);
  final searchQuery = ref.watch(transactionSearchQueryProvider).trim().toLowerCase();

  return transactionsAsync.when(
    data: (transactions) {
      return transactions.where((tx) {
        // Category filter
        if (categoryFilter != null && categoryFilter.isNotEmpty) {
          if (tx.categoryId != categoryFilter) return false;
        }

        // Account filter
        if (accountFilter != null && accountFilter.isNotEmpty) {
          if (tx.accountId != accountFilter && tx.toAccountId != accountFilter) {
            return false;
          }
        }

        // Type filter
        if (typeFilter != null) {
          if (tx.type != typeFilter) return false;
        }

        // Search query (matches note, categoryName, or accountName)
        if (searchQuery.isNotEmpty) {
          final noteMatch = tx.note?.toLowerCase().contains(searchQuery) ?? false;
          final catMatch = tx.categoryName.toLowerCase().contains(searchQuery);
          final accMatch = tx.accountName.toLowerCase().contains(searchQuery);
          final toAccMatch = tx.toAccountName?.toLowerCase().contains(searchQuery) ?? false;

          if (!noteMatch && !catMatch && !accMatch && !toAccMatch) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (err, stack) => [],
  );
});

/// UI Controller State for Transaction Mutations.
class TransactionControllerState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const TransactionControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  TransactionControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return TransactionControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Controller managing Add, Update, and Delete actions for transactions.
class TransactionController extends StateNotifier<TransactionControllerState> {
  final TransactionService _service;
  final Ref _ref;

  TransactionController(this._service, this._ref)
      : super(const TransactionControllerState());

  String _getUserId() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw const TransactionException("User is not authenticated.");
    }
    return user.uid;
  }

  /// Adds a new transaction and updates account balance(s).
  Future<bool> addTransaction({
    required TransactionType type,
    required double amount,
    required String categoryId,
    required String categoryName,
    required String categoryIcon,
    required String categoryColorHex,
    required String accountId,
    required String accountName,
    String? toAccountId,
    String? toAccountName,
    required DateTime date,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.addTransaction(
        userId: userId,
        type: type,
        amount: amount,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        categoryColorHex: categoryColorHex,
        accountId: accountId,
        accountName: accountName,
        toAccountId: toAccountId,
        toAccountName: toAccountName,
        date: date,
        note: note,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: "Transaction recorded successfully!",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Updates an existing transaction.
  Future<bool> updateTransaction({
    required TransactionModel oldTx,
    required TransactionModel newTx,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.updateTransaction(
        userId: userId,
        oldTx: oldTx,
        newTx: newTx,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: "Transaction updated successfully!",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Deletes a transaction and restores account balance(s).
  Future<bool> deleteTransaction(TransactionModel tx) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.deleteTransaction(
        userId: userId,
        tx: tx,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: "Transaction deleted successfully!",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, TransactionControllerState>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return TransactionController(service, ref);
});
