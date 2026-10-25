import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../navigation/presentation/main_bottom_nav.dart';

class PinSetupScreen extends StatefulWidget {
  final String phoneNumber;

  const PinSetupScreen({super.key, required this.phoneNumber});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = "";
  bool _enableBiometrics = true;

  void _onKeyPress(String key) {
    if (key == "clear") {
      setState(() => _pin = "");
      return;
    }
    if (key == "del") {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }

    if (_pin.length < 4) {
      setState(() => _pin += key);

      if (_pin.length == 4) {
        // Complete PIN setup and route into Main Application
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainBottomNav()),
            (route) => false,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                "Шаг 3 из 3",
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              "Установите PIN-код",
              style: AppTypography.display1.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              "4 цифры для быстрого и защищенного входа",
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 36),

            // 4 Pin Dots with Luminous Glow
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.cyanAccent : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppColors.cyanAccent : Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: AppColors.cyanAccent.withValues(alpha: 0.6),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Biometric Option Switch
            GestureDetector(
              onTap: () => setState(() => _enableBiometrics = !_enableBiometrics),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 22,
                    color: _enableBiometrics ? AppColors.cyanAccent : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Включить Face ID / Биометрию",
                    style: AppTypography.bodySmall.copyWith(
                      color: _enableBiometrics ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _enableBiometrics,
                    onChanged: (val) => setState(() => _enableBiometrics = val),
                    activeColor: AppColors.cyanAccent,
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Custom Glass Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
              child: Column(
                children: [
                  _buildKeypadRow(["1", "2", "3"]),
                  const SizedBox(height: 16),
                  _buildKeypadRow(["4", "5", "6"]),
                  const SizedBox(height: 16),
                  _buildKeypadRow(["7", "8", "9"]),
                  const SizedBox(height: 16),
                  _buildKeypadRow(["clear", "0", "del"]),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        return GestureDetector(
          onTap: () => _onKeyPress(key),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            alignment: Alignment.center,
            child: _buildKeyContent(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyContent(String key) {
    if (key == "del") {
      return const Icon(Icons.backspace_outlined, color: Colors.white, size: 22);
    }
    if (key == "clear") {
      return Text(
        "СБРОС",
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      );
    }
    return Text(
      key,
      style: AppTypography.titleLarge.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}
