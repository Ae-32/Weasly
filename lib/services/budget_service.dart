import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetException implements Exception {
  final String message;
  const BudgetException(this.message);

  @override
  String toString() => message;
}

/// Firestore Service layer for managing budget records.
/// Collection path: users/{userId}/budgets/
class BudgetService {
  final FirebaseFirestore _firestore;

  BudgetService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _budgetsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  /// Streams all budgets for a user, ordered by creation date ascending.
  Stream<List<BudgetModel>> getBudgetsStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _budgetsRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Adds a new budget record.
  Future<void> addBudget(String userId, BudgetModel budget) async {
    if (userId.isEmpty) {
      throw const BudgetException("User is not authenticated.");
    }
    if (budget.amount <= 0) {
      throw const BudgetException("Budget amount must be greater than zero.");
    }
    if (budget.categoryId.isEmpty) {
      throw const BudgetException("Please select a category for the budget.");
    }

    try {
      final docRef = _budgetsRef(userId).doc();
      final modelWithId = budget.copyWith(id: docRef.id);
      await docRef.set(modelWithId.toMap());
    } catch (e) {
      throw BudgetException("Failed to add budget: ${e.toString()}");
    }
  }

  /// Updates an existing budget record.
  Future<void> updateBudget(String userId, BudgetModel budget) async {
    if (userId.isEmpty) {
      throw const BudgetException("User is not authenticated.");
    }
    if (budget.amount <= 0) {
      throw const BudgetException("Budget amount must be greater than zero.");
    }

    try {
      await _budgetsRef(userId).doc(budget.id).update(budget.toMap());
    } catch (e) {
      throw BudgetException("Failed to update budget: ${e.toString()}");
    }
  }

  /// Deletes a budget record.
  Future<void> deleteBudget(String userId, String budgetId) async {
    if (userId.isEmpty) {
      throw const BudgetException("User is not authenticated.");
    }

    try {
      await _budgetsRef(userId).doc(budgetId).delete();
    } catch (e) {
      throw BudgetException("Failed to delete budget: ${e.toString()}");
    }
  }
}
