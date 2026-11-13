from fastapi.testclient import TestClient

from app.api.v1 import sync
from app.core.security import create_access_token, user_id_for_phone
from app.main import app

client = TestClient(app)


def _auth(phone: str) -> dict:
    token = create_access_token(user_id=user_id_for_phone(phone), device_id="test-device")
    return {"Authorization": f"Bearer {token}"}


def setup_function(_):
    sync._memory.clear()


def test_same_phone_same_id_different_phones_differ():
    assert user_id_for_phone("+998 90 123-45-67") == user_id_for_phone("998901234567")
    assert user_id_for_phone("+998901234567") != user_id_for_phone("+998901234568")
    assert "998901234567" not in user_id_for_phone("+998901234567")


def test_backup_round_trip_and_reinstall_restore(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    data = {"ledger": {"items": [{"id": "a", "amount": 5000, "type": "income"}]}, "obligations": []}
    r = client.put("/api/v1/sync/backup", json={"data": data}, headers=_auth("+998901112233"))
    assert r.status_code == 200
    assert r.json()["persistent"] is False  # no DATABASE_URL -> honest about it

    # "Reinstall": a new device signs in with the same number and gets the data back.
    token = create_access_token(user_id=user_id_for_phone("+998901112233"), device_id="new-phone")
    r = client.get("/api/v1/sync/backup", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["data"] == data


def test_users_are_isolated_and_data_is_encrypted_at_rest(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    client.put("/api/v1/sync/backup", json={"data": {"secret": "Korzinka 45000"}}, headers=_auth("+998901000001"))
    assert client.get("/api/v1/sync/backup", headers=_auth("+998901000002")).status_code == 404
    stored = sync._memory[user_id_for_phone("+998901000001")]["payload"]
    assert "Korzinka" not in stored


def test_auth_required_and_delete(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    assert client.get("/api/v1/sync/backup").status_code == 401
    assert client.get("/api/v1/sync/backup", headers={"Authorization": "Bearer bad"}).status_code == 401
    h = _auth("+998907777777")
    client.put("/api/v1/sync/backup", json={"data": {"x": 1}}, headers=h)
    assert client.delete("/api/v1/sync/backup", headers=h).json() == {"deleted": True}
    assert client.get("/api/v1/sync/backup", headers=h).status_code == 404


def test_status_and_health_report_storage(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    assert client.get("/api/v1/sync/status").json() == {"persistent": False, "database": "unconfigured"}
    assert client.get("/health").json()["integrations"]["backup_storage"]["persistent"] is False


def test_database_url_variants_are_converted_for_asyncpg():
    dsn, kw = sync._asyncpg_args("postgresql://u:p@ep-x.neon.tech/db?sslmode=require&channel_binding=require")
    assert dsn == "postgresql://u:p@ep-x.neon.tech/db" and kw == {"ssl": "require"}
    dsn, kw = sync._asyncpg_args("postgresql+asyncpg://u:p@localhost:5432/db")
    assert dsn == "postgresql://u:p@localhost:5432/db" and kw == {}
    dsn, kw = sync._asyncpg_args("postgres://u:p@db.supabase.co:5432/postgres")
    assert dsn.startswith("postgresql://") and kw == {"ssl": "require"}
