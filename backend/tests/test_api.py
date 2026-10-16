"""API behavior, database persistence, validation and operational guarantees."""

from datetime import datetime, timedelta
from uuid import UUID, uuid4
from zoneinfo import ZoneInfo

import pytest
from sqlalchemy import select
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Loan


def create(client, payload):
    response = client.post("/api/loans", json=payload)
    assert response.status_code == 201, response.text
    return response.json()


def test_health_has_service_identity(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "labledger-api"}


def test_ready_checks_database(client):
    assert client.get("/ready").json() == {"status": "ready", "database": "reachable"}


def test_readiness_failure_is_503_without_leaking_connection_details(client, app):
    class UnavailableDatabase:
        def execute(self, statement):
            raise OperationalError("sensitive-database-host", None, Exception("sensitive-password"))

    app.dependency_overrides[get_db] = lambda: UnavailableDatabase()
    response = client.get("/ready")
    assert response.status_code == 503
    assert response.json() == {"status": "not_ready", "database": "unreachable"}
    assert "sensitive" not in response.text
    # A database outage should not trigger a liveness restart loop.
    assert client.get("/health").status_code == 200


def test_empty_collection(client):
    assert client.get("/api/loans").json() == []


def test_create_returns_location_uuid_and_utc_timestamp(client, loan_payload):
    response = client.post("/api/loans", json=loan_payload)
    data = response.json()
    assert response.status_code == 201
    assert response.headers["Location"] == f"/api/loans/{data['id']}"
    assert UUID(data["id"]).version == 4
    assert datetime.fromisoformat(data["created_at"].replace("Z", "+00:00")).utcoffset() == timedelta(0)
    assert {key: data[key] for key in loan_payload} == loan_payload


def test_created_item_is_persisted_in_an_independent_session(client, loan_payload, test_engine):
    created = create(client, loan_payload)
    with Session(test_engine) as independent_session:
        row = independent_session.scalar(select(Loan).where(Loan.id == created["id"]))
        assert row is not None
        assert row.equipment == loan_payload["equipment"]
        assert row.due_date.isoformat() == loan_payload["due_date"]


def test_get_item(client, loan_payload):
    created = create(client, loan_payload)
    assert client.get(f"/api/loans/{created['id']}").json() == created


def test_collection_contains_created_items(client, loan_payload):
    first = create(client, loan_payload)
    second = create(client, {**loan_payload, "equipment": "Raspberry Pi 5"})
    rows = client.get("/api/loans").json()
    assert {row["id"] for row in rows} == {first["id"], second["id"]}
    assert rows[0]["id"] == second["id"]


def test_update_replaces_values_and_preserves_identity(client, loan_payload):
    original = create(client, loan_payload)
    replacement = {**loan_payload, "equipment": "Digital multimeter", "status": "collected"}
    response = client.put(f"/api/loans/{original['id']}", json=replacement)
    assert response.status_code == 200
    assert response.json()["equipment"] == "Digital multimeter"
    assert response.json()["status"] == "collected"
    assert response.json()["created_at"] == original["created_at"]
    assert client.get(f"/api/loans/{original['id']}").json() == response.json()


def test_delete_removes_row_and_returns_no_body(client, loan_payload, test_engine):
    original = create(client, loan_payload)
    response = client.delete(f"/api/loans/{original['id']}")
    assert response.status_code == 204
    assert response.content == b""
    assert client.get(f"/api/loans/{original['id']}").status_code == 404
    with Session(test_engine) as session:
        assert session.get(Loan, original["id"]) is None


@pytest.mark.parametrize("method", ["get", "put", "delete"])
def test_unknown_item_returns_404(client, loan_payload, method):
    kwargs = {"json": loan_payload} if method == "put" else {}
    response = getattr(client, method)(f"/api/loans/{uuid4()}", **kwargs)
    assert response.status_code == 404
    assert response.json()["detail"] == "Loan not found"


@pytest.mark.parametrize("loan_id", ["not-a-uuid", "1", "stats-typo"])
def test_invalid_item_identifiers_are_rejected(client, loan_id):
    assert client.get(f"/api/loans/{loan_id}").status_code == 422


@pytest.mark.parametrize(
    "changes",
    [
        {"equipment": ""},
        {"equipment": "   "},
        {"equipment": "a" * 121},
        {"borrower": "\t"},
        {"due_date": "2026-02-30"},
        {"due_date": "tomorrow"},
        {"status": "lost"},
        {"notes": "n" * 2001},
        {"admin": True},
    ],
)
def test_validation_rejects_bad_inputs_without_writing(client, loan_payload, changes):
    response = client.post("/api/loans", json={**loan_payload, **changes})
    assert response.status_code == 422
    assert client.get("/api/loans").json() == []


def test_put_is_not_a_partial_update(client, loan_payload):
    original = create(client, loan_payload)
    assert client.put(f"/api/loans/{original['id']}", json={"status": "returned"}).status_code == 422
    assert client.get(f"/api/loans/{original['id']}").json()["status"] == "requested"


def test_name_whitespace_and_default_values(client, loan_payload):
    minimal = {
        "equipment": "  Arduino kit  ",
        "borrower": "  Demo Student  ",
        "due_date": loan_payload["due_date"],
    }
    data = create(client, minimal)
    assert data["equipment"] == "Arduino kit"
    assert data["borrower"] == "Demo Student"
    assert data["status"] == "requested"
    assert data["notes"] == ""


def test_status_filter_returns_only_matching_items(client, loan_payload):
    create(client, loan_payload)
    returned = create(client, {**loan_payload, "status": "returned"})
    rows = client.get("/api/loans?status=returned").json()
    assert [row["id"] for row in rows] == [returned["id"]]
    assert client.get("/api/loans?status=invalid").status_code == 422


def test_stats_zero_state_and_static_route_order(client):
    response = client.get("/api/loans/stats")
    assert response.status_code == 200
    assert response.json() == {"total": 0, "active": 0, "overdue": 0, "returned": 0}


def test_stats_count_only_collected_past_due_as_overdue(client, loan_payload):
    today = datetime.now(ZoneInfo("Asia/Kolkata")).date()
    yesterday = (today - timedelta(days=1)).isoformat()
    tomorrow = (today + timedelta(days=1)).isoformat()
    cases = [
        ("requested", yesterday),
        ("collected", yesterday),
        ("collected", today.isoformat()),
        ("collected", tomorrow),
        ("returned", yesterday),
    ]
    for loan_status, due_date in cases:
        create(client, {**loan_payload, "status": loan_status, "due_date": due_date})
    assert client.get("/api/loans/stats").json() == {
        "total": 5, "active": 4, "overdue": 1, "returned": 1
    }


def test_stats_refresh_after_return_and_delete(client, loan_payload):
    past = (datetime.now(ZoneInfo("Asia/Kolkata")).date() - timedelta(days=1)).isoformat()
    row = create(client, {**loan_payload, "status": "collected", "due_date": past})
    assert client.get("/api/loans/stats").json()["overdue"] == 1
    client.put(f"/api/loans/{row['id']}", json={**loan_payload, "status": "returned"})
    assert client.get("/api/loans/stats").json() == {
        "total": 1, "active": 0, "overdue": 0, "returned": 1
    }
    client.delete(f"/api/loans/{row['id']}")
    assert client.get("/api/loans/stats").json()["total"] == 0


def test_metrics_have_real_traffic_and_bounded_route_labels(client, loan_payload):
    row = create(client, loan_payload)
    client.get(f"/api/loans/{row['id']}")
    client.get("/a-made-up-user-controlled-path")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "text/plain" in response.headers["content-type"]
    assert 'labledger_http_requests_total{method="POST",route="/api/loans",status="201"} 1.0' in response.text
    assert 'route="/api/loans/{loan_id}"' in response.text
    assert 'route="unmatched"' in response.text
    assert "labledger_http_request_duration_seconds_bucket" in response.text
    assert row["id"] not in response.text
    assert loan_payload["borrower"] not in response.text
    assert "a-made-up" not in response.text
    assert 'route="/metrics"' not in response.text


def test_openapi_documents_crud_and_swagger_is_available(client):
    schema = client.get("/openapi.json").json()
    assert {"get", "post"} <= schema["paths"]["/api/loans"].keys()
    assert {"get", "put", "delete"} <= schema["paths"]["/api/loans/{loan_id}"].keys()
    assert client.get("/docs").status_code == 200
