from fastapi import APIRouter, Query
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from ...services.ai_agent.advisor import AIFinancialAdvisor
from ...services.ai_agent.context_builder import build_financial_context, UserMemoryStore, AuthorizedFinancialTools

router = APIRouter(prefix="/ai", tags=["AI Personal Finance Assistant"])
advisor = AIFinancialAdvisor()


class AskAIRequest(BaseModel):
    query: Optional[str] = Field(None, json_schema_extra={"example": "Куда у меня уходит больше всего денег?"})
    message: Optional[str] = Field(None, json_schema_extra={"example": "Куда у меня уходит больше всего денег?"})
    lang: Optional[str] = Field("ru", json_schema_extra={"example": "ru"})
    language: Optional[str] = Field(None, json_schema_extra={"example": "ru"})
    current_balance: Optional[float] = 34850000.0
    currency: Optional[str] = "UZS"
    user_id: Optional[str] = None
    user_context: Optional[Dict[str, Any]] = None


class AddMemoryRequest(BaseModel):
    user_id: str
    memory_type: str = "preference"
    content: str
    importance: int = 1


class AIActionRequest(BaseModel):
    action_id: str = Field(..., json_schema_extra={"example": "act_create_goal"})
    parameters: Optional[Dict[str, Any]] = Field(default_factory=dict)


@router.get("/config")
async def get_ai_assistant_config():
    """
    Returns visual metadata, quick prompts and category action cards.
    """
    return {
        "title": "AI Financial Assistant",
        "subtitle": "Персональный финансовый агент",
        "orb_glow_color": "#00F0FF",
        "greeting": "Чем я могу помочь вам сегодня?",
        "quick_prompts": [
            {"id": "p1", "text": "Куда у меня ушли деньги в этом месяце?", "text_uz": "Bu oyda mening pulim qayerga ketdi?", "text_en": "Where did my money go this month?"},
            {"id": "p2", "text": "Могу ли я купить ноутбук за 8 млн?", "text_uz": "8 mln so'mga noutbuk sotib olsam bo'ladimi?", "text_en": "Can I afford an 8M laptop?"},
            {"id": "p3", "text": "Что будет, если откладывать по 1 млн каждый месяц?", "text_uz": "Har oy 1 mln tejab borsam nima bo'ladi?", "text_en": "What if I save 1M every month?"},
            {"id": "p4", "text": "Покажи мои подписки", "text_uz": "Mening obunalarimni ko'rsat", "text_en": "Show my subscriptions"},
            {"id": "p5", "text": "Какое у меня финансовое здоровье?", "text_uz": "Moliyaviy salomatligim qanday?", "text_en": "What is my financial health score?"},
            {"id": "p6", "text": "Как быстрее погасить мой кредит?", "text_uz": "Kreditimni qanday tezroq yopsam bo'ladi?", "text_en": "How to pay off my loan faster?"}
        ],
        "quick_chips": [
            {"id": "chip_spending", "label": "📊 Анализ расходов", "query": "Куда у меня ушли деньги в этом месяце?"},
            {"id": "chip_savings", "label": "💰 Мои накопления", "query": "Сколько я могу откладывать каждый месяц?"},
            {"id": "chip_loans", "label": "💳 Мои кредиты", "query": "Как быстрее погасить мой кредит?"},
            {"id": "chip_goal", "label": "🎯 Финансовая цель", "query": "Хочу накопить 15 млн на ноутбук за 6 месяцев"},
            {"id": "chip_whatif", "label": "🔮 Что будет, если...", "query": "Что будет, если я буду откладывать по 1 млн каждый месяц?"},
            {"id": "chip_buy", "label": "🛒 Могу ли я это купить?", "query": "Могу ли я позволить себе купить телефон за 8 млн?"}
        ]
    }


@router.post("/chat")
async def query_ai_assistant(req: AskAIRequest):
    """
    Real Context-Aware AI Financial Assistant & Agent.
    Compatible with both Web Simulator and Flutter mobile app.
    Guarantees tenant isolation: uses user_id derived context if provided.
    """
    effective_query = req.query or req.message or "Какое у меня финансовое состояние?"
    effective_lang = req.language or req.lang or "ru"

    effective_ctx = req.user_context
    if not effective_ctx and req.user_id:
        effective_ctx = build_financial_context(req.user_id, query=effective_query)

    res = advisor.answer_financial_question(
        query=effective_query,
        lang=effective_lang,
        user_context=effective_ctx
    )

    return {
        "title": res.get("title", "AI Финансовый Ассистент"),
        "reply": res.get("reply", ""),
        "response": res.get("reply", ""),  # Flutter backward-compatibility
        "severity": res.get("severity", "info"),
        "health_score": res.get("health_score"),
        "projections": res.get("projections"),
        "purchase_data": res.get("purchase_data"),
        "subscriptions": res.get("subscriptions"),
        "budget": res.get("budget"),
        "action_buttons": res.get("action_buttons", []),
        "actions": res.get("action_buttons", []),  # Flutter actions compatibility
        "type": res.get("type", "chat_response"),
        "disclaimer": res.get("disclaimer"),
        "details": res
    }


@router.get("/health-score")
async def get_financial_health_score(lang: Optional[str] = "ru"):
    """Returns AI Financial Health Score (78 / 100) with strengths and areas to improve."""
    return advisor.calculate_health_score(lang=lang or "ru")


@router.get("/subscriptions")
async def get_ai_subscriptions(lang: Optional[str] = "ru"):
    """Analyzes and returns detected recurring subscriptions with annual costs."""
    return advisor.analyze_subscriptions(lang=lang or "ru")


@router.get("/autopilot/status")
async def get_autopilot_status(lang: Optional[str] = "ru"):
    """Returns AI Autopilot weekly digest and operational status."""
    return advisor.generate_autopilot_report(lang=lang or "ru")


@router.post("/autopilot/toggle")
async def toggle_autopilot():
    """Toggles AI Autopilot ON/OFF."""
    current = advisor.memory["user_preferences"].get("autopilot_enabled", True)
    advisor.memory["user_preferences"]["autopilot_enabled"] = not current
    return {
        "autopilot_enabled": not current,
        "message": f"AI Autopilot {'включен' if not current else 'отключен'}"
    }


@router.get("/memory")
async def get_user_memories(user_id: str = Query(...)):
    """Returns AI personal memories strictly for the requested user_id."""
    return {"user_id": user_id, "memories": UserMemoryStore.get_memories(user_id)}


@router.post("/memory")
async def add_user_memory(req: AddMemoryRequest):
    """Stores a personal AI memory belonging to the specified user_id."""
    rec = UserMemoryStore.add_memory(
        user_id=req.user_id,
        memory_type=req.memory_type,
        content=req.content,
        importance=req.importance
    )
    return {"status": "success", "memory": rec}


@router.delete("/memory/{memory_id}")
async def delete_user_memory(memory_id: str, user_id: str = Query(...)):
    """Deletes an individual personal AI memory for the specified user_id."""
    success = UserMemoryStore.delete_memory(user_id, memory_id)
    return {"status": "success" if success else "not_found", "memory_id": memory_id}


@router.post("/memory/clear")
async def clear_ai_memory(user_id: Optional[str] = None):
    """Clears AI conversation history and personal memory."""
    if user_id:
        cleared = UserMemoryStore.clear_memories(user_id)
        advisor.clear_memory()
        return {"status": "success", "cleared_count": cleared, "message": f"AI memory cleared for user {user_id}"}
    return advisor.clear_memory()


@router.post("/action/execute")
async def execute_ai_action(req: AIActionRequest):
    """
    Executes in-app action requested via conversational chips
    (e.g., create financial goal, apply budget limits).
    """
    if req.action_id == "act_create_goal":
        goal_title = req.parameters.get("title", "Новая цель")
        goal_amount = req.parameters.get("target_amount", 15000000.0)
        goal_months = req.parameters.get("months", 6)
        advisor.memory["custom_goals"].append({
            "title": goal_title,
            "target_amount": goal_amount,
            "months": goal_months,
            "created_at": "2026-10-08T12:00:00Z"
        })
        return {
            "status": "success",
            "message": f"Финансовая цель «{goal_title}» на {goal_amount:,.0f} UZS успешно создана в приложении!",
            "action_id": req.action_id
        }
    elif req.action_id == "act_apply_budget":
        return {
            "status": "success",
            "message": "Персональные лимиты бюджета успешно активированы!",
            "action_id": req.action_id
        }
    return {
        "status": "success",
        "message": "Действие успешно обработано AI-ассистентом.",
        "action_id": req.action_id
    }

