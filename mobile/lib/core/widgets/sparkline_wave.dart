import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SparklineWavePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color strokeColor;

  SparklineWavePainter({
    required this.dataPoints,
    this.strokeColor = AppColors.cyanAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    final maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (dataPoints.length - 1);

    double getY(double val) {
      final normalized = (val - minVal) / range;
      // Invert Y and leave padding
      return size.height - (normalized * (size.height * 0.75) + (size.height * 0.12));
    }

    path.moveTo(0, getY(dataPoints[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(dataPoints[0]));

    for (int i = 0; i < dataPoints.length - 1; i++) {
      final p0X = i * stepX;
      final p0Y = getY(dataPoints[i]);
      final p1X = (i + 1) * stepX;
      final p1Y = getY(dataPoints[i + 1]);

      final controlX1 = p0X + (stepX / 2);
      final controlY1 = p0Y;
      final controlX2 = p0X + (stepX / 2);
      final controlY2 = p1Y;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1X, p1Y);
      fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1X, p1Y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          strokeColor.withValues(alpha: 0.28),
          AppColors.primaryBlue.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Glowing blur stroke
    final glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Crisp foreground stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant SparklineWavePainter oldDelegate) => true;
}

class SparklineWave extends StatelessWidget {
  final List<double> dataPoints;
  final double height;
  final Color strokeColor;

  const SparklineWave({
    super.key,
    required this.dataPoints,
    this.height = 70,
    this.strokeColor = AppColors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: SparklineWavePainter(
          dataPoints: dataPoints,
          strokeColor: strokeColor,
        ),
      ),
    );
  }
}
