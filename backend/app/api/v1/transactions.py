from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone

from ...services.parser.service import TransactionProcessingService, IngestionResult
from ...services.parser.classifier import TransactionClassifier
from ...services.parser.base import TransactionStatus, TransactionDirection
from .cards import mock_cards_db
from ...db.supabase_client import supabase_client

router = APIRouter(prefix="/transactions", tags=["Transactions & Ingestion Engine"])
processing_service = TransactionProcessingService()

# In-memory primary transactions database
mock_transactions_db: List[Dict[str, Any]] = [
    {
        "id": "tx-1",
        "user_id": "usr_99890_mock_id",
        "card_last4": "4821",
        "amount": 2380.0,
        "amount_tiyin": 238000,
        "amount_formatted": "2 380 USD",
        "currency": "USD",
        "direction": "expense",
        "merchant": "Food & Dining",
        "category": "Food",
        "source": "push",
        "status": "confirmed",
        "confidence_score": 0.98,
        "occurred_at": datetime.now(timezone.utc).isoformat(),
        "is_internal_transfer": False,
        "is_refund": False
    },
    {
        "id": "tx-2",
        "user_id": "usr_99890_mock_id",
        "card_last4": "4821",
        "amount": 4200.0,
        "amount_tiyin": 420000,
        "amount_formatted": "4 200 USD",
        "currency": "USD",
        "direction": "income",
        "merchant": "Salary Transfer",
        "category": "Salary",
        "source": "sms",
        "status": "confirmed",
        "confidence_score": 0.99,
        "occurred_at": datetime.now(timezone.utc).isoformat(),
        "is_internal_transfer": False,
        "is_refund": False
    }
]

idempotency_cache: Dict[str, Dict[str, Any]] = {}


class IngestNotificationRequest(BaseModel):
    raw_text: Optional[str] = None
    text: Optional[str] = None
    package_name: Optional[str] = None
    package: Optional[str] = None
    source: str = Field("push", pattern="^(sms|push|manual|import)$")
    idempotency_key: Optional[str] = None
    timestamp: Optional[datetime] = None


class ReviewActionRequest(BaseModel):
    action: str = Field(..., pattern="^(confirm|edit|ignore)$")
    corrected_category: Optional[str] = None
    corrected_merchant: Optional[str] = None


class EditTransactionRequest(BaseModel):
    direction: Optional[str] = Field(None, pattern="^(income|expense|transfer|refund)$")
    amount: Optional[float] = None
    currency: Optional[str] = None
    category: Optional[str] = None
    merchant: Optional[str] = None
    card_last4: Optional[str] = None
    description: Optional[str] = None
    occurred_at: Optional[datetime] = None


class FinancialSourceSettingsRequest(BaseModel):
    listener_status: Optional[str] = Field(None, pattern="^(connected|permission_required|disabled|error)$")
    auto_detection_enabled: Optional[bool] = None
    ai_categorization_enabled: Optional[bool] = None
    auto_creation_enabled: Optional[bool] = None


class SimulatePushRequest(BaseModel):
    preset: Optional[str] = None
    custom_text: Optional[str] = None
    custom_package: Optional[str] = None
    package_name: Optional[str] = None
    title: Optional[str] = None
    text: Optional[str] = None


# Presets for instant end-to-end testing
SIMULATION_PRESETS = {
    "evos_purchase": {
        "text": "Оплата картой 180 000 UZS в EVOS. Karta *4821. Dostupno: 3 820 000 UZS",
        "package": "uz.click.app"
    },
    "salary_income": {
        "text": "Зачисление зарплаты 8 000 000 UZS на карту *4821. Dostupno: 11 820 000 UZS",
        "package": "app.bank.uzum"
    },
    "incoming_transfer": {
        "text": "Поступление 2 000 000 UZS на карту *4821 от Alisher M.",
        "package": "uz.dida.payme"
    },
    "outgoing_transfer": {
        "text": "Перевод 300 000 UZS на карту *1122 с карты *4821",
        "package": "uz.dida.payme"
    },
    "refund": {
        "text": "Возврат 250 000 UZS в Korzinka на карту *4821",
        "package": "uz.click.app"
    },
    "cash_withdrawal": {
        "text": "Снятие наличных 500 000 UZS в банкомате Kapitalbank с карты *4821",
        "package": "com.kapitalbank"
    },
    "loan_payment": {
        "text": "Погашение кредита 1 200 000 UZS с карты *4821. Kapitalbank",
        "package": "com.kapitalbank"
    },
    "credit_card_payment": {
        "text": "Оплата кредитной карты 450 000 UZS. Karta *1122",
        "package": "app.bank.uzum"
    },
    "internal_transfer": {
        "text": "Перевод 500 000 UZS с карты *4821 на карту *1122",
        "package": "uz.dida.payme"
    },
    "fee_commission": {
        "text": "Комиссия за перевод 5 000 UZS с карты *4821",
        "package": "uz.click.app"
    },
    "usd_purchase": {
        "text": "Purchase: $45.20 at STARBUCKS with card ending 4821",
        "package": "com.kapitalbank"
    },
    "non_financial_telegram": {
        "text": "Привет! Перезвони мне на номер 998901234567, срочно нужно обсудить проект",
        "package": "org.telegram.messenger"
    },
    "non_financial_whatsapp": {
        "text": "Код для входа: 489123. Никому не сообщайте его.",
        "package": "com.whatsapp"
    },
    "missing_amount": {
        "text": "Успешный вход в мобильное приложение банка Kapitalbank",
        "package": "com.kapitalbank"
    }
}


@router.post("/ingest")
async def ingest_notification(req: IngestNotificationRequest):
    content = req.text or req.raw_text
    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Необходимо указать текст уведомления (поле text или raw_text)"
        )

    pkg = req.package_name or req.package

    # Idempotency check: fast cache hit
    if req.idempotency_key and req.idempotency_key in idempotency_cache:
        cached = idempotency_cache[req.idempotency_key]
        return {
            "status": "already_processed",
            "accepted": False,
            "is_duplicate": True,
            "idempotency_key": req.idempotency_key,
            "merchant": cached.get("merchant"),
            "direction": cached.get("direction"),
            "amount_tiyin": cached.get("amount_tiyin"),
            "amount_formatted": cached.get("amount_formatted"),
            "transaction": cached,
            "rejection_reason": "Уведомление с данным idempotency_key уже обработано ранее",
            "message": "Уведомление с данным idempotency_key уже обработано ранее"
        }

    user_id = "usr_99890_mock_id"
    res: IngestionResult = processing_service.process_notification(
        raw_text=content,
        user_id=user_id,
        package_name=pkg,
        source=req.source,
        timestamp=req.timestamp,
        existing_transactions=mock_transactions_db,
        idempotency_key=req.idempotency_key
    )

    if res.status == "ignored_non_financial":
        return {
            "status": "ignored_non_financial",
            "accepted": False,
            "is_financial": False,
            "financial_type": res.financial_type,
            "message": res.message,
            "rejection_reason": res.message,
            "confidence_score": res.confidence_score
        }

    if res.status == "already_processed":
        return {
            "status": "already_processed",
            "accepted": False,
            "is_duplicate": True,
            "is_financial": True,
            "financial_type": res.financial_type,
            "merchant": res.merchant,
            "amount_formatted": res.amount_formatted,
            "message": res.message,
            "rejection_reason": res.message,
            "related_transaction_id": res.related_transaction_id
        }

    if res.status == "unrecognized":
        return {
            "status": "unrecognized",
            "accepted": False,
            "is_financial": res.is_financial,
            "message": res.message,
            "rejection_reason": res.message,
            "confidence_score": res.confidence_score
        }

    # Register successfully parsed transaction
    tx_dict = res.transaction
    if tx_dict:
        mock_transactions_db.insert(0, tx_dict)

        # Update card balance & monthly spending if card identified
        if tx_dict.get("card_last4"):
            for card in mock_cards_db:
                if card.get("last4") == tx_dict.get("card_last4"):
                    if tx_dict.get("direction") == "expense":
                        card["monthly_spending"] = card.get("monthly_spending", 0.0) + tx_dict.get("amount", 0.0)

        # Cache idempotency key
        if req.idempotency_key:
            idempotency_cache[req.idempotency_key] = tx_dict

        # Broadcast via Supabase Realtime if configured
        if supabase_client.is_configured:
            try:
                await supabase_client.broadcast_realtime_event(
                    channel=f"user_{user_id}",
                    event="new_transaction",
                    payload=tx_dict
                )
            except Exception:
                pass

    net_worth_impact = 0.0 if res.is_internal_transfer else (res.amount if res.direction in ("income", "refund") else -res.amount)

    return {
        "status": res.status,
        "accepted": True,
        "is_financial": res.is_financial,
        "financial_type": res.financial_type,
        "category": res.category,
        "merchant": res.merchant,
        "direction": res.direction,
        "amount": res.amount,
        "amount_tiyin": tx_dict.get("amount_tiyin") if tx_dict else None,
        "amount_formatted": res.amount_formatted,
        "currency": res.currency,
        "card_last4": res.card_last4,
        "confidence_score": res.confidence_score,
        "is_internal_transfer": res.is_internal_transfer,
        "is_refund": res.is_refund,
        "related_transaction_id": res.related_transaction_id,
        "requires_user_review": res.requires_user_review,
        "ai_advisory_note": res.ai_advisory_note,
        "advisory": res.ai_advisory_note,
        "financial_impact": {
            "net_worth_impact": net_worth_impact
        },
        "transaction": tx_dict,
        "message": res.message
    }


@router.post("/simulate-push")
async def simulate_push(req: SimulatePushRequest):
    """
    Developer & Sandbox test harness for all 18 banking notification scenarios.
    """
    preset_data = SIMULATION_PRESETS.get(req.preset) if req.preset else None
    text = req.text or req.custom_text or (preset_data["text"] if preset_data else None)
    if not text:
        text = "Оплата картой 180 000 UZS в EVOS"
    pkg = req.package_name or req.custom_package or (preset_data["package"] if preset_data else None)
    if not pkg:
        pkg = "uz.click.app"

    ingest_req = IngestNotificationRequest(
        text=text,
        package_name=pkg,
        source="push",
        idempotency_key=f"sim_{int(datetime.now(timezone.utc).timestamp() * 1000)}"
    )
    return await ingest_notification(ingest_req)


@router.get("/")
async def list_transactions(
    direction: Optional[str] = None,
    category: Optional[str] = None,
    status: Optional[str] = None,
    limit: int = Query(20, le=100)
):
    results = mock_transactions_db
    if direction:
        results = [t for t in results if t.get("direction") == direction]
    if category:
        results = [t for t in results if t.get("category") == category]
    if status:
        results = [t for t in results if t.get("status") == status]
    return {"transactions": results[:limit], "total": len(results)}


@router.get("/review-queue")
async def get_review_queue():
    queue = [t for t in mock_transactions_db if t.get("status") == "needs_review"]
    return {"pending_reviews": queue, "count": len(queue)}


@router.patch("/{tx_id}/edit")
@router.put("/{tx_id}")
async def edit_transaction(tx_id: str, req: EditTransactionRequest):
    """
    Manual correction endpoint:
    Allows user to correct category, merchant, amount, type, date.
    Feeds correction into TransactionClassifier to improve future categorization.
    """
    for tx in mock_transactions_db:
        if tx["id"] == tx_id:
            if req.direction:
                tx["direction"] = req.direction
            if req.amount is not None:
                tx["amount"] = req.amount
                tx["amount_tiyin"] = int(req.amount * 100)
                curr = req.currency or tx.get("currency", "UZS")
                tx["amount_formatted"] = f"{int(req.amount):,} {curr}".replace(",", " ")
            if req.currency:
                tx["currency"] = req.currency
            if req.card_last4:
                tx["card_last4"] = req.card_last4
            if req.description:
                tx["description"] = req.description
            if req.occurred_at:
                tx["occurred_at"] = req.occurred_at.isoformat()

            # Record correction in merchant dictionary for continuous learning
            if req.merchant:
                tx["merchant"] = req.merchant
            if req.category:
                tx["category"] = req.category
                if tx.get("merchant"):
                    TransactionClassifier.record_correction(tx["merchant"], req.category)

            tx["status"] = "confirmed"
            tx["user_edited"] = True
            return {
                "status": "success",
                "message": "Транзакция успешно обновлена, классификатор запомнил изменение категории",
                "transaction": tx
            }

    raise HTTPException(status_code=404, detail="Транзакция не найдена")


@router.patch("/{tx_id}/review")
async def review_transaction(tx_id: str, req: ReviewActionRequest):
    for tx in mock_transactions_db:
        if tx["id"] == tx_id:
            if req.action == "confirm":
                tx["status"] = "confirmed"
            elif req.action == "ignore":
                tx["status"] = "ignored"
            elif req.action == "edit":
                if req.corrected_category:
                    tx["category"] = req.corrected_category
                if req.corrected_merchant:
                    tx["merchant"] = req.corrected_merchant
                if req.corrected_category and tx.get("merchant"):
                    TransactionClassifier.record_correction(tx["merchant"], req.corrected_category)
                tx["status"] = "confirmed"
            return {"status": "success", "transaction": tx}
    raise HTTPException(status_code=404, detail="Транзакция не найдена")


@router.get("/sources/status")
async def get_financial_sources_status():
    """Returns the live status of notification listening and ingestion toggles."""
    return {
        "status": "success",
        "settings": processing_service.settings
    }


@router.post("/sources/settings")
async def update_financial_sources_settings(req: FinancialSourceSettingsRequest):
    """Updates user preferences for automated financial notifications."""
    if req.listener_status:
        processing_service.settings["listener_status"] = req.listener_status
    if req.auto_detection_enabled is not None:
        processing_service.settings["auto_detection_enabled"] = req.auto_detection_enabled
    if req.ai_categorization_enabled is not None:
        processing_service.settings["ai_categorization_enabled"] = req.ai_categorization_enabled
    if req.auto_creation_enabled is not None:
        processing_service.settings["auto_creation_enabled"] = req.auto_creation_enabled

    return {
        "status": "success",
        "message": "Настройки источников финансовых данных успешно сохранены",
        "settings": processing_service.settings
    }
