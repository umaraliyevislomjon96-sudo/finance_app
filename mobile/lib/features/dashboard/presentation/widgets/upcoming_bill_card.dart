import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';

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
    final effectiveIcon = categoryIcon ?? icon ?? Icons.home_outlined;
    final effectiveSubtitle = amountWithDate ?? '${amount ?? ""} • $dueDate';
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: 20,
      onTap: onTap,
      gradientColors: [
        const Color(0xFF131D2D),
        const Color(0xFF0F1624),
      ],
      child: Row(
        children: [
          // Cyan tinted rounded container with home icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cyanAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cyanAccent.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              effectiveIcon,
              color: isCritical ? AppColors.expenseRed : AppColors.cyanAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  effectiveSubtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textMuted,
            size: 14,
          ),
        ],
      ),
    );
  }
}
