import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payday_settings_model.dart';

/// Firestore Service layer for managing single-document PaydaySettings per user.
/// Stored under users/{userId}/paydaySettings/config.
class PaydayService {
  final FirebaseFirestore _firestore;

  PaydayService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _docRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('paydaySettings')
        .doc('config');
  }

  /// Streams real-time PaydaySettingsModel for a given user.
  Stream<PaydaySettingsModel?> getPaydaySettingsStream(String userId) {
    return _docRef(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return PaydaySettingsModel.fromMap(snapshot.data()!);
    });
  }

  /// Saves or updates the single PaydaySettings config document for a user.
  Future<void> savePaydaySettings(
      String userId, PaydaySettingsModel settings) async {
    await _docRef(userId).set(settings.toMap(), SetOptions(merge: true));
  }

  /// Clears/resets the payday settings document.
  Future<void> clearPaydaySettings(String userId) async {
    await _docRef(userId).delete();
  }
}
