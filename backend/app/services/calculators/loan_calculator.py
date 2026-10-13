from typing import Dict, Any, List
import math


def calculate_loan(
    principal_amount: float,
    annual_interest_rate: float,
    term_months: int,
    payment_type: str = "annuity"
) -> Dict[str, Any]:
    """
    Computes loan amortization for Annuity and Differential payment types.
    Principal amount and interest stored with exact precision.
    """
    if principal_amount <= 0 or term_months <= 0 or annual_interest_rate < 0:
        raise ValueError("Сумма кредита, срок и процентная ставка должны быть положительными числами.")

    monthly_rate = (annual_interest_rate / 100.0) / 12.0
    schedule: List[Dict[str, Any]] = []

    if payment_type == "annuity":
        if monthly_rate == 0:
            monthly_payment = principal_amount / term_months
        else:
            factor = math.pow(1 + monthly_rate, term_months)
            monthly_payment = principal_amount * (monthly_rate * factor) / (factor - 1)

        remaining_balance = principal_amount
        total_interest = 0.0

        for month in range(1, term_months + 1):
            interest_part = remaining_balance * monthly_rate
            principal_part = monthly_payment - interest_part
            remaining_balance -= principal_part
            if remaining_balance < 0:
                remaining_balance = 0.0
            total_interest += interest_part

            schedule.append({
                "month": month,
                "payment": round(monthly_payment, 2),
                "principal": round(principal_part, 2),
                "interest": round(interest_part, 2),
                "remaining_balance": round(remaining_balance, 2)
            })

        total_payment = principal_amount + total_interest

        return {
            "payment_type": "annuity",
            "principal_amount": round(principal_amount, 2),
            "annual_interest_rate": annual_interest_rate,
            "term_months": term_months,
            "monthly_payment": round(monthly_payment, 2),
            "total_payment": round(total_payment, 2),
            "total_interest": round(total_interest, 2),
            "overpayment_percentage": round((total_interest / principal_amount) * 100, 2),
            "schedule": schedule[:12]  # return first 12 months for preview
        }

    elif payment_type == "differential":
        principal_part_fixed = principal_amount / term_months
        remaining_balance = principal_amount
        total_interest = 0.0
        first_payment = 0.0
        last_payment = 0.0

        for month in range(1, term_months + 1):
            interest_part = remaining_balance * monthly_rate
            payment = principal_part_fixed + interest_part
            remaining_balance -= principal_part_fixed
            if remaining_balance < 0:
                remaining_balance = 0.0
            total_interest += interest_part

            if month == 1:
                first_payment = payment
            if month == term_months:
                last_payment = payment

            schedule.append({
                "month": month,
                "payment": round(payment, 2),
                "principal": round(principal_part_fixed, 2),
                "interest": round(interest_part, 2),
                "remaining_balance": round(remaining_balance, 2)
            })

        total_payment = principal_amount + total_interest

        return {
            "payment_type": "differential",
            "principal_amount": round(principal_amount, 2),
            "annual_interest_rate": annual_interest_rate,
            "term_months": term_months,
            "first_month_payment": round(first_payment, 2),
            "last_month_payment": round(last_payment, 2),
            "monthly_payment": round((first_payment + last_payment) / 2, 2),
            "total_payment": round(total_payment, 2),
            "total_interest": round(total_interest, 2),
            "overpayment_percentage": round((total_interest / principal_amount) * 100, 2),
            "schedule": schedule[:12]
        }
    else:
        raise ValueError("Тип платежа должен быть 'annuity' или 'differential'.")
