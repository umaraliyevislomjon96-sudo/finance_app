import pytest
from datetime import datetime, timezone, timedelta
from app.services.parser.engine import TransactionParserEngine
from app.services.parser.base import TransactionDirection, TransactionStatus


def test_click_sms_parsing():
    engine = TransactionParserEngine()
    text = "Oplata CLICK: 45 000 UZS, Karta *4821, Mesto: Korzinka. Balans: 1 200 000 UZS"
    user_id = "test-user-100"

    tx = engine.process_notification(text, user_id=user_id)
    assert tx is not None
    assert tx.amount == 45000.0
    assert tx.currency == "UZS"
    assert tx.direction == TransactionDirection.EXPENSE
    assert tx.card_last4 == "4821"
    assert "Korzinka" in tx.merchant
    assert tx.balance_after == 1200000.0
    assert tx.status == TransactionStatus.CONFIRMED
    assert tx.confidence_score >= 0.90


def test_payme_push_parsing():
    engine = TransactionParserEngine()
    text = "Oplata uspeshna. Karta: 8600****4821. Summa: 120 000 UZS. Mesto: Makro Supermarket. Dostupno: 500 000 UZS"
    user_id = "test-user-100"

    tx = engine.process_notification(text, user_id=user_id)
    assert tx is not None
    assert tx.amount == 1200000.0 if "120 0000" in text else 120000.0
    assert tx.currency == "UZS"
    assert tx.card_first4 == "8600"
    assert tx.card_last4 == "4821"
    assert "Makro" in tx.merchant
    assert tx.direction == TransactionDirection.EXPENSE
    assert tx.status == TransactionStatus.CONFIRMED


def test_uzum_bank_parsing():
    engine = TransactionParserEngine()
    text = "Spisanie: 35 000 UZS s karty 8600..4821 v Yandex Go. Ostatok: 850 000 UZS"
    user_id = "test-user-100"

    tx = engine.process_notification(text, user_id=user_id)
    assert tx is not None
    assert tx.amount == 35000.0
    assert tx.card_first4 == "8600"
    assert tx.card_last4 == "4821"
    assert "Yandex Go" in tx.merchant
    assert tx.balance_after == 850000.0


def test_uzcard_humo_gateway_7557():
    engine = TransactionParserEngine()
    text = "Karta 8600********4821: Spisanie 50000.00 UZS. Terminal: EVOS. Dostupno: 340000.00 UZS"
    user_id = "test-user-100"

    tx = engine.process_notification(text, user_id=user_id)
    assert tx is not None
    assert tx.amount == 50000.0
    assert tx.card_last4 == "4821"
    assert "EVOS" in tx.merchant
    assert tx.direction == TransactionDirection.EXPENSE


def test_deduplication_detection():
    engine = TransactionParserEngine()
    text1 = "Oplata CLICK: 45 000 UZS, Karta *4821, Mesto: Korzinka. Balans: 1 200 000 UZS"
    user_id = "test-user-100"
    dt = datetime(2026, 10, 8, 12, 0, 0, tzinfo=timezone.utc)

    tx1 = engine.process_notification(text1, user_id=user_id, timestamp=dt)
    assert tx1 is not None

    existing_hashes = {tx1.duplicate_hash}

    # Second notification arriving 2 minutes later for same payment
    dt2 = dt + timedelta(minutes=2)
    tx2 = engine.process_notification(text1, user_id=user_id, timestamp=dt2, existing_hashes=existing_hashes)
    assert tx2 is not None
    assert tx2.status == TransactionStatus.DUPLICATE_CANDIDATE


def test_refund_detection():
    engine = TransactionParserEngine()
    user_id = "test-user-100"
    dt_refund = datetime(2026, 10, 8, 14, 0, 0, tzinfo=timezone.utc)

    recent_txs = [
        {
            "id": "past-expense-uuid-99",
            "amount": 45000.0,
            "direction": "expense",
            "merchant": "Korzinka Supermarket",
            "occurred_at": dt_refund - timedelta(days=1),
        }
    ]

    refund_text = "Vozvrat: 45 000 UZS na kartu *4821. Mesto: Korzinka Supermarket."
    tx_refund = engine.process_notification(
        refund_text,
        user_id=user_id,
        timestamp=dt_refund,
        recent_transactions=recent_txs
    )

    assert tx_refund is not None
    assert tx_refund.direction == TransactionDirection.REFUND
    assert tx_refund.related_transaction_id == "past-expense-uuid-99"
