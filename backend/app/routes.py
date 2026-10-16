"""Equipment loan lifecycle and dashboard aggregates."""

from datetime import datetime
import os
from typing import Annotated
from uuid import UUID
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Loan
from app.schemas import LoanRead, LoanStats, LoanStatus, LoanWrite

router = APIRouter(prefix="/api/loans", tags=["Equipment loans"])
Database = Annotated[Session, Depends(get_db)]


def find_loan(loan_id: UUID, db: Session) -> Loan:
    loan = db.get(Loan, str(loan_id))
    if loan is None:
        raise HTTPException(status_code=404, detail="Loan not found")
    return loan


@router.get("", response_model=list[LoanRead])
def list_loans(db: Database, status: LoanStatus | None = None) -> list[Loan]:
    query = select(Loan).order_by(Loan.created_at.desc(), Loan.id)
    if status is not None:
        query = query.where(Loan.status == status.value)
    return list(db.scalars(query))


# Static route must precede /{loan_id}, otherwise "stats" is parsed as a UUID.
@router.get("/stats", response_model=LoanStats)
def loan_stats(db: Database) -> LoanStats:
    today = datetime.now(ZoneInfo(os.getenv("BUSINESS_TIMEZONE", "Asia/Kolkata"))).date()
    total, active, overdue, returned = db.execute(
        select(
            func.count(Loan.id),
            func.coalesce(func.sum(case((Loan.status != "returned", 1), else_=0)), 0),
            func.coalesce(
                func.sum(case(((Loan.status == "collected") & (Loan.due_date < today), 1), else_=0)),
                0,
            ),
            func.coalesce(func.sum(case((Loan.status == "returned", 1), else_=0)), 0),
        )
    ).one()
    return LoanStats(total=total, active=active, overdue=overdue, returned=returned)


@router.post("", response_model=LoanRead, status_code=status.HTTP_201_CREATED)
def create_loan(payload: LoanWrite, db: Database, response: Response) -> Loan:
    values = payload.model_dump()
    values["status"] = payload.status.value
    loan = Loan(**values)
    db.add(loan)
    db.commit()
    db.refresh(loan)
    response.headers["Location"] = f"/api/loans/{loan.id}"
    return loan


@router.get("/{loan_id}", response_model=LoanRead)
def get_loan(loan_id: UUID, db: Database) -> Loan:
    return find_loan(loan_id, db)


@router.put("/{loan_id}", response_model=LoanRead)
def update_loan(loan_id: UUID, payload: LoanWrite, db: Database) -> Loan:
    loan = find_loan(loan_id, db)
    for key, value in payload.model_dump().items():
        setattr(loan, key, value.value if isinstance(value, LoanStatus) else value)
    db.commit()
    db.refresh(loan)
    return loan


@router.delete("/{loan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_loan(loan_id: UUID, db: Database) -> Response:
    loan = find_loan(loan_id, db)
    db.delete(loan)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
