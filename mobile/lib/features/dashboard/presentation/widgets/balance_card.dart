import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sparkline_wave.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/localization/currency_controller.dart';

/// Hero card: total balance, trend and savings sparkline on the brand gradient.
class BalanceCard extends StatefulWidget {
  final double totalBalanceUzs;
  final double changePercentage;
  final bool isDemo;
  final VoidCallback? onDetailsTap;

  const BalanceCard({
    super.key,
    this.totalBalanceUzs = 34850000.0,
    this.changePercentage = 8.4,
    this.isDemo = true,
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
    final p = context.palette;
    final currency = CurrencyController.instance;

    return AnimatedBuilder(
      animation: currency,
      builder: (context, _) {
        final points = _timeframeData[_selectedTimeframe] ?? _timeframeData['1M']!;
        final positive = widget.changePercentage >= 0;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: p.heroGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: p.isDark ? 0.35 : 0.28),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Soft light blobs give the flat gradient depth.
              Positioned(
                top: -60,
                right: -40,
                child: _Glow(size: 180, color: Colors.white.withValues(alpha: 0.14)),
              ),
              Positioned(
                bottom: -70,
                left: -30,
                child: _Glow(size: 160, color: const Color(0xFF18D5FF).withValues(alpha: 0.22)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Общий баланс',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: _isMasked ? 'Показать сумму' : 'Скрыть сумму',
                          onPressed: () => setState(() => _isMasked = !_isMasked),
                          icon: Icon(
                            _isMasked ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const Spacer(),
                        if (widget.isDemo) ...[
                          const StatusPill(label: 'Демо', color: Colors.white, onDark: true),
                          const SizedBox(width: 6),
                        ],
                        StatusPill(
                          label: '${positive ? '+' : ''}${widget.changePercentage.toStringAsFixed(1)}%',
                          icon: positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: Colors.white,
                          onDark: true,
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: FittedBox(
                        key: ValueKey('$_isMasked${currency.isUsd}'),
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isMasked ? '•••••• ${currency.symbol}' : currency.format(widget.totalBalanceUzs),
                          style: AppTypography.money(34, Colors.white, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Изменение за месяц',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    SparklineWave(dataPoints: points, height: 56, strokeColor: Colors.white),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final tf in _timeframeData.keys)
                          Expanded(child: _timeframeButton(tf)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timeframeButton(String tf) {
    final selected = tf == _selectedTimeframe;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedTimeframe = tf),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: Text(
          tf,
          style: TextStyle(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
