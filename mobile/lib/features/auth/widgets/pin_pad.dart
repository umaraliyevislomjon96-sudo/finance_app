import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_palette.dart';

/// Row of PIN dots that shakes on error.
class PinDots extends StatefulWidget {
  final int length;
  final int filled;
  final bool error;

  const PinDots({super.key, required this.length, required this.filled, this.error = false});

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void didUpdateWidget(PinDots old) {
    super.didUpdateWidget(old);
    if (widget.error && !old.error) {
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(_shake.isAnimating ? dx : 0, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (i) {
          final on = i < widget.filled;
          final color = widget.error ? p.expense : p.primary;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on || widget.error ? color : Colors.transparent,
              border: Border.all(color: on || widget.error ? color : p.borderStrong, width: 2),
            ),
          );
        }),
      ),
    );
  }
}

/// Numeric keypad. [leading] fills the bottom-left key (e.g. biometrics).
class PinPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final Widget? leading;
  final bool enabled;

  const PinPad({super.key, required this.onDigit, required this.onDelete, this.leading, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget key(Widget child, VoidCallback? onTap, {String? label}) => Semantics(
          button: true,
          label: label,
          child: SizedBox(
            width: 76,
            height: 76,
            child: Material(
              color: onTap == null ? Colors.transparent : p.surface,
              shape: CircleBorder(side: BorderSide(color: onTap == null ? Colors.transparent : p.border)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enabled ? onTap : null,
                child: Center(child: child),
              ),
            ),
          ),
        );

    Widget digit(String d) => key(
          Text(d, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: p.textPrimary)),
          () {
            HapticFeedback.selectionClick();
            onDigit(d);
          },
          label: d,
        );

    Widget row(List<Widget> children) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: children),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          leading == null ? key(const SizedBox(), null) : SizedBox(width: 76, height: 76, child: Center(child: leading)),
          digit('0'),
          key(Icon(Icons.backspace_outlined, color: p.textSecondary), onDelete, label: 'Стереть'),
        ]),
      ],
    );
  }
}
