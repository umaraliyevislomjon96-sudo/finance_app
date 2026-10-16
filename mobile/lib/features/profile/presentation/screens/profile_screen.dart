import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenCards;
  final VoidCallback? onOpenAi;

  const ProfileScreen({
    super.key,
    required this.onBack,
    this.onOpenNotifications,
    this.onOpenCards,
    this.onOpenAi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final loc = LocalizationController.instance;
    final curr = CurrencyController.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([theme, loc, curr]),
      builder: (context, _) {
        final isDark = theme.isDarkMode;
        final cardBg = isDark ? const Color(0xFF141E33) : Colors.white;
        final borderColor = isDark ? AppColors.softBorder : const Color(0xFFE2E8F0);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Bar: ← 👤 ПРОФИЛЬ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: onBack,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Text('👤', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'ПРОФИЛЬ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40), // Balance placeholder
                    ],
                  ),

                  const SizedBox(height: 24),

                  // [ Фото ] / Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F0FF), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyanAccent.withOpacity(0.35),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'AM',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141E33),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cyanAccent, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: AppColors.cyanAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Alex Mercer
                  Text(
                    'Alex Mercer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // alex@email.com
                  const Text(
                    'alex@email.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Divider ──────────────────
                  Divider(
                    color: isDark ? AppColors.softBorder : const Color(0xFFE2E8F0),
                    thickness: 1,
                  ),

                  const SizedBox(height: 12),

                  // 6 Menu Items Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 1. 👤 Личные данные (Имя, телефон, email)
                        _buildProfileMenuItem(
                          icon: '👤',
                          iconBgColor: AppColors.primaryBlue.withOpacity(0.12),
                          title: 'Личные данные',
                          subtitle: 'Имя, телефон, email',
                          isDark: isDark,
                          onTap: () => _showPersonalDataSheet(context, isDark),
                        ),

                        _buildItemDivider(borderColor),

                        // 2. 💳 Карты и счета (Карты, банки, наличные)
                        _buildProfileMenuItem(
                          icon: '💳',
                          iconBgColor: AppColors.cyanAccent.withOpacity(0.12),
                          title: 'Карты и счета',
                          subtitle: 'Карты, банки, наличные',
                          isDark: isDark,
                          onTap: onOpenCards ?? () => _showCardsSheet(context, isDark, curr),
                        ),

                        _buildItemDivider(borderColor),

                        // 3. 🔐 Безопасность (PIN, Face ID, устройства)
                        _buildProfileMenuItem(
                          icon: '🔐',
                          iconBgColor: AppColors.incomeGreen.withOpacity(0.12),
                          title: 'Безопасность',
                          subtitle: 'PIN, Face ID, устройства',
                          isDark: isDark,
                          onTap: () => _showSecuritySheet(context, isDark),
                        ),

                        _buildItemDivider(borderColor),

                        // 4. ⚙️ Настройки (Язык, тема, уведомления)
                        _buildProfileMenuItem(
                          icon: '⚙️',
                          iconBgColor: AppColors.warningAmber.withOpacity(0.12),
                          title: 'Настройки',
                          subtitle: 'Язык, тема, уведомления',
                          isDark: isDark,
                          onTap: () => _showSettingsSheet(context, isDark, theme, loc),
                        ),

                        _buildItemDivider(borderColor),

                        // 5. 🤖 AI Финансист (AI Autopilot, память, отчёты)
                        _buildProfileMenuItem(
                          icon: '🤖',
                          iconBgColor: AppColors.savingsPurple.withOpacity(0.12),
                          title: 'AI Финансист',
                          subtitle: 'AI Autopilot, память, отчёты',
                          isDark: isDark,
                          onTap: onOpenAi ?? () => _showAiFinancierSheet(context, isDark),
                        ),

                        _buildItemDivider(borderColor),

                        // 6. 🔒 Конфиденциальность (Данные, экспорт, удаление)
                        _buildProfileMenuItem(
                          icon: '🔒',
                          iconBgColor: AppColors.expenseRed.withOpacity(0.12),
                          title: 'Конфиденциальность',
                          subtitle: 'Данные, экспорт, удаление',
                          isDark: isDark,
                          onTap: () => _showPrivacySheet(context, isDark),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider ──────────────────
                  Divider(
                    color: isDark ? AppColors.softBorder : const Color(0xFFE2E8F0),
                    thickness: 1,
                  ),

                  const SizedBox(height: 18),

                  // Выйти из аккаунта
                  GestureDetector(
                    onTap: () {
                      _showLogoutDialog(context, isDark);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.expenseRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.expenseRed.withOpacity(0.35)),
                      ),
                      child: const Center(
                        child: Text(
                          'Выйти из аккаунта',
                          style: TextStyle(
                            color: AppColors.expenseRed,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem({
    required String icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isLast ? Radius.zero : const Radius.circular(22),
        bottom: isLast ? const Radius.circular(22) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            // Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 76,
      endIndent: 18,
      color: borderColor,
    );
  }

  // --- MODALS & DETAILS ---

  void _showPersonalDataSheet(BuildContext context, bool isDark) {
    _showAppModalSheet(
      context: context,
      title: '👤 Личные данные',
      isDark: isDark,
      children: [
        _buildDetailRow('ФИО', 'Alex Mercer'),
        _buildDetailRow('Номер телефона', '+998 90 123 45 67'),
        _buildDetailRow('Email', 'alex@email.com'),
        _buildDetailRow('Статус профиля', 'Верифицирован (Tier 2)'),
      ],
    );
  }

  void _showCardsSheet(BuildContext context, bool isDark, CurrencyController curr) {
    _showAppModalSheet(
      context: context,
      title: '💳 Карты и счета',
      isDark: isDark,
      children: [
        _buildDetailRow('Kapitalbank Visa', curr.format(18450000.0)),
        _buildDetailRow('Payme Card Uzcard', curr.format(9600000.0)),
        _buildDetailRow('TBC Bank Humo', curr.format(6800000.0)),
        _buildDetailRow('Наличные в кошельке', curr.format(2500000.0)),
      ],
    );
  }

  void _showSecuritySheet(BuildContext context, bool isDark) {
    _showAppModalSheet(
      context: context,
      title: '🔐 Безопасность',
      isDark: isDark,
      children: [
        _buildDetailRow('PIN-код', 'Установлен (6 цифр)'),
        _buildDetailRow('Биометрия (Face ID)', 'Включено'),
        _buildDetailRow('Активное устройство', 'iPhone 16 Pro (iOS 18)'),
        _buildDetailRow('Аппаратный анклав', 'Secure Enclave AES-256'),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context, bool isDark, ThemeController theme, LocalizationController loc) {
    _showAppModalSheet(
      context: context,
      title: '⚙️ Настройки',
      isDark: isDark,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Язык приложения', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          trailing: Text(
            loc.currentLanguage == AppLanguage.ru ? 'Русский' : (loc.currentLanguage == AppLanguage.en ? 'English' : "O'zbekcha"),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cyanAccent),
          ),
          onTap: () {
            final next = loc.currentLanguage == AppLanguage.ru
                ? AppLanguage.en
                : (loc.currentLanguage == AppLanguage.en ? AppLanguage.uz : AppLanguage.ru);
            loc.setLanguage(next);
            Navigator.pop(context);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Тема оформления', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          trailing: Text(
            isDark ? 'Тёмная (Obsidian)' : 'Светлая (Ceramic)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cyanAccent),
          ),
          onTap: () {
            theme.toggleTheme();
            Navigator.pop(context);
          },
        ),
        _buildDetailRow('Push-уведомления', 'Zero-Touch Interceptor (Вкл)'),
      ],
    );
  }

  void _showAiFinancierSheet(BuildContext context, bool isDark) {
    _showAppModalSheet(
      context: context,
      title: '🤖 AI Финансист',
      isDark: isDark,
      children: [
        _buildDetailRow('AI Autopilot', 'Включен (Еженедельные отчёты)'),
        _buildDetailRow('Контекстная память', 'Активна (24 факта)'),
        _buildDetailRow('Health Score', '78 / 100'),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyanAccent.withOpacity(0.15),
            foregroundColor: AppColors.cyanAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pop(context);
            if (onOpenAi != null) onOpenAi!();
          },
          child: const Text('Открыть AI Chat & Agent'),
        ),
      ],
    );
  }

  void _showPrivacySheet(BuildContext context, bool isDark) {
    _showAppModalSheet(
      context: context,
      title: '🔒 Конфиденциальность',
      isDark: isDark,
      children: [
        _buildDetailRow('Локальное шифрование', 'SQLCipher AES-256'),
        _buildDetailRow('Экспорт выписки', 'JSON / CSV доступен'),
        _buildDetailRow('Синхронизация данных', 'Анонимизирована'),
        _buildDetailRow('Закон РУз № ЗРУ-547', 'Полное соответствие'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141E33) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Выход из аккаунта', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Вы уверены, что хотите выйти? Локальные ключи будут заблокированы до ввода PIN-кода.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onBack();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Вы успешно вышли из аккаунта')),
              );
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showAppModalSheet({
    required BuildContext context,
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111928) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppColors.softBorder),
              ...children,
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
