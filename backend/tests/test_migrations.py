"""Real Alembic round-trip on a temporary SQLite DB, never production."""

from pathlib import Path

from alembic import command
from alembic.config import Config
from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from sqlalchemy import create_engine, inspect

from app.database import Base
from app.database import get_engine
from app.migrate import upgrade_schema


def test_migration_upgrade_matches_models_and_downgrades(tmp_path, monkeypatch):
    database_file = tmp_path / "migration-test.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{database_file}")
    backend = Path(__file__).resolve().parents[1]
    config = Config(str(backend / "alembic.ini"))
    command.upgrade(config, "head")
    command.upgrade(config, "head")  # A second rollout must be idempotent.
    engine = create_engine(f"sqlite:///{database_file}")
    assert "loans" in inspect(engine).get_table_names()
    assert {index["name"] for index in inspect(engine).get_indexes("loans")} == {
        "ix_loans_due_date", "ix_loans_status"
    }
    with engine.connect() as connection:
        assert compare_metadata(MigrationContext.configure(connection), Base.metadata) == []
    command.downgrade(config, "base")
    assert "loans" not in inspect(engine).get_table_names()
    engine.dispose()


def test_startup_migration_wrapper_is_idempotent(tmp_path, monkeypatch):
    database_file = tmp_path / "startup-test.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{database_file}")
    get_engine.cache_clear()
    try:
        upgrade_schema()
        upgrade_schema()
        assert "loans" in inspect(get_engine()).get_table_names()
    finally:
        get_engine().dispose()
        get_engine.cache_clear()
