# Integration contract

Application: LabLedger, original campus equipment loan tracker.
Backend API prefix `/api/loans`; GET collection and item, POST create, PUT update, DELETE archive/remove; GET `/api/loans/stats` before dynamic route. Model fields: id(UUID or string), equipment(str), borrower(str), due_date(ISOdate), status(requested|collected|returned), notes(str), created_at(datetime). API collection returns a JSON array. Stats JSON: total,active,overdue,returned. `/health` liveness, `/ready` DB-dependent503onfailure, `/metrics` Prometheus, `/docs`.
Postgres SQLAlchemy with Alembic; database URL injected via environment. Tests isolatedSQLite/mock, never real production DB. Backend port8000; frontend Nginx nonroot8080; compose frontendlocalhost3000 and backendlocalhost8000. Frontend calls relative`/api/*`,same-origin proxy forwards full path. Cluster namespace`labledger`.
CI must test and build frontend before building/scanning/publishing both images. GHCR SHA tags, Trivy HIGH/CRITICAL fail, Helm deployment gated by explicit configured deployment variables. Local code must not claim that cloud operations or successfulCIalreadyoccurred.
All source credentials are placeholders/localgenerated .env only; no secrets inGit. ActualAWSandrepo visibility require user approvals. Root coordinates all Git commits and evidence.
