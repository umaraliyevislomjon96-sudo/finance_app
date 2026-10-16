import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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

  const SpendingDonutChart({
    super.key,
    this.categories = const [
      SpendingCategoryItem(name: 'Еда и кафе', percentage: 34, color: AppColors.cyanAccent, icon: Icons.restaurant_rounded),
      SpendingCategoryItem(name: 'Транспорт', percentage: 22, color: AppColors.primaryBlue, icon: Icons.directions_car_rounded),
      SpendingCategoryItem(name: 'Жилье и счета', percentage: 20, color: Color(0xFF8B5CF6), icon: Icons.home_rounded),
      SpendingCategoryItem(name: 'Покупки', percentage: 14, color: AppColors.incomeGreen, icon: Icons.shopping_bag_rounded),
      SpendingCategoryItem(name: 'Развлечения', percentage: 10, color: Color(0xFFF59E0B), icon: Icons.movie_rounded),
    ],
  });

  @override
  State<SpendingDonutChart> createState() => _SpendingDonutChartState();
}

class _SpendingDonutChartState extends State<SpendingDonutChart> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.categories[_selectedIndex];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Структура расходов',
            style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut Chart with center readout
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(140, 140),
                      painter: _DonutChartPainter(
                        categories: widget.categories,
                        selectedIndex: _selectedIndex,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${selectedItem.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: selectedItem.color,
                          ),
                        ),
                        Text(
                          selectedItem.name,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  children: widget.categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == _selectedIndex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? item.color.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: item.color.withOpacity(0.3)) : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${item.percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? item.color : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<SpendingCategoryItem> categories;
  final int selectedIndex;

  _DonutChartPainter({
    required this.categories,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    double startAngle = -pi / 2;

    for (int i = 0; i < categories.length; i++) {
      final item = categories[i];
      final sweepAngle = (item.percentage / 100) * 2 * pi;
      final isSelected = i == selectedIndex;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 18 : 14
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.05, // small gap between slices
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}
