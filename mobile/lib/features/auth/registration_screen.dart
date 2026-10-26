import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/glowing_orb.dart';
import 'otp_screen.dart';

/// Step 1: phone number. Sends the SMS code and opens [OtpScreen].
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  // Consent must be an explicit action, so nothing is pre-ticked.
  bool _consentTerms = false;
  bool _consentSms = false;
  bool _consentAi = false;

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');
  bool get _canSubmit => _digits.length == 9 && _consentTerms && !_loading;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() => _error = null));
    final reason = AuthController.instance.signOutReason;
    if (reason != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
        AuthController.instance.signOutReason = null;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final phone = '+998$_digits';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AuthController.instance.requestOtp(phone);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(phoneNumber: phone, initial: result),
      ));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationController.instance;
    return AnimatedBuilder(
      animation: loc,
      builder: (context, _) {
        final p = context.palette;
        final text = Theme.of(context).textTheme;
        return Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page + 4, AppSpacing.lg, AppSpacing.page + 4, AppSpacing.xxl),
              children: [
                Row(
                  children: [
                    const GlowingOrb(size: 28),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Aurora Finance', style: text.titleMedium)),
                    _langSwitch(p, loc),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(loc.t('welcome_title'), style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(loc.t('welcome_subtitle'), style: text.bodyMedium?.copyWith(color: p.textMuted)),
                const SizedBox(height: AppSpacing.xxxl),
                Text('Номер телефона', style: text.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  inputFormatters: [_UzPhoneFormatter()],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: p.textPrimary, letterSpacing: 0.5),
                  decoration: InputDecoration(
                    hintText: '90 123 45 67',
                    errorText: _error,
                    errorMaxLines: 3,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text('+998', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: p.textSecondary)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                  onSubmitted: (_) => _canSubmit ? _submit() : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                _consent(p, _consentTerms, 'Принимаю условия сервиса и согласен на обработку персональных данных', (v) => setState(() => _consentTerms = v), required: true),
                _consent(p, _consentSms, 'Разрешаю автоматически учитывать операции из SMS и push-уведомлений банков', (v) => setState(() => _consentSms = v)),
                _consent(p, _consentAi, 'Включить AI-советника по моим финансам', (v) => setState(() => _consentAi = v)),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text(loc.t('send_sms_code')),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 14, color: p.textMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Мы не храним данные карт и не проводим платежи',
                        style: TextStyle(color: p.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _langSwitch(AppPalette p, LocalizationController loc) {
    return PopupMenuButton<AppLanguage>(
      tooltip: 'Язык',
      initialValue: loc.currentLanguage,
      onSelected: loc.setLanguage,
      itemBuilder: (_) => const [
        PopupMenuItem(value: AppLanguage.ru, child: Text('Русский')),
        PopupMenuItem(value: AppLanguage.uz, child: Text("O'zbekcha")),
        PopupMenuItem(value: AppLanguage.en, child: Text('English')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 16, color: p.textSecondary),
            const SizedBox(width: 6),
            Text(loc.currentLanguage.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: p.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _consent(AppPalette p, bool value, String label, ValueChanged<bool> onChanged, {bool required = false}) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: [if (required) TextSpan(text: ' *', style: TextStyle(color: p.expense))],
                ),
                style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats 9 local digits as "90 123 45 67".
class _UzPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    // Backspace over a separator: drop the digit before it instead.
    if (newValue.text.length < oldValue.text.length && digits == oldDigits && digits.isNotEmpty) {
      digits = digits.substring(0, digits.length - 1);
    }
    final d = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(d[i]);
    }
    final s = buf.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
