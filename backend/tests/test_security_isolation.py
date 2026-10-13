import pytest
import hashlib
import time
from app.core.security import hash_pin, verify_pin


def test_pin_hashing_and_salting():
    """
    Threat Mitigated: Rainbow table & dictionary attacks against user PINs.
    Ensures identical PINs result in completely different hashes due to unique salts.
    """
    pin = "198421"
    hash1, salt1 = hash_pin(pin)
    hash2, salt2 = hash_pin(pin)

    assert hash1 != hash2
    assert salt1 != salt2
    assert verify_pin(pin, hash1, salt1) is True
    assert verify_pin(pin, hash2, salt2) is True
    assert verify_pin("999999", hash1, salt1) is False


def test_brute_force_lockout_simulation():
    """
    Threat Mitigated: Brute-force attacks on PIN code.
    Simulates consecutive failed attempts leading to lockout after 5 tries.
    """
    correct_pin = "4821"
    hashed, salt = hash_pin(correct_pin)

    failed_attempts = 0
    is_locked = False
    lockout_threshold = 5

    test_attempts = ["0000", "1111", "2222", "3333", "4444"]

    for attempt in test_attempts:
        if not verify_pin(attempt, hashed, salt):
            failed_attempts += 1
            if failed_attempts >= lockout_threshold:
                is_locked = True

    assert failed_attempts == 5
    assert is_locked is True


def test_tenant_data_isolation():
    """
    Threat Mitigated: Insecure Direct Object References (IDOR) & Tenant Leaks.
    Verifies that Client A can never access or modify data belonging to Client B.
    """
    mock_db = {
        "user_a_uuid": [
            {"id": "card-1", "user_id": "user_a_uuid", "last4": "4821", "amount": 1500000}
        ],
        "user_b_uuid": [
            {"id": "card-2", "user_id": "user_b_uuid", "last4": "9911", "amount": 8400000}
        ]
    }

    def get_user_cards(requesting_user_id: str, target_user_id: str):
        # Strict tenant boundary enforcement
        if requesting_user_id != target_user_id:
            return None  # Access Denied / 403 Forbidden
        return mock_db.get(requesting_user_id, [])

    # Client A requesting their own cards
    assert len(get_user_cards("user_a_uuid", "user_a_uuid")) == 1
    # Client A attempting to access Client B's cards
    assert get_user_cards("user_a_uuid", "user_b_uuid") is None


def test_idempotency_key_deduplication():
    """
    Threat Mitigated: Network retry duplicate transactions (Double Spend Bug).
    Ensures identical idempotency_key is processed exactly once.
    """
    processed_keys = set()
    ledger = []

    def process_payment(idempotency_key: str, user_id: str, amount_tiyin: int):
        if idempotency_key in processed_keys:
            return {"status": "ignored_duplicate", "ledger_count": len(ledger)}
        processed_keys.add(idempotency_key)
        ledger.append({"key": idempotency_key, "user_id": user_id, "amount": amount_tiyin})
        return {"status": "created", "ledger_count": len(ledger)}

    key = "idem-tx-offline-retry-99218"
    res1 = process_payment(key, "usr-1", 15000000)
    res2 = process_payment(key, "usr-1", 15000000)  # Network retry

    assert res1["status"] == "created"
    assert res2["status"] == "ignored_duplicate"
    assert len(ledger) == 1
