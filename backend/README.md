# LabLedger API

LabLedger tracks requests, collection and return of campus lab equipment. It is
an original equipment-loan domain, rather than a renamed task-board application.
The backend uses Python 3.12, FastAPI, SQLAlchemy and Alembic. The full stack uses
PostgreSQL; SQLite is an explicit, optional local development/test alternative.

## Run locally

The root Compose configuration is the easiest way to run the PostgreSQL-backed
application. To run only the API against an existing development database:

```bash
cd backend
python3.12 -m venv .venv
.venv/bin/pip install -r requirements.txt
export DATABASE_URL='postgresql+psycopg://USER:PASSWORD@127.0.0.1:5432/labledger'
export BUSINESS_TIMEZONE='Asia/Kolkata'
.venv/bin/python -m app.migrate
.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Replace the example credentials locally; do not commit them. `DATABASE_URL` is
required: missing configuration never silently switches production to SQLite.
For a disposable local SQLite demonstration, explicitly set
`DATABASE_URL=sqlite:///./labledger.db` before migration/startup. Do not present
that demonstration as PostgreSQL evidence.

The container runs as UID/GID `10001`. Its default command applies migrations
and then replaces the shell with Uvicorn. The migration module retries an
unavailable database for a bounded startup window, and uses a PostgreSQL
transaction advisory lock to serialize concurrent schema upgrades. Kubernetes
may run it from a controlled migration Job before the application rollout.
Application startup never calls `Base.metadata.create_all`.

The runtime uses the maintained Python 3.12 Alpine image, reducing unused OS
packages. Its musl-compatible Psycopg binary wheel and `Asia/Kolkata` timezone
support are verified independently of the application's database. Linux's
SQLAlchemy dependency `greenlet` is pinned explicitly even though some Mac
installations do not request it automatically. Image selection and dependency
pins do not replace the strict Trivy gate on the final built image.

## API contract

| Method | Path | Result |
| --- | --- | --- |
| GET | `/api/loans` | JSON array, newest first; optional `?status=collected` filter |
| POST | `/api/loans` | Create a loan, `201` with `Location` header |
| GET | `/api/loans/{uuid}` | One loan, or `404` |
| PUT | `/api/loans/{uuid}` | Replace writable fields, retaining ID and creation time |
| DELETE | `/api/loans/{uuid}` | Permanently remove a loan, `204` without a response body |
| GET | `/api/loans/stats` | `total`, `active`, `overdue`, `returned` counts |
| GET | `/health` | Cheap process liveness; independent of the database |
| GET | `/ready` | `SELECT 1` database check; `503` if unreachable |
| GET | `/metrics` | Prometheus text exposition with bounded labels |
| GET | `/docs` | Interactive OpenAPI/Swagger documentation |

Example request body:

```json
{
  "equipment": "Arduino Uno kit",
  "borrower": "Demo Student",
  "due_date": "2026-10-20",
  "status": "requested",
  "notes": "For a robotics workshop"
}
```

Equipment and borrower names are trimmed, nonempty and at most 120 characters.
Notes are at most 2,000 characters. Unknown fields, invalid dates and invalid
status values return `422`. `PUT` requires all three core fields; it is not a
partial-update endpoint. Status defaults to `requested`, and notes default to
an empty string. Status can be `requested`, `collected` or `returned`; this
small CRUD service deliberately permits correcting a status in either direction.
Deleting records is irreversible; use Return in the UI to retain loan history.

Active means requested or collected. Overdue means **collected** with a due
date strictly before today's business date. A request for equipment that has
not been collected is never overdue, and a collected item due today is not
overdue yet. `BUSINESS_TIMEZONE` defaults to `Asia/Kolkata`. Stored creation
timestamps and JSON timestamps use UTC. Due dates are calendar dates, not
midnight UTC timestamps.

## Test and lint

```bash
cd backend
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/pytest -v
.venv/bin/ruff check app tests alembic
.venv/bin/pip check
```

Each API test gets a fresh, in-memory SQLite database with a `StaticPool` and a
FastAPI dependency override. Tests explicitly overwrite any externally supplied
`DATABASE_URL` before importing the app. They never connect to production.
The migration test runs the actual Alembic upgrade twice, compares the resulting
schema to SQLAlchemy metadata and downgrades a disposable database. This is
useful fast verification; root Compose integration must still establish that
the PostgreSQL dialect, real database readiness and containers work together.

Runtime dependencies, including resolved transitive versions, are pinned in
`requirements.txt`; direct package intent is in `requirements.in`. Development
tools are separate in `requirements-dev.txt`. The current Starlette test client
uses `httpx2`. Do not add pytest or the HTTP test client to the runtime image.

## Metrics and operational limits

The request counter is `labledger_http_requests_total`; latency is
`labledger_http_request_duration_seconds` (a histogram with `_bucket`, `_sum`
and `_count` series). Labels are `method`, `route`, `status`; routes use templates
such as `/api/loans/{loan_id}`, and unknown routes share `unmatched`. Borrower
names, item UUIDs, query strings and arbitrary user paths are never labels.
The metrics endpoint excludes its own scrapes. Each process has its own registry;
the chart runs one Uvicorn process per Pod and Prometheus scrapes each Pod.

This classroom demonstration has no login/authorization layer. It is intended
for synthetic data and controlled evaluation access. Do not load real borrower
personal data or expose it as an unrestricted production service. TLS, identity,
authorization, backups and audit retention would be required for that use.
Health probes and tests do not constitute evidence of AWS, Kubernetes, CI,
image scanning or deployment: record those separately from real executions.
