import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/providers/pin_provider.dart';
import 'package:Weasly/services/pin_service.dart';
import '../services/pin_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinSetStateNotifier Tests', () {
    late MockSecureStorage mockStorage;
    late PinService pinService;

    setUp(() {
      mockStorage = MockSecureStorage();
      pinService = PinService(storage: mockStorage);
    });

    test('isPinSet defaults to false when no PIN is saved', () async {
      final notifier = PinSetStateNotifier(pinService);
      await Future.delayed(Duration.zero);
      expect(notifier.state, isFalse);
    });

    test('setupPin saves PIN and updates state to true', () async {
      final notifier = PinSetStateNotifier(pinService);
      await notifier.setupPin('1234');
      expect(notifier.state, isTrue);
      expect(await pinService.hasPin(), isTrue);
    });

    test('removePin deletes PIN and updates state to false', () async {
      final notifier = PinSetStateNotifier(pinService);
      await notifier.setupPin('4321');
      expect(notifier.state, isTrue);

      await notifier.removePin();
      expect(notifier.state, isFalse);
      expect(await pinService.hasPin(), isFalse);
    });
  });

  group('PinUnlockedStateNotifier Tests', () {
    test('starts locked and handles unlock/lock state changes', () {
      final notifier = PinUnlockedStateNotifier();
      expect(notifier.state, isFalse);

      notifier.unlock();
      expect(notifier.state, isTrue);

      notifier.lock();
      expect(notifier.state, isFalse);
    });
  });
}
