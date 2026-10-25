import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/notification_listener_service.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/balance_card.dart';
import '../widgets/metric_pill_card.dart';
import '../widgets/ai_insight_banner.dart';
import '../widgets/upcoming_bill_card.dart';
import '../widgets/spending_donut_chart.dart';
import '../widgets/holographic_bank_card.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAi;
  final VoidCallback? onNavigateToCalculators;
  final VoidCallback? onNavigateToBills;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToNotifications;

  const HomeDashboardScreen({
    super.key,
    this.onNavigateToAi,
    this.onNavigateToCalculators,
    this.onNavigateToBills,
    this.onNavigateToProfile,
    this.onNavigateToNotifications,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String? _lastIncomingPush;
  int _activeCardIndex = 0;
  final PageController _cardPageController = PageController(viewportFraction: 0.9);
  StreamSubscription? _pushSubscription;

  @override
  void initState() {
    super.initState();
    _pushSubscription = NotificationListenerService.instance.onTransactionIngested.listen((tx) {
      if (mounted) {
        setState(() {
          _lastIncomingPush = 'Учтено: ${tx['merchant']} • ${tx['amount_formatted']}';
        });
      }
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    _cardPageController.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  void _showNotificationsSheet(BuildContext context) {
    if (widget.onNavigateToNotifications != null) {
      widget.onNavigateToNotifications!();
      return;
    }
    final p = context.palette;
    showAppSheet(
      context: context,
      title: 'Уведомления',
      icon: Icons.notifications_active_outlined,
      builder: (ctx) => Column(
        children: [
          _notificationItem(
            p,
            icon: Icons.shopping_cart_outlined,
            title: 'Korzinka',
            subtitle: 'Payme • 2 мин назад',
            amount: '-45 000 UZS',
            amountColor: p.expense,
          ),
          _notificationItem(
            p,
            icon: Icons.coffee_outlined,
            title: 'Coffee House',
            subtitle: 'Click • 3 часа назад',
            amount: '-35 000 UZS',
            amountColor: p.expense,
          ),
          _notificationItem(
            p,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Зарплата',
            subtitle: 'Uzum Bank • вчера, 18:20',
            amount: '+8 500 000 UZS',
            amountColor: p.income,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _notificationItem(
    AppPalette p, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: p.border))),
      child: Row(
        children: [
          IconBadge(icon: icon, color: amountColor, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: p.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: AppTypography.money(14, amountColor)),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    if (widget.onNavigateToProfile != null) {
      widget.onNavigateToProfile!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          onBack: () => Navigator.of(context).pop(),
          onOpenAi: () {
            Navigator.of(context).pop();
            widget.onNavigateToAi?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationController.instance;
    final curr = CurrencyController.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([loc, curr]),
      builder: (context, _) {
        final p = context.palette;
        const cards = [
          ('Kapitalbank', 'Visa', '•••• 4892', 18450000.0, [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF0B1220)]),
          ('Payme', 'Uzcard', '•••• 1234', 9600000.0, [Color(0xFF00598A), Color(0xFF0284C7), Color(0xFF0369A1)]),
          ('TBC Bank', 'Humo', '•••• 9012', 6800000.0, [Color(0xFF3B0F8C), Color(0xFF5B21B6), Color(0xFF1E1B4B)]),
        ];

        return Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            bottom: false,
            child: _buildScroll(
              cards: cards,
              curr: curr,
              p: p,
              loc: loc,
              head: [
                _buildHeader(context, p),

                if (_lastIncomingPush != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _pushBanner(p),
                ],

                const SizedBox(height: AppSpacing.xl),
                BalanceCard(
                  totalBalanceUzs: 34850000.0,
                  changePercentage: 8.4,
                  onDetailsTap: widget.onNavigateToAi,
                ),

                const SizedBox(height: AppSpacing.xl),
                _quickActions(p),

                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: MetricPillCard(
                        label: loc.t('monthly_income'),
                        amount: curr.format(22000000.0),
                        icon: Icons.south_west_rounded,
                        iconColor: p.income,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: MetricPillCard(
                        label: loc.t('monthly_spending'),
                        amount: curr.format(8450000.0),
                        icon: Icons.north_east_rounded,
                        iconColor: p.expense,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(title: 'Мои карты', actionLabel: '${cards.length} активные'),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The card carousel needs to bleed to the screen edges, so it is inserted
  /// into the list outside the horizontal page padding.
  Widget _buildScroll({
    required List<Widget> head,
    required List<(String, String, String, double, List<Color>)> cards,
    required CurrencyController curr,
    required AppPalette p,
    required LocalizationController loc,
  }) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, 0),
          sliver: SliverList(delegate: SliverChildListDelegate(head)),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _cardPageController,
              padEnds: false,
              physics: const BouncingScrollPhysics(),
              itemCount: cards.length,
              onPageChanged: (idx) => setState(() => _activeCardIndex = idx),
              itemBuilder: (context, i) {
                final c = cards[i];
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? AppSpacing.page : 6, right: 6, bottom: 12),
                  child: HolographicBankCard(
                    bankName: c.$1,
                    cardType: c.$2,
                    maskedPan: c.$3,
                    balanceFormatted: curr.format(c.$4),
                    gradientColors: c.$5,
                  ),
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xxxl),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(cards.length, (idx) {
                  final isActive = idx == _activeCardIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? p.primary : p.borderStrong,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SpendingDonutChart(totalLabel: 'Октябрь • ${curr.format(8450000.0, compact: true)}'),
              const SizedBox(height: AppSpacing.lg),
              AiInsightBanner(
                insightText:
                    '«Еда и кафе» — 34% трат. Направив ${curr.format(1500000.0)} на досрочное погашение кредитки, вы сократите срок долга на 4 месяца.',
                onActionTap: widget.onNavigateToAi,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(
                title: loc.t('upcoming_bills'),
                actionLabel: 'Все',
                onAction: widget.onNavigateToBills,
              ),
              UpcomingBillCard(
                title: 'Аренда квартиры',
                dueDate: '30 октября • через 5 дней',
                amount: curr.format(4500000.0),
                categoryIcon: Icons.home_rounded,
                isCritical: true,
                onTap: widget.onNavigateToBills,
              ),
              const SizedBox(height: AppSpacing.md),
              UpcomingBillCard(
                title: 'Автокредит Kapitalbank',
                dueDate: '5 ноября',
                amount: curr.format(2850000.0),
                categoryIcon: Icons.directions_car_filled_rounded,
                onTap: widget.onNavigateToBills,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppPalette p) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Открыть профиль',
          child: GestureDetector(
            onTap: () => _openProfile(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting, style: TextStyle(color: p.textMuted, fontSize: 13)),
                    const SizedBox(height: 1),
                    Text(
                      'Alex Mercer',
                      style: TextStyle(color: p.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _healthPill(p),
        const SizedBox(width: AppSpacing.sm),
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Уведомления',
          showDot: true,
          onTap: () => _showNotificationsSheet(context),
        ),
      ],
    );
  }

  Widget _healthPill(AppPalette p) {
    return Tooltip(
      message: 'Финансовое здоровье',
      child: InkWell(
        onTap: widget.onNavigateToAi,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: 0.78,
                  strokeWidth: 3,
                  backgroundColor: p.surfaceSunken,
                  color: p.income,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '78',
                style: AppTypography.money(14, p.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pushBanner(AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.income.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: p.income),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lastIncomingPush!,
              style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(AppPalette p) {
    final actions = [
      (Icons.auto_awesome, 'Спросить AI', p.primary, widget.onNavigateToAi),
      (Icons.calculate_outlined, 'Кредит', p.savings, widget.onNavigateToCalculators),
      (Icons.receipt_long_outlined, 'Коммуналка', p.accent, widget.onNavigateToBills),
      (Icons.notifications_none_rounded, 'Операции', p.warning, () => _showNotificationsSheet(context)),
    ];
    return Row(
      children: [
        for (final a in actions)
          Expanded(
            child: InkWell(
              onTap: a.$4,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.border),
                        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Icon(a.$1, color: a.$3, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
