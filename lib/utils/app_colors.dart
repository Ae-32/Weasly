import 'package:flutter/material.dart';

/// Design system color tokens for Weasly.
/// All colors correspond to the design tokens defined in ui-context.md & DESIGN.md.
class AppColors {
  AppColors._();

  // Light Mode Tokens (Confirmed Figma CSS Export)
  static const Color bgBase = Color(0xFFFAF7F2);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF211A16);
  static const Color textMuted = Color(0xFF8A7F73);
  static const Color textMutedAlt = Color(0xFF9A9998);
  static const Color textMutedLight = Color(0xFFBBB6B4);
  static const Color accentPrimary = Color(0xFFE06E03);
  static const Color accentPrimaryLight = Color(0xFFEFD8C2);
  static const Color iconButtonBg = Color(0xFFEDE0D9);
  static const Color accentSecondary = Color(0xFF4E8C6E);
  static const Color borderDefault = Color(0xFFE8E1D8);
  static const Color stateError = Color(0xFFD64545);
  static const Color stateSuccess = Color(0xFF4E8C6E);
  static const Color stateWarning = Color(0xFFD9A63D);

  // Semantic Aliases
  static const Color primary = accentPrimary;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = accentSecondary;
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = Color(0xFF534438);
  static const Color surfaceVariant = Color(0xFFEDE0D9);
  static const Color surfaceContainerHigh = Color(0xFFF3E5DF);
  static const Color error = stateError;
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Dark Mode Tokens
  static const Color darkBgBase = Color(0xFF1A1714);
  static const Color darkBgSurface = Color(0xFF26221E);
  static const Color darkTextPrimary = Color(0xFFF5F1EC);
  static const Color darkTextMuted = Color(0xFFA69A8C);
  static const Color darkAccentPrimary = Color(0xFFE8A85C);
  static const Color darkAccentSecondary = Color(0xFF6FAE8C);
  static const Color darkBorderDefault = Color(0xFF3A342E);
  static const Color darkStateError = Color(0xFFE5695B);
  static const Color darkStateSuccess = Color(0xFF6FAE8C);
  static const Color darkStateWarning = Color(0xFFE8C05C);
}
