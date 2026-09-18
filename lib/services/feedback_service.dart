import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

/// Service layer for submitting and managing user feedback entries in Firestore.
class FeedbackService {
  final FirebaseFirestore _firestore;

  FeedbackService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _feedbackRef {
    return _firestore.collection('feedback');
  }

  /// Submits a user feedback entry to Firestore under the `feedback` collection.
  Future<void> submitFeedback(FeedbackModel feedback) async {
    final docRef = _feedbackRef.doc();
    final feedbackWithId = feedback.copyWith(id: docRef.id);
    await docRef.set(feedbackWithId.toMap());
  }
}
