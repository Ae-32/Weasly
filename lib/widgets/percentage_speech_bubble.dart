import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BubblePointerPosition {
  bottomRight,
  bottomLeft,
  topRight,
  topLeft,
}

/// Floating percentage badge pill displaying percentage over pie/donut chart slices
class PercentageSpeechBubble extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final BubblePointerPosition? pointerPosition;

  const PercentageSpeechBubble({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.pointerPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.quicksand(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.1,
        ),
      ),
    );
  }
}
