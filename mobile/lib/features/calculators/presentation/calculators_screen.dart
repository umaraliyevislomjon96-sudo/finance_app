import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  int _selectedTab = 0; // 0: Loan, 1: Credit Card

  // Loan State
  double _loanAmount = 25000000.0;
  double _loanRate = 22.0;
  int _loanTermMonths = 24;
  String _paymentType = 'annuity'; // 'annuity' or 'differential'

  // Credit Card State
  double _cardDebt = 5000000.0;
  double _cardLimit = 12000000.0;
  double _cardApr = 28.0;
  double _extraPay = 250000.0;

  double get _monthlyAnnuityPayment {
    final monthlyRate = (_loanRate / 100.0) / 12.0;
    if (monthlyRate == 0) return _loanAmount / _loanTermMonths;
    final factor = pow(1 + monthlyRate, _loanTermMonths);
    return _loanAmount * (monthlyRate * factor) / (factor - 1);
  }

  double get _totalLoanPayment => _monthlyAnnuityPayment * _loanTermMonths;
  double get _totalLoanOverpayment => max(0.0, _totalLoanPayment - _loanAmount);

  // Credit card trap simulation
  Map<String, dynamic> get _creditCardSimulation {
    final monthlyRate = (_cardApr / 100.0) / 12.0;
    const minPayRate = 0.05; // 5% minimum payment

    // Strategy 1: Minimum payment only
    double balMin = _cardDebt;
    double interestMin = 0.0;
    int monthsMin = 0;
    while (balMin > 10000 && monthsMin < 360) {
      monthsMin++;
      final accruedInterest = balMin * monthlyRate;
      interestMin += accruedInterest;
      double pay = balMin * minPayRate;
      if (pay < 100000) pay = 100000;
      if (pay > balMin + accruedInterest) pay = balMin + accruedInterest;
      balMin = (balMin + accruedInterest) - pay;
    }

    // Strategy 2: Accelerated (min + extraPay)
    double balAcc = _cardDebt;
    double interestAcc = 0.0;
    int monthsAcc = 0;
    while (balAcc > 10000 && monthsAcc < 360) {
      monthsAcc++;
      final accruedInterest = balAcc * monthlyRate;
      interestAcc += accruedInterest;
      double pay = (balAcc * minPayRate) + _extraPay;
      if (pay > balAcc + accruedInterest) pay = balAcc + accruedInterest;
      balAcc = (balAcc + accruedInterest) - pay;
    }

    final savedInterest = max(0.0, interestMin - interestAcc);
    final savedMonths = max(0, monthsMin - monthsAcc);

    return {
      'months_min': monthsMin,
      'interest_min': interestMin,
      'months_acc': monthsAcc,
      'interest_acc': interestAcc,
      'saved_interest': savedInterest,
      'saved_months': savedMonths,
      'utilization_pct': (_cardDebt / _cardLimit) * 100,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationController.instance;
    final curr = CurrencyController.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([loc, curr]),
      builder: (context, _) {
        final p = context.palette;
        return Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.xxxl),
              physics: const BouncingScrollPhysics(),
              children: [
                ScreenHeader(
                  title: loc.t('nav_calculators'),
                  subtitle: 'Посчитайте до того, как подписать договор',
                  actions: [_currencyToggle(p, curr)],
                ),
                const SizedBox(height: AppSpacing.xl),
                SegmentedTabs(
                  labels: [loc.t('loan_calculator'), loc.t('credit_card_calculator')],
                  index: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: AppSpacing.xl),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _selectedTab == 0
                      ? KeyedSubtree(key: const ValueKey('loan'), child: _buildLoanView(loc, curr, p))
                      : KeyedSubtree(key: const ValueKey('card'), child: _buildCreditCardView(loc, curr, p)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _currencyToggle(AppPalette p, CurrencyController curr) {
    return Tooltip(
      message: 'Сменить валюту',
      child: InkWell(
        onTap: curr.toggleCurrency,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded, size: 16, color: p.accent),
              const SizedBox(width: 4),
              Text(
                curr.isUzs ? 'UZS' : 'USD',
                style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard({required AppPalette p, required List<Widget> children}) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _legendDot(Color color, String label, AppPalette p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
      ],
    );
  }

  Widget _kv(String label, String value, Color valueColor, AppPalette p, {bool end = false}) {
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.money(16, valueColor)),
      ],
    );
  }

  Widget _buildLoanView(LocalizationController loc, CurrencyController curr, AppPalette p) {
    final principal = _loanAmount;
    final overpayment = _totalLoanOverpayment;
    final total = _totalLoanPayment;
    final principalRatio = total > 0 ? (principal / total).clamp(0.0, 1.0) : 1.0;
    final overpaymentRatio = total > 0 ? (overpayment / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resultCard(p: p, children: [
          Text(loc.t('monthly_payment'), style: TextStyle(color: p.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(curr.format(_monthlyAnnuityPayment), style: AppTypography.money(32, p.textPrimary)),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(flex: max(1, (principalRatio * 100).round()), child: ColoredBox(color: p.primary)),
                  const SizedBox(width: 2),
                  Expanded(flex: max(1, (overpaymentRatio * 100).round()), child: ColoredBox(color: p.expense)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendDot(p.primary, 'Основной долг ${(principalRatio * 100).toStringAsFixed(0)}%', p),
              _legendDot(p.expense, 'Проценты ${(overpaymentRatio * 100).toStringAsFixed(0)}%', p),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: p.border, height: 1),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kv(loc.t('total_overpayment'), curr.format(_totalLoanOverpayment), p.expense, p),
              _kv('Всего выплат', curr.format(_totalLoanPayment), p.textPrimary, p, end: true),
            ],
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        _inputsCard(p, [
          _buildSlider(
            p: p,
            label: loc.t('loan_amount'),
            valueText: curr.format(_loanAmount),
            min: 1000000,
            max: 200000000,
            currentValue: _loanAmount,
            onChanged: (val) => setState(() => _loanAmount = (val / 100000).round() * 100000.0),
          ),
          _buildSlider(
            p: p,
            label: loc.t('interest_rate'),
            valueText: '${_loanRate.toStringAsFixed(1)}%',
            min: 5,
            max: 50,
            currentValue: _loanRate,
            onChanged: (val) => setState(() => _loanRate = (val * 2).round() / 2),
          ),
          _buildSlider(
            p: p,
            label: loc.t('loan_term_months'),
            valueText: '$_loanTermMonths мес.',
            min: 3,
            max: 120,
            currentValue: _loanTermMonths.toDouble(),
            onChanged: (val) => setState(() => _loanTermMonths = val.round()),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Text('Тип платежа', style: TextStyle(color: p.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        SegmentedTabs(
          labels: [loc.t('annuity'), loc.t('differential')],
          index: _paymentType == 'annuity' ? 0 : 1,
          onChanged: (i) => setState(() => _paymentType = i == 0 ? 'annuity' : 'differential'),
        ),
      ],
    );
  }

  Widget _inputsCard(AppPalette p, List<Widget> sliders) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        children: [
          for (var i = 0; i < sliders.length; i++) ...[
            if (i > 0) Divider(color: p.border, height: AppSpacing.lg),
            sliders[i],
          ],
        ],
      ),
    );
  }

  Widget _buildCreditCardView(LocalizationController loc, CurrencyController curr, AppPalette p) {
    final sim = _creditCardSimulation;
    final double utilPct = sim['utilization_pct'];
    final bool isHighUtil = utilPct > 50.0;

    final int monthsMin = sim['months_min'];
    final int monthsAcc = sim['months_acc'];
    final double maxMonths = max(monthsMin.toDouble(), 1.0);
    final double barMin = (monthsMin / maxMonths).clamp(0.2, 1.0) * 120.0;
    final double barAcc = (monthsAcc / maxMonths).clamp(0.12, 1.0) * 120.0;

    Widget column(String months, double height, Color color, String title, String interest) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(months, style: AppTypography.money(15, color)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 56,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.55)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textPrimary)),
            const SizedBox(height: 2),
            Text('проценты: $interest', style: TextStyle(fontSize: 11, color: p.textMuted)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resultCard(p: p, children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: p.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loc.t('cc_min_trap_warning'),
                  style: TextStyle(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              StatusPill(
                label: 'Лимит занят ${utilPct.toStringAsFixed(0)}%',
                color: isHighUtil ? p.expense : p.income,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
            decoration: BoxDecoration(
              color: p.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                column('$monthsMin мес.', barMin, p.expense, 'Только минимум', curr.format(sim['interest_min'], compact: true)),
                column('$monthsAcc мес.', barAcc, p.income, 'С доплатой', curr.format(sim['interest_acc'], compact: true)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: p.income.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.savings_outlined, color: p.income, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(color: p.textPrimary, fontSize: 13, height: 1.4),
                      children: [
                        const TextSpan(text: 'Доплата сэкономит '),
                        TextSpan(
                          text: curr.format(sim['saved_interest']),
                          style: TextStyle(color: p.income, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' и ${sim['saved_months']} мес. выплат'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        _inputsCard(p, [
          _buildSlider(
            p: p,
            label: loc.t('cc_debt_balance'),
            valueText: curr.format(_cardDebt),
            min: 500000,
            max: 50000000,
            currentValue: _cardDebt,
            onChanged: (val) => setState(() => _cardDebt = (val / 50000).round() * 50000.0),
          ),
          _buildSlider(
            p: p,
            label: loc.t('cc_credit_limit'),
            valueText: curr.format(_cardLimit),
            min: 1000000,
            max: 100000000,
            currentValue: _cardLimit,
            onChanged: (val) => setState(() => _cardLimit = (val / 100000).round() * 100000.0),
          ),
          _buildSlider(
            p: p,
            label: 'Годовая ставка (APR)',
            valueText: '${_cardApr.toStringAsFixed(1)}%',
            min: 10,
            max: 60,
            currentValue: _cardApr,
            onChanged: (val) => setState(() => _cardApr = (val * 2).round() / 2),
          ),
          _buildSlider(
            p: p,
            label: 'Доплата к минимальному платежу',
            valueText: curr.format(_extraPay),
            min: 50000,
            max: 2000000,
            currentValue: _extraPay,
            onChanged: (val) => setState(() => _extraPay = (val / 10000).round() * 10000.0),
          ),
        ]),
      ],
    );
  }

  Widget _buildSlider({
    required AppPalette p,
    required String label,
    required String valueText,
    required double min,
    required double max,
    required double currentValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: p.textSecondary, fontSize: 13))),
            Text(valueText, style: AppTypography.money(15, p.textPrimary)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          ),
          child: Slider(
            value: currentValue.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
