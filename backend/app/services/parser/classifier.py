import re
from typing import Optional, Dict, Any, Tuple
from .detector import FinancialTransactionType


class TransactionClassifier:
    """
    Transaction Categorization & Merchant Intelligence Engine.
    Maps extracted merchants, financial operation types, and transaction context
    into 18 standard categories with dynamic user correction learning.
    """

    CATEGORIES = [
        "Food",
        "Groceries",
        "Transport",
        "Shopping",
        "Entertainment",
        "Subscriptions",
        "Health",
        "Education",
        "Housing",
        "Utilities",
        "Travel",
        "Salary",
        "Transfer",
        "Loan",
        "Credit Card",
        "Cash Withdrawal",
        "Fees",
        "Other"
    ]

    # Curated merchant catalog mapped to default category
    MERCHANT_CATALOG = {
        # Groceries
        "korzinka": "Groceries",
        "korzinka supermarket": "Groceries",
        "makro": "Groceries",
        "makro supermarket": "Groceries",
        "havas": "Groceries",
        "carrefour": "Groceries",
        "baraka market": "Groceries",
        "magnum": "Groceries",
        "green apple": "Groceries",
        "tc kopeyka": "Groceries",

        # Food & Dining
        "evos": "Food",
        "wendy's": "Food",
        "kfc": "Food",
        "mcdonald's": "Food",
        "oqtepa lavash": "Food",
        "black star burger": "Food",
        "rayhon": "Food",
        "bon!": "Food",
        "paul": "Food",
        "costa coffee": "Food",
        "starbucks": "Food",
        "bellissimo": "Food",
        "bellissimo pizza": "Food",
        "dodo pizza": "Food",
        "chopar": "Food",
        "feed up": "Food",
        "safia": "Food",
        "safia bakery": "Food",
        "les ailes": "Food",

        # Transport & Fuel
        "yandex go": "Transport",
        "yandex taxi": "Transport",
        "mytaxi": "Transport",
        "express 24": "Transport",
        "uklon": "Transport",
        "toshkent metropoliteni": "Transport",
        "metro": "Transport",
        "lukoil": "Transport",
        "uzbekneftegaz": "Transport",
        "ung": "Transport",
        "gaznafta": "Transport",
        "uber": "Transport",

        # Subscriptions
        "netflix": "Subscriptions",
        "spotify": "Subscriptions",
        "youtube": "Subscriptions",
        "youtube premium": "Subscriptions",
        "apple services": "Subscriptions",
        "apple.com/bill": "Subscriptions",
        "yandex plus": "Subscriptions",
        "telegram premium": "Subscriptions",
        "chatgpt": "Subscriptions",
        "openai": "Subscriptions",
        "icloud": "Subscriptions",
        "playstation network": "Subscriptions",

        # Utilities
        "paynet": "Utilities",
        "toshissiqquvvati": "Utilities",
        "hududgaz": "Utilities",
        "uzsuvtaminot": "Utilities",
        "res elektr": "Utilities",
        "kommunal": "Utilities",

        # Health & Pharmacy
        "oson apteka": "Health",
        "grand pharm": "Health",
        "best pharm": "Health",
        "999 apteka": "Health",
        "shox med": "Health",
        "medion": "Health",
        "akfa medline": "Health",
        "doctor d": "Health",
        "hayat": "Health",

        # Shopping
        "uzum market": "Shopping",
        "zoodmall": "Shopping",
        "mediapark": "Shopping",
        "texnomart": "Shopping",
        "asaxiy": "Shopping",
        "zara": "Shopping",
        "inditex": "Shopping",
        "lc waikiki": "Shopping",
        "mango": "Shopping",
        "amazon": "Shopping",
        "wildberries": "Shopping",

        # Entertainment
        "cinema palace": "Entertainment",
        "magic city": "Entertainment",
        "tashkent city mall": "Entertainment",
        "steam": "Entertainment",
        "kino.uz": "Entertainment",

        # Education
        "cambridge": "Education",
        "najot ta'lim": "Education",
        "pdp": "Education",
        "wiut": "Education",
        "mdist": "Education",
        "inha": "Education",

        # Travel
        "uzbekistan airways": "Travel",
        "centrum air": "Travel",
        "silk avia": "Travel",
        "turkish airlines": "Travel",
        "flydubai": "Travel",
        "booking.com": "Travel",
        "airbnb": "Travel",
        "aviasales": "Travel",
    }

    # Dynamic user correction storage: normalized_merchant -> category
    user_corrections: Dict[str, str] = {}

    @classmethod
    def record_correction(cls, merchant: str, category: str):
        """Saves user manual adjustment to improve future classification."""
        if category in cls.CATEGORIES:
            norm_key = re.sub(r"[^a-zA-Z0-9а-яА-ЯёЁ]", "", merchant.lower())
            if norm_key:
                cls.user_corrections[norm_key] = category

    @classmethod
    def classify(
        cls,
        merchant: str,
        financial_type: FinancialTransactionType,
        text: str = ""
    ) -> Tuple[str, float]:
        """
        Returns (category, confidence_score_for_category).
        """
        # Step 1: Specific operation types dictate category directly
        if financial_type == FinancialTransactionType.SALARY_INCOME:
            return "Salary", 0.99
        if financial_type == FinancialTransactionType.CASH_WITHDRAWAL:
            return "Cash Withdrawal", 0.98
        if financial_type == FinancialTransactionType.LOAN_PAYMENT:
            return "Loan", 0.98
        if financial_type == FinancialTransactionType.CREDIT_CARD_PAYMENT:
            return "Credit Card", 0.98
        if financial_type == FinancialTransactionType.FEE_COMMISSION:
            return "Fees", 0.97
        if financial_type in (FinancialTransactionType.TRANSFER, FinancialTransactionType.INTERNAL_TRANSFER):
            return "Transfer", 0.95

        # Step 2: Check user correction memory
        norm_key = re.sub(r"[^a-zA-Z0-9а-яА-ЯёЁ]", "", (merchant or "").lower())
        if norm_key in cls.user_corrections:
            return cls.user_corrections[norm_key], 0.99

        # Step 3: Match against merchant catalog
        merchant_lower = (merchant or "").lower().strip()
        for m_name, cat in cls.MERCHANT_CATALOG.items():
            if m_name in merchant_lower or merchant_lower in m_name:
                return cat, 0.95

        # Step 4: Scan notification text for keyword signals
        text_lower = text.lower()
        if any(w in text_lower for w in ["apteka", "аптека", "farmatsiya", "poliklinika"]):
            return "Health", 0.90
        if any(w in text_lower for w in ["kafe", "restoran", "кафе", "ресторан", "lavash", "fast food", "burger", "pizza"]):
            return "Food", 0.90
        if any(w in text_lower for w in ["supermarket", "supermarketi", "oziq-ovqat", "гастроном", "продукты"]):
            return "Groceries", 0.90
        if any(w in text_lower for w in ["zapravka", "azs", "бензин", "metan", "propan"]):
            return "Transport", 0.90
        if any(w in text_lower for w in ["kommunal", "gaz", "elektr", "issiq suv", "sovuq suv"]):
            return "Utilities", 0.90
        if any(w in text_lower for w in ["arenda", "kvartira", "ijara", "жильё"]):
            return "Housing", 0.90
        if any(w in text_lower for w in ["avia", "aviachipta", "mehmonxona", "hotel"]):
            return "Travel", 0.90

        # Step 5: Default fallback
        if financial_type == FinancialTransactionType.PURCHASE:
            return "Shopping", 0.70

        return "Other", 0.60
