import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';

/// Firestore Service layer for managing financial accounts.
/// Data is scoped strictly under users/{userId}/accounts/{accountId} per architecture.md invariants.
class AccountService {
  final FirebaseFirestore _firestore;

  AccountService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference helper for a given user.
  CollectionReference<Map<String, dynamic>> _userAccountsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('accounts');
  }

  /// Returns a real-time stream of accounts for a specific user.
  Stream<List<AccountModel>> getAccountsStream(String userId) {
    return _userAccountsRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Adds a new account document to Firestore under users/{userId}/accounts.
  Future<void> addAccount(String userId, AccountModel account) async {
    await _userAccountsRef(userId).add(account.toMap());
  }

  /// Updates an existing account document in Firestore.
  Future<void> updateAccount(String userId, AccountModel account) async {
    await _userAccountsRef(userId).doc(account.id).update(account.toMap());
  }

  /// Deletes an account document from Firestore.
  Future<void> deleteAccount(String userId, String accountId) async {
    await _userAccountsRef(userId).doc(accountId).delete();
  }

  /// Seeds default accounts (Cash, GCash, Bank) if a user has no accounts yet.
  Future<void> seedDefaultAccountsIfEmpty(String userId) async {
    final snapshot = await _userAccountsRef(userId).limit(1).get();
    if (snapshot.docs.isEmpty) {
      final now = DateTime.now();
      final defaultAccounts = [
        AccountModel(
          id: '',
          name: 'Cash Wallet',
          type: 'cash',
          balance: 0.0,
          note: 'Everyday spending',
          colorHex: 'c5942c', // Tertiary amber
          createdAt: now,
        ),
        AccountModel(
          id: '',
          name: 'GCash',
          type: 'gcash',
          balance: 0.0,
          note: 'Digital transactions',
          colorHex: 'd98a3d', // Primary amber
          createdAt: now.add(const Duration(milliseconds: 1)),
        ),
        AccountModel(
          id: '',
          name: 'Main Bank',
          type: 'bank',
          balance: 0.0,
          note: 'Savings & Salary',
          colorHex: '2b694e', // Secondary green
          createdAt: now.add(const Duration(milliseconds: 2)),
        ),
      ];

      final batch = _firestore.batch();
      for (final acc in defaultAccounts) {
        final docRef = _userAccountsRef(userId).doc();
        batch.set(docRef, acc.toMap());
      }
      await batch.commit();
    }
  }
}
