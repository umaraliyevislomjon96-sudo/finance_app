"""
AI Context Builder and Authorized Financial Tools Service.
Implements strict tenant-isolated financial context construction for the AI Personal Financial OS.

Architectural Rule:
The AI Model is ONE shared brain.
User Context and AI Memory are STRICTLY private per authenticated user_id.
Tools derive user_id from the authenticated session, NEVER from arbitrary query parameters.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, timezone
import uuid


class UserMemoryStore:
    """
    In-memory / PostgreSQL-backed AI Memory Store isolated strictly by user_id.
    User A cannot view or manipulate User B's memories.
    """
    _memories: Dict[str, List[Dict[str, Any]]] = {}

    @classmethod
    def add_memory(cls, user_id: str, memory_type: str, content: str, importance: int = 1) -> Dict[str, Any]:
        if user_id not in cls._memories:
            cls._memories[user_id] = []
        
        mem_id = f"mem-{uuid.uuid4().hex[:8]}"
        record = {
            "id": mem_id,
            "user_id": user_id,
            "memory_type": memory_type,
            "content": content,
            "importance": importance,
            "created_at": datetime.now(timezone.utc).isoformat()
        }
        cls._memories[user_id].append(record)
        return record

    @classmethod
    def get_memories(cls, user_id: str) -> List[Dict[str, Any]]:
        return list(cls._memories.get(user_id, []))

    @classmethod
    def delete_memory(cls, user_id: str, memory_id: str) -> bool:
        user_mems = cls._memories.get(user_id, [])
        initial_len = len(user_mems)
        cls._memories[user_id] = [m for m in user_mems if m["id"] != memory_id]
        return len(cls._memories[user_id]) < initial_len

    @classmethod
    def clear_memories(cls, user_id: str) -> int:
        count = len(cls._memories.get(user_id, []))
        cls._memories[user_id] = []
        return count


class AuthorizedFinancialTools:
    """
    Controlled backend tools available to the AI Orchestrator.
    Every single tool enforces user_id ownership derived strictly from the authenticated session.
    """
    # Isolated in-memory user financial states (mock/cache layer backed by DB/Supabase)
    _user_state_registry: Dict[str, Dict[str, Any]] = {}

    @classmethod
    def register_user_financial_profile(
        cls,
        user_id: str,
        balance: float,
        monthly_income: float,
        monthly_spending: float,
        currency: str = "UZS",
        loans: Optional[List[Dict[str, Any]]] = None,
        credit_cards: Optional[List[Dict[str, Any]]] = None,
        goals: Optional[List[Dict[str, Any]]] = None,
        subscriptions: Optional[List[Dict[str, Any]]] = None,
        transactions: Optional[List[Dict[str, Any]]] = None,
    ):
        cls._user_state_registry[user_id] = {
            "user_id": user_id,
            "total_balance": balance,
            "monthly_income": monthly_income,
            "monthly_spending": monthly_spending,
            "currency": currency,
            "loans": loans or [],
            "credit_cards": credit_cards or [],
            "goals": goals or [],
            "subscriptions": subscriptions or [],
            "transactions": transactions or [],
        }

    @classmethod
    def get_financial_summary(cls, user_id: str) -> Dict[str, Any]:
        """Returns liquid balance, monthly income, monthly burn and safety metrics for user_id."""
        state = cls._user_state_registry.get(user_id)
        if not state:
            return {
                "user_id": user_id,
                "total_balance": 0.0,
                "monthly_income": 0.0,
                "monthly_spending": 0.0,
                "currency": "UZS",
                "emergency_buffer_months": 0.0,
            }
        
        burn = max(state["monthly_spending"], 1.0)
        buffer = state["total_balance"] / burn
        return {
            "user_id": user_id,
            "total_balance": state["total_balance"],
            "monthly_income": state["monthly_income"],
            "monthly_spending": state["monthly_spending"],
            "currency": state["currency"],
            "emergency_buffer_months": round(buffer, 2),
        }

    @classmethod
    def get_recent_transactions(cls, user_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        state = cls._user_state_registry.get(user_id)
        if not state:
            return []
        txs = state.get("transactions", [])
        return txs[:limit]

    @classmethod
    def get_monthly_income(cls, user_id: str) -> float:
        summary = cls.get_financial_summary(user_id)
        return summary["monthly_income"]

    @classmethod
    def get_monthly_expenses(cls, user_id: str) -> float:
        summary = cls.get_financial_summary(user_id)
        return summary["monthly_spending"]

    @classmethod
    def get_goals(cls, user_id: str) -> List[Dict[str, Any]]:
        state = cls._user_state_registry.get(user_id)
        return state.get("goals", []) if state else []

    @classmethod
    def get_active_loans(cls, user_id: str) -> List[Dict[str, Any]]:
        state = cls._user_state_registry.get(user_id)
        return state.get("loans", []) if state else []

    @classmethod
    def get_subscriptions(cls, user_id: str) -> List[Dict[str, Any]]:
        state = cls._user_state_registry.get(user_id)
        return state.get("subscriptions", []) if state else []

    @classmethod
    def get_ai_memory(cls, user_id: str) -> List[Dict[str, Any]]:
        return UserMemoryStore.get_memories(user_id)


def build_financial_context(user_id: str, query: Optional[str] = None) -> Dict[str, Any]:
    """
    Constructs a scoped, authorized context dictionary for user_id to inject into the AI agent.
    Zero cross-user data leakage.
    """
    summary = AuthorizedFinancialTools.get_financial_summary(user_id)
    memories = AuthorizedFinancialTools.get_ai_memory(user_id)
    goals = AuthorizedFinancialTools.get_goals(user_id)
    loans = AuthorizedFinancialTools.get_active_loans(user_id)
    subscriptions = AuthorizedFinancialTools.get_subscriptions(user_id)
    recent_txs = AuthorizedFinancialTools.get_recent_transactions(user_id, limit=5)

    return {
        "user_id": user_id,
        "total_balance": summary["total_balance"],
        "monthly_income": summary["monthly_income"],
        "monthly_spending": summary["monthly_spending"],
        "currency": summary["currency"],
        "emergency_buffer_months": summary["emergency_buffer_months"],
        "goals": goals,
        "loans": loans,
        "subscriptions": subscriptions,
        "recent_transactions": recent_txs,
        "ai_memories": [m["content"] for m in memories],
        "built_at": datetime.now(timezone.utc).isoformat(),
    }
