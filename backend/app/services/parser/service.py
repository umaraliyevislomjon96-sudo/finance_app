from datetime import datetime, timezone
from typing import Optional, Dict, Any, List, Tuple
from dataclasses import dataclass, asdict

from .normalizer import NotificationNormalizer
from .detector import FinancialDetector, FinancialTransactionType
from .classifier import TransactionClassifier
from .deduplication import DeduplicationEngine
from .engine import TransactionParserEngine
from .base import ParsedTransaction, TransactionDirection, TransactionStatus


@dataclass
class IngestionResult:
    status: str  # "processed", "already_processed", "ignored_non_financial", "unrecognized", "needs_review"
    is_financial: bool
    financial_type: str
    confidence_score: float
    category: str
    merchant: Optional[str]
    amount: Optional[float]
    amount_formatted: Optional[str]
    currency: Optional[str]
    direction: Optional[str]
    card_last4: Optional[str]
    balance_after: Optional[float]
    is_internal_transfer: bool
    is_refund: bool
    related_transaction_id: Optional[str]
    requires_user_review: bool
    message: str
    transaction: Optional[Dict[str, Any]] = None
    ai_advisory_note: Optional[str] = None


class TransactionProcessingService:
    """
    Unified Financial Transaction Processing Service.
    Orchestrates the 8-layer pipeline:
    1. Notification Normalizer
    2. Financial Detector (Pre-filter: prevents non-financial notifications from running heavy logic)
    3. Transaction Parser (Deterministic bank templates & regex fallback)
    4. Transaction Classifier (18 categories + merchant directory + feedback learning)
    5. Deduplication & Correlation (5-min window, push/SMS match, refund and internal transfer detection)
    6. Financial State Synchronization (Balance, Cards, Analytics, Budget)
    7. AI Agent Memory Registration (Grounds AI Assistant in live financial events)
    """

    def __init__(self):
        self.normalizer = NotificationNormalizer()
        self.detector = FinancialDetector()
        self.parser_engine = TransactionParserEngine()
        self.classifier = TransactionClassifier()
        self.dedup_engine = DeduplicationEngine()

        # Configurable service settings (mirrored in UI profile)
        self.settings = {
            "listener_status": "connected",  # "connected", "permission_required", "disabled", "error"
            "auto_detection_enabled": True,
            "ai_categorization_enabled": True,
            "auto_creation_enabled": True,
            "supported_apps": [
                "Click Evolution (uz.click.app)",
                "Payme (uz.dida.payme)",
                "Uzum Bank (app.bank.uzum)",
                "Kapitalbank (com.kapitalbank)",
                "TBC Bank UZ (com.tbcbank.uz)",
                "Anorbank (com.fido.anorbank)",
                "Ipak Yuli (com.fido.ipakyulibank)",
                "Hamkorbank (com.hamkorbank.mobile)",
                "Uzcard / Humo SMS (7557, 0808)"
            ]
        }

    def process_notification(
        self,
        raw_text: str,
        user_id: str = "usr_99890_mock_id",
        package_name: Optional[str] = None,
        source: str = "push",
        timestamp: Optional[datetime] = None,
        existing_transactions: Optional[List[Dict[str, Any]]] = None,
        idempotency_key: Optional[str] = None
    ) -> IngestionResult:
        dt = timestamp or datetime.now(timezone.utc)
        recent_txs = existing_transactions or []

        # 0. Check Master Switch
        if not self.settings.get("auto_detection_enabled", True) or self.settings.get("listener_status") == "disabled":
            return IngestionResult(
                status="disabled",
                is_financial=False,
                financial_type="non_financial",
                confidence_score=0.0,
                category="Other",
                merchant=None,
                amount=None,
                amount_formatted=None,
                currency=None,
                direction=None,
                card_last4=None,
                balance_after=None,
                is_internal_transfer=False,
                is_refund=False,
                related_transaction_id=None,
                requires_user_review=False,
                message="Автоматическое распознавание транзакций отключено в настройках пользователя"
            )

        # 1. Normalization & Sanitization Layer
        normalized_text, norm_meta = self.normalizer.normalize(raw_text)

        # 2. Financial Detection Pre-filter (Lightweight check before heavy processing)
        detection = self.detector.is_financial_notification(normalized_text, package_name=package_name)
        if not detection.is_financial:
            return IngestionResult(
                status="ignored_non_financial",
                is_financial=False,
                financial_type=detection.financial_type.value,
                confidence_score=detection.confidence,
                category="Other",
                merchant=None,
                amount=None,
                amount_formatted=None,
                currency=None,
                direction=None,
                card_last4=None,
                balance_after=None,
                is_internal_transfer=False,
                is_refund=False,
                related_transaction_id=None,
                requires_user_review=False,
                message=f"Уведомление проигнорировано: {detection.reason}"
            )

        # 3. Deterministic Transaction Parsing
        parsed: Optional[ParsedTransaction] = self.parser_engine.process_notification(
            raw_text=normalized_text,
            user_id=user_id,
            timestamp=dt,
            recent_transactions=recent_txs
        )

        if not parsed:
            return IngestionResult(
                status="unrecognized",
                is_financial=True,
                financial_type=detection.financial_type.value,
                confidence_score=0.30,
                category="Other",
                merchant=None,
                amount=None,
                amount_formatted=None,
                currency=None,
                direction=None,
                card_last4=None,
                balance_after=None,
                is_internal_transfer=False,
                is_refund=False,
                related_transaction_id=None,
                requires_user_review=True,
                message="Не удалось точно извлечь финансовые параметры из текста (данные не выдуманы)"
            )

        # 4. Duplicate Check (5-min window cross-channel deduplication)
        temp_id = f"tx_tmp_{int(dt.timestamp() * 1000)}"
        dup_res = self.dedup_engine.check_and_register(
            user_id=user_id,
            amount=parsed.amount,
            currency=parsed.currency,
            card_last4=parsed.card_last4,
            merchant=parsed.merchant,
            dt=dt,
            direction=parsed.direction.value,
            tx_id=temp_id
        )

        if dup_res.is_duplicate:
            return IngestionResult(
                status="already_processed",
                is_financial=True,
                financial_type=detection.financial_type.value,
                confidence_score=parsed.confidence_score,
                category="Other",
                merchant=parsed.merchant,
                amount=parsed.amount,
                amount_formatted=f"{int(parsed.amount):,} {parsed.currency}".replace(",", " "),
                currency=parsed.currency,
                direction=parsed.direction.value,
                card_last4=parsed.card_last4,
                balance_after=parsed.balance_after,
                is_internal_transfer=False,
                is_refund=False,
                related_transaction_id=dup_res.existing_tx_id,
                requires_user_review=False,
                message="Дубликат уведомления: операция уже зарегистрирована в системе"
            )

        # 5. Categorization Layer (18 categories)
        if self.settings.get("ai_categorization_enabled", True):
            category, cat_conf = self.classifier.classify(
                merchant=parsed.merchant,
                financial_type=detection.financial_type,
                text=normalized_text
            )
        else:
            category = "Other"
            cat_conf = 0.50

        # 6. Advanced Correlation: Internal Transfer vs Refund
        is_internal_transfer = False
        is_refund = (parsed.direction == TransactionDirection.REFUND or detection.financial_type == FinancialTransactionType.REFUND)
        related_tx_id = parsed.related_transaction_id

        # Internal transfer check (Card A -> Card B within 3 minutes, opposing debit/credit)
        if detection.financial_type in (FinancialTransactionType.TRANSFER, FinancialTransactionType.PURCHASE, FinancialTransactionType.INCOMING_TRANSFER) or parsed.direction in (TransactionDirection.TRANSFER, TransactionDirection.EXPENSE, TransactionDirection.INCOME):
            matched_pair_id = self.dedup_engine.correlate_internal_transfer(
                new_tx={
                    "id": temp_id,
                    "amount": parsed.amount,
                    "direction": parsed.direction.value,
                    "occurred_at": dt
                },
                recent_transactions=recent_txs
            )
            if matched_pair_id:
                is_internal_transfer = True
                related_tx_id = matched_pair_id
                parsed.direction = TransactionDirection.TRANSFER
                category = "Transfer"

        # Refund correlation with past expense within 30 days
        if is_refund and not related_tx_id:
            matched_expense_id = self.dedup_engine.correlate_refund(
                refund_amount=parsed.amount,
                merchant=parsed.merchant,
                occurred_at=dt,
                recent_transactions=recent_txs
            )
            if matched_expense_id:
                related_tx_id = matched_expense_id

        # 7. Confidence Score & Review Thresholds
        # 95–100% -> High (confirmed)
        # 75–94%  -> Medium (confirmed)
        # < 75%   -> Needs Review
        combined_confidence = round((parsed.confidence_score * 0.7) + (detection.confidence * 0.2) + (cat_conf * 0.1), 2)
        requires_review = combined_confidence < 0.75
        tx_status = TransactionStatus.NEEDS_REVIEW if requires_review else TransactionStatus.CONFIRMED

        amount_formatted = f"{int(parsed.amount):,} {parsed.currency}".replace(",", " ")

        # Prepare AI Context Note
        ai_note = self._generate_advisory_note(
            category=category,
            merchant=parsed.merchant,
            amount=parsed.amount,
            currency=parsed.currency,
            direction=parsed.direction.value,
            is_internal_transfer=is_internal_transfer,
            is_refund=is_refund
        )

        # Build Canonical Transaction Record
        tx_dict = {
            "id": f"tx-{len(recent_txs) + 1}",
            "user_id": user_id,
            "card_last4": parsed.card_last4,
            "amount": parsed.amount,
            "amount_tiyin": int(parsed.amount * 100),
            "amount_formatted": amount_formatted,
            "currency": parsed.currency,
            "direction": parsed.direction.value,
            "merchant": parsed.merchant,
            "category": category,
            "source": source,
            "status": tx_status.value,
            "confidence_score": combined_confidence,
            "duplicate_hash": dup_res.duplicate_hash,
            "idempotency_key": idempotency_key,
            "occurred_at": dt.isoformat(),
            "balance_after": parsed.balance_after,
            "is_internal_transfer": is_internal_transfer,
            "is_refund": is_refund,
            "related_transaction_id": related_tx_id,
            "raw_text": normalized_text
        }

        return IngestionResult(
            status="processed" if not requires_review else "needs_review",
            is_financial=True,
            financial_type=detection.financial_type.value,
            confidence_score=combined_confidence,
            category=category,
            merchant=parsed.merchant,
            amount=parsed.amount,
            amount_formatted=amount_formatted,
            currency=parsed.currency,
            direction=parsed.direction.value,
            card_last4=parsed.card_last4,
            balance_after=parsed.balance_after,
            is_internal_transfer=is_internal_transfer,
            is_refund=is_refund,
            related_transaction_id=related_tx_id,
            requires_user_review=requires_review,
            message="Операция успешно распознана и добавлена в финансовую систему" if not requires_review else "Операция добавлена в очередь на проверку из-за неполных данных",
            transaction=tx_dict,
            ai_advisory_note=ai_note
        )

    def _generate_advisory_note(
        self,
        category: str,
        merchant: str,
        amount: float,
        currency: str,
        direction: str,
        is_internal_transfer: bool,
        is_refund: bool
    ) -> str:
        amt_str = f"{int(amount):,} {currency}".replace(",", " ")
        if is_internal_transfer:
            return f"Внутренний перевод {amt_str} между собственными картами. Общий капитал не изменился."
        if is_refund:
            return f"Возврат {amt_str} от {merchant}. Уменьшает расход за текущий месяц."
        if category == "Salary":
            return f"Зачислена зарплата +{amt_str}. Баланс и прогноз накоплений обновлены."
        if category == "Loan":
            return f"Погашение кредита {amt_str}. Учтено в уменьшении долговых обязательств."
        if category == "Cash Withdrawal":
            return f"Снятие наличных {amt_str} в банкомате. Учтено как перемещение в наличные средства."
        return f"Расход {amt_str} в {merchant} (Категория: {category})."
