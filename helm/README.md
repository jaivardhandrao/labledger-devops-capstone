# LabLedger Helm deployment

This chart implements the application part of M8 and the scrape target for M9. Rendering a chart is **not** proof that it deployed. Actual cluster evidence is collected separately after a real run.

## Required before deployment

- An approved, already created Kubernetes cluster and an explicit `KUBE_CONTEXT`.
- Helm, an Ingress Controller implementing class `nginx`, and Metrics Server for CPU-based HPA.
- A default storage provisioner (local cluster), or the EBS CSI driver plus an appropriate StorageClass (EKS). `k8s/storageclass-gp3.yaml` is an example, not an installed driver.
- Two published GHCR images tagged with the same full Git commit SHA. Private images require an externally created image-pull Secret, referenced by `imagePullSecrets`.
- Namespace `labledger`, and an externally created `labledger-db` Secret. No real credentials belong in Git, Helm values, screenshots, command arguments or Terraform variables.

The database Secret has four keys:

| Key | Purpose |
|---|---|
| `username` | PostgreSQL role name |
| `password` | Strong generated database password |
| `database` | Database name |
| `database-url` | `postgresql+psycopg://<URL-encoded-user>:<URL-encoded-password>@labledger-postgres:5432/<database>` |

Use `scripts/cluster-create-secret.sh` after applying `k8s/namespace.yaml`. It prompts privately and passes the Secret to kubectl through stdin. It does not log the password. Keep all four values consistent. Reapplying a different Secret does **not** automatically change a password in an already initialized PostgreSQL PVC; use the database's credential rotation procedure instead.

## Deploy SHA-tagged images

```bash
export KUBE_CONTEXT='<approved-cluster-context>'
export GITHUB_OWNER='<lowercase-github-owner>'
export IMAGE_SHA='<full-40-character-commit-sha>'
kubectl --context "$KUBE_CONTEXT" apply -f k8s/namespace.yaml
./scripts/cluster-create-secret.sh
./scripts/cluster-deploy.sh
./scripts/cluster-check.sh
```

The deploy script uses `--wait --wait-for-jobs`. Pass extra Helm flags after the script name, for example `--set database.storage.className=gp3 --set ingress.host=demo.example.edu`. Creating or modifying public AWS resources, DNS, ingress exposure or security rules requires separate approval; these commands do not grant it.

The default hostname is `labledger.local`. Configure hostname resolution to the actual Ingress address, or use a local request with `Host: labledger.local`. No custom domain purchase is required. Ingress preserves `/api` when sending API requests to FastAPI; no rewrite annotation strips it. The frontend's mounted Nginx configuration also preserves `/api` for a frontend port-forward. Swagger can be opened through a backend port-forward; the public Ingress intentionally routes only `/` and `/api`.

```bash
kubectl --context "$KUBE_CONTEXT" -n labledger port-forward svc/labledger-frontend 3000:8080
# Separate terminal for Swagger, readiness and Prometheus format:
kubectl --context "$KUBE_CONTEXT" -n labledger port-forward svc/labledger-backend 8000:8000
# Visit localhost:3000 and localhost:8000/docs using the School Chrome profile.
```

## Local cluster override

`values-local.yaml` explicitly uses local images and `pullPolicy: Never`. It is solely for an existing local cluster; it is not GHCR publication or AWS evidence.

```bash
docker build -t labledger-backend:local backend
docker build -t labledger-frontend:local frontend
minikube -p labledger-capstone image load labledger-backend:local
minikube -p labledger-capstone image load labledger-frontend:local
helm upgrade --install labledger helm/labledger \
  --kube-context labledger-capstone -n labledger \
  -f helm/labledger/values-local.yaml --wait --wait-for-jobs --timeout 8m
```

The namespace and external Secret must already exist. Enable the local profile's Ingress, Metrics Server and storage provisioner before demonstrating these features. These instructions do not create a cluster or enable add-ons automatically.

## Startup, migration and failure behavior

1. PostgreSQL starts with persistent data and reports database readiness using `pg_isready`.
2. One migration Job per Helm release revision calls `python -m app.migrate`. The backend's migration wrapper uses PostgreSQL advisory locking.
3. Each API Pod's init container checks `alembic_version` against the migration heads in that image. It fails after 240 seconds rather than silently starting against the wrong schema.
4. The API starts with Uvicorn. `/health` checks process liveness; `/ready` checks database access. A database outage removes the Pod from Service endpoints without making liveness depend on PostgreSQL.
5. Two frontend and at least two backend replicas are requested. HPA targets 65% of the backend's 100m CPU request, with 2–4 replicas; Metrics Server is required. A cheap health request is not a guaranteed scaling demonstration.

The API and frontend use non-root UIDs 10001 and 101 respectively, drop Linux capabilities, disallow privilege escalation and have read-only roots with explicit writable temporary volumes. PostgreSQL runs as the upstream Alpine image's UID 70 with a PVC. Tokens are not mounted into application Pods.

For schema-changing upgrades use backward-compatible expand/migrate/contract changes. Automatic application rollback does not reverse database migrations. Never run two independent Helm upgrades against this release simultaneously. Do not assume `helm uninstall` destroys data: StatefulSet PVCs are deliberately retained.

## Rendering and evidence

```bash
helm lint helm/labledger -f helm/labledger/values-local.yaml
helm template labledger helm/labledger -n labledger \
  -f helm/labledger/values-local.yaml > /tmp/labledger-rendered.yaml
./scripts/cluster-capture.sh
```

Keep real `get pods`, Services and `helm list` terminal screenshots plus School Chrome screenshots of the running UI and Ingress. HPA output must show real CPU data; `unknown` is a prerequisite failure, not successful scaling. `monitoring/README.md` explains actual scrape and dashboard evidence. See `monitoring/validation.md` for the current artifact-validation scope.
