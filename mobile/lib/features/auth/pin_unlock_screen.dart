import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/pin_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/glowing_orb.dart';
import 'widgets/pin_pad.dart';

/// Lock screen shown on launch and after the app was in background too long.
class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final _pinService = PinService.instance;
  String _pin = '';
  bool _error = false;
  bool _checking = false;
  bool _biometrics = false;
  String? _message;
  Duration? _lockLeft;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final enabled = await _pinService.biometricsEnabled() && await _pinService.biometricsAvailable();
    if (!mounted) return;
    setState(() => _biometrics = enabled);
    await _refreshLock();
    if (enabled && _lockLeft == null) _tryBiometrics();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLock() async {
    final left = await _pinService.lockRemaining();
    if (!mounted) return;
    setState(() => _lockLeft = left);
    _lockTimer?.cancel();
    if (left != null) {
      _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final l = await _pinService.lockRemaining();
        if (!mounted) return;
        setState(() => _lockLeft = l);
        if (l == null) {
          _lockTimer?.cancel();
          setState(() => _message = null);
        }
      });
    }
  }

  Future<void> _tryBiometrics() async {
    await AuthController.instance.unlockWithBiometrics();
  }

  Future<void> _onDigit(String d) async {
    if (_checking || _lockLeft != null || _pin.length >= PinService.pinLength) return;
    setState(() {
      _error = false;
      _pin += d;
    });
    if (_pin.length < PinService.pinLength) return;

    setState(() => _checking = true);
    final result = await AuthController.instance.unlockWithPin(_pin);
    if (!mounted) return;
    switch (result) {
      case PinCheck.ok:
      case PinCheck.wiped:
        return; // AuthGate swaps the screen.
      case PinCheck.wrong:
        final attempts = await _pinService.failedAttempts();
        setState(() => _message = attempts >= 3 ? 'Неверный PIN. Попыток до паузы: ${5 - attempts}' : 'Неверный PIN-код');
      case PinCheck.lockedOut:
        setState(() => _message = 'Слишком много попыток');
        await _refreshLock();
    }
    setState(() {
      _error = true;
      _pin = '';
      _checking = false;
    });
  }

  Future<void> _forgot() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Забыли PIN?'),
        content: const Text('Мы выйдем из аккаунта на этом устройстве. Войдите по номеру телефона и задайте новый PIN.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти')),
        ],
      ),
    );
    if (ok == true) await AuthController.instance.forgotPin();
  }

  String _format(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final locked = _lockLeft != null;
    final phone = AuthController.instance.phone;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const GlowingOrb(size: 56),
            const SizedBox(height: AppSpacing.sm),
            Text('Введите PIN-код', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            if (phone != null && phone.length >= 4)
              Text('Аккаунт •• ${phone.substring(phone.length - 4)}', style: text.bodyMedium?.copyWith(color: p.textMuted)),
            const SizedBox(height: AppSpacing.xxl),
            PinDots(length: PinService.pinLength, filled: _pin.length, error: _error),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 22,
              child: Text(
                locked ? 'Попробуйте через ${_format(_lockLeft!)}' : (_message ?? ''),
                style: TextStyle(color: locked || _error ? p.expense : p.textMuted, fontSize: 13),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: PinPad(
                enabled: !locked && !_checking,
                onDigit: _onDigit,
                onDelete: () {
                  if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
                },
                leading: _biometrics
                    ? IconButton(
                        tooltip: 'Войти по биометрии',
                        iconSize: 32,
                        onPressed: locked ? null : _tryBiometrics,
                        icon: Icon(Icons.fingerprint_rounded, color: p.primary),
                      )
                    : null,
              ),
            ),
            TextButton(onPressed: _forgot, child: Text('Забыли PIN?', style: TextStyle(color: p.textSecondary))),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
