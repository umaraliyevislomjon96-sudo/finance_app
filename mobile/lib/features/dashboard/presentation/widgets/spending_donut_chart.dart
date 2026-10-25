import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/glass_card.dart';

class SpendingCategoryItem {
  final String name;
  final double percentage;
  final Color color;
  final IconData icon;

  const SpendingCategoryItem({
    required this.name,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class SpendingDonutChart extends StatefulWidget {
  final List<SpendingCategoryItem> categories;
  final String? totalLabel;

  const SpendingDonutChart({
    super.key,
    this.totalLabel,
    this.categories = const [
      SpendingCategoryItem(name: 'Еда и кафе', percentage: 34, color: Color(0xFF18B8E6), icon: Icons.restaurant_rounded),
      SpendingCategoryItem(name: 'Транспорт', percentage: 22, color: Color(0xFF2F6FF0), icon: Icons.directions_car_rounded),
      SpendingCategoryItem(name: 'Жильё и счета', percentage: 20, color: Color(0xFF8B5CF6), icon: Icons.home_rounded),
      SpendingCategoryItem(name: 'Покупки', percentage: 14, color: Color(0xFF22B45E), icon: Icons.shopping_bag_rounded),
      SpendingCategoryItem(name: 'Развлечения', percentage: 10, color: Color(0xFFF2A00B), icon: Icons.movie_rounded),
    ],
  });

  @override
  State<SpendingDonutChart> createState() => _SpendingDonutChartState();
}

class _SpendingDonutChartState extends State<SpendingDonutChart> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = widget.categories[_selectedIndex];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Структура расходов', style: Theme.of(context).textTheme.titleMedium)),
              if (widget.totalLabel != null)
                Text(widget.totalLabel!, style: TextStyle(color: p.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              SizedBox(
                width: 136,
                height: 136,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => CustomPaint(
                    painter: _DonutChartPainter(
                      categories: widget.categories,
                      selectedIndex: _selectedIndex,
                      progress: progress,
                      trackColor: p.surfaceSunken,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(selected.icon, size: 18, color: selected.color),
                          const SizedBox(height: 2),
                          Text(
                            '${selected.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < widget.categories.length; i++) _legendRow(i, p),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(int index, AppPalette p) {
    final item = widget.categories[index];
    final isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? item.color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? p.textPrimary : p.textSecondary,
                ),
              ),
            ),
            Text(
              '${item.percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? p.textPrimary : p.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<SpendingCategoryItem> categories;
  final int selectedIndex;
  final double progress;
  final Color trackColor;

  _DonutChartPainter({
    required this.categories,
    required this.selectedIndex,
    required this.progress,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    const gap = 0.04;
    double startAngle = -pi / 2;
    for (int i = 0; i < categories.length; i++) {
      final item = categories[i];
      final sweep = (item.percentage / 100) * 2 * pi * progress;
      final isSelected = i == selectedIndex;
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        max(0, sweep - gap),
        false,
        Paint()
          ..color = isSelected ? item.color : item.color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 18 : 14
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.selectedIndex != selectedIndex || old.progress != progress || old.trackColor != trackColor;
}
