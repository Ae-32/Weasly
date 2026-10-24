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
  static const Color darkTextMutedAlt = Color(0xFF8E8478);
  static const Color darkTextMutedLight = Color(0xFF6B6259);
  static const Color darkAccentPrimary = Color(0xFFE8A85C);
  static const Color darkAccentPrimaryLight = Color(0xFF3D3025);
  static const Color darkIconButtonBg = Color(0xFF332B25);
  static const Color darkAccentSecondary = Color(0xFF6FAE8C);
  static const Color darkBorderDefault = Color(0xFF3A342E);
  static const Color darkStateError = Color(0xFFE5695B);
  static const Color darkStateSuccess = Color(0xFF6FAE8C);
  static const Color darkStateWarning = Color(0xFFE8C05C);

  /// Helper to get the theme-aware colors from the current BuildContext.
  static AppColorsExtension of(BuildContext context) => context.colors;
}

/// ThemeExtension providing reactive, theme-aware design tokens across Weasly.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color bgBase;
  final Color bgSurface;
  final Color textPrimary;
  final Color textMuted;
  final Color textMutedAlt;
  final Color textMutedLight;
  final Color accentPrimary;
  final Color accentPrimaryLight;
  final Color iconButtonBg;
  final Color accentSecondary;
  final Color borderDefault;
  final Color stateError;
  final Color stateSuccess;
  final Color stateWarning;
  final Color cardShadow;
  final Color periodToggleBg;

  const AppColorsExtension({
    required this.bgBase,
    required this.bgSurface,
    required this.textPrimary,
    required this.textMuted,
    required this.textMutedAlt,
    required this.textMutedLight,
    required this.accentPrimary,
    required this.accentPrimaryLight,
    required this.iconButtonBg,
    required this.accentSecondary,
    required this.borderDefault,
    required this.stateError,
    required this.stateSuccess,
    required this.stateWarning,
    required this.cardShadow,
    required this.periodToggleBg,
  });

  /// Light theme color token set.
  static const light = AppColorsExtension(
    bgBase: AppColors.bgBase,
    bgSurface: AppColors.bgSurface,
    textPrimary: AppColors.textPrimary,
    textMuted: AppColors.textMuted,
    textMutedAlt: AppColors.textMutedAlt,
    textMutedLight: AppColors.textMutedLight,
    accentPrimary: AppColors.accentPrimary,
    accentPrimaryLight: AppColors.accentPrimaryLight,
    iconButtonBg: AppColors.iconButtonBg,
    accentSecondary: AppColors.accentSecondary,
    borderDefault: AppColors.borderDefault,
    stateError: AppColors.stateError,
    stateSuccess: AppColors.stateSuccess,
    stateWarning: AppColors.stateWarning,
    cardShadow: Color.fromRGBO(43, 36, 32, 0.04),
    periodToggleBg: Color(0xFFEDE0D9),
  );

  /// Dark theme color token set (Warm Espresso palette).
  static const dark = AppColorsExtension(
    bgBase: AppColors.darkBgBase,
    bgSurface: AppColors.darkBgSurface,
    textPrimary: AppColors.darkTextPrimary,
    textMuted: AppColors.darkTextMuted,
    textMutedAlt: AppColors.darkTextMutedAlt,
    textMutedLight: AppColors.darkTextMutedLight,
    accentPrimary: AppColors.darkAccentPrimary,
    accentPrimaryLight: AppColors.darkAccentPrimaryLight,
    iconButtonBg: AppColors.darkIconButtonBg,
    accentSecondary: AppColors.darkAccentSecondary,
    borderDefault: AppColors.darkBorderDefault,
    stateError: AppColors.darkStateError,
    stateSuccess: AppColors.darkStateSuccess,
    stateWarning: AppColors.darkStateWarning,
    cardShadow: Color.fromRGBO(0, 0, 0, 0.40),
    periodToggleBg: Color(0xFF332B25),
  );

  @override
  AppColorsExtension copyWith({
    Color? bgBase,
    Color? bgSurface,
    Color? textPrimary,
    Color? textMuted,
    Color? textMutedAlt,
    Color? textMutedLight,
    Color? accentPrimary,
    Color? accentPrimaryLight,
    Color? iconButtonBg,
    Color? accentSecondary,
    Color? borderDefault,
    Color? stateError,
    Color? stateSuccess,
    Color? stateWarning,
    Color? cardShadow,
    Color? periodToggleBg,
  }) {
    return AppColorsExtension(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textMutedAlt: textMutedAlt ?? this.textMutedAlt,
      textMutedLight: textMutedLight ?? this.textMutedLight,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentPrimaryLight: accentPrimaryLight ?? this.accentPrimaryLight,
      iconButtonBg: iconButtonBg ?? this.iconButtonBg,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      borderDefault: borderDefault ?? this.borderDefault,
      stateError: stateError ?? this.stateError,
      stateSuccess: stateSuccess ?? this.stateSuccess,
      stateWarning: stateWarning ?? this.stateWarning,
      cardShadow: cardShadow ?? this.cardShadow,
      periodToggleBg: periodToggleBg ?? this.periodToggleBg,
    );
  }

  @override
  AppColorsExtension lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      bgBase: Color.lerp(bgBase, other.bgBase, t) ?? bgBase,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t) ?? bgSurface,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      textMutedAlt: Color.lerp(textMutedAlt, other.textMutedAlt, t) ?? textMutedAlt,
      textMutedLight: Color.lerp(textMutedLight, other.textMutedLight, t) ?? textMutedLight,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t) ?? accentPrimary,
      accentPrimaryLight: Color.lerp(accentPrimaryLight, other.accentPrimaryLight, t) ?? accentPrimaryLight,
      iconButtonBg: Color.lerp(iconButtonBg, other.iconButtonBg, t) ?? iconButtonBg,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t) ?? accentSecondary,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t) ?? borderDefault,
      stateError: Color.lerp(stateError, other.stateError, t) ?? stateError,
      stateSuccess: Color.lerp(stateSuccess, other.stateSuccess, t) ?? stateSuccess,
      stateWarning: Color.lerp(stateWarning, other.stateWarning, t) ?? stateWarning,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t) ?? cardShadow,
      periodToggleBg: Color.lerp(periodToggleBg, other.periodToggleBg, t) ?? periodToggleBg,
    );
  }

  /// Convenience alias for text secondary matching textMuted.
  Color get textSecondary => textMuted;

  /// Standard card box shadow with the theme-aware shadow color.
  BoxShadow get cardBoxShadow => BoxShadow(
        color: cardShadow,
        blurRadius: 12,
        offset: const Offset(0, 4),
      );
}

/// Convenience extension on BuildContext to quickly access reactive design colors and brightness.
extension BuildContextColors on BuildContext {
  /// Theme-aware design colors for the current theme mode.
  AppColorsExtension get colors {
    final ext = Theme.of(this).extension<AppColorsExtension>();
    if (ext != null) return ext;
    return Theme.of(this).brightness == Brightness.dark
        ? AppColorsExtension.dark
        : AppColorsExtension.light;
  }

  /// Whether the current active theme is dark mode.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
