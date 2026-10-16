import 'package:flutter/material.dart';

enum AppLanguage { ru, en, uz }

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static final Map<AppLanguage, Map<String, String>> _localizedValues = {
    AppLanguage.ru: {
      'app_title': 'Aurora Finance',
      'welcome_title': 'Умный финансовый мониторинг',
      'welcome_subtitle': 'Автоматический учёт расходов и доходов без ручного ввода. Безопасно и приватно.',
      'login_with_phone': 'Войти по номеру телефона',
      'enter_phone': 'Введите номер телефона',
      'send_sms_code': 'Получить SMS-код',
      'or_continue_with': 'или продолжить через',
      'sign_in_google': 'Войти с Google',
      'sign_in_apple': 'Войти с Apple ID',
      'sign_in_github': 'Войти с GitHub',
      'pin_setup_title': 'Задайте PIN-код',
      'pin_setup_subtitle': 'Для быстрого и безопасного входа в приложение',
      'enable_biometrics': 'Включить Face ID / Отпечаток',
      'confirm_pin': 'Подтвердить',
      'total_balance': 'Общий баланс',
      'monthly_spending': 'Расходы за месяц',
      'monthly_income': 'Доходы за месяц',
      'upcoming_bills': 'Ближайшие платежи',
      'nav_home': 'Главная',
      'nav_calculators': 'Калькуляторы',
      'nav_ai': 'AI-Ассистент',
      'nav_profile': 'Профиль',
      'loan_calculator': 'Кредитный калькулятор',
      'credit_card_calculator': 'Калькулятор кредитки',
      'loan_amount': 'Сумма кредита',
      'interest_rate': 'Процентная ставка',
      'loan_term_months': 'Срок кредита (мес.)',
      'monthly_payment': 'Ежемесячный платеж',
      'total_overpayment': 'Переплата по процентам',
      'annuity': 'Аннуитетный',
      'differential': 'Дифференцированный',
      'cc_debt_balance': 'Текущий долг по карте',
      'cc_credit_limit': 'Кредитный лимит',
      'cc_min_payment_pct': 'Минимальный платеж (%)',
      'cc_min_trap_warning': 'Ловушка минимального платежа',
      'cc_accelerated_strategy': 'Ускоренное погашение',
      'cc_interest_saved': 'Экономия на процентах',
      'cc_months_saved': 'Месяцев сэкономлено',
      'ai_chat_title': 'Контекстный AI-Ассистент',
      'ai_chat_placeholder': 'Спросите о ваших расходах, долгах или планах...',
      'theme_dark': 'Тёмная тема (Obsidian)',
      'theme_light': 'Светлая тема (Ceramic)',
      'language': 'Язык',
      'zero_manual_entry': 'Zero-Touch учёт: банковские SMS и пуши распознаются мгновенно.',
      'legal_compliance': 'Соответствует Закону РУз «О персональных данных» [Проверить у юриста]',
    },
    AppLanguage.en: {
      'app_title': 'Aurora Finance',
      'welcome_title': 'Smart Financial Monitoring',
      'welcome_subtitle': 'Automatic expense & income tracking with zero manual entry. Secure & non-custodial.',
      'login_with_phone': 'Sign in with phone number',
      'enter_phone': 'Enter phone number',
      'send_sms_code': 'Get SMS Code',
      'or_continue_with': 'or continue with',
      'sign_in_google': 'Sign in with Google',
      'sign_in_apple': 'Sign in with Apple ID',
      'sign_in_github': 'Sign in with GitHub',
      'pin_setup_title': 'Set up PIN code',
      'pin_setup_subtitle': 'For quick and secure access to your finances',
      'enable_biometrics': 'Enable Face ID / Fingerprint',
      'confirm_pin': 'Confirm',
      'total_balance': 'Total Balance',
      'monthly_spending': 'Monthly Spending',
      'monthly_income': 'Monthly Income',
      'upcoming_bills': 'Upcoming Bills',
      'nav_home': 'Home',
      'nav_calculators': 'Calculators',
      'nav_ai': 'AI Assistant',
      'nav_profile': 'Profile',
      'loan_calculator': 'Loan Calculator',
      'credit_card_calculator': 'Credit Card Calculator',
      'loan_amount': 'Loan Amount',
      'interest_rate': 'Interest Rate',
      'loan_term_months': 'Loan Term (months)',
      'monthly_payment': 'Monthly Payment',
      'total_overpayment': 'Total Interest Overpayment',
      'annuity': 'Annuity',
      'differential': 'Differential',
      'cc_debt_balance': 'Current Card Debt',
      'cc_credit_limit': 'Credit Limit',
      'cc_min_payment_pct': 'Minimum Payment (%)',
      'cc_min_trap_warning': 'Minimum Payment Trap',
      'cc_accelerated_strategy': 'Accelerated Payoff',
      'cc_interest_saved': 'Interest Saved',
      'cc_months_saved': 'Months Saved',
      'ai_chat_title': 'Contextual AI Assistant',
      'ai_chat_placeholder': 'Ask about your spending, debt payoff, or budget...',
      'theme_dark': 'Dark Mode (Obsidian)',
      'theme_light': 'Light Mode (Ceramic)',
      'language': 'Language',
      'zero_manual_entry': 'Zero-Touch: bank SMS & push notifications parsed in real time.',
      'legal_compliance': 'Complies with Uzbekistan Personal Data Law [Check with legal counsel]',
    },
    AppLanguage.uz: {
      'app_title': 'Aurora Finance',
      'welcome_title': 'Aqlli moliyaviy monitoring',
      'welcome_subtitle': 'Qo\'lda kiritishsiz avtomatik xarajat va daromadlar hisobi. Xavfsiz va shaxsiy.',
      'login_with_phone': 'Telefon raqami orqali kirish',
      'enter_phone': 'Telefon raqamini kiriting',
      'send_sms_code': 'SMS kodni olish',
      'or_continue_with': 'yoki quyidagilar orqali',
      'sign_in_google': 'Google orqali kirish',
      'sign_in_apple': 'Apple ID orqali kirish',
      'sign_in_github': 'GitHub orqali kirish',
      'pin_setup_title': 'PIN-kod o\'rnating',
      'pin_setup_subtitle': 'Ilovaga tez va xavfsiz kirish uchun',
      'enable_biometrics': 'Face ID / Barmoq izini yoqish',
      'confirm_pin': 'Tasdiqlash',
      'total_balance': 'Umumiy balans',
      'monthly_spending': 'Oylik xarajatlar',
      'monthly_income': 'Oylik daromadlar',
      'upcoming_bills': 'Yaqin to\'lovlar',
      'nav_home': 'Asosiy',
      'nav_calculators': 'Kalkulyatorlar',
      'nav_ai': 'AI Yordamchi',
      'nav_profile': 'Profil',
      'loan_calculator': 'Kredit kalkulyatori',
      'credit_card_calculator': 'Kredit karta kalkulyatori',
      'loan_amount': 'Kredit miqdori',
      'interest_rate': 'Foiz stavkasi',
      'loan_term_months': 'Kredit muddati (oy)',
      'monthly_payment': 'Oylik to\'lov',
      'total_overpayment': 'Ortiqcha foiz to\'lovi',
      'annuity': 'Annuitet',
      'differential': 'Differensial',
      'cc_debt_balance': 'Joriy qarz miqdori',
      'cc_credit_limit': 'Kredit limiti',
      'cc_min_payment_pct': 'Minimal to\'lov (%)',
      'cc_min_trap_warning': 'Minimal to\'lov tuzog\'i',
      'cc_accelerated_strategy': 'Tezlashtirilgan to\'lov',
      'cc_interest_saved': 'Tejalgan foizlar',
      'cc_months_saved': 'Tejalgan oylar',
      'ai_chat_title': 'Kontekstual AI Yordamchi',
      'ai_chat_placeholder': 'Xarajatlar, qarzlar yoki byudjet bo\'yicha savol bering...',
      'theme_dark': 'Tungi rejim (Obsidian)',
      'theme_light': 'Kunduzgi rejim (Ceramic)',
      'language': 'Til',
      'zero_manual_entry': 'Zero-Touch: bank SMS va bildirishnomalari avtomatik hisoblanadi.',
      'legal_compliance': 'O\'zbekiston Shaxsiy ma\'lumotlar to\'g\'risidagi qonuniga mos [Yurist bilan tekshiring]',
    },
  };

  String text(String key) {
    return _localizedValues[language]?[key] ?? _localizedValues[AppLanguage.ru]?[key] ?? key;
  }
}

class LocalizationController extends ChangeNotifier {
  static final LocalizationController instance = LocalizationController._();
  LocalizationController._();

  AppLanguage _currentLanguage = AppLanguage.ru;

  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  String t(String key) {
    return AppLocalizations(_currentLanguage).text(key);
  }
}
