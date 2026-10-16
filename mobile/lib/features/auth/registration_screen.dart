import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/social_auth_service.dart';
import 'otp_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController(text: "90 123 45 67");
  bool _isLoading = false;

  // Consents per Law of the Republic of Uzbekistan 'On Personal Data' [Проверить у юриста]
  bool _consentTerms = true;
  bool _consentSms = true;
  bool _consentAi = true;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinuePhone() {
    final loc = LocalizationController.instance;
    if (!_consentTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.expenseRed,
          content: Text("Для продолжения необходимо принять Условия сервиса и согласие на обработку данных (ст. 13 Закона РУз)"),
        ),
      );
      return;
    }

    final rawPhone = _phoneController.text.replaceAll(' ', '');
    final fullPhone = "+998$rawPhone";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(phoneNumber: fullPhone),
      ),
    );
  }

  Future<void> _handleOAuthLogin(String provider) async {
    setState(() => _isLoading = true);
    final result = await SocialAuthService.instance.signInWithProvider(provider: provider);
    setState(() => _isLoading = false);

    if (result != null && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.expenseRed,
          content: Text("Ошибка авторизации через $provider. Повторите попытку."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationController.instance;

    return AnimatedBuilder(
      animation: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar: Badge & Language Selector (RU, EN, UZ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cyanAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 14, color: AppColors.cyanAccent),
                            const SizedBox(width: 6),
                            Text(
                              "SPENDLY FINTECH",
                              style: AppTypography.caption.copyWith(
                                color: AppColors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildLangPill(AppLanguage.ru, 'RU'),
                            const SizedBox(width: 4),
                            _buildLangPill(AppLanguage.en, 'EN'),
                            const SizedBox(width: 4),
                            _buildLangPill(AppLanguage.uz, 'UZ'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Title & Subtitle
                  Text(
                    loc.t('welcome_title'),
                    style: AppTypography.display1.copyWith(
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loc.t('welcome_subtitle'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone Input Container
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D2D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.softBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          "+998",
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 24, color: Colors.white.withOpacity(0.12)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "90 123 45 67",
                              hintStyle: TextStyle(color: AppColors.textDisabled),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Phone Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onContinuePhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.t('send_sms_code'),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider with "or continue with"
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.08))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          loc.t('or_continue_with'),
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.08))),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // OAuth Buttons Grid (Google, Apple ID, GitHub)
                  Row(
                    children: [
                      // Google
                      Expanded(
                        child: _buildOAuthButton(
                          icon: Icons.g_mobiledata,
                          label: "Google",
                          color: const Color(0xFFEA4335),
                          onTap: () => _handleOAuthLogin('google'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Apple ID (Required per Apple Guidelines)
                      Expanded(
                        child: _buildOAuthButton(
                          icon: Icons.apple,
                          label: "Apple ID",
                          color: Colors.white,
                          onTap: () => _handleOAuthLogin('apple'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // GitHub
                      Expanded(
                        child: _buildOAuthButton(
                          icon: Icons.code,
                          label: "GitHub",
                          color: const Color(0xFF6E5494),
                          onTap: () => _handleOAuthLogin('github'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Legal Consents Box
                  GlassCard(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "ЮРИДИЧЕСКИЕ СОГЛАСИЯ (ЗАКОН РУЗ)",
                              style: AppTypography.caption.copyWith(
                                color: AppColors.cyanAccent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cyanAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "[Проверить у юриста]",
                                style: AppTypography.caption.copyWith(fontSize: 9, color: AppColors.cyanAccent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildConsentRow(
                          value: _consentTerms,
                          label: "Согласен с Условиями сервиса и обработкой персональных данных (ст. 13 Закона РУз)",
                          onChanged: (val) => setState(() => _consentTerms = val),
                        ),
                        const SizedBox(height: 10),
                        _buildConsentRow(
                          value: _consentSms,
                          label: "Разрешить автоматический учет push и SMS транзакций (ст. 27¹ Закона РУз)",
                          onChanged: (val) => setState(() => _consentSms = val),
                        ),
                        const SizedBox(height: 10),
                        _buildConsentRow(
                          value: _consentAi,
                          label: "Включить контекстного AI-советника (деперсонализированная аналитика)",
                          onChanged: (val) => setState(() => _consentAi = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Non-custodial privacy guarantee
                  Center(
                    child: Text(
                      "🔒 Non-custodial: Мы не храним CVV, PIN карт и не осуществляем платежи.",
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOAuthButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131D2D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.softBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangPill(AppLanguage lang, String label) {
    final isSelected = LocalizationController.instance.currentLanguage == lang;
    return GestureDetector(
      onTap: () => LocalizationController.instance.setLanguage(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildConsentRow({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: value ? AppColors.primaryBlue : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: value ? AppColors.primaryBlue : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: value ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
