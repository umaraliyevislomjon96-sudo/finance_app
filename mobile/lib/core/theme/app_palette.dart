import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware semantic colors. Widgets read these through `context.palette`
/// instead of hard-coding dark-only values, so light and dark themes stay in sync.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color income;
  final Color expense;
  final Color savings;
  final Color warning;
  final Color navBar;
  final Color shadow;
  final List<Color> heroGradient;
  final List<Color> aiGradient;

  const AppPalette({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.income,
    required this.expense,
    required this.savings,
    required this.warning,
    required this.navBar,
    required this.shadow,
    required this.heroGradient,
    required this.aiGradient,
  });

  static const dark = AppPalette(
    background: AppColors.primaryBackground,
    backgroundAlt: AppColors.secondaryBackground,
    surface: Color(0xFF111A28),
    surfaceAlt: Color(0xFF172234),
    surfaceSunken: Color(0xFF0C131F),
    border: Color(0x14FFFFFF),
    borderStrong: Color(0x29FFFFFF),
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: Color(0xFF7C8BA1),
    primary: AppColors.primaryBlue,
    onPrimary: Colors.white,
    accent: AppColors.cyanAccent,
    income: AppColors.incomeGreen,
    expense: AppColors.expenseRed,
    savings: AppColors.savingsPurple,
    warning: AppColors.warningAmber,
    navBar: Color(0xF20B111C),
    shadow: Color(0x66000000),
    heroGradient: [Color(0xFF1B4FD8), Color(0xFF2F80FF), Color(0xFF0EA5C6)],
    aiGradient: [Color(0xFF0F2A44), Color(0xFF1B1F4B)],
  );

  static const light = AppPalette(
    background: Color(0xFFF4F6FB),
    backgroundAlt: Color(0xFFEDF1F8),
    surface: Colors.white,
    surfaceAlt: Color(0xFFF6F8FC),
    surfaceSunken: Color(0xFFEEF2F8),
    border: Color(0xFFE3E8F0),
    borderStrong: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0B1220),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    primary: Color(0xFF1E60D5),
    onPrimary: Colors.white,
    accent: Color(0xFF0284C7),
    income: Color(0xFF15803D),
    expense: Color(0xFFDC2626),
    savings: Color(0xFF6366F1),
    warning: Color(0xFFB45309),
    navBar: Color(0xF7FFFFFF),
    shadow: Color(0x140F172A),
    heroGradient: [Color(0xFF1E4FD0), Color(0xFF2F6FF0), Color(0xFF0B8FC4)],
    aiGradient: [Color(0xFFE6F4FF), Color(0xFFEEEBFF)],
  );

  bool get isDark => background.computeLuminance() < 0.2;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> g(List<Color> a, List<Color> b) =>
        [for (var i = 0; i < a.length; i++) c(a[i], b[i])];
    return AppPalette(
      background: c(background, other.background),
      backgroundAlt: c(backgroundAlt, other.backgroundAlt),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      accent: c(accent, other.accent),
      income: c(income, other.income),
      expense: c(expense, other.expense),
      savings: c(savings, other.savings),
      warning: c(warning, other.warning),
      navBar: c(navBar, other.navBar),
      shadow: c(shadow, other.shadow),
      heroGradient: g(heroGradient, other.heroGradient),
      aiGradient: g(aiGradient, other.aiGradient),
    );
  }
}

/// Spacing scale (4pt grid).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal page gutter used by every tab.
  static const double page = 20;
}

/// Corner radius scale.
class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
