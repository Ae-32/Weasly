import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Exception thrown for invalid biometric operations.
class BiometricException implements Exception {
  final String message;
  const BiometricException(this.message);

  @override
  String toString() => message;
}

/// Service handling local device biometric authentication (fingerprint / face unlock).
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Checks if the device hardware supports biometrics and is configured.
  Future<bool> canCheckBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics capability: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking biometrics capability: $e');
      return false;
    }
  }

  /// Prompts the user for biometric authentication.
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access Weasly',
  }) async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        debugPrint('Biometrics not available on this device.');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication failed with code ${e.code}: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during biometric authentication: $e');
      return false;
    }
  }
}
