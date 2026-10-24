import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

/// Mascot banner widget with a speech bubble displaying data-driven insights.
class MascotInsightBubble extends StatefulWidget {
  final List<String> insights;

  MascotInsightBubble({
    super.key,
    required List<String> insights,
  }) : insights = insights.isEmpty
            ? ['Keep logging your daily stashes to build smarter money habits!']
            : insights;

  MascotInsightBubble.single({
    super.key,
    required String insightText,
  }) : insights = [insightText];

  @override
  State<MascotInsightBubble> createState() => _MascotInsightBubbleState();
}

class _MascotInsightBubbleState extends State<MascotInsightBubble> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant MascotInsightBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insights != widget.insights) {
      if (_currentIndex >= widget.insights.length) {
        _currentIndex = 0;
      }
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.insights.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 7), (_) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.insights.length;
          });
        }
      });
    }
  }

  void _nextInsight() {
    if (widget.insights.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.insights.length;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentText = widget.insights[_currentIndex];

    return GestureDetector(
      onTap: _nextInsight,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderDefault),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow,
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
                color: colors.accentPrimaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.accentPrimary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    'assets/images/Weasly_Dashboard_Welcome.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.pets_rounded,
                      size: 28,
                      color: colors.accentPrimary,
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
                  color: colors.bgBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.accentPrimary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Weasly',
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.accentPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: colors.accentPrimary.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        if (widget.insights.length > 1)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.insights.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(left: 3),
                                width: index == _currentIndex ? 12 : 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: index == _currentIndex
                                      ? colors.accentPrimary
                                      : colors.accentPrimary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        currentText,
                        key: ValueKey<int>(_currentIndex),
                        style: GoogleFonts.quicksand(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
