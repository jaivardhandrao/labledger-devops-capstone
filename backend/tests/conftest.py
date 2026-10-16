"""Every test owns an in-memory DB; production URLs are never opened."""

import os
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

# This is set before importing the ASGI app. API tests also override get_db, so
# even a developer's externally configured production DATABASE_URL is ignored.
os.environ["DATABASE_URL"] = "sqlite+pysqlite://"

from app.database import Base, get_db  # noqa: E402
from app.main import create_app  # noqa: E402


@pytest.fixture
def test_engine():
    engine = create_engine(
        "sqlite+pysqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    Base.metadata.create_all(engine)
    yield engine
    Base.metadata.drop_all(engine)
    engine.dispose()


@pytest.fixture
def app(test_engine):
    application = create_app()

    def override_db() -> Generator[Session, None, None]:
        with Session(test_engine) as session:
            yield session

    application.dependency_overrides[get_db] = override_db
    yield application
    application.dependency_overrides.clear()


@pytest.fixture
def client(app):
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def loan_payload():
    return {
        "equipment": "Arduino Uno kit",
        "borrower": "Demo Student",
        "due_date": "2030-10-20",
        "status": "requested",
        "notes": "For the robotics workshop",
    }
