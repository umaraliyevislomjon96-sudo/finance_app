import re
from datetime import datetime, timezone
from typing import Optional
from .base import (
    BaseBankParser,
    ParsedTransaction,
    TransactionDirection,
    TransactionStatus,
    clean_amount,
    calculate_duplicate_hash,
)


class UniversalInternationalParser(BaseBankParser):
    name = "UniversalInternational"

    # Example 1: Purchase: $45.20 at STARBUCKS with card ending 4821. Available: $1,250.00
    # Example 2: Apple Pay: You paid EUR 18.50 at Uber. Card *4821
    # Example 3: Revolut: Spent £14.99 at Netflix. Remaining balance: £420.50
    # Example 4: Refund of $120.00 from AMAZON to card ending 4821
    def match(self, text: str) -> bool:
        keywords = ["PURCHASE", "SPENT", "PAID", "CARD ENDING", "APPLE PAY", "REVOLUT", "REFUND"]
        return any(k in text.upper() for k in keywords)

    def parse(self, text: str, user_id: str, timestamp: Optional[datetime] = None) -> Optional[ParsedTransaction]:
        dt = timestamp or datetime.now(timezone.utc)
        norm = text.strip()

        direction = TransactionDirection.EXPENSE
        if any(w in norm.lower() for w in ["refund", "reversal", "cashback"]):
            direction = TransactionDirection.REFUND
        elif any(w in norm.lower() for w in ["received", "deposit", "salary", "inbound"]):
            direction = TransactionDirection.INCOME
        elif any(w in norm.lower() for w in ["transfer to", "sent to"]):
            direction = TransactionDirection.TRANSFER

        # Amount & Symbol
        curr_map = {"$": "USD", "€": "EUR", "£": "GBP", "₽": "RUB"}
        currency = "USD"
        amount = 0.0

        sym_match = re.search(r"([$€£₽])\s*(\d[\d,.]*)", norm)
        if sym_match:
            currency = curr_map.get(sym_match.group(1), "USD")
            amount = clean_amount(sym_match.group(2))
        else:
            code_before = re.search(r"\b(USD|EUR|GBP|RUB)\s*(\d[\d,.]*)", norm, re.IGNORECASE)
            if code_before:
                currency = code_before.group(1).upper()
                amount = clean_amount(code_before.group(2))
            else:
                code_after = re.search(r"(\d[\d,.]*)\s*(USD|EUR|GBP|RUB)\b", norm, re.IGNORECASE)
                if code_after:
                    amount = clean_amount(code_after.group(1))
                    currency = code_after.group(2).upper()
                else:
                    return None

        # Card Last4
        card_match = re.search(r"(?:ending|card|karta|\*+)\s*(?:\:|\s)*\*+(\d{4})", norm, re.IGNORECASE)
        if not card_match:
            card_match = re.search(r"ending\s+(\d{4})", norm, re.IGNORECASE)
        card_last4 = card_match.group(1) if card_match else None

        # Merchant
        merchant = "International Merchant"
        at_match = re.search(r"(?:at|v|from|u)\s+([A-Za-z0-9\s\.\-]+?)(?:\s+(?:with|on|card|using|\.|\;)|$)", norm, re.IGNORECASE)
        if at_match:
            merchant = at_match.group(1).strip()

        dup_hash = calculate_duplicate_hash(user_id, amount, currency, card_last4, merchant, dt)

        return ParsedTransaction(
            amount=amount,
            currency=currency,
            direction=direction,
            merchant=merchant,
            card_first4=None,
            card_last4=card_last4,
            bank_name="International",
            occurred_at=dt,
            balance_after=None,
            confidence_score=0.92,
            duplicate_hash=dup_hash,
            status=TransactionStatus.CONFIRMED,
            raw_text=text,
            parsed_fields={"parser": self.name}
        )
