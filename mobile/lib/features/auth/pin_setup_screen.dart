import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/pin_service.dart';
import '../../core/theme/app_palette.dart';
import 'widgets/pin_pad.dart';

/// Step 3: choose a 4-digit PIN, then repeat it. Biometrics can be enabled
/// when the device supports it.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String? _first;
  bool _error = false;
  bool _saving = false;
  bool _biometricsAvailable = false;
  bool _biometrics = true;

  @override
  void initState() {
    super.initState();
    PinService.instance.biometricsAvailable().then((v) {
      if (mounted) setState(() => _biometricsAvailable = v);
    });
  }

  bool _isWeak(String pin) {
    if (pin.split('').toSet().length == 1) return true; // 1111
    const runs = '01234567890';
    const reverse = '09876543210';
    return runs.contains(pin) || reverse.contains(pin); // 1234, 4321
  }

  Future<void> _onDigit(String d) async {
    if (_saving || _pin.length >= PinService.pinLength) return;
    setState(() {
      _error = false;
      _pin += d;
    });
    if (_pin.length < PinService.pinLength) return;

    await Future.delayed(const Duration(milliseconds: 150));
    if (_first == null) {
      if (_isWeak(_pin)) {
        _fail('Слишком простой PIN. Не используйте одинаковые цифры или 1234.');
        return;
      }
      setState(() {
        _first = _pin;
        _pin = '';
      });
      return;
    }
    if (_pin != _first) {
      _fail('PIN-коды не совпали. Придумайте заново.');
      setState(() => _first = null);
      return;
    }
    setState(() => _saving = true);
    await AuthController.instance.setPin(_pin, biometrics: _biometricsAvailable && _biometrics);
  }

  void _fail(String message) {
    setState(() {
      _error = true;
      _pin = '';
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final confirming = _first != null;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, 0),
              child: Row(
                children: [
                  if (confirming)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _first = null;
                        _pin = '';
                      }),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Заново'),
                    ),
                  const Spacer(),
                  Text('Шаг 3 из 3', style: TextStyle(color: p.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const Spacer(),
            Icon(Icons.lock_outline_rounded, size: 36, color: p.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(confirming ? 'Повторите PIN-код' : 'Придумайте PIN-код', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              confirming ? 'Введите те же 4 цифры ещё раз' : 'Он нужен для быстрого входа в приложение',
              style: text.bodyMedium?.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PinDots(length: PinService.pinLength, filled: _pin.length, error: _error),
            const SizedBox(height: AppSpacing.xl),
            if (_biometricsAvailable)
              SwitchListTile.adaptive(
                value: _biometrics,
                onChanged: (v) => setState(() => _biometrics = v),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                secondary: Icon(Icons.fingerprint_rounded, color: p.primary),
                title: Text('Вход по отпечатку или Face ID', style: TextStyle(color: p.textPrimary, fontSize: 14)),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _saving
                  ? const Padding(padding: EdgeInsets.all(AppSpacing.xxxl), child: CircularProgressIndicator())
                  : PinPad(
                      onDigit: _onDigit,
                      onDelete: () {
                        if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
