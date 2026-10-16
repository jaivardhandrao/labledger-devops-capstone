"""Create the equipment-loan ledger.

Revision ID: 0001
Revises: None
"""

from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "loans",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("equipment", sa.String(120), nullable=False),
        sa.Column("borrower", sa.String(120), nullable=False),
        sa.Column("due_date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("status IN ('requested', 'collected', 'returned')", name="ck_loans_status"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_loans_due_date", "loans", ["due_date"])
    op.create_index("ix_loans_status", "loans", ["status"])


def downgrade() -> None:
    op.drop_index("ix_loans_status", table_name="loans")
    op.drop_index("ix_loans_due_date", table_name="loans")
    op.drop_table("loans")
