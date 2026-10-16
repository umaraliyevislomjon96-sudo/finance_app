import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'pin_setup_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _countdown = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Default demo OTP 123456
    _controllers[0].text = "1";
    _controllers[1].text = "2";
    _controllers[2].text = "3";
    _controllers[3].text = "4";
    _controllers[4].text = "5";
    _controllers[5].text = "6";
  }

  void _startTimer() {
    _timer?.cancel();
    _countdown = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onVerify() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.expenseRed,
          content: Text("Введите полный 6-значный SMS-код"),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(phoneNumber: widget.phoneNumber),
      ),
    );
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
                "Шаг 2 из 3",
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Код из SMS",
                style: AppTypography.display1.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  text: "Мы отправили 6-значный код подтверждения на номер ",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: widget.phoneNumber,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6 OTP Digit Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Container(
                    width: 48,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D2D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _controllers[index].text.isNotEmpty
                            ? AppColors.cyanAccent
                            : AppColors.softBorder,
                        width: 1.5,
                      ),
                      boxShadow: _controllers[index].text.isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppColors.cyanAccent.withOpacity(0.2),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: "",
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        setState(() {});
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Timer / Resend Row
              Center(
                child: _countdown > 0
                    ? Text(
                        "Запросить повторно через $_countdown сек",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      )
                    : GestureDetector(
                        onTap: _startTimer,
                        child: Text(
                          "Отправить код повторно",
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const Spacer(),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Подтвердить и продолжить",
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
