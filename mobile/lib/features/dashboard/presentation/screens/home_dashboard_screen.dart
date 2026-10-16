import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/notification_listener_service.dart';
import '../widgets/balance_card.dart';
import '../widgets/metric_pill_card.dart';
import '../widgets/ai_insight_banner.dart';
import '../widgets/upcoming_bill_card.dart';
import '../widgets/spending_donut_chart.dart';
import '../widgets/holographic_bank_card.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAi;
  final VoidCallback? onNavigateToBills;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToNotifications;

  const HomeDashboardScreen({
    super.key,
    this.onNavigateToAi,
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
  final PageController _cardPageController = PageController(viewportFraction: 0.92);

  @override
  void initState() {
    super.initState();
    // Subscribe to incoming push transactions
    NotificationListenerService.instance.onTransactionIngested.listen((tx) {
      if (mounted) {
        setState(() {
          _lastIncomingPush = "Учтено: ${tx['merchant']} • ${tx['amount_formatted']}";
        });
      }
    });
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  void _showNotificationsSheet(BuildContext context) {
    if (widget.onNavigateToNotifications != null) {
      widget.onNavigateToNotifications!();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.softBorder),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
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
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, color: AppColors.cyanAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Уведомления',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildNotificationItem(
                icon: Icons.credit_card_rounded,
                title: 'Payme • Korzinka supermarket',
                subtitle: 'Распознано Zero-Touch • 2 мин назад',
                amount: '-45 000 UZS',
                amountColor: AppColors.expenseRed,
              ),
              const SizedBox(height: 10),
              _buildNotificationItem(
                icon: Icons.coffee_rounded,
                title: 'Click • Coffee House Tashkent',
                subtitle: 'Распознано Zero-Touch • 3 часа назад',
                amount: '-35 000 UZS',
                amountColor: AppColors.expenseRed,
              ),
              const SizedBox(height: 10),
              _buildNotificationItem(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Uzum Bank • Поступление зарплаты',
                subtitle: 'Зачисление на карту • Вчера, 18:20',
                amount: '+8 500 000 UZS',
                amountColor: AppColors.incomeGreen,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.cyanAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: amountColor, fontWeight: FontWeight.w800, fontSize: 13)),
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
          onOpenNotifications: () {
            Navigator.of(context).pop();
            _showNotificationsSheet(context);
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
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // COMPACT BANKING HEADER: [AM] Alex Mercer 🔔
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Clickable User Profile: [AM] + Alex Mercer
                      GestureDetector(
                        onTap: () => _openProfile(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00F0FF), Color(0xFF2563EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.cyanAccent.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'AM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Alex Mercer',
                              style: AppTypography.cardTitle.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // AI Health Score Pill: ✦ 78 / 100
                      GestureDetector(
                        onTap: widget.onNavigateToAi,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.cyanAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cyanAccent.withOpacity(0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '✦ 78/100',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Notification Bell Icon (🔔)
                      GestureDetector(
                        onTap: () => _showNotificationsSheet(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.softBorder),
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              Positioned(
                                top: 9,
                                right: 9,
                                child: SizedBox(
                                  width: 7,
                                  height: 7,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.cyanAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Push feedback banner
                  if (_lastIncomingPush != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.incomeGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.incomeGreen.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.incomeGreen),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _lastIncomingPush!,
                              style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 1. Main Total Balance Card (Dynamic UZS / USD)
                  BalanceCard(
                    totalBalanceUzs: 34850000.0,
                    changePercentage: 8.4,
                    onDetailsTap: widget.onNavigateToAi,
                  ),

                  const SizedBox(height: 16),

                  // 2. Income & Spending Metrics
                  Row(
                    children: [
                      Expanded(
                        child: MetricPillCard(
                          label: loc.t('monthly_income'),
                          amount: curr.format(22000000.0),
                          icon: Icons.arrow_upward_rounded,
                          iconColor: AppColors.incomeGreen,
                          iconBgColor: AppColors.incomeGreen.withOpacity(0.12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricPillCard(
                          label: loc.t('monthly_spending'),
                          amount: curr.format(8450000.0),
                          icon: Icons.arrow_downward_rounded,
                          iconColor: AppColors.expenseRed,
                          iconBgColor: AppColors.expenseRed.withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // 3. Holographic Bank Cards Carousel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Мои банковские карты',
                        style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        '3 активные',
                        style: AppTypography.caption.copyWith(color: AppColors.cyanAccent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 205,
                    child: PageView(
                      controller: _cardPageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (idx) => setState(() => _activeCardIndex = idx),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: HolographicBankCard(
                            bankName: 'Kapitalbank',
                            cardType: 'Visa Platinum',
                            maskedPan: '••••  ••••  ••••  4892',
                            balanceFormatted: curr.format(18450000.0),
                            gradientColors: const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF020617)],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: HolographicBankCard(
                            bankName: 'Payme Card',
                            cardType: 'Uzcard',
                            maskedPan: '••••  ••••  ••••  1234',
                            balanceFormatted: curr.format(9600000.0),
                            gradientColors: const [Color(0xFF003B5C), Color(0xFF0284C7), Color(0xFF0369A1)],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: HolographicBankCard(
                            bankName: 'TBC Bank',
                            cardType: 'Humo',
                            maskedPan: '••••  ••••  ••••  9012',
                            balanceFormatted: curr.format(6800000.0),
                            gradientColors: const [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF0F172A)],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Carousel Indicators
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (idx) {
                      final isActive = idx == _activeCardIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.cyanAccent : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 22),

                  // 4. Interactive Spending Donut Chart
                  const SpendingDonutChart(),

                  const SizedBox(height: 20),

                  // 5. AI Insight Banner
                  AiInsightBanner(
                    insightText: '«Рестораны» составляют 34% трат. Направив ${curr.format(1500000.0)} на досрочное погашение кредитки, вы сократите срок долга на 4 месяца.',
                    onActionTap: widget.onNavigateToAi,
                  ),

                  const SizedBox(height: 24),

                  // 6. Upcoming Bills Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.t('upcoming_bills'),
                        style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: widget.onNavigateToBills,
                        child: Text(
                          'Все',
                          style: AppTypography.caption.copyWith(color: AppColors.cyanAccent, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  UpcomingBillCard(
                    title: 'Аренда квартиры',
                    dueDate: '30 Октября',
                    amount: curr.format(4500000.0),
                    categoryIcon: Icons.home_rounded,
                    isCritical: true,
                  ),
                  const SizedBox(height: 10),
                  UpcomingBillCard(
                    title: 'Автокредит Kapitalbank',
                    dueDate: '5 Ноября',
                    amount: curr.format(2850000.0),
                    categoryIcon: Icons.directions_car_filled_rounded,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
