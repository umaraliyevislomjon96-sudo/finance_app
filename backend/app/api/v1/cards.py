from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field, field_validator
from typing import List, Dict, Any

router = APIRouter(prefix="/cards", tags=["Cards Management"])

mock_cards_db: List[Dict[str, Any]] = [
    {
        "id": "card-1",
        "bank_name": "Kapitalbank",
        "card_name": "Main Debit",
        "card_type": "UZCARD",
        "first4": "8600",
        "last4": "4821",
        "currency": "UZS",
        "monthly_spending": 2380.0,
        "color_theme": "neon_blue",
        "is_active": True,
        "masked_number": "8600 •••• •••• 4821"
    },
    {
        "id": "card-2",
        "bank_name": "Uzum Bank",
        "card_name": "Online Shopping",
        "card_type": "HUMO",
        "first4": "9860",
        "last4": "1122",
        "currency": "UZS",
        "monthly_spending": 750.0,
        "color_theme": "cyan_glow",
        "is_active": True,
        "masked_number": "9860 •••• •••• 1122"
    }
]


class AddCardRequest(BaseModel):
    bank_name: str = Field(..., example="Kapitalbank")
    display_name: str = Field(..., example="Main Travel Card")
    card_type: str = Field("UZCARD", pattern="^(UZCARD|HUMO|VISA|MASTERCARD)$")
    first4: str = Field(..., min_length=4, max_length=4, example="8600")
    last4: str = Field(..., min_length=4, max_length=4, example="4821")
    currency: str = Field("UZS", example="UZS")
    color_theme: str = Field("cyan_glow")

    @field_validator("first4", "last4")
    @classmethod
    def digits_only(cls, v: str) -> str:
        if not v.isdigit():
            raise ValueError("Допустимы только 4 цифры")
        return v


@router.post("/", status_code=status.HTTP_201_CREATED)
async def add_card(req: AddCardRequest):
    card_id = f"card-{len(mock_cards_db) + 1}"
    new_card = {
        "id": card_id,
        "bank_name": req.bank_name,
        "card_name": req.display_name,
        "card_type": req.card_type,
        "first4": req.first4,
        "last4": req.last4,
        "currency": req.currency,
        "monthly_spending": 0.0,
        "color_theme": req.color_theme,
        "is_active": True,
        "masked_number": f"{req.first4} •••• •••• {req.last4}"
    }
    mock_cards_db.append(new_card)
    return {"status": "success", "card": new_card}


@router.get("/")
async def list_cards():
    return {"cards": mock_cards_db, "count": len(mock_cards_db)}


@router.delete("/{card_id}")
async def hide_card(card_id: str):
    for c in mock_cards_db:
        if c["id"] == card_id:
            c["is_active"] = False
            return {"status": "success", "message": "Карта скрыта из аналитики"}
    raise HTTPException(status_code=404, detail="Карта не найдена")
