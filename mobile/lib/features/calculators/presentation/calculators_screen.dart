import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
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
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.t('nav_calculators'),
                        style: AppTypography.display2.copyWith(fontWeight: FontWeight.w800, fontSize: 24),
                      ),
                      // Currency Indicator
                      GestureDetector(
                        onTap: () => curr.toggleCurrency(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cyanAccent.withOpacity(0.3)),
                          ),
                          child: Text(
                            curr.symbol,
                            style: const TextStyle(
                              color: AppColors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Subtabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.softBorder),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, loc.t('loan_calculator')),
                        _buildTabButton(1, loc.t('credit_card_calculator')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_selectedTab == 0) _buildLoanView(loc, curr) else _buildCreditCardView(loc, curr),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTypography.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanView(LocalizationController loc, CurrencyController curr) {
    final principal = _loanAmount;
    final overpayment = _totalLoanOverpayment;
    final total = _totalLoanPayment;
    final principalRatio = total > 0 ? (principal / total).clamp(0.0, 1.0) : 1.0;
    final overpaymentRatio = total > 0 ? (overpayment / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result Summary Card
        GlassCard(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          borderColor: AppColors.primaryBlue.withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.t('monthly_payment'),
                style: AppTypography.caption.copyWith(color: AppColors.cyanAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                curr.format(_monthlyAnnuityPayment),
                style: AppTypography.display1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 16),

              // Visual Segmented Bar: Principal vs Overpayment
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (principalRatio * 100).round(),
                        child: Container(color: AppColors.primaryBlue),
                      ),
                      Expanded(
                        flex: (overpaymentRatio * 100).round(),
                        child: Container(color: AppColors.expenseRed),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("Тело: ${(principalRatio * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.expenseRed, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("Проценты: ${(overpaymentRatio * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 11, color: AppColors.expenseRed)),
                    ],
                  ),
                ],
              ),

              const Divider(height: 24, color: Colors.white12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.t('total_overpayment'), style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        curr.format(_totalLoanOverpayment),
                        style: AppTypography.titleMedium.copyWith(color: AppColors.expenseRed, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Всего выплат", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        curr.format(_totalLoanPayment),
                        style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sliders
        _buildSlider(
          label: loc.t('loan_amount'),
          valueText: curr.format(_loanAmount),
          min: 1000000,
          max: 200000000,
          currentValue: _loanAmount,
          onChanged: (val) => setState(() => _loanAmount = val),
        ),
        const SizedBox(height: 18),

        _buildSlider(
          label: loc.t('interest_rate'),
          valueText: "${_loanRate.toStringAsFixed(1)} %",
          min: 5,
          max: 50,
          currentValue: _loanRate,
          onChanged: (val) => setState(() => _loanRate = val),
        ),
        const SizedBox(height: 18),

        _buildSlider(
          label: loc.t('loan_term_months'),
          valueText: "$_loanTermMonths мес.",
          min: 3,
          max: 120,
          currentValue: _loanTermMonths.toDouble(),
          onChanged: (val) => setState(() => _loanTermMonths = val.round()),
        ),
        const SizedBox(height: 20),

        // Payment Type Switcher
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: Center(child: Text(loc.t('annuity'))),
                selected: _paymentType == 'annuity',
                onSelected: (_) => setState(() => _paymentType = 'annuity'),
                selectedColor: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: Center(child: Text(loc.t('differential'))),
                selected: _paymentType == 'differential',
                onSelected: (_) => setState(() => _paymentType = 'differential'),
                selectedColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditCardView(LocalizationController loc, CurrencyController curr) {
    final sim = _creditCardSimulation;
    final double utilPct = sim['utilization_pct'];
    final bool isHighUtil = utilPct > 50.0;

    final int monthsMin = sim['months_min'];
    final int monthsAcc = sim['months_acc'];
    final double maxMonths = max(monthsMin.toDouble(), 1.0);
    final double barMinHeight = (monthsMin / maxMonths).clamp(0.2, 1.0) * 110.0;
    final double barAccHeight = (monthsAcc / maxMonths).clamp(0.15, 1.0) * 110.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Savings & Trap Card
        GlassCard(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          borderColor: AppColors.cyanAccent.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.t('cc_min_trap_warning'),
                    style: AppTypography.caption.copyWith(color: AppColors.warningOrange, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isHighUtil ? AppColors.expenseRed.withOpacity(0.15) : AppColors.incomeGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHighUtil ? AppColors.expenseRed.withOpacity(0.4) : AppColors.incomeGreen.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      "Лимит занят: ${utilPct.toStringAsFixed(0)}%",
                      style: AppTypography.caption.copyWith(
                        color: isHighUtil ? AppColors.expenseRed : AppColors.incomeGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visual Overpayment Mountain / Columns
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Min Payment Trap Column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "$monthsMin мес.",
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.expenseRed, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: barMinHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.expenseRed, Color(0xFF991B1B)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: AppColors.expenseRed.withOpacity(0.3), blurRadius: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("⚠️ Мин. платёж", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                        Text(curr.format(sim['interest_min']), style: const TextStyle(fontSize: 10, color: AppColors.expenseRed, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    // Accelerated Payoff Column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "$monthsAcc мес.",
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.incomeGreen, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: barAccHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.cyanAccent, AppColors.incomeGreen],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: AppColors.incomeGreen.withOpacity(0.35), blurRadius: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("🚀 Ускоренное", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.incomeGreen)),
                        Text(curr.format(sim['interest_acc']), style: const TextStyle(fontSize: 10, color: AppColors.incomeGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Highlighted Savings Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyanAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyanAccent.withOpacity(0.25)),
                ),
                child: Text(
                  "Экономия: ${curr.format(sim['saved_interest'])} и ${sim['saved_months']} мес. свободы от долгов!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.cyanAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildSlider(
          label: loc.t('cc_debt_balance'),
          valueText: curr.format(_cardDebt),
          min: 500000,
          max: 50000000,
          currentValue: _cardDebt,
          onChanged: (val) => setState(() => _cardDebt = val),
        ),
        const SizedBox(height: 18),

        _buildSlider(
          label: loc.t('cc_credit_limit'),
          valueText: curr.format(_cardLimit),
          min: 1000000,
          max: 100000000,
          currentValue: _cardLimit,
          onChanged: (val) => setState(() => _cardLimit = val),
        ),
        const SizedBox(height: 18),

        _buildSlider(
          label: "Процентная ставка (APR)",
          valueText: "${_cardApr.toStringAsFixed(1)} %",
          min: 10,
          max: 60,
          currentValue: _cardApr,
          onChanged: (val) => setState(() => _cardApr = val),
        ),
        const SizedBox(height: 18),

        _buildSlider(
          label: "Доплата к мин. платежу (+)",
          valueText: curr.format(_extraPay),
          min: 50000,
          max: 2000000,
          currentValue: _extraPay,
          onChanged: (val) => setState(() => _extraPay = val),
        ),
      ],
    );
  }

  Widget _buildSlider({
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
            Text(valueText, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryBlue,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: AppColors.cyanAccent,
            overlayColor: AppColors.cyanAccent.withOpacity(0.2),
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
