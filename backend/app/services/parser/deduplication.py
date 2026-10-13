import hashlib
import re
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any, Tuple
from dataclasses import dataclass


@dataclass
class DeduplicationResult:
    is_duplicate: bool
    duplicate_hash: str
    existing_tx_id: Optional[str] = None
    reason: Optional[str] = None


class DeduplicationEngine:
    """
    Advanced Deduplication and Correlation Engine:
    - 5-minute epoch bucket hashing for multi-source Push + SMS matching
    - Internal transfer correlation (Card A -> Card B zero net-worth shift)
    - Refund correlation (links reversal to past purchase within 30 days)
    """

    def __init__(self, time_window_seconds: int = 300):
        self.time_window_seconds = time_window_seconds
        # hash -> { "tx_id": str, "occurred_at": datetime, "amount": float, "merchant": str }
        self._seen_hashes: Dict[str, Dict[str, Any]] = {}

    def generate_hash(
        self,
        user_id: str,
        amount: float,
        currency: str,
        card_last4: Optional[str],
        merchant: str,
        dt: datetime,
        direction: str
    ) -> str:
        epoch_bucket = int(dt.timestamp() // self.time_window_seconds)
        norm_merchant = re.sub(r"[^a-zA-Z0-9а-яА-ЯёЁ]", "", (merchant or "").lower())
        # To bridge Push and SMS, group expense/purchase under common direction
        norm_direction = "outflow" if direction in ["expense", "purchase", "cash_withdrawal"] else (
            "inflow" if direction in ["income", "salary", "refund"] else direction
        )
        payload = f"{user_id}:{amount:.2f}:{currency}:{(card_last4 or 'any')}:{norm_merchant}:{norm_direction}:{epoch_bucket}"
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def check_and_register(
        self,
        user_id: str,
        amount: float,
        currency: str,
        card_last4: Optional[str],
        merchant: str,
        dt: datetime,
        direction: str,
        tx_id: str
    ) -> DeduplicationResult:
        dup_hash = self.generate_hash(user_id, amount, currency, card_last4, merchant, dt, direction)

        if dup_hash in self._seen_hashes:
            existing = self._seen_hashes[dup_hash]
            return DeduplicationResult(
                is_duplicate=True,
                duplicate_hash=dup_hash,
                existing_tx_id=existing.get("tx_id"),
                reason="Обнаружен дубликат уведомления (Push + SMS) в пределах 5-минутного интервала"
            )

        # Also check without card_last4 in case one notification had card masked as 'none'
        if card_last4:
            relaxed_hash = self.generate_hash(user_id, amount, currency, None, merchant, dt, direction)
            if relaxed_hash in self._seen_hashes:
                existing = self._seen_hashes[relaxed_hash]
                return DeduplicationResult(
                    is_duplicate=True,
                    duplicate_hash=relaxed_hash,
                    existing_tx_id=existing.get("tx_id"),
                    reason="Обнаружен дубликат транзакции с совпадающей суммой и мерчантом без указания карты"
                )

        # Register hash
        self._seen_hashes[dup_hash] = {
            "tx_id": tx_id,
            "occurred_at": dt,
            "amount": amount,
            "merchant": merchant
        }
        return DeduplicationResult(
            is_duplicate=False,
            duplicate_hash=dup_hash
        )

    def correlate_internal_transfer(
        self,
        new_tx: Dict[str, Any],
        recent_transactions: List[Dict[str, Any]],
        max_time_diff_seconds: int = 180
    ) -> Optional[str]:
        """
        Detects if an incoming transaction is an internal transfer between user's own cards:
        Card A (-500 000) and Card B (+500 000) occurring within 3 minutes.
        Returns matching transaction ID if correlated.
        """
        amount = new_tx.get("amount", 0.0)
        direction = new_tx.get("direction", "")
        occurred_at = new_tx.get("occurred_at")
        if isinstance(occurred_at, str):
            occurred_at = datetime.fromisoformat(occurred_at.replace("Z", "+00:00"))

        for past_tx in recent_transactions:
            if past_tx.get("id") == new_tx.get("id"):
                continue

            past_dt = past_tx.get("occurred_at")
            if isinstance(past_dt, str):
                past_dt = datetime.fromisoformat(past_dt.replace("Z", "+00:00"))

            time_diff = abs((occurred_at - past_dt).total_seconds()) if (occurred_at and past_dt) else 9999

            if time_diff <= max_time_diff_seconds and past_tx.get("amount") == amount:
                past_dir = past_tx.get("direction", "")
                # Opposing directions for internal transfer
                is_opposing = (
                    (direction in ["expense", "transfer"] and past_dir in ["income", "transfer"]) or
                    (direction in ["income", "transfer"] and past_dir in ["expense", "transfer"])
                )
                if is_opposing:
                    return past_tx.get("id")

        return None

    def correlate_refund(
        self,
        refund_amount: float,
        merchant: str,
        occurred_at: datetime,
        recent_transactions: List[Dict[str, Any]],
        max_days: int = 30
    ) -> Optional[str]:
        """
        Finds original expense transaction within the last 30 days matching the refund.
        """
        norm_merchant = re.sub(r"[^a-zA-Z0-9а-яА-ЯёЁ]", "", (merchant or "").lower())

        for past_tx in recent_transactions:
            if past_tx.get("direction") != "expense":
                continue

            past_dt = past_tx.get("occurred_at")
            if isinstance(past_dt, str):
                past_dt = datetime.fromisoformat(past_dt.replace("Z", "+00:00"))

            days_diff = (occurred_at - past_dt).total_seconds() / 86400 if (occurred_at and past_dt) else 999
            if 0 <= days_diff <= max_days:
                past_m = re.sub(r"[^a-zA-Z0-9а-яА-ЯёЁ]", "", (past_tx.get("merchant") or "").lower())
                # Exact or partial merchant match and amount matches (full or partial refund)
                if (norm_merchant in past_m or past_m in norm_merchant) and past_tx.get("amount", 0.0) >= refund_amount:
                    return past_tx.get("id")

        return None
