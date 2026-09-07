import 'package:flutter/material.dart';
import 'app_toast.dart';

/// Helper forwarding calls to [AppToast] pop banner system with automatic action-color detection.
class SuccessBanner {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('delete') ||
        lowerMessage.contains('deleted') ||
        lowerMessage.contains('remove') ||
        lowerMessage.contains('removed') ||
        lowerMessage.contains('clear') ||
        lowerMessage.contains('cleared') ||
        lowerMessage.contains('reset')) {
      AppToast.showDelete(
        context,
        message,
        duration: duration,
      );
    } else if (lowerMessage.contains('update') ||
        lowerMessage.contains('updated') ||
        lowerMessage.contains('edit') ||
        lowerMessage.contains('edited')) {
      AppToast.showInfo(
        context,
        message,
        title: 'Updated',
        duration: duration,
      );
    } else {
      AppToast.showSuccess(
        context,
        message,
        duration: duration,
      );
    }
  }

  static void showDelete(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    AppToast.showDelete(
      context,
      message,
      duration: duration,
    );
  }
}
