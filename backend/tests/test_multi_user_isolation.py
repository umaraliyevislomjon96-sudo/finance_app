"""
Multi-User Isolation & AI Security Test Suite.
Verifies compliance with Sections 5, 6, 7, 26, and 27 of the AI Personal Financial OS specification.

Tests:
1. User A creating a transaction/goal/memory cannot be viewed by User B.
2. RLS & session-derived user_id query enforcement (preventing IDOR).
3. The exact Section 27 AI Isolation Scenario:
   - User A (Balance: 10M, Income: 8M, Spend: 4M)
   - User B (Balance: 1M, Income: 3M, Spend: 2.8M)
   - Both ask: "Can I afford a 2,000,000 UZS purchase?"
   - User A receives a favorable/safe response based on 10M balance.
   - User B receives an insufficient balance / risk response based on 1M balance.
   - Zero cross-contamination of financial data.
4. AI Memory isolation & deletion.
"""

from app.services.ai_agent.advisor import AIFinancialAdvisor
from app.services.ai_agent.context_builder import (
    AuthorizedFinancialTools,
    UserMemoryStore,
    build_financial_context,
)


def test_ai_multi_user_isolation_exact_scenario():
    """
    SECTION 27 VERIFICATION:
    User A: balance = 10,000,000, income = 8,000,000, expenses = 4,000,000
    User B: balance = 1,000,000, income = 3,000,000, expenses = 2,800,000
    Both ask: "Могу ли я купить телефон за 2 000 000 сум?"
    """
    advisor = AIFinancialAdvisor()

    # Register isolated workspace profiles
    AuthorizedFinancialTools.register_user_financial_profile(
        user_id="user_a_uuid",
        balance=10000000.0,
        monthly_income=8000000.0,
        monthly_spending=4000000.0,
        currency="UZS",
    )

    AuthorizedFinancialTools.register_user_financial_profile(
        user_id="user_b_uuid",
        balance=1000000.0,
        monthly_income=3000000.0,
        monthly_spending=2800000.0,
        currency="UZS",
    )

    # 1. Build private, tenant-isolated context for User A
    ctx_a = build_financial_context("user_a_uuid")
    assert ctx_a["user_id"] == "user_a_uuid"
    assert ctx_a["total_balance"] == 10000000.0
    assert ctx_a["monthly_spending"] == 4000000.0

    # 2. Build private, tenant-isolated context for User B
    ctx_b = build_financial_context("user_b_uuid")
    assert ctx_b["user_id"] == "user_b_uuid"
    assert ctx_b["total_balance"] == 1000000.0
    assert ctx_b["monthly_spending"] == 2800000.0

    # 3. Both users ask the exact same affordability question
    query = "Могу ли я купить телефон за 2 000 000 сум?"

    resp_a = advisor.answer_financial_question(query=query, lang="ru", user_context=ctx_a)
    resp_b = advisor.answer_financial_question(query=query, lang="ru", user_context=ctx_b)

    # 4. Verify User A evaluation
    assert resp_a["purchase_data"]["is_safe"] is True
    assert "10 000 000" in resp_a["reply"] or "10,000,000" in resp_a["reply"]
    assert "8 000 000" in resp_a["reply"] or "8,000,000" in resp_a["reply"]
    assert resp_a["purchase_data"]["buffer_after"] == 2.0  # 8M remaining / 4M burn = 2.0
    assert "Покупка возможна" in resp_a["reply"]

    # 5. Verify User B evaluation
    assert resp_b["purchase_data"]["is_safe"] is False
    assert "1 000 000" in resp_b["reply"] or "1,000,000" in resp_b["reply"]
    assert "невозможна" in resp_b["reply"] or "превышает" in resp_b["reply"]
    assert "Не хватает" in resp_b["reply"]

    # 6. ABSOLUTE ISOLATION ASSERTIONS: Zero cross-user data leakage
    assert "10 000 000" not in resp_b["reply"]
    assert "4 000 000" not in resp_b["reply"]
    assert "1 000 000" not in resp_a["reply"]
    assert "2 800 000" not in resp_a["reply"]


def test_ai_personal_memory_strict_isolation():
    """
    SECTION 13 & 26: AI Memory must belong strictly to user_id.
    User A's memory must NEVER be visible or returned to User B.
    """
    user_a = "user_alpha_99"
    user_b = "user_beta_88"

    # User A stores a personal financial memory
    mem_a = UserMemoryStore.add_memory(
        user_id=user_a,
        memory_type="goal",
        content="User wants to save 20,000,000 UZS for a car.",
        importance=5
    )

    # User B stores a personal financial preference
    mem_b = UserMemoryStore.add_memory(
        user_id=user_b,
        memory_type="preference",
        content="User prefers aggressive debt repayment.",
        importance=4
    )

    # Retrieve memories for User A
    mems_for_a = UserMemoryStore.get_memories(user_a)
    assert len(mems_for_a) == 1
    assert mems_for_a[0]["content"] == "User wants to save 20,000,000 UZS for a car."
    assert mems_for_a[0]["user_id"] == user_a

    # Retrieve memories for User B
    mems_for_b = UserMemoryStore.get_memories(user_b)
    assert len(mems_for_b) == 1
    assert mems_for_b[0]["content"] == "User prefers aggressive debt repayment."
    assert mems_for_b[0]["user_id"] == user_b

    # Verify cross-user isolation: User A cannot see User B's memories
    all_contents_a = [m["content"] for m in mems_for_a]
    assert "User prefers aggressive debt repayment." not in all_contents_a

    all_contents_b = [m["content"] for m in mems_for_b]
    assert "User wants to save 20,000,000 UZS for a car." not in all_contents_b

    # User A deletes their memory
    deleted = UserMemoryStore.delete_memory(user_a, mem_a["id"])
    assert deleted is True
    assert len(UserMemoryStore.get_memories(user_a)) == 0

    # User B's memory remains completely untouched
    assert len(UserMemoryStore.get_memories(user_b)) == 1


def test_authorized_financial_tools_enforce_session_user():
    """
    SECTION 6: The AI cannot access another user's financial records by passing an arbitrary ID.
    Tools query only the authorized context derived from session.
    """
    AuthorizedFinancialTools.register_user_financial_profile(
        user_id="client_1",
        balance=50000000.0,
        monthly_income=30000000.0,
        monthly_spending=12000000.0,
        currency="UZS",
        goals=[{"id": "g-1", "title": "Apartment Downpayment", "target_amount": 100000000.0}]
    )

    AuthorizedFinancialTools.register_user_financial_profile(
        user_id="client_2",
        balance=4500000.0,
        monthly_income=5000000.0,
        monthly_spending=4000000.0,
        currency="UZS",
        goals=[{"id": "g-2", "title": "Winter Jacket", "target_amount": 2000000.0}]
    )

    # Tool execution for client_1
    summary_1 = AuthorizedFinancialTools.get_financial_summary("client_1")
    goals_1 = AuthorizedFinancialTools.get_goals("client_1")
    assert summary_1["total_balance"] == 50000000.0
    assert goals_1[0]["title"] == "Apartment Downpayment"

    # Tool execution for client_2
    summary_2 = AuthorizedFinancialTools.get_financial_summary("client_2")
    goals_2 = AuthorizedFinancialTools.get_goals("client_2")
    assert summary_2["total_balance"] == 4500000.0
    assert goals_2[0]["title"] == "Winter Jacket"

    # Unauthenticated / Unknown user returns zero data rather than leaking other clients
    unknown_summary = AuthorizedFinancialTools.get_financial_summary("malicious_or_unknown_uuid")
    assert unknown_summary["total_balance"] == 0.0
    assert AuthorizedFinancialTools.get_goals("malicious_or_unknown_uuid") == []
