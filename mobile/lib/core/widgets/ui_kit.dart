import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// Large page title used at the top of every tab.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (onBack != null) ...[
          CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack!, tooltip: 'Назад'),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: text.bodySmall?.copyWith(color: p.textMuted)),
              ],
            ],
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: AppSpacing.sm), a],
      ],
    );
  }
}

/// Section title with an optional trailing text action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  actionLabel!,
                  style: TextStyle(color: p.accent, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Round 40px icon button on a subtle surface (header actions, back buttons).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool showDot;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final button = Material(
      color: p.surface,
      shape: CircleBorder(side: BorderSide(color: p.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: p.textPrimary),
              if (showDot)
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Tinted rounded square holding an icon; the tint follows the icon color.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double radius;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.palette.isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

/// Small status label ("+8.4%", "Критично", "Демо").
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool onDark;

  const StatusPill({super.key, required this.label, required this.color, this.icon, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.16) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 3)],
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Pill-shaped segmented control with an animated thumb.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: p.border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.isDark ? p.primary : p.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: [BoxShadow(color: p.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: i == index
                                  ? (p.isDark ? Colors.white : p.textPrimary)
                                  : p.textMuted,
                            ),
                            child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Friendly empty state with an icon, explanation and one next step.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          IconBadge(icon: icon, color: p.accent, size: 56, radius: 18),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: text.bodyMedium?.copyWith(color: p.textMuted), textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens a consistently styled bottom sheet with a title row.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  IconData? icon,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final p = ctx.palette;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      IconBadge(icon: icon, color: p.accent, size: 36, radius: AppRadius.sm),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(child: Text(title, style: Theme.of(ctx).textTheme.titleLarge)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                builder(ctx),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Label/value row used inside detail sheets.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const DetailRow({super.key, required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: p.textMuted))),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
