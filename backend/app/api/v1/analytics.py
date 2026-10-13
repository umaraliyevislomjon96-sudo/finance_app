from fastapi import APIRouter
from pydantic import BaseModel, Field
from typing import Dict, Any, List

router = APIRouter(prefix="/analytics", tags=["Financial Analytics & Cashflow"])

mock_obligations_db: List[Dict[str, Any]] = [
    {
        "id": "obl-1",
        "title": "Rent (Квартира)",
        "amount": 1500.0,
        "due_date": "Sep 30",
        "category": "rent",
        "icon": "home",
        "frequency": "monthly",
        "status": "pending",
        "days_left": 5
    },
    {
        "id": "obl-2",
        "title": "Автокредит",
        "amount": 380.0,
        "due_date": "Oct 12",
        "category": "loan",
        "icon": "directions_car",
        "frequency": "monthly",
        "status": "pending",
        "days_left": 17
    },
    {
        "id": "obl-3",
        "title": "Netflix Premium",
        "amount": 14.99,
        "due_date": "Oct 05",
        "category": "subscription",
        "icon": "subscriptions",
        "frequency": "monthly",
        "status": "auto_pay",
        "days_left": 10
    },
    {
        "id": "obl-4",
        "title": "Telegram Premium",
        "amount": 3.99,
        "due_date": "Oct 18",
        "category": "subscription",
        "icon": "telegram",
        "frequency": "monthly",
        "status": "auto_pay",
        "days_left": 23
    }
]

class AddObligationRequest(BaseModel):
    title: str = Field(..., example="Коммунальные услуги")
    amount: float = Field(..., example=65.0)
    due_date: str = Field(..., example="Oct 10")
    category: str = Field("utilities", example="utilities")


@router.get("/dashboard-summary")
async def get_dashboard_summary():
    """
    Supplies the primary metrics powering the Home Dashboard screen.
    Direct 1:1 match with the design system mockup.
    """
    return {
        "user_greeting": "Good evening, Alex",
        "total_balance": 12480.0,
        "currency_symbol": "$",
        "currency_code": "USD",
        "balance_change_percentage": 12.0,
        "balance_change_direction": "up",
        "balance_change_label": "from last month",
        "sparkline_trend": [10800, 11100, 11450, 11200, 11900, 12200, 12480],
        "metric_cards": [
            {
                "id": "income",
                "label": "Income",
                "amount": 4200.0,
                "direction": "up",
                "accent_color": "#22C55E",
                "icon_type": "arrow_up_circle"
            },
            {
                "id": "spending",
                "label": "Spending",
                "amount": 2380.0,
                "direction": "down",
                "accent_color": "#F05252",
                "icon_type": "arrow_down_circle"
            },
            {
                "id": "savings",
                "label": "Savings",
                "amount": 1250.0,
                "direction": "up",
                "accent_color": "#818CF8",
                "icon_type": "arrow_up_circle"
            }
        ],
        "active_ai_insight": {
            "id": "ins-food-1",
            "tag": "AI Insight",
            "title": "Your food spending is lower than last month.",
            "type": "positive_anomaly",
            "impact_amount": 140.0,
            "currency": "$"
        },
        "upcoming_bills": mock_obligations_db[:2]
    }


@router.get("/categories")
async def get_category_analytics():
    return {
        "total_spending": 2380.0,
        "categories": [
            {
                "name": "Жильё и Аренда",
                "amount": 1500.0,
                "percentage": 63.0,
                "color": "#2F80FF",
                "icon": "🏠"
            },
            {
                "name": "Еда и Рестораны",
                "amount": 420.0,
                "percentage": 17.6,
                "color": "#18D5FF",
                "icon": "🍔"
            },
            {
                "name": "Транспорт и Такси",
                "amount": 210.0,
                "percentage": 8.8,
                "color": "#F59E0B",
                "icon": "🚕"
            },
            {
                "name": "Подписки и Сервисы",
                "amount": 140.0,
                "percentage": 5.9,
                "color": "#A855F7",
                "icon": "⚡"
            },
            {
                "name": "Прочее",
                "amount": 110.0,
                "percentage": 4.7,
                "color": "#64748B",
                "icon": "🛍️"
            }
        ],
        "top_merchants": [
            {"merchant": "Korzinka Supermarket", "amount": 280.0, "count": 6},
            {"merchant": "Yandex Go", "amount": 165.0, "count": 14},
            {"merchant": "Makro", "amount": 140.0, "count": 3},
            {"merchant": "EVOS", "amount": 85.0, "count": 4}
        ]
    }


@router.get("/obligations")
async def list_obligations():
    total_due = sum(o["amount"] for o in mock_obligations_db if o["status"] != "paid")
    return {
        "obligations": mock_obligations_db,
        "total_due": total_due,
        "count": len(mock_obligations_db)
    }


@router.post("/obligations")
async def add_obligation(req: AddObligationRequest):
    new_obl = {
        "id": f"obl-{len(mock_obligations_db) + 1}",
        "title": req.title,
        "amount": req.amount,
        "due_date": req.due_date,
        "category": req.category,
        "icon": "receipt_long",
        "frequency": "monthly",
        "status": "pending",
        "days_left": 15
    }
    mock_obligations_db.append(new_obl)
    return {"status": "success", "obligation": new_obl}
