"""Strict API inputs and public response models."""

from datetime import date, datetime, timezone
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field, field_validator


class LoanStatus(str, Enum):
    requested = "requested"
    collected = "collected"
    returned = "returned"


class LoanWrite(BaseModel):
    model_config = ConfigDict(extra="forbid")

    equipment: str = Field(min_length=1, max_length=120)
    borrower: str = Field(min_length=1, max_length=120)
    due_date: date
    status: LoanStatus = LoanStatus.requested
    notes: str = Field(default="", max_length=2000)

    @field_validator("equipment", "borrower", mode="before")
    @classmethod
    def trim_name(cls, value: object) -> object:
        return value.strip() if isinstance(value, str) else value


class LoanRead(LoanWrite):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: str
    created_at: datetime

    @field_validator("created_at")
    @classmethod
    def ensure_utc_timestamp(cls, value: datetime) -> datetime:
        # PostgreSQL returns aware datetimes; SQLite drops timezone metadata.
        return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value


class LoanStats(BaseModel):
    total: int
    active: int
    overdue: int
    returned: int
