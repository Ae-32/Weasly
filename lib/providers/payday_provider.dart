import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payday_settings_model.dart';
import '../services/payday_service.dart';
import 'auth_provider.dart';

/// Provider for accessing the PaydayService instance.
final paydayServiceProvider = Provider<PaydayService>((ref) {
  return PaydayService();
});

/// StreamProvider exposing real-time PaydaySettings for the logged-in user.
final paydaySettingsStreamProvider = StreamProvider<PaydaySettingsModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  final service = ref.watch(paydayServiceProvider);
  return service.getPaydaySettingsStream(user.uid);
});

/// Calculated model representing live Payday Info for UI countdown display.
class PaydayInfo {
  final PaydaySettingsModel settings;
  final int daysRemaining;
  final DateTime nextPaydayDate;
  final double expectedAmount;
  final bool isCustomExpired;

  const PaydayInfo({
    required this.settings,
    required this.daysRemaining,
    required this.nextPaydayDate,
    required this.expectedAmount,
    required this.isCustomExpired,
  });
}

/// Computed provider calculating countdown strictly from saved PaydaySettings.
/// Returns null if payday is not configured yet (no guessing from transactions).
final paydayCountdownProvider = Provider<PaydayInfo?>((ref) {
  final settingsAsync = ref.watch(paydaySettingsStreamProvider);
  final settings = settingsAsync.asData?.value;

  if (settings == null) {
    return null; // Triggers friendly empty state
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDate = settings.calculateNextUpcomingPayday(today);
  final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
  final days = targetDateOnly.difference(today).inDays;

  final isCustomExpired = settings.frequency == PaydayFrequency.custom && targetDateOnly.isBefore(today);

  return PaydayInfo(
    settings: settings,
    daysRemaining: days < 0 ? 0 : days,
    nextPaydayDate: targetDate,
    expectedAmount: settings.expectedAmount,
    isCustomExpired: isCustomExpired,
  );
});

/// State for PaydayController actions.
class PaydayState {
  final bool isLoading;
  final String? errorMessage;

  const PaydayState({
    this.isLoading = false,
    this.errorMessage,
  });

  PaydayState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return PaydayState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller managing saving and clearing user PaydaySettings.
class PaydayController extends StateNotifier<PaydayState> {
  final Ref _ref;

  PaydayController(this._ref) : super(const PaydayState());

  Future<bool> saveSettings(PaydaySettingsModel settings) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(errorMessage: 'User not authenticated.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = _ref.read(paydayServiceProvider);
      await service.savePaydaySettings(user.uid, settings);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> clearSettings() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(errorMessage: 'User not authenticated.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = _ref.read(paydayServiceProvider);
      await service.clearPaydaySettings(user.uid);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final paydayControllerProvider = StateNotifierProvider<PaydayController, PaydayState>((ref) {
  return PaydayController(ref);
});

