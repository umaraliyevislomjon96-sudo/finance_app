from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Optional, Dict, Any, List
import re
import hashlib


class TransactionDirection(str, Enum):
    INCOME = "income"
    EXPENSE = "expense"
    TRANSFER = "transfer"
    REFUND = "refund"
    UNKNOWN = "unknown"


class TransactionStatus(str, Enum):
    CONFIRMED = "confirmed"
    NEEDS_REVIEW = "needs_review"
    DUPLICATE_CANDIDATE = "duplicate_candidate"
    IGNORED = "ignored"


@dataclass
class ParsedTransaction:
    amount: float
    currency: str
    direction: TransactionDirection
    merchant: str
    card_first4: Optional[str]
    card_last4: Optional[str]
    bank_name: Optional[str]
    occurred_at: datetime
    balance_after: Optional[float]
    confidence_score: float
    duplicate_hash: str
    status: TransactionStatus
    raw_text: str
    parsed_fields: Dict[str, Any] = field(default_factory=dict)
    related_transaction_id: Optional[str] = None


class BaseBankParser:
    name: str = "base"

    def match(self, text: str) -> bool:
        raise NotImplementedError

    def parse(self, text: str, user_id: str, timestamp: Optional[datetime] = None) -> Optional[ParsedTransaction]:
        raise NotImplementedError


def clean_amount(val_str: str) -> float:
    # Handles: "45 000,50", "45,000.50", "45000", "45 000"
    cleaned = val_str.replace(" ", "").replace("\xa0", "").strip()
    if "," in cleaned and "." in cleaned:
        cleaned = cleaned.replace(",", "")
    elif "," in cleaned and "." not in cleaned:
        cleaned = cleaned.replace(",", ".")
    return float(cleaned)


def calculate_duplicate_hash(
    user_id: str,
    amount: float,
    currency: str,
    card_last4: Optional[str],
    merchant: str,
    dt: datetime
) -> str:
    # 5-minute time window rounding to prevent duplicate SMS + Push events
    epoch_mins = int(dt.timestamp() // 300)
    norm_merchant = re.sub(r"[^a-zA-Z0-9а-яА-ЯёЁ]", "", merchant.lower())
    payload = f"{user_id}:{amount:.2f}:{currency}:{(card_last4 or 'none')}:{norm_merchant}:{epoch_mins}"
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()
