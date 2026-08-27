import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kHasSeenOnboardingKey = 'has_seen_onboarding';

/// Provider for SharedPreferences instance, overridden at app startup in main().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

/// Controller managing the device-level onboarding completion status.
class OnboardingController extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardingController(this._prefs)
      : super(_prefs.getBool(_kHasSeenOnboardingKey) ?? false);

  /// Marks onboarding as completed and persists the flag in SharedPreferences.
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_kHasSeenOnboardingKey, true);
    state = true;
  }
}

/// Provider for reading and updating onboarding status.
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingController(prefs);
});
