import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/ui_kit.dart';

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
        final p = context.palette;
        final text = Theme.of(context).textTheme;

        return Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.xxxl),
              children: [
                ScreenHeader(title: 'Профиль', onBack: onBack),
                const SizedBox(height: AppSpacing.xxl),

                // Identity
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg + 2),
                  onTap: () => _showPersonalDataSheet(context),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [p.accent, p.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'AM',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alex Mercer', style: text.titleLarge),
                            const SizedBox(height: 2),
                            Text('alex@email.com', style: TextStyle(color: p.textMuted, fontSize: 14)),
                            const SizedBox(height: 8),
                            StatusPill(label: 'Профиль подтверждён', icon: Icons.verified_rounded, color: p.income),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.textMuted),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
                _groupLabel('Финансы', p),
                _menuGroup(p, [
                  _MenuItem(Icons.credit_card_rounded, p.accent, 'Карты и счета', 'Карты, банки, наличные',
                      onOpenCards ?? () => _showCardsSheet(context, curr)),
                  _MenuItem(Icons.auto_awesome, p.savings, 'AI-финансист', 'Автопилот, память, отчёты',
                      onOpenAi ?? () => _showAiFinancierSheet(context)),
                ]),

                const SizedBox(height: AppSpacing.xl),
                _groupLabel('Приложение', p),
                _menuGroup(p, [
                  _MenuItem(Icons.tune_rounded, p.primary, 'Настройки', 'Тема, язык, валюта',
                      () => _showSettingsSheet(context, theme, loc, curr)),
                  _MenuItem(Icons.shield_outlined, p.income, 'Безопасность', 'PIN, биометрия, устройства',
                      () => _showSecuritySheet(context)),
                  _MenuItem(Icons.lock_outline_rounded, p.warning, 'Конфиденциальность', 'Данные, экспорт, удаление',
                      () => _showPrivacySheet(context)),
                ]),

                const SizedBox(height: AppSpacing.xxl),
                TextButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: Icon(Icons.logout_rounded, color: p.expense, size: 20),
                  label: Text('Выйти из аккаунта', style: TextStyle(color: p.expense, fontSize: 15, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(child: Text('Aurora Finance • версия 1.0.0', style: TextStyle(color: p.textMuted, fontSize: 12))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _groupLabel(String label, AppPalette p) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(color: p.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6),
        ),
      );

  Widget _menuGroup(AppPalette p, List<_MenuItem> items) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 72, color: p.border),
            InkWell(
              onTap: items[i].onTap,
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(AppRadius.lg) : Radius.zero,
                bottom: i == items.length - 1 ? const Radius.circular(AppRadius.lg) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                child: Row(
                  children: [
                    IconBadge(icon: items[i].icon, color: items[i].color, size: 40, radius: 12),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary)),
                          const SizedBox(height: 2),
                          Text(items[i].subtitle, style: TextStyle(fontSize: 13, color: p.textMuted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 22, color: p.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- SHEETS ---

  void _detailSheet(BuildContext context, String title, IconData icon, List<(String, String)> rows, {Widget? footer}) {
    showAppSheet(
      context: context,
      title: title,
      icon: icon,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) DetailRow(label: rows[i].$1, value: rows[i].$2, last: i == rows.length - 1),
          if (footer != null) ...[const SizedBox(height: AppSpacing.lg), footer],
        ],
      ),
    );
  }

  void _showPersonalDataSheet(BuildContext context) => _detailSheet(context, 'Личные данные', Icons.person_outline_rounded, [
        ('Имя', 'Alex Mercer'),
        ('Телефон', '+998 90 123 45 67'),
        ('Email', 'alex@email.com'),
        ('Статус', 'Подтверждён'),
      ]);

  void _showCardsSheet(BuildContext context, CurrencyController curr) => _detailSheet(context, 'Карты и счета', Icons.credit_card_rounded, [
        ('Kapitalbank Visa', curr.format(18450000.0)),
        ('Payme Uzcard', curr.format(9600000.0)),
        ('TBC Bank Humo', curr.format(6800000.0)),
        ('Наличные', curr.format(2500000.0)),
      ]);

  void _showSecuritySheet(BuildContext context) => _detailSheet(context, 'Безопасность', Icons.shield_outlined, [
        ('PIN-код', 'Установлен'),
        ('Биометрия', 'Включена'),
        ('Хранение ключей', 'Защищённое хранилище устройства'),
      ]);

  void _showAiFinancierSheet(BuildContext context) => _detailSheet(
        context,
        'AI-финансист',
        Icons.auto_awesome,
        [
          ('Автопилот', 'Еженедельные отчёты'),
          ('Контекстная память', 'Активна'),
        ],
        footer: onOpenAi == null
            ? null
            : FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onOpenAi!();
                },
                child: const Text('Открыть чат с AI'),
              ),
      );

  void _showPrivacySheet(BuildContext context) => _detailSheet(context, 'Конфиденциальность', Icons.lock_outline_rounded, [
        ('Локальные данные', 'Защищённое хранилище'),
        ('Экспорт выписки', 'JSON / CSV'),
        ('Закон РУз «О персональных данных»', 'Требует юр. проверки'),
      ]);

  void _showSettingsSheet(BuildContext context, ThemeController theme, LocalizationController loc, CurrencyController curr) {
    showAppSheet(
      context: context,
      title: 'Настройки',
      icon: Icons.tune_rounded,
      builder: (ctx) => AnimatedBuilder(
        animation: Listenable.merge([theme, loc, curr]),
        builder: (ctx, _) {
          final p = ctx.palette;
          Widget label(String t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(t, style: TextStyle(color: p.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              );
          const langs = [AppLanguage.ru, AppLanguage.uz, AppLanguage.en];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              label('Тема оформления'),
              SegmentedTabs(
                labels: const ['Тёмная', 'Светлая'],
                index: theme.isDarkMode ? 0 : 1,
                onChanged: (i) => theme.setThemeMode(i == 0 ? ThemeMode.dark : ThemeMode.light),
              ),
              const SizedBox(height: AppSpacing.xl),
              label('Язык'),
              SegmentedTabs(
                labels: const ['Русский', "O'zbekcha", 'English'],
                index: langs.indexOf(loc.currentLanguage),
                onChanged: (i) => loc.setLanguage(langs[i]),
              ),
              const SizedBox(height: AppSpacing.xl),
              label('Валюта отображения'),
              SegmentedTabs(
                labels: const ['UZS', 'USD'],
                index: curr.isUzs ? 0 : 1,
                onChanged: (i) => curr.setCurrency(i == 0 ? AppCurrency.uzs : AppCurrency.usd),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Локальные ключи будут заблокированы до ввода PIN-кода.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: p.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.expense, minimumSize: const Size(0, 44)),
            onPressed: () {
              Navigator.pop(ctx);
              onBack();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Вы вышли из аккаунта')),
              );
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.color, this.title, this.subtitle, this.onTap);
}
