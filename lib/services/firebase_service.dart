import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase initialization and core service wrapper.
class FirebaseService {
  FirebaseService._();

  /// Initializes Firebase Core services.
  /// If firebase_options.dart is configured via FlutterFire CLI later,
  /// options will be passed here seamlessly.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      debugPrint("Firebase initialized successfully.");
    } catch (e) {
      debugPrint("Firebase initialization note: $e");
    }
  }
}
