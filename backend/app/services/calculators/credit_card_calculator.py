from typing import Dict, Any


def calculate_credit_card_payoff(
    current_balance: float,
    credit_limit: float,
    annual_interest_rate: float,
    min_payment_percent: float = 5.0,
    min_payment_floor: float = 50000.0,
    target_monthly_payment: float = 0.0
) -> Dict[str, Any]:
    """
    Simulates credit card payoff duration and compares Minimum Payment vs Accelerated Strategy.
    """
    if current_balance <= 0 or credit_limit <= 0 or annual_interest_rate < 0:
        raise ValueError("Баланс задолженности, кредитный лимит и ставка должны быть положительными.")

    monthly_rate = (annual_interest_rate / 100.0) / 12.0
    utilization_rate = round((current_balance / credit_limit) * 100.0, 1)

    # 1. Simulate Minimum Payment Strategy
    balance_min = current_balance
    months_min = 0
    total_interest_min = 0.0
    max_months_safety = 360  # 30 years ceiling to prevent infinite loops

    while balance_min > 1.0 and months_min < max_months_safety:
        months_min += 1
        interest_charge = balance_min * monthly_rate
        total_interest_min += interest_charge
        balance_min += interest_charge

        # Min payment is percent of balance or floor
        min_pay = max(balance_min * (min_payment_percent / 100.0), min_payment_floor)
        if min_pay >= balance_min:
            min_pay = balance_min

        balance_min -= min_pay

    # 2. Simulate Target / Accelerated Payment Strategy
    # If target payment is not provided, test with +30% above initial minimum payment
    first_min_pay = max(current_balance * (min_payment_percent / 100.0), min_payment_floor)
    effective_target_pay = target_monthly_payment if target_monthly_payment > first_min_pay else first_min_pay * 1.5

    balance_acc = current_balance
    months_acc = 0
    total_interest_acc = 0.0

    while balance_acc > 1.0 and months_acc < max_months_safety:
        months_acc += 1
        interest_charge = balance_acc * monthly_rate
        total_interest_acc += interest_charge
        balance_acc += interest_charge

        pay = effective_target_pay
        if pay >= balance_acc:
            pay = balance_acc

        balance_acc -= pay

    interest_saved = max(0.0, total_interest_min - total_interest_acc)
    months_saved = max(0, months_min - months_acc)

    # Health status based on credit utilization
    if utilization_rate <= 30.0:
        utilization_status = "healthy"
        utilization_advice = "Отличная утилизация лимита (<30%). Кредитный рейтинг в безопасности."
    elif utilization_rate <= 60.0:
        utilization_status = "moderate"
        utilization_advice = "Умеренная нагрузка. Рекомендуется снизить задолженность до 30% от лимита."
    else:
        utilization_status = "high"
        utilization_advice = "Критическая нагрузка (>60%). Банки могут снизить скоринг. Погасите долг в приоритете."

    return {
        "current_balance": round(current_balance, 2),
        "credit_limit": round(credit_limit, 2),
        "utilization_rate": utilization_rate,
        "utilization_status": utilization_status,
        "utilization_advice": utilization_advice,
        "minimum_payment_plan": {
            "initial_monthly_payment": round(first_min_pay, 2),
            "months_to_payoff": months_min,
            "total_interest": round(total_interest_min, 2),
            "total_repayment": round(current_balance + total_interest_min, 2)
        },
        "accelerated_payment_plan": {
            "fixed_monthly_payment": round(effective_target_pay, 2),
            "months_to_payoff": months_acc,
            "total_interest": round(total_interest_acc, 2),
            "total_repayment": round(current_balance + total_interest_acc, 2)
        },
        "comparison": {
            "months_saved": months_saved,
            "interest_saved": round(interest_saved, 2),
            "savings_percent": round((interest_saved / (total_interest_min or 1.0)) * 100, 1)
        }
    }
