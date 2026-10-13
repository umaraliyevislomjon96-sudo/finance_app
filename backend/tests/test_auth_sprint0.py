import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.api.v1.auth import mock_user_profile, mock_sessions_db, mock_consents_db

client = TestClient(app)


def test_phone_otp_format_validation():
    """
    Threat Mitigated: Malformed input / SMS gateway resource depletion.
    Validates +998 Uzbekistan phone format.
    """
    # Invalid phone format
    res_bad = client.post("/api/v1/auth/otp/request", json={"phone": "123456789"})
    assert res_bad.status_code == 400

    # Valid Uzbek phone format
    res_good = client.post("/api/v1/auth/otp/request", json={"phone": "+998901234567"})
    assert res_good.status_code == 200
    data = res_good.json()
    assert data["status"] == "success"
    assert data["expires_in_seconds"] == 60


def test_otp_verify_and_session_generation():
    """
    Threat Mitigated: Unauthorized access & unverified session token creation.
    """
    # Invalid OTP code
    res_bad = client.post(
        "/api/v1/auth/otp/verify",
        json={
            "phone": "+998901234567",
            "code": "000000",
            "device_id": "test-device-uuid-1",
            "device_name": "Test iPhone"
        }
    )
    assert res_bad.status_code == 400

    # Valid OTP code
    res_good = client.post(
        "/api/v1/auth/otp/verify",
        json={
            "phone": "+998901234567",
            "code": "123456",
            "device_id": "test-device-uuid-1",
            "device_name": "Test iPhone"
        }
    )
    assert res_good.status_code == 200
    data = res_good.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user_id"] == "usr_99890_mock_id"


def test_pin_setup_and_verification():
    """
    Threat Mitigated: Plain-text PIN storage and brute-force access.
    """
    # Setup PIN
    res_setup = client.post(
        "/api/v1/auth/pin/setup",
        json={"pin": "8421", "enable_biometrics": True}
    )
    assert res_setup.status_code == 200
    assert res_setup.json()["biometrics_enabled"] is True

    # Verify correct PIN
    res_verify = client.post(
        "/api/v1/auth/pin/verify",
        json={"pin": "8421", "device_id": "test-device-uuid-1"}
    )
    assert res_verify.status_code == 200
    assert res_verify.json()["authenticated"] is True

    # Verify incorrect PIN
    res_wrong = client.post(
        "/api/v1/auth/pin/verify",
        json={"pin": "0000", "device_id": "test-device-uuid-1"}
    )
    assert res_wrong.status_code == 401


def test_multi_device_management_and_remote_revocation():
    """
    Threat Mitigated: Session hijacking & unauthorized retained device access.
    Enables user to view all active logins and revoke a specific remote device.
    """
    # List devices
    res_list = client.get("/api/v1/auth/devices")
    assert res_list.status_code == 200
    devices = res_list.json()
    assert len(devices) >= 2

    remote_device_id = "and-pixel8-uuid-4412"

    # Revoke remote device
    res_revoke = client.delete(f"/api/v1/auth/devices/{remote_device_id}")
    assert res_revoke.status_code == 200
    assert res_revoke.json()["revoked_device_id"] == remote_device_id

    # Verify revoked device is no longer in active list
    res_list_after = client.get("/api/v1/auth/devices")
    active_ids = [d["device_id"] for d in res_list_after.json()]
    assert remote_device_id not in active_ids


def test_consents_ledger_audit():
    """
    Threat Mitigated: Non-compliance with Law of the Republic of Uzbekistan 'On Personal Data' [Проверить у юриста].
    Verifies that explicit consents are logged with version and timestamp.
    """
    payload = {
        "consents": [
            {"consent_type": "terms_of_service", "is_granted": True, "version": "v1.0_2026_03"},
            {"consent_type": "privacy_policy_uz", "is_granted": True, "version": "v1.0_2026_03"},
            {"consent_type": "sms_parsing_consent", "is_granted": True, "version": "v1.0_2026_03"}
        ],
        "device_id": "ios-device-uuid-9821"
    }
    res_post = client.post("/api/v1/auth/consents", json=payload)
    assert res_post.status_code == 200
    assert res_post.json()["updated_count"] == 3

    res_get = client.get("/api/v1/auth/consents")
    assert res_get.status_code == 200
    consents = res_get.json()["consents"]
    types = [c["consent_type"] for c in consents]
    assert "sms_parsing_consent" in types


def test_account_deletion_with_grace_period():
    """
    Threat Mitigated: Accidental irrecoverable data loss + GDPR/Uzbek Law right to erasure.
    Ensures a 30-day grace period is granted before physical purge.
    """
    res_del = client.delete("/api/v1/auth/me")
    assert res_del.status_code == 200
    data = res_del.json()
    assert data["status_code"] == "pending_deletion"
    assert data["grace_period_days"] == 30
    assert "deletion_scheduled_at" in data

    # User re-activates account within grace period
    res_cancel = client.post("/api/v1/auth/cancel-deletion")
    assert res_cancel.status_code == 200
    assert res_cancel.json()["status"] == "success"


def test_data_export_archive():
    """
    Threat Mitigated: Vendor lock-in & lack of data transparency.
    Verifies export archive contains user profile, cards, obligations, transactions.
    """
    res = client.get("/api/v1/auth/export")
    assert res.status_code == 200
    export_data = res.json()
    assert "export_metadata" in export_data
    assert "user_profile" in export_data
    assert "registered_cards_metadata" in export_data
    assert "transactions_history" in export_data
    assert "obligations" in export_data
