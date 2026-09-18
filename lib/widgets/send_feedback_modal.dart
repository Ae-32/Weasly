import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/feedback_model.dart';
import '../providers/feedback_provider.dart';
import '../utils/app_colors.dart';
import 'app_toast.dart';
import 'success_banner.dart';

/// Modal bottom sheet allowing users to submit feedback, report bugs, or share feature requests.
class SendFeedbackModal extends ConsumerStatefulWidget {
  const SendFeedbackModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SendFeedbackModal(),
    );
  }

  @override
  ConsumerState<SendFeedbackModal> createState() => _SendFeedbackModalState();
}

class _SendFeedbackModalState extends ConsumerState<SendFeedbackModal> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  int _selectedRating = 5;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return '5 • Love it!';
      case 4:
        return '4 • Good experience';
      case 3:
        return '3 • It\'s okay';
      case 2:
        return '2 • Needs improvement';
      case 1:
      default:
        return '1 • Disappointed';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(feedbackControllerProvider.notifier)
        .submitFeedback(
          category: FeedbackCategory.general,
          rating: _selectedRating,
          message: _messageController.text,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        SuccessBanner.show(
          context,
          'Thank you! Your feedback has been sent successfully.',
        );
      } else {
        final state = ref.read(feedbackControllerProvider);
        final error = state.error?.toString() ?? 'Failed to send feedback. Please try again.';
        AppToast.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedbackControllerProvider);
    final isLoading = state.isLoading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Send Feedback',
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                'We\'d love to hear your thoughts, ideas, or issues!',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Rating Selector
              Text(
                'HOW ARE YOU ENJOYING WEASLY?',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      final isFilled = starNum <= _selectedRating;
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFilled ? AppColors.accentPrimary : AppColors.textMutedLight,
                          size: 32,
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() => _selectedRating = starNum);
                              },
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getRatingText(_selectedRating),
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Feedback Message Input
              Text(
                'YOUR MESSAGE',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 500,
                enabled: !isLoading,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Tell us what you like, what we can improve, or any feature you\'d love to see...',
                  hintStyle: GoogleFonts.quicksand(
                    fontSize: 13,
                    color: AppColors.textMutedLight,
                  ),
                  filled: true,
                  fillColor: AppColors.bgBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.accentPrimary,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your feedback message.';
                  }
                  if (val.trim().length < 5) {
                    return 'Please provide at least 5 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Submit Feedback',
                          style: GoogleFonts.quicksand(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
