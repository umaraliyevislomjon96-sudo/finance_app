import pytest
from app.services.ai_agent.advisor import AIFinancialAdvisor


def test_affordability_safe():
    advisor = AIFinancialAdvisor()
    resp = advisor.analyze_affordability(
        item_cost=700.0,
        currency="USD",
        current_balance=12480.0,
        avg_daily_burn=80.0,
        days_left_in_month=15,
        upcoming_obligations=1500.0,
    )
    assert "доступна" in resp.title
    assert resp.severity == "info"
    assert resp.impact_amount == 700.0


def test_affordability_risk():
    advisor = AIFinancialAdvisor()
    resp = advisor.analyze_affordability(
        item_cost=4000.0,
        currency="USD",
        current_balance=5000.0,
        avg_daily_burn=100.0,
        days_left_in_month=15,
        upcoming_obligations=1500.0,
    )
    assert "Риск" in resp.title
    assert resp.severity == "warning"


def test_category_anomaly_spike():
    advisor = AIFinancialAdvisor()
    resp = advisor.detect_category_anomalies(
        category_name="Такси",
        current_month_spent=450000.0,
        prev_month_spent=300000.0,
        currency="UZS"
    )
    assert resp is not None
    assert "выросли на 50%" in resp.title
    assert resp.severity == "warning"


def test_ai_health_score_calculation():
    advisor = AIFinancialAdvisor()
    hs = advisor.calculate_health_score(lang="ru")
    assert hs["score"] == 78
    assert len(hs["strengths"]) >= 2
    assert len(hs["improvements"]) >= 1
    assert "78" in hs["summary"]


def test_ai_what_if_simulator():
    advisor = AIFinancialAdvisor()
    sim = advisor.simulate_what_if(monthly_delta=1000000.0, scenario_type="save_monthly", lang="ru")
    assert len(sim["projections"]) == 4
    assert sim["projections"][0]["amount"] == 3000000.0   # 3 months
    assert sim["projections"][1]["amount"] == 6000000.0   # 6 months
    assert sim["projections"][2]["amount"] == 12000000.0  # 12 months
    assert sim["projections"][3]["amount"] == 24000000.0  # 24 months


def test_ai_purchase_evaluator():
    advisor = AIFinancialAdvisor()
    p = advisor.evaluate_purchase(item_cost=8000000.0, item_name="телефон", lang="ru")
    assert p["is_safe"] is True
    assert p["buffer_before"] > p["buffer_after"]
    assert "Покупка возможна" in p["reply"]


def test_ai_goals_and_subscriptions():
    advisor = AIFinancialAdvisor()
    g = advisor.calculate_goal_plan(target_amount=15000000.0, months=6, item_name="ноутбук")
    assert g["required_monthly"] == 2500000.0
    assert "ноутбук" in g["reply"]

    subs = advisor.analyze_subscriptions(lang="ru")
    assert len(subs["subscriptions"]) >= 3
    assert subs["total_annual"] > 0


def test_ai_memory_and_autopilot():
    advisor = AIFinancialAdvisor()
    auto = advisor.generate_autopilot_report(lang="ru")
    assert auto["autopilot_enabled"] is True
    assert "Autopilot" in auto["title"]

    advisor.memory["conversation_history"].append({"query": "тест"})
    clear_res = advisor.clear_memory()
    assert clear_res["status"] == "success"
    assert len(advisor.memory["conversation_history"]) == 0

