# -*- coding: utf-8 -*-
import pytest
from datetime import datetime, timezone, timedelta

from app.services.parser.service import TransactionProcessingService
from app.services.parser.detector import FinancialDetector, FinancialTransactionType
from app.services.parser.classifier import TransactionClassifier
from app.services.parser.base import TransactionStatus, TransactionDirection


# ==============================================================================
# REQUIREMENT 22: COMPREHENSIVE 18-SCENARIO TECHNICAL AUDIT & TEST SUITE
# ==============================================================================

@pytest.fixture
def service():
    return TransactionProcessingService()


# 1. Bank Purchase Notification
def test_scenario_01_bank_purchase_notification(service):
    text = "Оплата картой 180 000 UZS в EVOS. Karta *4821. Dostupno: 3 820 000 UZS"
    res = service.process_notification(text, package_name="uz.click.app")

    assert res.is_financial is True
    assert res.direction == "expense"
    assert res.amount == 180000.0
    assert res.currency == "UZS"
    assert "EVOS" in (res.merchant or "")
    assert res.category == "Food"
    assert res.card_last4 == "4821"
    assert res.confidence_score >= 0.90
    assert res.requires_user_review is False
    assert res.status == "processed"


# 2. Incoming Transfer
def test_scenario_02_incoming_transfer(service):
    text = "Поступление 2 000 000 UZS на карту *4821 от Alisher M."
    res = service.process_notification(text, package_name="uz.dida.payme")

    assert res.is_financial is True
    assert res.direction == "income"
    assert res.amount == 2000000.0
    assert res.currency == "UZS"
    assert res.card_last4 == "4821"
    assert res.is_internal_transfer is False


# 3. Outgoing Transfer
def test_scenario_03_outgoing_transfer(service):
    text = "Перевод 300 000 UZS на карту *1122 с карты *4821. Komissiya: 0"
    res = service.process_notification(text, package_name="uz.dida.payme")

    assert res.is_financial is True
    assert res.direction == "transfer"
    assert res.amount == 300000.0
    assert res.category == "Transfer"
    assert res.card_last4 in ("1122", "4821")


# 4. Salary
def test_scenario_04_salary_income(service):
    text = "Зачисление зарплаты 8 000 000 UZS на карту *4821. Dostupno: 11 820 000 UZS"
    res = service.process_notification(text, package_name="app.bank.uzum")

    assert res.is_financial is True
    assert res.direction == "income"
    assert res.amount == 8000000.0
    assert res.category == "Salary"
    assert res.ai_advisory_note is not None
    assert "8 000 000" in res.ai_advisory_note


# 5. Refund
def test_scenario_05_refund(service):
    dt_ref = datetime(2026, 10, 8, 15, 0, 0, tzinfo=timezone.utc)
    recent = [
        {
            "id": "past_tx_korzinka_1",
            "amount": 250000.0,
            "direction": "expense",
            "merchant": "Korzinka Supermarket",
            "occurred_at": (dt_ref - timedelta(days=2)).isoformat()
        }
    ]
    text = "Возврат 250 000 UZS в Korzinka на карту *4821"
    res = service.process_notification(text, timestamp=dt_ref, existing_transactions=recent)

    assert res.is_financial is True
    assert res.is_refund is True
    assert res.amount == 250000.0
    assert res.related_transaction_id == "past_tx_korzinka_1"


# 6. ATM Cash Withdrawal
def test_scenario_06_atm_withdrawal(service):
    text = "Снятие наличных 500 000 UZS в банкомате Kapitalbank с карты *4821"
    res = service.process_notification(text, package_name="com.kapitalbank")

    assert res.is_financial is True
    assert res.amount == 500000.0
    assert res.category == "Cash Withdrawal"
    assert "Банкомат" in (res.merchant or "")


# 7. Loan Payment
def test_scenario_07_loan_payment(service):
    text = "Погашение кредита 1 200 000 UZS с карты *4821. Kapitalbank"
    res = service.process_notification(text, package_name="com.kapitalbank")

    assert res.is_financial is True
    assert res.amount == 1200000.0
    assert res.category == "Loan"
    assert res.direction == "expense"


# 8. Credit Card Payment
def test_scenario_08_credit_card_payment(service):
    text = "Оплата кредитной карты 450 000 UZS. Karta *1122"
    res = service.process_notification(text, package_name="app.bank.uzum")

    assert res.is_financial is True
    assert res.amount == 450000.0
    assert res.category == "Credit Card"


# 9. Internal Transfer (Card A -> Card B without Net Worth shift)
def test_scenario_09_internal_transfer(service):
    dt_now = datetime(2026, 10, 8, 16, 0, 0, tzinfo=timezone.utc)
    # Existing Card A debit notification arrived 1 minute ago
    existing = [
        {
            "id": "tx_card_a_debit",
            "amount": 500000.0,
            "direction": "expense",
            "card_last4": "4821",
            "occurred_at": (dt_now - timedelta(minutes=1)).isoformat()
        }
    ]
    # Card B credit notification arrives
    text = "Поступление 500 000 UZS на карту *1122"
    res = service.process_notification(text, timestamp=dt_now, existing_transactions=existing)

    assert res.is_financial is True
    assert res.is_internal_transfer is True
    assert res.related_transaction_id == "tx_card_a_debit"
    assert res.ai_advisory_note is not None
    assert "500 000" in res.ai_advisory_note


# 10. Duplicate Notification (Push + SMS in 5-minute bucket)
def test_scenario_10_duplicate_notification(service):
    dt = datetime(2026, 10, 8, 12, 0, 0, tzinfo=timezone.utc)
    push_text = "Oplata 45 000 UZS v KORZINKA. Karta *1234. Dostupno: 34 850 000 UZS"
    sms_text = "Karta 8600********1234: Spisanie 45000.00 UZS. Terminal: KORZINKA. Dostupno: 34850000.00 UZS"

    res1 = service.process_notification(push_text, timestamp=dt)
    assert res1.status == "processed"

    # SMS arrives 2 minutes later for the same transaction
    dt_sms = dt + timedelta(minutes=2)
    res2 = service.process_notification(sms_text, timestamp=dt_sms)
    assert res2.status == "already_processed"
    assert res2.amount == 45000.0


# 11. Unknown / Non-financial Notification (Telegram / WhatsApp with numbers)
def test_scenario_11_non_financial_notification_rejected(service):
    tg_text = "Привет! Перезвони мне на номер 998901234567, срочно нужно обсудить проект"
    res_tg = service.process_notification(tg_text, package_name="org.telegram.messenger")
    assert res_tg.is_financial is False
    assert res_tg.status == "ignored_non_financial"

    wa_text = "Код для входа: 489123. Никому не сообщайте его."
    res_wa = service.process_notification(wa_text, package_name="com.whatsapp")
    assert res_wa.is_financial is False
    assert res_wa.status == "ignored_non_financial"


# 12. Notification Without Amount (Never invent data)
def test_scenario_12_notification_without_amount(service):
    text = "Успешный вход в мобильное приложение банка Kapitalbank"
    res = service.process_notification(text, package_name="com.kapitalbank")

    assert res.is_financial is False
    assert res.amount is None
    assert res.status == "ignored_non_financial"


# 13. Notification With Different Currency (USD, EUR, RUB)
def test_scenario_13_multi_currency(service):
    usd_text = "Purchase: $45.20 at STARBUCKS with card ending 4821"
    res_usd = service.process_notification(usd_text)
    assert res_usd.is_financial is True
    assert res_usd.currency == "USD"
    assert res_usd.amount == 45.20

    eur_text = "Apple Pay: You paid EUR 18.50 at Uber. Card *4821"
    res_eur = service.process_notification(eur_text)
    assert res_eur.is_financial is True
    assert res_eur.currency == "EUR"
    assert res_eur.amount == 18.50


# 14. Multiple Notifications in Quick Burst (< 3 seconds)
def test_scenario_14_rapid_burst_notifications(service):
    dt = datetime(2026, 10, 8, 14, 0, 0, tzinfo=timezone.utc)
    t1 = "Оплата картой 25 000 UZS в Yandex Go с карты *4821"
    t2 = "Оплата картой 30 000 UZS в Safia Bakery с карты *4821"
    t3 = "Оплата картой 15 000 UZS в Oson Apteka с карты *4821"

    r1 = service.process_notification(t1, timestamp=dt)
    r2 = service.process_notification(t2, timestamp=dt + timedelta(seconds=1))
    r3 = service.process_notification(t3, timestamp=dt + timedelta(seconds=2))

    assert r1.status == "processed" and r1.category == "Transport"
    assert r2.status == "processed" and r2.category == "Food"
    assert r3.status == "processed" and r3.category == "Health"


# 15. Notification Permission Disabled State
def test_scenario_15_permission_disabled_state(service):
    service.settings["listener_status"] = "disabled"
    text = "Оплата картой 180 000 UZS в EVOS"
    res = service.process_notification(text)

    assert res.status == "disabled"
    assert res.is_financial is False

    # Re-enable
    service.settings["listener_status"] = "connected"
    res_re = service.process_notification(text)
    assert res_re.status == "processed"


# 16. AI Unavailable (Graceful Fallback to Deterministic Rules)
def test_scenario_16_ai_unavailable_fallback(service):
    service.settings["ai_categorization_enabled"] = False
    text = "Оплата картой 180 000 UZS в EVOS"
    res = service.process_notification(text)

    assert res.is_financial is True
    assert res.amount == 180000.0
    assert res.status in ("processed", "needs_review")


# 17. App Restart / Hash Persistence Simulation
def test_scenario_17_persistence_simulation():
    svc1 = TransactionProcessingService()
    dt = datetime(2026, 10, 8, 18, 0, 0, tzinfo=timezone.utc)
    t = "Оплата картой 85 000 UZS в Makro с карты *4821"
    r1 = svc1.process_notification(t, timestamp=dt)
    assert r1.status == "processed"

    # Simulate app restart with new service instance loading recorded duplicate hash
    svc2 = TransactionProcessingService()
    svc2.dedup_engine._seen_hashes[r1.transaction["duplicate_hash"]] = {
        "tx_id": r1.transaction["id"],
        "occurred_at": dt,
        "amount": 85000.0,
        "merchant": "Makro"
    }

    r2 = svc2.process_notification(t, timestamp=dt + timedelta(minutes=1))
    assert r2.status == "already_processed"


# 18. Manual Correction & Feedback Loop
def test_scenario_18_manual_correction_feedback_loop():
    # User corrects an unknown merchant "Custom Coffee Lab" to "Food"
    merchant = "Custom Coffee Lab"
    cat_before, _ = TransactionClassifier.classify(merchant, FinancialTransactionType.PURCHASE)
    assert cat_before in ("Shopping", "Other")

    # Record user correction
    TransactionClassifier.record_correction(merchant, "Food")
    cat_after, conf = TransactionClassifier.classify(merchant, FinancialTransactionType.PURCHASE)
    assert cat_after == "Food"
    assert conf >= 0.95
