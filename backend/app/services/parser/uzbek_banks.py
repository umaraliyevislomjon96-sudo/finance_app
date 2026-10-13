import re
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from .base import (
    BaseBankParser,
    ParsedTransaction,
    TransactionDirection,
    TransactionStatus,
    clean_amount,
    calculate_duplicate_hash,
)


class ClickNotificationParser(BaseBankParser):
    name = "Click"

    # Example 1: Oplata CLICK: 45 000 UZS, Karta *4821, Mesto: Korzinka. Balans: 1 200 000 UZS
    # Example 2: Perevod CLICK: 150 000 UZS s karty *4821. Balans: 950 000 UZS
    # Example 3: CLICK: Zachislenie 2 000 000 UZS na kartu *4821. Otpravitel: CLICK
    def match(self, text: str) -> bool:
        return "CLICK" in text.upper()

    def parse(self, text: str, user_id: str, timestamp: Optional[datetime] = None) -> Optional[ParsedTransaction]:
        dt = timestamp or datetime.now(timezone.utc)
        norm = text.strip()

        # Direction
        direction = TransactionDirection.EXPENSE
        if any(w in norm.lower() for w in ["zachislenie", "пополнение", "tushum", "kirim"]):
            direction = TransactionDirection.INCOME
        elif any(w in norm.lower() for w in ["perevod", "o'tkazma", "перевод"]):
            direction = TransactionDirection.TRANSFER
        elif any(w in norm.lower() for w in ["vozvrat", "qaytarildi", "возврат", "reversal"]):
            direction = TransactionDirection.REFUND

        # Amount & Currency
        amount_match = re.search(r"(\d[\d\s,.]*)\s*(UZS|USD|EUR|сум|so'm)", norm, re.IGNORECASE)
        if not amount_match:
            return None
        amount = clean_amount(amount_match.group(1))
        currency = "UZS" if amount_match.group(2).upper() in ["UZS", "СУМ", "SO'M"] else amount_match.group(2).upper()

        # Card Last4
        card_match = re.search(r"karta\s*(?:\:|\s)*\*+(\d{4})", norm, re.IGNORECASE)
        card_last4 = card_match.group(1) if card_match else None

        # Merchant
        merchant = "Click Payment"
        mesto_match = re.search(r"Mesto:\s*([^.]+)", norm, re.IGNORECASE)
        if mesto_match:
            merchant = mesto_match.group(1).strip()
        elif direction == TransactionDirection.TRANSFER:
            merchant = "Click Transfer"
        elif direction == TransactionDirection.INCOME:
            merchant = "Click Inbound Transfer"

        # Balance after
        balance_match = re.search(r"Balans:\s*([\d\s,.]+)\s*(?:UZS|сум|so'm)", norm, re.IGNORECASE)
        balance_after = clean_amount(balance_match.group(1)) if balance_match else None

        dup_hash = calculate_duplicate_hash(user_id, amount, currency, card_last4, merchant, dt)

        return ParsedTransaction(
            amount=amount,
            currency=currency,
            direction=direction,
            merchant=merchant,
            card_first4=None,
            card_last4=card_last4,
            bank_name="Click",
            occurred_at=dt,
            balance_after=balance_after,
            confidence_score=0.96,
            duplicate_hash=dup_hash,
            status=TransactionStatus.CONFIRMED,
            raw_text=text,
            parsed_fields={"parser": self.name}
        )


class PaymeNotificationParser(BaseBankParser):
    name = "Payme"

    # Example: Oplata uspeshna. Karta: 8600****4821. Summa: 120 000 UZS. Mesto: Makro Supermarket. Dostupno: 500 000 UZS
    # Example: Perevod: 250 000 UZS na kartu *1122. Komissiya: 0. Karta: 8600****4821.
    def match(self, text: str) -> bool:
        return "PAYME" in text.upper() or ("OPLATA USPESHNA" in text.upper() and "KARTA:" in text.upper())

    def parse(self, text: str, user_id: str, timestamp: Optional[datetime] = None) -> Optional[ParsedTransaction]:
        dt = timestamp or datetime.now(timezone.utc)
        norm = text.strip()

        direction = TransactionDirection.EXPENSE
        if any(w in norm.lower() for w in ["perevod", "o'tkazma", "перевод"]):
            direction = TransactionDirection.TRANSFER
        elif any(w in norm.lower() for w in ["popolnenie", "zachislenie", "kirim"]):
            direction = TransactionDirection.INCOME
        elif any(w in norm.lower() for w in ["vozvrat", "qaytarildi", "reversal"]):
            direction = TransactionDirection.REFUND

        amount_match = re.search(r"(?:Summa|сумма|\:)\s*(\d[\d\s,.]*)\s*(UZS|сум|so'm)", norm, re.IGNORECASE)
        if not amount_match:
            amount_match = re.search(r"(\d[\d\s,.]*)\s*(UZS|сум|so'm)", norm, re.IGNORECASE)
            if not amount_match:
                return None
        amount = clean_amount(amount_match.group(1))
        currency = "UZS"

        # Card First4 / Last4
        card_match = re.search(r"(\d{4})\*{2,8}(\d{4})", norm)
        card_first4 = card_match.group(1) if card_match else None
        card_last4 = card_match.group(2) if card_match else None

        # Merchant
        mesto_match = re.search(r"Mesto:\s*([^.]+)", norm, re.IGNORECASE)
        merchant = mesto_match.group(1).strip() if mesto_match else ("Payme Transfer" if direction == TransactionDirection.TRANSFER else "Payme Service")

        bal_match = re.search(r"Dostupno:\s*([\d\s,.]+)", norm, re.IGNORECASE)
        balance_after = clean_amount(bal_match.group(1)) if bal_match else None

        dup_hash = calculate_duplicate_hash(user_id, amount, currency, card_last4, merchant, dt)

        return ParsedTransaction(
            amount=amount,
            currency=currency,
            direction=direction,
            merchant=merchant,
            card_first4=card_first4,
            card_last4=card_last4,
            bank_name="Payme",
            occurred_at=dt,
            balance_after=balance_after,
            confidence_score=0.97,
            duplicate_hash=dup_hash,
            status=TransactionStatus.CONFIRMED,
            raw_text=text,
            parsed_fields={"parser": self.name}
        )


class UzumBankParser(BaseBankParser):
    name = "Uzum Bank"

    # Example: Spisanie: 35 000 UZS s karty 8600..4821 v Yandex Go. Ostatok: 850 000 UZS
    # Example: Uzum Bank: Zachislenie zarplaty 8 500 000 UZS na kartu *4821. Dostupno: 9 350 000 UZS
    def match(self, text: str) -> bool:
        return "UZUM" in text.upper() or "APELSIN" in text.upper() or "S KARTY 8600" in text.upper()

    def parse(self, text: str, user_id: str, timestamp: Optional[datetime] = None) -> Optional[ParsedTransaction]:
        dt = timestamp or datetime.now(timezone.utc)
        norm = text.strip()

        direction = TransactionDirection.EXPENSE
        if any(w in norm.lower() for w in ["zachislenie", "popolnenie", "tushum"]):
            direction = TransactionDirection.INCOME
        elif any(w in norm.lower() for w in ["perevod", "o'tkazma"]):
            direction = TransactionDirection.TRANSFER
        elif any(w in norm.lower() for w in ["vozvrat", "qaytarildi"]):
            direction = TransactionDirection.REFUND

        amt_match = re.search(r"(\d[\d\s,.]*)\s*(UZS|USD|сум)", norm, re.IGNORECASE)
        if not amt_match:
            return None
        amount = clean_amount(amt_match.group(1))
        currency = "UZS" if amt_match.group(2).upper() in ["UZS", "СУМ"] else amt_match.group(2).upper()

        card_match = re.search(r"(\d{4})[\.\*]{2,8}(\d{4})", norm)
        card_first4 = card_match.group(1) if card_match else None
        card_last4 = card_match.group(2) if card_match else None

        merchant = "Uzum Bank"
        v_match = re.search(r"\sv\s+([^.]+?)(?:\.|\s+Ostatok)", norm, re.IGNORECASE)
        if v_match:
            merchant = v_match.group(1).strip()

        bal_match = re.search(r"(?:Ostatok|Dostupno):\s*([\d\s,.]+)", norm, re.IGNORECASE)
        balance_after = clean_amount(bal_match.group(1)) if bal_match else None

        dup_hash = calculate_duplicate_hash(user_id, amount, currency, card_last4, merchant, dt)

        return ParsedTransaction(
            amount=amount,
            currency=currency,
            direction=direction,
            merchant=merchant,
            card_first4=card_first4,
            card_last4=card_last4,
            bank_name="Uzum Bank",
            occurred_at=dt,
            balance_after=balance_after,
            confidence_score=0.95,
            duplicate_hash=dup_hash,
            status=TransactionStatus.CONFIRMED,
            raw_text=text,
            parsed_fields={"parser": self.name}
        )


class UzcardHumoGatewayParser(BaseBankParser):
    name = "UzcardHumoGateway"

    # Gateway SMS 7557 / 0808
    # Example 1: Karta 8600********4821: Spisanie 50000.00 UZS. Terminal: EVOS. Dostupno: 340000.00 UZS
    # Example 2: Karta 9860********1122: Zachislenie 1200000 UZS. Dostupno: 2500000 UZS
    # Example 3: 8600********4821: Otmena pokupki 45000 UZS. Korzinka. Dostupno: 385000 UZS
    def match(self, text: str) -> bool:
        return bool(re.search(r"(?:8600|9860|5614|6262)\*+", text)) or "TERMINAL:" in text.upper()

    def parse(self, text: str, user_id: str, timestamp: Optional[datetime] = None) -> Optional[ParsedTransaction]:
        dt = timestamp or datetime.now(timezone.utc)
        norm = text.strip()

        direction = TransactionDirection.EXPENSE
        if any(w in norm.lower() for w in ["zachislenie", "popolnenie", "postuplenie"]):
            direction = TransactionDirection.INCOME
        elif any(w in norm.lower() for w in ["otmena", "vozvrat", "reversal"]):
            direction = TransactionDirection.REFUND
        elif any(w in norm.lower() for w in ["perevod", "o'tkazma"]):
            direction = TransactionDirection.TRANSFER

        amt_match = re.search(r"(\d[\d\s,.]*)\s*(UZS|USD)", norm, re.IGNORECASE)
        if not amt_match:
            return None
        amount = clean_amount(amt_match.group(1))
        currency = amt_match.group(2).upper()

        card_match = re.search(r"(\d{4})\*+(\d{4})", norm)
        card_first4 = card_match.group(1) if card_match else None
        card_last4 = card_match.group(2) if card_match else None

        merchant = "Retail Merchant"
        terminal_match = re.search(r"Terminal:\s*([^.]+)", norm, re.IGNORECASE)
        if terminal_match:
            merchant = terminal_match.group(1).strip()
        else:
            # Check trailing name
            name_match = re.search(r"UZS\.\s*([^.]+?)\.\s*Dostupno", norm, re.IGNORECASE)
            if name_match:
                merchant = name_match.group(1).strip()

        bal_match = re.search(r"Dostupno:\s*([\d\s,.]+)", norm, re.IGNORECASE)
        balance_after = clean_amount(bal_match.group(1)) if bal_match else None

        dup_hash = calculate_duplicate_hash(user_id, amount, currency, card_last4, merchant, dt)

        return ParsedTransaction(
            amount=amount,
            currency=currency,
            direction=direction,
            merchant=merchant,
            card_first4=card_first4,
            card_last4=card_last4,
            bank_name="Uzcard/Humo",
            occurred_at=dt,
            balance_after=balance_after,
            confidence_score=0.98,
            duplicate_hash=dup_hash,
            status=TransactionStatus.CONFIRMED,
            raw_text=text,
            parsed_fields={"parser": self.name}
        )


class CyrillicBankNotificationParser(BaseBankParser):
    name = "CyrillicBank"

    # Common Cyrillic & Russian patterns from Uzbek / CIS banking apps:
    # Example 1: "Оплата картой 180 000 UZS в EVOS"
    # Example 2: "Зачисление зарплаты 8 000 000 UZS на карту *4821"
    # Example 3: "Поступление 2 000 000 UZS"
    # Example 4: "Возврат 250 000 UZS в Korzinka"
    # Example 5: "Снятие наличных 500 000 UZS в банкомате Kapitalbank"
    # Example 6: "Погашение кредита 1 200 000 UZS"
    # Example 7: "Оплата кредитной карты 450 000 UZS"
    # Example 8: "Перевод 300 000 UZS на карту *1122"
    # Example 9: "Комиссия за перевод 5 000 UZS"
    CYRILLIC_KEYWORDS = [
        "оплата", "списание", "покупка", "зачисление", "поступление",
        "пополнение", "перевод", "возврат", "снятие наличных", "зарплат",
        "погашение кредита", "кредитной карты", "комиссия"
    ]

    def match(self, text: str) -> bool:
        t_low = text.lower()
        return any(k in t_low for k in self.CYRILLIC_KEYWORDS)

    def parse(self, text: str, user_id: str, timestamp: Optional[datetime] = None) -> Optional[ParsedTransaction]:
        dt = timestamp or datetime.now(timezone.utc)
        norm = text.strip()
        norm_low = norm.lower()

        # 1. Determine direction & specific operation type
        direction = TransactionDirection.EXPENSE
        specific_type = "purchase"

        if "зарплат" in norm_low:
            direction = TransactionDirection.INCOME
            specific_type = "salary_income"
        elif any(w in norm_low for w in ["возврат", "отмена покупки"]):
            direction = TransactionDirection.REFUND
            specific_type = "refund"
        elif "снятие наличных" in norm_low:
            direction = TransactionDirection.EXPENSE
            specific_type = "cash_withdrawal"
        elif "погашение кредита" in norm_low:
            direction = TransactionDirection.EXPENSE
            specific_type = "loan_payment"
        elif "кредитной карты" in norm_low:
            direction = TransactionDirection.EXPENSE
            specific_type = "credit_card_payment"
        elif any(w in norm_low for w in ["поступление", "зачисление", "пополнение"]):
            direction = TransactionDirection.INCOME
            specific_type = "incoming_transfer"
        elif "перевод" in norm_low:
            direction = TransactionDirection.TRANSFER
            specific_type = "transfer"
        elif "комиссия" in norm_low:
            direction = TransactionDirection.EXPENSE
            specific_type = "fee_commission"

        # 2. Extract Amount and Currency
        amt_match = re.search(r"(\d[\d\s,.]*)\s*(UZS|USD|EUR|RUB|сум|руб|\$|€)", norm, re.IGNORECASE)
        if not amt_match:
            # Check for currency symbol first
            sym_match = re.search(r"([$€₽])\s*(\d[\d,.]*)", norm)
            if sym_match:
                sym_map = {"$": "USD", "€": "EUR", "₽": "RUB"}
                amount = clean_amount(sym_match.group(2))
                currency = sym_map.get(sym_match.group(1), "USD")
            else:
                return None
        else:
            amount = clean_amount(amt_match.group(1))
            raw_curr = amt_match.group(2).upper()
            curr_map = {"СУМ": "UZS", "РУБ": "RUB", "$": "USD", "€": "EUR"}
            currency = curr_map.get(raw_curr, raw_curr)

        # 3. Card identifier
        card_match = re.search(r"(?:картой|карту|карты|карта|\*|karta)\s*(?::|\s)*\*+(\d{4})", norm, re.IGNORECASE)
        if not card_match:
            card_match = re.search(r"(\d{4})\*+(\d{4})", norm)
            card_last4 = card_match.group(2) if card_match else None
            card_first4 = card_match.group(1) if card_match else None
        else:
            card_last4 = card_match.group(1)
            card_first4 = None

        # 4. Merchant extraction
        merchant = "Банковская операция"
        if specific_type == "salary_income":
            merchant = "Работодатель (Зарплата)"
        elif specific_type == "loan_payment":
            merchant = "Погашение кредита"
        elif specific_type == "credit_card_payment":
            merchant = "Кредитная карта"
        elif specific_type == "cash_withdrawal":
            # Extract ATM location if specified
            atm_match = re.search(r"в\s+(?:банкомате\s+)?([A-Za-z0-9а-яА-ЯёЁ\s\-]+?)(?:\.|\,|$)", norm, re.IGNORECASE)
            merchant = f"Банкомат {atm_match.group(1).strip()}" if atm_match else "Банкомат (Снятие)"
        elif specific_type == "fee_commission":
            merchant = "Банковская комиссия"
        elif specific_type == "transfer":
            to_match = re.search(r"на\s+(?:карту\s+)?\*?(\d{4})", norm, re.IGNORECASE)
            merchant = f"Перевод на карту *{to_match.group(1)}" if to_match else "Банковский перевод"
        elif specific_type == "incoming_transfer":
            from_match = re.search(r"от\s+([A-Za-z0-9а-яА-ЯёЁ\s\-]+?)(?:\.|\,|$)", norm, re.IGNORECASE)
            merchant = f"Перевод от {from_match.group(1).strip()}" if from_match else "Входящий перевод"
        else:
            # Look for "в <Мерчант>" e.g. "в EVOS", "в Korzinka"
            v_match = re.search(r"\bв\s+([A-Za-z0-9а-яА-ЯёЁ\s\.\'\-]+?)(?:\.|\,|$|\s+с\s+карты|\s+картой|\s+на\s+карту|\s+на\s+счет|\s+карта|\s+karta)", norm, re.IGNORECASE)
            if v_match:
                merchant = v_match.group(1).strip()
            else:
                m_match = re.search(r"(?:Mesto:|Терминал:)\s*([^.]+)", norm, re.IGNORECASE)
                if m_match:
                    merchant = m_match.group(1).strip()
                else:
                    merchant = "Торговая точка"

        # 5. Balance after
        bal_match = re.search(r"(?:Остаток|Баланс|Доступно):\s*([\d\s,.]+)", norm, re.IGNORECASE)
        balance_after = clean_amount(bal_match.group(1)) if bal_match else None

        confidence = 0.98 if (amount > 0 and merchant not in ["Банковская операция", "Торговая точка"]) else 0.92
        dup_hash = calculate_duplicate_hash(user_id, amount, currency, card_last4, merchant, dt)

        return ParsedTransaction(
            amount=amount,
            currency=currency,
            direction=direction,
            merchant=merchant,
            card_first4=card_first4,
            card_last4=card_last4,
            bank_name="Banking Gateway",
            occurred_at=dt,
            balance_after=balance_after,
            confidence_score=confidence,
            duplicate_hash=dup_hash,
            status=TransactionStatus.CONFIRMED,
            raw_text=text,
            parsed_fields={
                "parser": self.name,
                "specific_type": specific_type
            }
        )

