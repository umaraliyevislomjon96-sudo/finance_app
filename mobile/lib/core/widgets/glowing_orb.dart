import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlowingOrb extends StatefulWidget {
  final double size;

  const GlowingOrb({
    super.key,
    this.size = 140,
  });

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final breath = _controller.value;
        final currentScale = 1.0 + (breath * 0.05);

        return Transform.scale(
          scale: currentScale,
          child: SizedBox(
            width: widget.size * 1.5,
            height: widget.size * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Atmospheric Ambient Glow
                Container(
                  width: widget.size * 1.3,
                  height: widget.size * 1.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyanAccent.withValues(alpha: 0.22 + (breath * 0.1)),
                        blurRadius: 55,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: AppColors.orbPurple.withValues(alpha: 0.28 + (breath * 0.08)),
                        blurRadius: 70,
                        spreadRadius: 14,
                      ),
                    ],
                  ),
                ),

                // 2. Main 3D Iridescent Sphere
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.4),
                      radius: 0.9,
                      colors: [
                        Color(0xFFE0F7FF), // Bright specular center
                        Color(0xFF38BDF8), // Cyan midtone
                        Color(0xFF818CF8), // Periwinkle blue
                        Color(0xFFA855F7), // Vibrant Purple
                        Color(0xFF4338CA), // Deep Indigo shadow
                        Color(0xFF1E1B4B), // Edge occlusion
                      ],
                      stops: [0.0, 0.22, 0.45, 0.70, 0.90, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyanAccent.withValues(alpha: 0.4),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                      const BoxShadow(
                        color: Color(0x8A000000),
                        blurRadius: 20,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                ),

                // 3. Specular Gloss Highlight
                Positioned(
                  top: widget.size * 0.28,
                  left: widget.size * 0.35,
                  child: Container(
                    width: widget.size * 0.32,
                    height: widget.size * 0.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(50),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
