# Actual local Kubernetes evidence

All results here came from the dedicated `labledger-capstone` minikube context on 16 October 2026. They are not AWS/EKS execution evidence. The previous user context was preserved.

- `final-image-provenance-and-health.json`: exact final frontend image content match and healthy review endpoints.
- `cluster-status.txt`, `application-pods-final.txt`, `monitoring-pods-final.txt`, `cluster-check-final.txt`: actual workloads, Services, Helm releases and operational checks.
- `ingress-api-crud.json`: real CRUD through Ingress against PostgreSQL; retained data is explicitly synthetic.
- `nonroot-and-postgres-table.txt`: actual runtime UIDs and Alembic-created loan table.
- `backend-readiness.json`, `backend-metrics.txt`: actual DB-dependent readiness and Prometheus-format metrics.
- `hpa-scale-up.txt`, `hpa-after-load.json`: real 2→4 scaling with all four Ready, followed by natural return to two.
- `application-traffic.json`, `persistent-traffic.json`: 90/90 and 2,338/2,338 successful read requests.
- `service-selector-drill.json`: genuine 200→503→200 selector fault and restoration.
- `prometheus-targets-final.json`: every applicable active target, 14 UP and 0 DOWN. Original unreachable loopback component targets and listener diagnosis are retained separately.
- `grafana-populated-dashboard.json`: authenticated local Grafana query API verified six panels and positive traffic samples through its actual Prometheus data source. This is API evidence, not a browser screenshot.
- `monitoring-chart-metadata.yaml`, `monitoring-chart-sha256.txt`: pinned official chart 92.9.0 provenance.
- `helm-artifact-validation.txt`: Helm/template and semantic artifact validation.

Failure/recovery records are intentionally retained. The initial load client summary is marked incomplete because it exhausted host ephemeral ports; no request total is claimed for that interrupted run. The replacement uses persistent, bounded connections and cleanup. Earlier Service-drill checks caught nullable EndpointSlices/controller timing and were repaired. No failed attempt was relabeled as an initial success.

`completed-log-allowlist.json` lists completed nonempty logs suitable for the final root audit. The four `*port-forward.log` files are still being written and should not be staged. No other writer from this implementation agent remains active. Browser screenshots are captured separately using the required School profile.
