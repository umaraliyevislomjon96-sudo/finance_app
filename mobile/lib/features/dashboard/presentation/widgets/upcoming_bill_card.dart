import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/ui_kit.dart';

class UpcomingBillCard extends StatelessWidget {
  final String title;
  final String? amountWithDate;
  final String? amount;
  final String? dueDate;
  final IconData? icon;
  final IconData? categoryIcon;
  final bool isCritical;
  final VoidCallback? onTap;

  const UpcomingBillCard({
    super.key,
    required this.title,
    this.amountWithDate,
    this.amount,
    this.dueDate,
    this.icon,
    this.categoryIcon,
    this.isCritical = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final effectiveIcon = categoryIcon ?? icon ?? Icons.home_outlined;
    final tone = isCritical ? p.expense : p.accent;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: effectiveIcon, color: tone),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (amountWithDate != null)
                  Text(amountWithDate!, style: TextStyle(color: p.textMuted, fontSize: 13))
                else if (dueDate != null)
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 13, color: isCritical ? p.expense : p.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        dueDate!,
                        style: TextStyle(
                          color: isCritical ? p.expense : p.textMuted,
                          fontSize: 12,
                          fontWeight: isCritical ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (amount != null && amountWithDate == null)
            Text(amount!, style: AppTypography.money(15, p.textPrimary)),
        ],
      ),
    );
  }
}
