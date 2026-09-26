import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payday_settings_model.dart';
import '../models/transaction_model.dart';
import 'transaction_service.dart';

/// Firestore Service layer for managing single-document PaydaySettings per user.
/// Stored under users/{userId}/paydaySettings/config.
class PaydayService {
  final FirebaseFirestore _firestore;
  final TransactionService _transactionService;

  PaydayService({
    FirebaseFirestore? firestore,
    TransactionService? transactionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _transactionService = transactionService ?? TransactionService();

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

  /// Records a payday income transaction via TransactionService and advances the next payday date.
  Future<void> confirmPayday({
    required String userId,
    required double amount,
    required String accountId,
    required String accountName,
    required String categoryId,
    required String categoryName,
    required String categoryIcon,
    required String categoryColorHex,
    required PaydaySettingsModel settings,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Create Income transaction using existing TransactionService (no duplication)
    await _transactionService.addTransaction(
      userId: userId,
      type: TransactionType.income,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColorHex: categoryColorHex,
      accountId: accountId,
      accountName: accountName,
      date: now,
      note: 'Payday Income',
    );

    // 2. Calculate next payday date after today
    final nextDate = settings.calculateNextUpcomingPayday(today.add(const Duration(days: 1)));

    // 3. Save updated PaydaySettingsModel
    final updatedSettings = settings.copyWith(
      lastConfirmedPaydayDate: today,
      lastDismissedPaydayDate: null,
      nextPaydayDate: nextDate,
      updatedAt: now,
    );

    await savePaydaySettings(userId, updatedSettings);
  }

  /// Marks today's payday prompt as dismissed and advances next payday date.
  Future<void> dismissPayday({
    required String userId,
    required PaydaySettingsModel settings,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final nextDate = settings.calculateNextUpcomingPayday(today.add(const Duration(days: 1)));

    final updatedSettings = settings.copyWith(
      lastDismissedPaydayDate: today,
      nextPaydayDate: nextDate,
      updatedAt: now,
    );

    await savePaydaySettings(userId, updatedSettings);
  }

  /// Clears/resets the payday settings document.
  Future<void> clearPaydaySettings(String userId) async {
    await _docRef(userId).delete();
  }
}

