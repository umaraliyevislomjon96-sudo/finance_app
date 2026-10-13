from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional
from ...services.calculators.loan_calculator import calculate_loan
from ...services.calculators.credit_card_calculator import calculate_credit_card_payoff

router = APIRouter(prefix="/calculators", tags=["Financial Calculators"])


class LoanCalculateRequest(BaseModel):
    principal_amount: float = Field(..., gt=0, description="Сумма кредита")
    annual_interest_rate: float = Field(..., ge=0, description="Годовая процентная ставка в %")
    term_months: int = Field(..., gt=0, le=360, description="Срок кредита в месяцах")
    payment_type: str = Field("annuity", description="'annuity' или 'differential'")


class CreditCardPayoffRequest(BaseModel):
    current_balance: float = Field(..., gt=0, description="Текущая сумма долга")
    credit_limit: float = Field(..., gt=0, description="Общий кредитный лимит")
    annual_interest_rate: float = Field(..., ge=0, description="Процентная ставка (APR) в %")
    min_payment_percent: float = Field(5.0, ge=1.0, le=50.0, description="Минимальный платеж в %")
    target_monthly_payment: Optional[float] = Field(0.0, ge=0.0, description="Желаемый фиксированный ежемесячный платеж")


@router.post("/loan")
async def get_loan_calculation(req: LoanCalculateRequest):
    """
    Рассчитывает ежемесячный платеж, переплату и график амортизации кредита.
    """
    try:
        res = calculate_loan(
            principal_amount=req.principal_amount,
            annual_interest_rate=req.annual_interest_rate,
            term_months=req.term_months,
            payment_type=req.payment_type
        )
        return {"status": "success", "result": res}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/credit-card")
async def get_credit_card_calculation(req: CreditCardPayoffRequest):
    """
    Рассчитывает стратегию погашения кредитной карты (минимальный платеж vs ускоренный план).
    """
    try:
        res = calculate_credit_card_payoff(
            current_balance=req.current_balance,
            credit_limit=req.credit_limit,
            annual_interest_rate=req.annual_interest_rate,
            min_payment_percent=req.min_payment_percent,
            target_monthly_payment=req.target_monthly_payment or 0.0
        )
        return {"status": "success", "result": res}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
