import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_model.dart';
import '../services/account_service.dart';
import 'auth_provider.dart';

/// Provider for accessing the AccountService instance.
final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService();
});

/// StreamProvider exposing the current user's list of accounts in real-time.
final accountsStreamProvider = StreamProvider<List<AccountModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  final accountService = ref.watch(accountServiceProvider);

  // Auto-seed default accounts for first-time users
  accountService.seedDefaultAccountsIfEmpty(user.uid);

  return accountService.getAccountsStream(user.uid);
});

/// Provider computing the exact total balance sum across all user accounts.
final totalBalanceProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsStreamProvider);
  return accountsAsync.when(
    data: (accounts) => accounts.fold(0.0, (sum, acc) => sum + acc.balance),
    loading: () => 0.0,
    error: (_, stack) => 0.0,
  );
});

/// UI State class for account operations.
class AccountState {
  final bool isLoading;
  final String? errorMessage;

  const AccountState({
    this.isLoading = false,
    this.errorMessage,
  });

  AccountState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Controller managing account actions (add, edit, delete).
class AccountController extends StateNotifier<AccountState> {
  final AccountService _service;
  final Ref _ref;

  AccountController(this._service, this._ref) : super(const AccountState());

  String? get _currentUserId => _ref.read(authStateProvider).value?.uid;

  Future<bool> addAccount(AccountModel account) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.addAccount(uid, account);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAccount(AccountModel account) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.updateAccount(uid, account);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.deleteAccount(uid, accountId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

/// Provider for accessing the AccountController in UI widgets.
final accountControllerProvider = StateNotifierProvider<AccountController, AccountState>((ref) {
  final service = ref.watch(accountServiceProvider);
  return AccountController(service, ref);
});
