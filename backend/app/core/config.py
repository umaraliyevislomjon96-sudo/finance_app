import os
from typing import List
from pydantic import BaseModel
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))


class Settings(BaseModel):
    PROJECT_NAME: str = "Aurora Finance Monitoring API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Security & Tokens
    SECRET_KEY: str = os.getenv("SECRET_KEY", "aurora-super-secure-production-monitoring-key-256bits-min")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    PIN_MAX_FAILED_ATTEMPTS: int = 5
    PIN_LOCKOUT_MINUTES: int = 15

    # Database & Redis
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:postgres@localhost:5432/aurora_finance")
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # Supabase Integration (Self-hosted or Cloud)
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_ANON_KEY: str = os.getenv("SUPABASE_ANON_KEY", "")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

    # Optional server-side Gemini provider. Never expose this value to clients.
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-3.8-flash")

    # Optional server-side Yandex SpeechKit TTS credentials. Never expose these to clients.
    YANDEX_SPEECHKIT_API_KEY: str = os.getenv("YANDEX_SPEECHKIT_API_KEY", "")
    YANDEX_SPEECHKIT_TTS_URL: str = os.getenv(
        "YANDEX_SPEECHKIT_TTS_URL", "https://tts.api.ml.yandexcloud.kz/tts/v3/utteranceSynthesis"
    )

    # Uzbekistan SMS Aggregators (Eskiz.uz / PlayMobile)
    SMS_PROVIDER: str = os.getenv("SMS_PROVIDER", "mock")  # "eskiz", "playmobile", "mock"
    ESKIZ_EMAIL: str = os.getenv("ESKIZ_EMAIL", "")
    ESKIZ_PASSWORD: str = os.getenv("ESKIZ_PASSWORD", "")
    PLAYMOBILE_LOGIN: str = os.getenv("PLAYMOBILE_LOGIN", "")
    PLAYMOBILE_PASSWORD: str = os.getenv("PLAYMOBILE_PASSWORD", "")

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]


settings = Settings()

