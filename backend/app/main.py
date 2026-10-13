from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .api.v1.auth import router as auth_router
from .api.v1.transactions import router as transactions_router
from .api.v1.cards import router as cards_router
from .api.v1.analytics import router as analytics_router
from .api.v1.ai_assistant import router as ai_router
from .api.v1.calculators import router as calculators_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description=(
        "Production-ready backend API for Personal Finance Monitoring. "
        "Strict non-custodial architecture: Zero card CVV/PIN/full number storage, "
        "read-only analytics layer powered by SMS/Push parsing engine and AI agent."
    ),
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(transactions_router, prefix=settings.API_V1_STR)
app.include_router(cards_router, prefix=settings.API_V1_STR)
app.include_router(analytics_router, prefix=settings.API_V1_STR)
app.include_router(ai_router, prefix=settings.API_V1_STR)
app.include_router(calculators_router, prefix=settings.API_V1_STR)


import os
from fastapi.responses import FileResponse

from .db.supabase_client import supabase_client

@app.get("/health")
async def health_check():
    supabase_status = await supabase_client.health_check()
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "mode": "monitoring_only_non_custodial",
        "security": {
            "pan_storage": "none",
            "cvv_storage": "none",
            "pin_storage": "pbkdf2_salted_hash_only"
        },
        "integrations": {
            "sms_provider": settings.SMS_PROVIDER,
            "supabase": supabase_status.get("status")
        }
    }


@app.get("/status/database")
async def database_status():
    """Returns database readiness, Supabase connectivity, and schema info."""
    supabase_info = await supabase_client.health_check()
    return {
        "engine": "PostgreSQL 16 (RLS Enabled)",
        "tenant_isolation": "Row Level Security (SET LOCAL app.current_user_id)",
        "currency_unit": "BIGINT (Tiyin / Cents)",
        "supabase": supabase_info,
        "regulatory_note": "Production deployment must comply with Art. 27¹ Law on Personal Data (hosting inside UZ) [Проверить у юриста]"
    }


@app.get("/preview")
async def get_mobile_preview():
    html_path = os.path.join(os.path.dirname(__file__), "static", "mobile_preview.html")
    return FileResponse(html_path, media_type="text/html")


@app.get("/download-apk")
async def download_apk():
    """Serves the compiled Android APK directly for one-click installation on mobile devices."""
    apk_path = os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "mobile",
            "build",
            "app",
            "outputs",
            "flutter-apk",
            "app-debug.apk",
        )
    )
    if os.path.exists(apk_path):
        return FileResponse(
            apk_path,
            media_type="application/vnd.android.package-archive",
            filename="aurora_finance.apk",
        )
    return {"error": "APK not found", "path": apk_path}



