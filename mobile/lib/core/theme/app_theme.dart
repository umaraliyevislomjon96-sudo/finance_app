import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppTheme {
  static ThemeData get darkTheme => _build(AppPalette.dark, Brightness.dark);
  static ThemeData get lightTheme => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.accent,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: p.borderStrong,
      outlineVariant: p.border,
      error: p.expense,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'SF Pro Display',
    );

    TextStyle t(double size, FontWeight w, Color c, {double? h, double ls = 0}) =>
        TextStyle(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

    return base.copyWith(
      extensions: [p],
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.surface,
      dividerColor: p.border,
      splashFactory: InkSparkle.splashFactory,
      textTheme: base.textTheme.copyWith(
        displaySmall: t(32, FontWeight.w700, p.textPrimary, ls: -0.8),
        headlineMedium: t(28, FontWeight.w700, p.textPrimary, ls: -0.6),
        headlineSmall: t(24, FontWeight.w700, p.textPrimary, ls: -0.4),
        titleLarge: t(20, FontWeight.w700, p.textPrimary, ls: -0.3),
        titleMedium: t(16, FontWeight.w600, p.textPrimary, ls: -0.1),
        titleSmall: t(14, FontWeight.w600, p.textPrimary),
        bodyLarge: t(16, FontWeight.w400, p.textPrimary, h: 1.45),
        bodyMedium: t(14, FontWeight.w400, p.textSecondary, h: 1.45),
        bodySmall: t(12, FontWeight.w400, p.textMuted, h: 1.4),
        labelLarge: t(14, FontWeight.w600, p.textPrimary),
        labelMedium: t(12, FontWeight.w600, p.textSecondary),
        labelSmall: t(11, FontWeight.w600, p.textMuted, ls: 0.4),
      ),
      iconTheme: IconThemeData(color: p.textSecondary, size: 22),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.textPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size(0, 52),
          side: BorderSide(color: p.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSunken,
        labelStyle: TextStyle(color: p.textMuted),
        hintStyle: TextStyle(color: p.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: p.primary,
        inactiveTrackColor: p.borderStrong,
        thumbColor: p.isDark ? p.accent : p.primary,
        overlayColor: p.primary.withValues(alpha: 0.14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl + 4)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: t(18, FontWeight.w700, p.textPrimary),
        contentTextStyle: t(14, FontWeight.w400, p.textSecondary, h: 1.45),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.surfaceAlt : const Color(0xFF0B1220),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: p.border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    );
  }
}
