import hashlib
import os
import hmac
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any
import jwt
from .config import settings


def hash_pin(pin: str, salt: Optional[str] = None) -> tuple[str, str]:
    """
    PBKDF2-HMAC-SHA256 PIN hashing with unique cryptographic salt.
    Prevents rainbow table and dictionary attacks.
    """
    salt_val = salt or os.urandom(16).hex()
    pwd_bytes = pin.encode("utf-8")
    salt_bytes = salt_val.encode("utf-8")
    key = hashlib.pbkdf2_hmac("sha256", pwd_bytes, salt_bytes, 100000)
    return key.hex(), salt_val


def verify_pin(pin: str, hashed_pin: str, salt: str) -> bool:
    computed, _ = hash_pin(pin, salt)
    return hmac.compare_digest(computed, hashed_pin)


def create_access_token(user_id: str, device_id: str, expires_delta: Optional[timedelta] = None) -> str:
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    payload: Dict[str, Any] = {
        "sub": user_id,
        "device_id": device_id,
        "type": "access",
        "iat": now,
        "exp": expire,
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(user_id: str, device_id: str) -> tuple[str, str]:
    now = datetime.now(timezone.utc)
    expire = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    raw_token = os.urandom(32).hex()
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    return raw_token, token_hash


def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if payload.get("type") != "access":
            return None
        return payload
    except jwt.PyJWTError:
        return None
