import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pin_service.dart';

/// Provider exposing the PinService instance.
final pinServiceProvider = Provider<PinService>((ref) {
  return PinService();
});

/// StateNotifier tracking whether a PIN is set up on this device.
class PinSetStateNotifier extends StateNotifier<bool> {
  final PinService _pinService;

  PinSetStateNotifier(this._pinService) : super(false) {
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await _pinService.hasPin();
    state = hasPin;
  }

  /// Sets up or updates the PIN.
  Future<void> setupPin(String pin) async {
    await _pinService.savePin(pin);
    state = true;
  }

  /// Verifies whether an entered PIN is correct.
  Future<bool> verifyPin(String pin) async {
    return await _pinService.verifyPin(pin);
  }

  /// Removes the current PIN.
  Future<void> removePin() async {
    await _pinService.removePin();
    state = false;
  }
}

/// Provider tracking whether a PIN is configured on the device.
final isPinSetProvider =
    StateNotifierProvider<PinSetStateNotifier, bool>((ref) {
  final pinService = ref.watch(pinServiceProvider);
  return PinSetStateNotifier(pinService);
});

/// StateNotifier tracking whether the current app session is unlocked via PIN.
class PinUnlockedStateNotifier extends StateNotifier<bool> {
  PinUnlockedStateNotifier() : super(false);

  void unlock() {
    state = true;
  }

  void lock() {
    state = false;
  }
}

/// Provider tracking whether the current app session has been unlocked via PIN.
final isPinUnlockedProvider =
    StateNotifierProvider<PinUnlockedStateNotifier, bool>((ref) {
  return PinUnlockedStateNotifier();
});
