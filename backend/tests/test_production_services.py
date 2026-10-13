import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.services.sms.sms_service import otp_manager, MockSmsProvider
from app.db.supabase_client import supabase_client


@pytest.mark.asyncio
async def test_sms_otp_flow_and_rate_limiting():
    # 1. Successful OTP dispatch in sandbox
    test_phone = "+998909998877"
    res1 = await otp_manager.issue_otp(test_phone)
    assert res1["status"] == "success"
    assert res1["demo_code"] == "123456"

    # 2. Verify OTP succeeds with correct code
    verified = otp_manager.verify_otp(test_phone, "123456")
    assert verified is True

    # 3. Verify OTP fails with wrong code
    res2 = await otp_manager.issue_otp(test_phone)
    verified_bad = otp_manager.verify_otp(test_phone, "000000")
    assert verified_bad is False

    # 4. Third request
    res3 = await otp_manager.issue_otp(test_phone)
    assert res3["status"] == "success"

    # 5. Fourth request triggers rate limiting (> 3 in 10 mins)
    with pytest.raises(ValueError, match="Превышен лимит запросов"):
        await otp_manager.issue_otp(test_phone)


@pytest.mark.asyncio
async def test_health_and_database_status_endpoints():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # /health
        resp = await client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "healthy"
        assert data["security"]["pan_storage"] == "none"
        assert data["security"]["cvv_storage"] == "none"

        # /status/database
        db_resp = await client.get("/status/database")
        assert db_resp.status_code == 200
        db_data = db_resp.json()
        assert "PostgreSQL 16" in db_data["engine"]
        assert "RLS Enabled" in db_data["engine"]
        assert "BIGINT (Tiyin / Cents)" in db_data["currency_unit"]
        assert "Art. 27" in db_data["regulatory_note"]


@pytest.mark.asyncio
async def test_oauth_providers_sign_in():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        for provider in ["google", "apple", "github"]:
            payload = {
                "provider": provider,
                "token_or_code": f"test_{provider}_jwt_token_valid",
                "email": f"test.{provider}@domain.com",
                "name": f"Tester {provider.capitalize()}",
                "device_id": f"dev-{provider}-uuid",
                "device_name": f"{provider.capitalize()} Device"
            }
            resp = await client.post("/api/v1/auth/oauth/sign-in", json=payload)
            assert resp.status_code == 200
            data = resp.json()
            assert "access_token" in data
            assert "refresh_token" in data
            assert data["token_type"] == "bearer"
            assert provider in data["user_id"]


@pytest.mark.asyncio
async def test_push_notification_ingestion_idempotency():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        push_payload = {
            "text": "Oplata 45 000 UZS v KORZINKA. Karta *1234. Dostupno: 34 850 000 UZS",
            "source": "push",
            "idempotency_key": "push_payme_987654321_hash1"
        }
        # First ingestion
        resp1 = await client.post("/api/v1/transactions/ingest", json=push_payload)
        assert resp1.status_code in (200, 201)
        data1 = resp1.json()
        assert data1["merchant"] == "KORZINKA"
        assert data1["direction"] == "expense"
        assert data1["amount_tiyin"] == 4500000

        # Duplicate ingestion with same idempotency key
        resp2 = await client.post("/api/v1/transactions/ingest", json=push_payload)
        assert resp2.status_code in (200, 201)
        data2 = resp2.json()
        assert data2["idempotency_key"] == "push_payme_987654321_hash1"
