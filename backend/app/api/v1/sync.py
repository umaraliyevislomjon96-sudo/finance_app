"""Encrypted backup of the user's app data, so a reinstall restores everything.

The phone keeps working offline from its local ledger; this is a copy keyed by
the account (phone-number derived user id). Only structured data is stored —
no SMS / notification texts — and it is encrypted at rest (AES-256-GCM).

Storage: PostgreSQL when DATABASE_URL is set in the environment (Neon,
Supabase, Render Postgres…); otherwise an in-memory fallback that is lost on
restart, reported as persistent=false so the app can tell the user.
"""
from __future__ import annotations

import asyncio
import base64
import hashlib
import json
import logging
import os
import time
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from fastapi import APIRouter, Header, HTTPException, Request
from pydantic import BaseModel

from ...core.config import settings
from ...core.security import decode_access_token

logger = logging.getLogger("aurora.sync")
router = APIRouter(prefix="/sync", tags=["Backup & sync"])

MAX_BACKUP_BYTES = 3 * 1024 * 1024
_memory: Dict[str, Dict[str, Any]] = {}
_pool = None
_db_error: Optional[str] = None
_last_attempt = 0.0
RETRY_AFTER_SECONDS = 60
CONNECT_TIMEOUT = 5

CREATE_TABLE = """
CREATE TABLE IF NOT EXISTS user_data_backups (
    user_id     TEXT PRIMARY KEY,
    payload     TEXT NOT NULL,
    version     INTEGER NOT NULL DEFAULT 1,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
)
"""


# ---------------- encryption ----------------

def _key() -> bytes:
    raw = os.getenv("BACKUP_ENCRYPTION_KEY")
    if raw:
        try:
            k = base64.b64decode(raw)
            if len(k) == 32:
                return k
        except Exception:
            pass
    # Derived from SECRET_KEY: keep SECRET_KEY stable or backups become unreadable.
    return hashlib.sha256(("aurora-backup:" + settings.SECRET_KEY).encode()).digest()


def _encrypt(data: dict, user_id: str) -> str:
    nonce = os.urandom(12)
    blob = AESGCM(_key()).encrypt(nonce, json.dumps(data, ensure_ascii=False).encode(), user_id.encode())
    return base64.b64encode(nonce + blob).decode()


def _decrypt(payload: str, user_id: str) -> dict:
    raw = base64.b64decode(payload)
    return json.loads(AESGCM(_key()).decrypt(raw[:12], raw[12:], user_id.encode()))


# ---------------- storage ----------------

def database_url() -> Optional[str]:
    """Explicitly configured DATABASE_URL (the config default points at localhost)."""
    url = os.getenv("DATABASE_URL", "").strip()
    return url or None


def _asyncpg_args(url: str) -> tuple[str, dict]:
    parts = urlsplit(url.replace("postgresql+asyncpg://", "postgresql://").replace("postgres://", "postgresql://", 1))
    query = dict(parse_qsl(parts.query))
    sslmode = query.pop("sslmode", None)
    query.pop("channel_binding", None)
    clean = urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query), parts.fragment))
    local = parts.hostname in ("localhost", "127.0.0.1", None)
    kwargs: dict = {}
    if sslmode in ("require", "verify-ca", "verify-full") or (sslmode is None and not local):
        kwargs["ssl"] = "require"
    return clean, kwargs


async def _get_pool():
    global _pool, _db_error, _last_attempt
    if _pool is not None or not database_url():
        return _pool
    # A broken DATABASE_URL must never make requests slow: try at most once a minute.
    if _db_error and time.monotonic() - _last_attempt < RETRY_AFTER_SECONDS:
        return None
    _last_attempt = time.monotonic()
    try:
        import asyncpg

        dsn, kwargs = _asyncpg_args(database_url())
        pool = await asyncio.wait_for(
            asyncpg.create_pool(dsn, min_size=0, max_size=4, command_timeout=10, timeout=CONNECT_TIMEOUT,
                                statement_cache_size=0, **kwargs),
            timeout=CONNECT_TIMEOUT + 2,
        )
        try:
            # min_size=0 means no connection yet: only a real query proves the database works.
            con = await asyncio.wait_for(pool.acquire(), timeout=CONNECT_TIMEOUT + 2)
            try:
                await con.execute(CREATE_TABLE)
            finally:
                await pool.release(con)
        except BaseException:
            pool.terminate()
            raise
        _pool = pool
        _db_error = None
    except Exception as exc:  # keep the API usable; report the problem
        _db_error = type(exc).__name__ or "error"
        logger.warning("Backup database unavailable: %s", _db_error)
    return _pool


def cached_storage_status() -> Dict[str, Any]:
    """For /health: never touches the database (Render health checks are short)."""
    if not database_url():
        return {"persistent": False, "database": "unconfigured"}
    if _pool is not None:
        return {"persistent": True, "database": "connected"}
    if _db_error:
        return {"persistent": False, "database": "error", "detail": _db_error}
    return {"persistent": False, "database": "connecting"}


@router.on_event("startup")
async def _connect_in_background():
    if database_url():
        asyncio.get_running_loop().create_task(_get_pool())


async def storage_status() -> Dict[str, Any]:
    if not database_url():
        return {"persistent": False, "database": "unconfigured"}
    pool = await _get_pool()
    if pool is None:
        return {"persistent": False, "database": "error", "detail": _db_error}
    return {"persistent": True, "database": "connected"}


async def _load(user_id: str) -> Optional[Dict[str, Any]]:
    pool = await _get_pool()
    if pool is None:
        return _memory.get(user_id)
    async with pool.acquire() as con:
        row = await con.fetchrow("SELECT payload, updated_at FROM user_data_backups WHERE user_id = $1", user_id)
    if row is None:
        return None
    return {"payload": row["payload"], "updated_at": row["updated_at"].isoformat()}


async def _save(user_id: str, payload: str) -> str:
    now = datetime.now(timezone.utc)
    pool = await _get_pool()
    if pool is None:
        _memory[user_id] = {"payload": payload, "updated_at": now.isoformat()}
        return now.isoformat()
    async with pool.acquire() as con:
        await con.execute(
            """INSERT INTO user_data_backups (user_id, payload, updated_at) VALUES ($1, $2, $3)
               ON CONFLICT (user_id) DO UPDATE SET payload = EXCLUDED.payload,
               updated_at = EXCLUDED.updated_at, version = user_data_backups.version + 1""",
            user_id, payload, now,
        )
    return now.isoformat()


async def _delete(user_id: str) -> None:
    pool = await _get_pool()
    if pool is None:
        _memory.pop(user_id, None)
        return
    async with pool.acquire() as con:
        await con.execute("DELETE FROM user_data_backups WHERE user_id = $1", user_id)


# ---------------- API ----------------

def _user_id(authorization: Optional[str]) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Войдите в аккаунт, чтобы сохранять данные.")
    payload = decode_access_token(authorization.split(" ", 1)[1].strip())
    if not payload or not payload.get("sub"):
        raise HTTPException(status_code=401, detail="Сессия истекла. Войдите заново.")
    return str(payload["sub"])


class BackupIn(BaseModel):
    data: Dict[str, Any]


@router.get("/status")
async def sync_status():
    """Whether backups survive a server restart (no auth, no user data)."""
    return await storage_status()


@router.get("/backup")
async def get_backup(authorization: Optional[str] = Header(None)):
    user_id = _user_id(authorization)
    row = await _load(user_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Резервной копии ещё нет.")
    try:
        data = _decrypt(row["payload"], user_id)
    except Exception:
        logger.error("Backup for a user could not be decrypted (key changed?)")
        raise HTTPException(status_code=500, detail="Не удалось расшифровать копию.")
    return {"data": data, "updated_at": row["updated_at"], **(await storage_status())}


@router.put("/backup")
async def put_backup(request: Request, authorization: Optional[str] = Header(None)):
    user_id = _user_id(authorization)
    body = await request.body()
    if len(body) > MAX_BACKUP_BYTES:
        raise HTTPException(status_code=413, detail="Слишком большая копия.")
    try:
        parsed = BackupIn.model_validate_json(body)
    except Exception:
        raise HTTPException(status_code=422, detail="Неверный формат копии.")
    updated_at = await _save(user_id, _encrypt(parsed.data, user_id))
    return {"updated_at": updated_at, **(await storage_status())}


@router.delete("/backup")
async def delete_backup(authorization: Optional[str] = Header(None)):
    user_id = _user_id(authorization)
    await _delete(user_id)
    return {"deleted": True}
