import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/services/pin_service.dart';

class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    dynamic cuOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    dynamic cuOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    dynamic cuOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PinService Tests', () {
    late MockSecureStorage mockStorage;
    late PinService pinService;

    setUp(() {
      mockStorage = MockSecureStorage();
      pinService = PinService(storage: mockStorage);
    });

    test('hasPin returns false when no PIN is stored', () async {
      final hasPin = await pinService.hasPin();
      expect(hasPin, isFalse);
    });

    test('savePin hashes and stores PIN securely', () async {
      await pinService.savePin('1234');
      final hasPin = await pinService.hasPin();
      expect(hasPin, isTrue);
    });

    test('verifyPin returns true for correct PIN and false for incorrect PIN', () async {
      await pinService.savePin('56789');

      final correctResult = await pinService.verifyPin('56789');
      expect(correctResult, isTrue);

      final incorrectResult = await pinService.verifyPin('0000');
      expect(incorrectResult, isFalse);
    });

    test('removePin deletes stored PIN hash', () async {
      await pinService.savePin('123456');
      expect(await pinService.hasPin(), isTrue);

      await pinService.removePin();
      expect(await pinService.hasPin(), isFalse);
    });
  });
}
