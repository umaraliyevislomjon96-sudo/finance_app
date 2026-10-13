import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.calculators.loan_calculator import calculate_loan
from app.services.calculators.credit_card_calculator import calculate_credit_card_payoff
from app.services.ai_agent.advisor import AIFinancialAdvisor

client = TestClient(app)


def test_loan_calculator_annuity():
    """
    Validates Annuity loan amortization:
    Principal: 10,000,000 UZS, Rate: 24%, Term: 12 months.
    """
    res = calculate_loan(
        principal_amount=10000000.0,
        annual_interest_rate=24.0,
        term_months=12,
        payment_type="annuity"
    )
    assert res["payment_type"] == "annuity"
    assert res["monthly_payment"] > 0
    assert res["total_interest"] > 0
    assert res["total_payment"] == round(10000000.0 + res["total_interest"], 2)
    assert len(res["schedule"]) == 12


def test_loan_calculator_differential():
    """
    Validates Differential loan amortization:
    First month payment is highest, last month payment is lowest.
    """
    res = calculate_loan(
        principal_amount=12000000.0,
        annual_interest_rate=20.0,
        term_months=12,
        payment_type="differential"
    )
    assert res["payment_type"] == "differential"
    assert res["first_month_payment"] > res["last_month_payment"]
    assert res["total_interest"] > 0
    assert len(res["schedule"]) == 12


def test_credit_card_payoff_calculator():
    """
    Validates Credit Card Payoff simulation:
    Compares minimum payment trap against accelerated strategy.
    """
    res = calculate_credit_card_payoff(
        current_balance=5000000.0,
        credit_limit=10000000.0,
        annual_interest_rate=28.0,
        min_payment_percent=5.0
    )
    assert res["utilization_rate"] == 50.0
    assert res["utilization_status"] == "moderate"
    assert res["minimum_payment_plan"]["months_to_payoff"] > res["accelerated_payment_plan"]["months_to_payoff"]
    assert res["comparison"]["interest_saved"] > 0


def test_calculators_api_endpoints():
    """
    Validates FastAPI endpoints for /calculators/loan and /calculators/credit-card.
    """
    # Loan API
    res_loan = client.post(
        "/api/v1/calculators/loan",
        json={
            "principal_amount": 25000000.0,
            "annual_interest_rate": 22.0,
            "term_months": 24,
            "payment_type": "annuity"
        }
    )
    assert res_loan.status_code == 200
    data_loan = res_loan.json()
    assert data_loan["status"] == "success"
    assert data_loan["result"]["monthly_payment"] > 0

    # Credit Card API
    res_card = client.post(
        "/api/v1/calculators/credit-card",
        json={
            "current_balance": 3000000.0,
            "credit_limit": 8000000.0,
            "annual_interest_rate": 26.0,
            "min_payment_percent": 5.0
        }
    )
    assert res_card.status_code == 200
    data_card = res_card.json()
    assert data_card["status"] == "success"
    assert "minimum_payment_plan" in data_card["result"]


def test_oauth_social_sign_in():
    """
    Validates OAuth social login for Google, Apple ID, and GitHub.
    """
    for provider in ["google", "apple", "github"]:
        res = client.post(
            "/api/v1/auth/oauth/sign-in",
            json={
                "provider": provider,
                "token_or_code": f"mock-{provider}-token-xyz",
                "email": f"user@{provider}.com",
                "name": f"Test {provider.capitalize()} User",
                "device_id": f"device-{provider}-01",
                "device_name": f"{provider.capitalize()} Phone"
            }
        )
        assert res.status_code == 200
        data = res.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert provider in data["user_id"]


def test_ai_financial_advisor_multilingual_context():
    """
    Validates that the AI advisor responds accurately in RU, UZ, and EN
    grounded in user's real transactions and balance.
    """
    advisor = AIFinancialAdvisor()

    # Question in Russian
    res_ru = advisor.answer_financial_question(query="Куда у меня уходит больше всего денег?", lang="ru")
    assert "Food & Dining" in res_ru["category_highlight"]
    assert "Korzinka" in res_ru["reply"]

    # Question in Uzbek
    res_uz = advisor.answer_financial_question(query="Mening eng ko'p pulim qayerga ketyapti?", lang="uz")
    assert "Korzinka" in res_uz["reply"]

    # Question in English
    res_en = advisor.answer_financial_question(query="Where does most of my money go?", lang="en")
    assert "Food & Dining" in res_en["reply"]
    assert "Korzinka" in res_en["reply"]

    # Question about savings
    res_save = advisor.answer_financial_question(query="Сколько я могу откладывать в месяц?", lang="ru")
    assert res_save["recommended_monthly_saving"] > 0
