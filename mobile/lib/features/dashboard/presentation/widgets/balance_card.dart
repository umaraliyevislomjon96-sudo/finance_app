import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/sparkline_wave.dart';
import '../../../../core/localization/currency_controller.dart';

class BalanceCard extends StatefulWidget {
  final double totalBalanceUzs;
  final double changePercentage;
  final VoidCallback? onDetailsTap;

  const BalanceCard({
    super.key,
    this.totalBalanceUzs = 34850000.0,
    this.changePercentage = 8.4,
    this.onDetailsTap,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isMasked = false;
  String _selectedTimeframe = '1M';

  final Map<String, List<double>> _timeframeData = {
    '1W': [32500000, 33100000, 33800000, 34200000, 34850000],
    '1M': [28000000, 31000000, 33500000, 32000000, 34850000],
    '3M': [21000000, 24500000, 28000000, 31500000, 34850000],
    '1Y': [12000000, 16000000, 22000000, 29000000, 34850000],
  };

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyController.instance;

    return AnimatedBuilder(
      animation: currency,
      builder: (context, _) {
        final currentPoints = _timeframeData[_selectedTimeframe] ?? _timeframeData['1M']!;
        final displayAmount = currency.format(widget.totalBalanceUzs);

        return GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          borderRadius: 24,
          borderColor: AppColors.primaryBlue.withOpacity(0.35),
          gradientColors: const [
            Color(0xFF101C30),
            Color(0xFF0C1424),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Label, Masking & Details Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Общий баланс',
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isMasked = !_isMasked),
                        child: Icon(
                          _isMasked ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.incomeGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.incomeGreen.withOpacity(0.3)),
                    ),
                    child: Text(
                      '+${widget.changePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.incomeGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Main Balance Number
              Text(
                _isMasked ? '••••••••' : displayAmount,
                style: AppTypography.largeNumber.copyWith(
                  fontSize: currency.isUsd ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Timeframe Selector & Trend Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Динамика накоплений',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: ['1W', '1M', '3M', '1Y'].map((tf) {
                        final isSelected = _selectedTimeframe == tf;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTimeframe = tf),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.cyanAccent.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected ? Border.all(color: AppColors.cyanAccent.withOpacity(0.5)) : null,
                            ),
                            child: Text(
                              tf,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.cyanAccent : AppColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Glowing Sparkline Wave Mesh
              SparklineWave(
                dataPoints: currentPoints,
                height: 54,
                strokeColor: AppColors.cyanAccent,
              ),
            ],
          ),
        );
      },
    );
  }
}
