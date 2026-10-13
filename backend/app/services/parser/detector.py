import re
from dataclasses import dataclass, field
from typing import Optional, List, Set
from enum import Enum


class FinancialTransactionType(str, Enum):
    PURCHASE = "purchase"
    CARD_PAYMENT = "card_payment"
    CASH_WITHDRAWAL = "cash_withdrawal"
    TRANSFER = "transfer"
    INCOMING_TRANSFER = "incoming_transfer"
    SALARY_INCOME = "salary_income"
    REFUND = "refund"
    FEE_COMMISSION = "fee_commission"
    LOAN_PAYMENT = "loan_payment"
    CREDIT_CARD_PAYMENT = "credit_card_payment"
    TOP_UP = "top_up"
    INTERNAL_TRANSFER = "internal_transfer"
    OTHER = "other_financial_transaction"
    NON_FINANCIAL = "non_financial"


@dataclass
class FinancialDetectionResult:
    is_financial: bool
    financial_type: FinancialTransactionType
    confidence: float
    reason: str
    detected_markers: List[str] = field(default_factory=list)


class FinancialDetector:
    """
    Financial Notification Detection Engine.
    Accurately classifies whether an incoming notification represents an actual
    financial transaction or non-financial noise (social, OTP, marketing, system).
    """

    # Non-financial application package identifiers
    NON_FINANCIAL_PACKAGES: Set[str] = {
        "com.whatsapp",
        "com.whatsapp.w4b",
        "org.telegram.messenger",
        "org.telegram.plus",
        "com.instagram.android",
        "com.google.android.youtube",
        "com.zhiliaoapp.musically",  # TikTok
        "com.facebook.katana",
        "com.facebook.orca",
        "com.twitter.android",
        "com.snapchat.android",
        "com.viber.voip",
        "com.discord",
        "com.google.android.gm",  # Gmail (unless financial parser explicitly handles mail)
    }

    # Known banking / payment package prefixes or substrings
    BANKING_PACKAGES: Set[str] = {
        "uz.click.app",
        "uz.dida.payme",
        "app.bank.uzum",
        "com.kapitalbank",
        "com.tbcbank.uz",
        "com.fido.anorbank",
        "com.fido.ipakyulibank",
        "com.hamkorbank.mobile",
        "com.kdb",
        "com.ipotekabank",
        "uz.agrobank.mobile",
        "uz.sqb.mobile",
        "uz.asakabank.mobile",
        "uz.xb.mobile",
        "uz.nbu.mobile",
        "com.revolut",
        "com.monzo",
    }

    # Non-transactional message patterns (even from banks)
    NON_TRANSACTION_PATTERNS = [
        re.compile(r"(?:kod|код|code|otp)\s*(?:dlya\s+vhoda|podtverzhdeniya|для\s+входа|подтверждения|tasdiqlash)", re.IGNORECASE),
        re.compile(r"(?:parol|пароль|password)\s*(?:uspeshno|izmenen|изменен|o'zgartirildi)", re.IGNORECASE),
        re.compile(r"(?:uspeshnyy\s+vhod|успешный\s+вход|muvaffaqiyatli\s+kirish)", re.IGNORECASE),
        re.compile(r"(?:skidk[ai]|акция|скидк[аи]|chegirma|promokod|промокод|reklama|реклама)", re.IGNORECASE),
        re.compile(r"(?:novaya\s+funktsiya|novosti|новости|yangiliklar|tehnicheskie\s+raboty|технические\s+работы)", re.IGNORECASE),
        re.compile(r"(?:oformite\s+kredit|оформите\s+кредит|kredit\s+olish|podayte\s+zayavku|подайте\s+заявку)", re.IGNORECASE),
    ]

    # Financial keywords mapped to candidate types
    FINANCIAL_KEYWORD_RULES = [
        # 1. Salary / Income
        (
            re.compile(r"\b(zarplata|зарплат[аы]|oylik|ish\s*haqi|salary|payroll)\b", re.IGNORECASE),
            FinancialTransactionType.SALARY_INCOME,
            0.96
        ),
        # 2. Refund / Reversal
        (
            re.compile(r"\b(vozvrat|возврат|refund|reversal|otmena\s+pokupki|qaytarildi|bekor\s+qilindi)\b", re.IGNORECASE),
            FinancialTransactionType.REFUND,
            0.95
        ),
        # 3. Cash Withdrawal (ATM)
        (
            re.compile(r"\b(snyatie\s+nalichnyh|снятие\s+наличных|naqd\s+pul\s+yechish|bankomat|atm\s+withdrawal|cash\s+withdrawal)\b", re.IGNORECASE),
            FinancialTransactionType.CASH_WITHDRAWAL,
            0.95
        ),
        # 4. Loan Payment
        (
            re.compile(r"\b(pogashenie\s+kredita|погашение\s+кредита|kredit\s+to['`]?lovi|kredit\s+so['`]?ndirish|loan\s+payment|avtokredit|ipoteka)\b", re.IGNORECASE),
            FinancialTransactionType.LOAN_PAYMENT,
            0.94
        ),
        # 5. Credit Card Payment
        (
            re.compile(r"\b(oplata\s+kreditnoy\s+karty|оплата\s+кредитной\s+карты|kredit\s+karta\s+to['`]?lovi|credit\s+card\s+payment)\b", re.IGNORECASE),
            FinancialTransactionType.CREDIT_CARD_PAYMENT,
            0.94
        ),
        # 6. Fees / Commission
        (
            re.compile(r"\b(komissiya|комиссия|xizmat\s+haqi|fee|commission|sms-xabarnoma|sms\s+xizmat)\b", re.IGNORECASE),
            FinancialTransactionType.FEE_COMMISSION,
            0.90
        ),
        # 7. Incoming Transfer / Top-up
        (
            re.compile(r"\b(postuplenie|поступление|zachislenie|зачисление|popolnenie|пополнение|tushum|kirim|kiruvchi|deposit|received)\b", re.IGNORECASE),
            FinancialTransactionType.INCOMING_TRANSFER,
            0.92
        ),
        # 8. Outgoing Transfer
        (
            re.compile(r"\b(perevod|перевод|o['`]?tkazma|kartadan\s+kartaga|transfer|p2p|sent\s+to)\b", re.IGNORECASE),
            FinancialTransactionType.TRANSFER,
            0.91
        ),
        # 9. Purchase / Card Payment
        (
            re.compile(r"\b(oplata|оплата|spisanie|списание|pokupka|покупка|to['`]?lov|yechildi|purchase|paid|spent|terminal:)\b", re.IGNORECASE),
            FinancialTransactionType.PURCHASE,
            0.93
        ),
    ]

    # Monetary presence indicator (amount + currency or symbol)
    AMOUNT_PATTERN = re.compile(
        r"(?:(?:\d[\d\s,.]*)\s*(?:UZS|USD|EUR|GBP|RUB|сум|so['`]?m|\$|€|£|₽))|"
        r"(?:(?:[\$€£₽]|USD|EUR|GBP|RUB|UZS)\s*(?:\d[\d,.]*))",
        re.IGNORECASE
    )

    @classmethod
    def is_financial_notification(
        cls,
        text: str,
        package_name: Optional[str] = None
    ) -> FinancialDetectionResult:
        if not text or len(text.strip()) < 5:
            return FinancialDetectionResult(
                is_financial=False,
                financial_type=FinancialTransactionType.NON_FINANCIAL,
                confidence=0.0,
                reason="Текст пустой или слишком короткий"
            )

        clean_text = text.strip()

        # Step 1: Reject known non-financial packages immediately
        if package_name and package_name.lower() in cls.NON_FINANCIAL_PACKAGES:
            return FinancialDetectionResult(
                is_financial=False,
                financial_type=FinancialTransactionType.NON_FINANCIAL,
                confidence=0.99,
                reason=f"Приложение {package_name} исключено из обработки финансовых уведомлений"
            )

        # Step 2: Check for non-transactional triggers (OTP, marketing, login alerts)
        for non_tx_pat in cls.NON_TRANSACTION_PATTERNS:
            if non_tx_pat.search(clean_text):
                return FinancialDetectionResult(
                    is_financial=False,
                    financial_type=FinancialTransactionType.NON_FINANCIAL,
                    confidence=0.95,
                    reason="Уведомление содержит сервисный, авторизационный или маркетинговый текст, не являющийся операцией"
                )

        # Step 3: Check for presence of monetary amount with currency
        has_amount = bool(cls.AMOUNT_PATTERN.search(clean_text))

        # Step 4: Evaluate financial keyword rules
        detected_type = FinancialTransactionType.NON_FINANCIAL
        highest_score = 0.0
        markers: List[str] = []

        for pattern, tx_type, score in cls.FINANCIAL_KEYWORD_RULES:
            match = pattern.search(clean_text)
            if match:
                matched_word = match.group(0)
                markers.append(matched_word)
                if score > highest_score:
                    highest_score = score
                    detected_type = tx_type

        # If has banking package name, boost confidence
        is_known_bank = bool(package_name and any(b in package_name.lower() for b in cls.BANKING_PACKAGES))
        if is_known_bank:
            highest_score = min(1.0, highest_score + 0.05)
            markers.append(f"package:{package_name}")

        # Decision synthesis
        if detected_type != FinancialTransactionType.NON_FINANCIAL and has_amount:
            # Confirmed financial transaction
            return FinancialDetectionResult(
                is_financial=True,
                financial_type=detected_type,
                confidence=round(highest_score, 2),
                reason=f"Обнаружена финансовая операция типа '{detected_type.value}' с суммой и ключевыми словами",
                detected_markers=markers
            )
        elif detected_type != FinancialTransactionType.NON_FINANCIAL and not has_amount:
            # Financial keyword present, but NO monetary amount -> cannot create financial transaction
            return FinancialDetectionResult(
                is_financial=False,
                financial_type=detected_type,
                confidence=0.40,
                reason="Обнаружены финансовые термины, но отсутствует сумма операции (нельзя выдумывать данные)",
                detected_markers=markers
            )
        elif has_amount and is_known_bank:
            # Bank notification with amount, but unrecognized verb
            return FinancialDetectionResult(
                is_financial=True,
                financial_type=FinancialTransactionType.OTHER,
                confidence=0.78,
                reason="Банковское уведомление содержит сумму, тип требует уточнения",
                detected_markers=markers + ["has_amount"]
            )
        else:
            # Message has numbers or text, but lacks financial transaction semantics
            return FinancialDetectionResult(
                is_financial=False,
                financial_type=FinancialTransactionType.NON_FINANCIAL,
                confidence=0.90,
                reason="Текст не содержит признаков финансовой операции",
                detected_markers=markers
            )
