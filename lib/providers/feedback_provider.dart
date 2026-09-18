import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import 'auth_provider.dart';

/// Provider for accessing the FeedbackService instance.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

/// StateNotifier handling the submission lifecycle for user feedback.
class FeedbackController extends StateNotifier<AsyncValue<void>> {
  final FeedbackService _service;
  final Ref _ref;

  FeedbackController(this._service, this._ref)
      : super(const AsyncValue.data(null));

  /// Submits feedback to Firestore.
  Future<bool> submitFeedback({
    required FeedbackCategory category,
    required int rating,
    required String message,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authStateProvider).value;
      final userId = user?.uid ?? 'anonymous';
      final userEmail = user?.email ?? 'anonymous';

      final feedback = FeedbackModel(
        id: '',
        userId: userId,
        userEmail: userEmail,
        category: category,
        rating: rating,
        message: message.trim(),
        appVersion: '1.0.0+1',
        createdAt: DateTime.now(),
      );

      await _service.submitFeedback(feedback);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final feedbackControllerProvider =
    StateNotifierProvider<FeedbackController, AsyncValue<void>>((ref) {
  final service = ref.watch(feedbackServiceProvider);
  return FeedbackController(service, ref);
});
