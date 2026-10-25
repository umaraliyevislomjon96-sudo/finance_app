import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Compact income / spending summary. Place inside an `Expanded` in a `Row`.
class MetricPillCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final String? caption;

  const MetricPillCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: iconColor, size: 32, radius: AppRadius.sm),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: TextStyle(color: p.textMuted, fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: AppTypography.money(18, p.textPrimary)),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
