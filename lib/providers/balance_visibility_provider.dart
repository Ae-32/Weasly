import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_provider.dart';

const String kHideAccountBalanceKey = 'hide_account_balance';
const String kHiddenBalanceMask = '• • • • •';

/// Controller managing the persistent "Hide Account Balance" privacy setting.
class BalanceVisibilityNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  BalanceVisibilityNotifier(this._prefs)
      : super(_prefs.getBool(kHideAccountBalanceKey) ?? false);

  /// Toggles the balance visibility preference and persists it to SharedPreferences.
  Future<void> toggle() async {
    final newValue = !state;
    await _prefs.setBool(kHideAccountBalanceKey, newValue);
    state = newValue;
  }

  /// Explicitly sets the balance hidden status and persists it.
  Future<void> setHideBalance(bool hide) async {
    await _prefs.setBool(kHideAccountBalanceKey, hide);
    state = hide;
  }
}

/// Provider exposing whether account and total balances should be concealed for privacy.
final balanceVisibilityProvider =
    StateNotifierProvider<BalanceVisibilityNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BalanceVisibilityNotifier(prefs);
});
