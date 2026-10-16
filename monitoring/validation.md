# Deployment artifact validation scope

The following checks were performed locally during implementation:

- Helm 4.3.0 `helm lint` passed with the explicit local override.
- Helm rendered the application templates successfully, including Deployments, ClusterIP Services, PostgreSQL StatefulSet/PVC, single migration Job, Ingress and HPA.
- Local and production-like rendering produced 11 and 12 manifests respectively; the latter includes a ServiceMonitor and explicit gp3 storage override.
- `scripts/cluster-validate.sh` passed semantic checks for Service selectors/ports, replica counts, non-root contexts, external Secret references, startup/migration gates, readiness/liveness, unchanged API paths, HPA bounds, scrape selectors and the six-panel dashboard.
- Invalid mutable `latest` tags, one-replica UI deployments and inverted HPA bounds were rejected.
- Shell scripts passed `bash -n` syntax checks.

These checks validate artifacts; they do **not** establish that a Kubernetes cluster, AWS infrastructure, Ingress Controller, Prometheus scrape target, HPA scale event or populated Grafana panel exists. Update the root evidence ledger with actual subsequent command output and screenshots after running the deployed system. Never relabel local cluster output as AWS evidence.
