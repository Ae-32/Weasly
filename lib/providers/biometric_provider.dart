import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_service.dart';
import 'onboarding_provider.dart';

const String _biometricEnabledKey = 'biometric_enabled';

/// Provider exposing the BiometricService instance.
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Controller managing the persistent "Enable biometric login" user setting.
class BiometricSettingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final BiometricService _biometricService;

  BiometricSettingNotifier(this._prefs, this._biometricService)
      : super(_prefs.getBool(_biometricEnabledKey) ?? false);

  /// Toggles biometric login setting.
  /// Returns (success: bool, errorMessage: String?)
  Future<(bool, String?)> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final canUseBiometrics = await _biometricService.canCheckBiometrics();
      if (!canUseBiometrics) {
        return (
          false,
          'Biometric authentication is not supported or set up on this device.'
        );
      }
    }

    await _prefs.setBool(_biometricEnabledKey, enabled);
    state = enabled;
    return (true, null);
  }
}

/// Provider exposing whether biometric login is enabled by the user.
final biometricEnabledProvider =
    StateNotifierProvider<BiometricSettingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final biometricService = ref.watch(biometricServiceProvider);
  return BiometricSettingNotifier(prefs, biometricService);
});

/// StateNotifier tracking whether the current app session is unlocked via biometrics.
class BiometricLockStateNotifier extends StateNotifier<bool> {
  BiometricLockStateNotifier() : super(false);

  void unlock() {
    state = true;
  }

  void lock() {
    state = false;
  }
}

/// Provider tracking whether the current app session has been unlocked.
final biometricUnlockedProvider =
    StateNotifierProvider<BiometricLockStateNotifier, bool>((ref) {
  return BiometricLockStateNotifier();
});
