import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recurring_bill_model.dart';

/// Firestore service for managing user recurring bills under users/{userId}/recurringBills.
class RecurringBillService {
  final FirebaseFirestore _firestore;

  RecurringBillService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userBillsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurringBills');
  }

  /// Listens to live updates of recurring bills, sorted by next due date ascending.
  Stream<List<RecurringBillModel>> getRecurringBillsStream(String userId) {
    return _userBillsCollection(userId)
        .orderBy('nextDueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecurringBillModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Adds a new recurring bill document to Firestore.
  Future<RecurringBillModel> addRecurringBill(String userId, RecurringBillModel bill) async {
    final collection = _userBillsCollection(userId);
    final docRef = bill.id.isNotEmpty ? collection.doc(bill.id) : collection.doc();
    final billWithId = bill.copyWith(id: docRef.id);

    await docRef.set(billWithId.toMap());
    return billWithId;
  }

  /// Updates an existing recurring bill document in Firestore.
  Future<void> updateRecurringBill(String userId, RecurringBillModel bill) async {
    final docRef = _userBillsCollection(userId).doc(bill.id);
    await docRef.update(bill.toMap());
  }

  /// Deletes a recurring bill document from Firestore.
  Future<void> deleteRecurringBill(String userId, String billId) async {
    final docRef = _userBillsCollection(userId).doc(billId);
    await docRef.delete();
  }

  /// Advances a recurring bill's due date to the next cycle period.
  Future<RecurringBillModel> advanceBillDueDate(String userId, RecurringBillModel bill) async {
    final nextDate = bill.calculateNextDueDate();
    final updatedBill = bill.copyWith(nextDueDate: nextDate);
    await updateRecurringBill(userId, updatedBill);
    return updatedBill;
  }
}
