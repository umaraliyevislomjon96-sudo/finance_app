import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// Base surface for every card in the app. Theme-aware: dark mode gets a soft
/// gradient with a hairline border, light mode a white card with a gentle shadow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final List<Color>? gradientColors;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg + 2),
    this.borderRadius = AppRadius.lg,
    this.onTap,
    this.borderColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? (p.isDark ? [p.surfaceAlt, p.surface] : [p.surface, p.surface]),
        ),
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: p.isDark ? 24 : 18,
            offset: Offset(0, p.isDark ? 10 : 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
