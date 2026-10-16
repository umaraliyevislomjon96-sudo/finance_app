import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';

class AiInsightBanner extends StatelessWidget {
  final String? title;
  final String? insightText;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  const AiInsightBanner({
    super.key,
    this.title,
    this.insightText,
    this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = insightText ?? title ?? '';
    final handleTap = onActionTap ?? onTap;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 22,
      borderColor: AppColors.cyanAccent.withOpacity(0.25),
      gradientColors: [
        const Color(0xFF0F1B2E),
        const Color(0xFF0C1422),
      ],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'AI Insight',
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.cyanAccent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  displayText,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: handleTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
