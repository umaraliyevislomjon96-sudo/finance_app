from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any, Tuple
import re
from .base import (
    BaseBankParser,
    ParsedTransaction,
    TransactionDirection,
    TransactionStatus,
    clean_amount,
    calculate_duplicate_hash,
)
from .uzbek_banks import (
    ClickNotificationParser,
    PaymeNotificationParser,
    UzumBankParser,
    UzcardHumoGatewayParser,
    CyrillicBankNotificationParser,
)
from .international import UniversalInternationalParser


class RegexFallbackParser(BaseBankParser):
    name = "RegexFallback"

    def match(self, text: str) -> bool:
        return True

    def parse(self, text: str, user_id: str, timestamp: Optional[datetime] = None) -> Optional[ParsedTransaction]:
        dt = timestamp or datetime.now(timezone.utc)
        norm = text.strip()

        # Look for numbers that resemble an amount
        amt_match = re.search(r"(\d[\d\s,.]*)\s*(UZS|USD|EUR|GBP|RUB|сум|so'm|\$|€)", norm, re.IGNORECASE)
        if not amt_match:
            return None

        amount = clean_amount(amt_match.group(1))
        raw_curr = amt_match.group(2).upper()
        curr_map = {"$": "USD", "€": "EUR", "СУМ": "UZS", "SO'M": "UZS"}
        currency = curr_map.get(raw_curr, raw_curr)

        direction = TransactionDirection.EXPENSE
        if any(w in norm.lower() for w in ["пополнение", "зачисление", "income", "received", "kirim"]):
            direction = TransactionDirection.INCOME
        elif any(w in norm.lower() for w in ["перевод", "transfer", "o'tkazma"]):
            direction = TransactionDirection.TRANSFER
        elif any(w in norm.lower() for w in ["возврат", "vozvrat", "refund", "qaytarildi", "reversal", "otmena"]):
            direction = TransactionDirection.REFUND

        card_match = re.search(r"(?:karta|card|\*)\s*\*+(\d{4})", norm, re.IGNORECASE)
        card_last4 = card_match.group(1) if card_match else None

        merchant = "Unknown Merchant"
        # Try generic phrase after in/at/v
        m_match = re.search(r"(?:v|at|mesto:|в)\s+([A-Za-z0-9а-яА-ЯёЁ\s\-]+?)(?:\.|\,|$)", norm, re.IGNORECASE)
        if m_match:
            merchant = m_match.group(1).strip()

        # Calculate confidence
        confidence = 0.0
        if amount > 0:
            confidence += 0.35
        if currency in ["UZS", "USD", "EUR", "RUB"]:
            confidence += 0.15
        if direction != TransactionDirection.UNKNOWN:
            confidence += 0.20
        if card_last4:
            confidence += 0.15
        if merchant != "Unknown Merchant":
            confidence += 0.15

        status = TransactionStatus.CONFIRMED if confidence >= 0.85 else (
            TransactionStatus.NEEDS_REVIEW if confidence >= 0.60 else TransactionStatus.IGNORED
        )

        dup_hash = calculate_duplicate_hash(user_id, amount, currency, card_last4, merchant, dt)

        return ParsedTransaction(
            amount=amount,
            currency=currency,
            direction=direction,
            merchant=merchant,
            card_first4=None,
            card_last4=card_last4,
            bank_name="Generic",
            occurred_at=dt,
            balance_after=None,
            confidence_score=round(confidence, 2),
            duplicate_hash=dup_hash,
            status=status,
            raw_text=text,
            parsed_fields={"parser": self.name}
        )


class TransactionParserEngine:
    def __init__(self):
        self.parsers: List[BaseBankParser] = [
            CyrillicBankNotificationParser(),
            ClickNotificationParser(),
            PaymeNotificationParser(),
            UzumBankParser(),
            UzcardHumoGatewayParser(),
            UniversalInternationalParser(),
            RegexFallbackParser(),
        ]

    def process_notification(
        self,
        raw_text: str,
        user_id: str,
        timestamp: Optional[datetime] = None,
        existing_hashes: Optional[set] = None,
        recent_transactions: Optional[List[Dict[str, Any]]] = None,
    ) -> Optional[ParsedTransaction]:
        """
        Orchestrates template matching, deduplication, refund correlation, and transfer linking.
        """
        parsed: Optional[ParsedTransaction] = None

        for p in self.parsers:
            if p.match(raw_text):
                res = p.parse(raw_text, user_id=user_id, timestamp=timestamp)
                if res is not None:
                    parsed = res
                    break

        if not parsed:
            return None

        # 1. Deduplication Detection
        if existing_hashes and parsed.duplicate_hash in existing_hashes:
            parsed.status = TransactionStatus.DUPLICATE_CANDIDATE

        # 2. Refund Correlation
        if parsed.direction == TransactionDirection.REFUND and recent_transactions:
            for past_tx in recent_transactions:
                # Match against past expense with same merchant or exact amount within 30 days
                if past_tx.get("direction") == "expense" and past_tx.get("merchant", "").lower() in parsed.merchant.lower():
                    parsed.related_transaction_id = str(past_tx.get("id"))
                    break

        # 3. Internal Transfer Detection
        if parsed.direction in [TransactionDirection.TRANSFER, TransactionDirection.EXPENSE] and recent_transactions:
            for past_tx in recent_transactions:
                # Same user, opposing direction, identical amount within 3 minutes
                past_dt = past_tx.get("occurred_at")
                if isinstance(past_dt, str):
                    try:
                        past_dt = datetime.fromisoformat(past_dt.replace("Z", "+00:00"))
                    except Exception:
                        past_dt = parsed.occurred_at
                elif not isinstance(past_dt, datetime):
                    past_dt = parsed.occurred_at

                t_diff = abs((parsed.occurred_at - past_dt).total_seconds())
                if t_diff <= 180 and past_tx.get("amount") == parsed.amount:
                    if (parsed.direction == TransactionDirection.EXPENSE and past_tx.get("direction") == "income") or \
                       (parsed.direction == TransactionDirection.TRANSFER and past_tx.get("direction") == "income"):
                        parsed.direction = TransactionDirection.TRANSFER
                        parsed.related_transaction_id = str(past_tx.get("id"))
                        break

        return parsed
