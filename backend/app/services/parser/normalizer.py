import re
from typing import Dict, Any, Tuple


class NotificationNormalizer:
    """
    Notification Normalizer Layer.
    Pre-processes raw incoming notification text:
    - Strips zero-width and invisible unicode characters
    - Unifies currency symbols and denominations (UZS, USD, EUR, RUB)
    - Normalizes regional apostrophes and formatting
    - Redacts sensitive credentials (OTP codes, PINs, CVV patterns)
    """

    # Currency normalization maps
    CURRENCY_REPLACEMENTS = [
        (re.compile(r"\b(so['`\u02bc\u02bb]m|so\x27m|som|сум|сумов|сўм)\b", re.IGNORECASE), "UZS"),
        (re.compile(r"([\$])\s*(\d[\d,.]*)", re.IGNORECASE), r"\2 USD"),
        (re.compile(r"([€])\s*(\d[\d,.]*)", re.IGNORECASE), r"\2 EUR"),
        (re.compile(r"([£])\s*(\d[\d,.]*)", re.IGNORECASE), r"\2 GBP"),
        (re.compile(r"([₽])\s*(\d[\d,.]*)", re.IGNORECASE), r"\2 RUB"),
        (re.compile(r"\b(доллар[а-я]*|dollar[s]?)\b", re.IGNORECASE), "USD"),
        (re.compile(r"\b(евро|euro[s]?)\b", re.IGNORECASE), "EUR"),
        (re.compile(r"\b(руб(?:л[ейя])?|rub)\b", re.IGNORECASE), "RUB"),
    ]

    # Sensitive patterns to redact immediately
    SENSITIVE_PATTERNS = [
        re.compile(r"(?:kod|код|code|parol|пароль|otp)\s*(?::|=|\s)\s*(\d{4,8})", re.IGNORECASE),
        re.compile(r"(?:cvv|cvc|pin|пин)\s*(?::|=|\s)\s*(\d{3,4})", re.IGNORECASE),
    ]

    @classmethod
    def clean_text(cls, raw: str) -> str:
        if not raw:
            return ""
        # Remove zero-width & invisible spaces
        text = re.sub(r"[\u200B-\u200D\uFEFF\u00A0]", " ", raw)
        # Normalize non-standard apostrophes used in Uzbek Latin
        text = re.sub(r"[`’‘ʻʼ]", "'", text)
        # Collapse multi-spaces and strip edges
        text = re.sub(r"[ \t]+", " ", text).strip()
        return text

    @classmethod
    def normalize(cls, raw: str) -> Tuple[str, Dict[str, Any]]:
        cleaned = cls.clean_text(raw)
        metadata: Dict[str, Any] = {"pii_redacted": False}

        # Check and redact sensitive OTP / PIN
        redacted = cleaned
        for pat in cls.SENSITIVE_PATTERNS:
            if pat.search(redacted):
                redacted = pat.sub(r"[CONFIDENTIAL]", redacted)
                metadata["pii_redacted"] = True

        # Unify currency tokens
        normalized_text = redacted
        for pattern, replacement in cls.CURRENCY_REPLACEMENTS:
            normalized_text = pattern.sub(replacement, normalized_text)

        return normalized_text, metadata
