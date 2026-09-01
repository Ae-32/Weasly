import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exception thrown for invalid PIN operations.
class PinException implements Exception {
  final String message;
  const PinException(this.message);

  @override
  String toString() => message;
}

/// Service handling local secure storage and hashing for user PIN.
class PinService {
  static const String _pinHashKey = 'weasly_user_pin_hash';
  static const String _salt = 'weasly_pin_salt_v1_';

  final FlutterSecureStorage _storage;

  PinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Hashes a plain-text 4-6 digit PIN using SHA-256 with a salt.
  String hashPin(String pin) {
    final bytes = utf8.encode('$_salt$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Checks whether a PIN is currently configured for this device.
  Future<bool> hasPin() async {
    try {
      final storedHash = await _storage.read(key: _pinHashKey);
      return storedHash != null && storedHash.isNotEmpty;
    } catch (e) {
      debugPrint('Error reading PIN status: $e');
      return false;
    }
  }

  /// Saves a new PIN securely by hashing it before storage.
  Future<void> savePin(String pin) async {
    if (pin.length < 4 || pin.length > 6) {
      throw const PinException('PIN must be 4 to 6 digits in length.');
    }
    final hashed = hashPin(pin);
    await _storage.write(key: _pinHashKey, value: hashed);
  }

  /// Verifies whether the entered PIN matches the stored hash.
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinHashKey);
      if (storedHash == null || storedHash.isEmpty) {
        return false;
      }
      final inputHash = hashPin(pin);
      return storedHash == inputHash;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Removes the stored PIN.
  Future<void> removePin() async {
    try {
      await _storage.delete(key: _pinHashKey);
    } catch (e) {
      debugPrint('Error removing PIN: $e');
    }
  }
}
