import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';

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
    final p = context.palette;
    final displayText = insightText ?? title ?? '';
    final handleTap = onActionTap ?? onTap;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.aiGradient,
        ),
        border: Border.all(color: p.accent.withValues(alpha: p.isDark ? 0.28 : 0.22)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: handleTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [p.primary, p.accent]),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Совет AI',
                        style: TextStyle(
                          color: p.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayText,
                        style: TextStyle(color: p.textPrimary, fontSize: 14, height: 1.45),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Обсудить с AI',
                            style: TextStyle(color: p.primary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: p.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
