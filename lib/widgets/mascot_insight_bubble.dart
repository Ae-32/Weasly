import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Small mascot banner widget with a speech bubble displaying data-driven insights.
class MascotInsightBubble extends StatelessWidget {
  final String insightText;

  const MascotInsightBubble({
    super.key,
    required this.insightText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mascot Avatar Container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE6D5),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/images/Weasly_Dashboard_Welcome.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets_rounded,
                    size: 28,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Speech Bubble Container
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Weasly',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: AppColors.accentPrimary.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insightText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
