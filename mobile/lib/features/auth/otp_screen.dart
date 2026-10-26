import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/ui_kit.dart';

/// Step 2: SMS code. On success the session is saved and [AuthGate] moves on
/// to PIN setup, so this screen pops itself back to the root.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final OtpRequestResult initial;

  const OtpScreen({super.key, required this.phoneNumber, required this.initial});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  late int _countdown;
  late String? _demoCode;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _demoCode = widget.initial.demoCode;
    _startTimer(widget.initial.expiresInSeconds);
    _controller.addListener(_onChanged);
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    _countdown = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown > 0 ? _countdown-- : t.cancel());
    });
  }

  void _onChanged() {
    setState(() => _error = null);
    if (_controller.text.length == _length && !_verifying) _verify();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await AuthController.instance.verifyOtp(widget.phoneNumber, _controller.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      _controller.clear();
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final r = await AuthController.instance.requestOtp(widget.phoneNumber);
      if (!mounted) return;
      setState(() => _demoCode = r.demoCode);
      _startTimer(r.expiresInSeconds);
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Новый код отправлен')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final code = _controller.text;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.xxl),
          children: [
            Row(children: [CircleIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Назад', onTap: () => Navigator.pop(context))]),
            const SizedBox(height: AppSpacing.xxl),
            Text('Код из SMS', style: text.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text.rich(
              TextSpan(
                text: 'Отправили 6 цифр на ',
                children: [TextSpan(text: _pretty(widget.phoneNumber), style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600))],
              ),
              style: text.bodyMedium?.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // One real input under six visual cells: paste and SMS autofill just work.
            Stack(
              children: [
                Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    enabled: !_verifying,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_length)],
                    showCursor: false,
                    enableInteractiveSelection: false,
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _focus.requestFocus(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_length, (i) {
                        final filled = i < code.length;
                        final active = i == code.length && _focus.hasFocus;
                        final borderColor = _error != null ? p.expense : (active ? p.primary : (filled ? p.borderStrong : p.border));
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 48,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: borderColor, width: active ? 2 : 1.2),
                          ),
                          child: Text(
                            filled ? code[i] : '',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.textPrimary),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: _verifying
                  ? Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: p.primary)),
                        const SizedBox(width: 10),
                        Text('Проверяем код…', style: TextStyle(color: p.textMuted, fontSize: 13)),
                      ],
                    )
                  : _error != null
                      ? Text(_error!, style: TextStyle(color: p.expense, fontSize: 13))
                      : null,
            ),
            if (_demoCode != null) _demoBanner(p),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: _countdown > 0
                  ? Text('Отправить снова через 0:${_countdown.toString().padLeft(2, '0')}', style: TextStyle(color: p.textMuted, fontSize: 14))
                  : TextButton(
                      onPressed: _resending ? null : _resend,
                      child: Text(_resending ? 'Отправляем…' : 'Отправить код снова'),
                    ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Изменить номер', style: TextStyle(color: p.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sandbox SMS provider returns the code; show it so testing needs no phone.
  Widget _demoBanner(AppPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: p.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Тестовый режим SMS. Код: $_demoCode', style: TextStyle(color: p.textPrimary, fontSize: 13)),
          ),
          TextButton(
            onPressed: _verifying ? null : () => _controller.text = _demoCode!,
            child: const Text('Вставить'),
          ),
        ],
      ),
    );
  }

  static String _pretty(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.length != 12) return phone;
    return '+${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10)}';
  }
}
