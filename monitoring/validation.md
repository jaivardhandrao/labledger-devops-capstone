# Deployment artifact validation scope

The following checks were performed locally during implementation:

- Helm 4.3.0 `helm lint` passed with the explicit local override.
- Helm rendered the application templates successfully, including Deployments, ClusterIP Services, PostgreSQL StatefulSet/PVC, single migration Job, Ingress and HPA.
- Local and production-like rendering produced 11 and 12 manifests respectively; the latter includes a ServiceMonitor and explicit gp3 storage override.
- `scripts/cluster-validate.sh` passed semantic checks for Service selectors/ports, replica counts, non-root contexts, external Secret references, startup/migration gates, readiness/liveness, unchanged API paths, HPA bounds, scrape selectors and the six-panel dashboard.
- Invalid mutable `latest` tags, one-replica UI deployments and inverted HPA bounds were rejected.
- Shell scripts passed `bash -n` syntax checks.

These checks validate artifacts; they do **not** establish that a Kubernetes cluster, AWS infrastructure, Ingress Controller, Prometheus scrape target, HPA scale event or populated Grafana panel exists. Update the root evidence ledger with actual subsequent command output and screenshots after running the deployed system. Never relabel local cluster output as AWS evidence.

## Subsequent actual local-cluster checks — 16 October 2026

A dedicated minikube profile `labledger-capstone` was deployed using only explicit context flags. These are local Kubernetes results, **not AWS/EKS evidence**. The previous user context was preserved.

- `helm upgrade --install` of LabLedger completed successfully; two UI and two API Pods plus PostgreSQL became Ready. The schema migration Job completed.
- CRUD passed through `http://localhost:8088` Ingress; the three retained UI records are clearly labeled synthetic demonstrations. The temporary CRUD probe was deleted.
- A measured 90-request traffic run completed with zero failed requests.
- Pinned official `kube-prometheus-stack` 92.9.0 was installed. Chart metadata and SHA256 are saved in `evidence/local-cluster`.
- Both backend targets were **UP** in Prometheus. Actual request-rate, latency, scrape-health and HPA queries returned time series.
- Grafana's authenticated query API found the imported six-panel dashboard and returned six traffic series with positive samples through the real Prometheus data source. Passwords were retrieved only in process memory and were not included in evidence.
- `scripts/cluster-check.sh` completed successfully; database-dependent `/ready` returned `database: reachable`; real `/metrics` output was captured.

Failures and repairs are retained: a namespace-selector CRD schema error was corrected to a Kubernetes label selector; initial image/DNS delays caused one bounded migration attempt to fail before its Job retry succeeded; constrained CPU/memory interrupted startup and required an authorized local-node adjustment; Grafana needed a startup probe; Helm 4 field ownership was reconciled after that explicit runtime repair. None of those failures was relabeled as a successful first attempt.

See the actual command logs, JSON and metrics in `../evidence/local-cluster/`. Browser screenshots/video are separate evidence and must come from the School Chrome profile; API checks alone are not screenshots.

### Final operational handoff

- `evidence/local-cluster/final-image-provenance-and-health.json` verifies the final host frontend image `sha256:18098bb883fab3b21d3a2add3195144f0534e10be3c5174fa6864aff659cfc80` against both Ready cluster Pods: the exported image configuration digest and all eleven filesystem layers match. Docker and CRI display different image-identity forms; layer/config comparison confirms the actual content.
- `hpa-scale-up.txt` records real CPU-triggered 2→4 scaling with all four API Pods Ready. `hpa-after-load.json` records the later natural return to two replicas.
- `persistent-traffic.json` records 2,338 successful GET requests and zero failed requests from a bounded persistent-connection regression. The earlier connection-per-request client was interrupted after exhausting host ephemeral ports; it is recorded separately, with no request-count claim.
- `service-selector-drill.json` records actual HTTP 200→503 with zero Service endpoints→200 after exact selector restoration. The script was repaired to handle nullable EndpointSlice arrays and asynchronous controller convergence; the earlier failed checks are retained. No database records, image identities or security rules were changed by this drill.
- The optional additional wrong-image/Helm-rollback drill was not started. The local release remains healthy for review.
- Browser screenshots remain a separate School-profile capture step. No AWS resources were used for these results.

### Local optional control-plane scrape diagnosis

The initial default monitoring configuration included three unreachable control-plane targets. Actual component arguments and listening sockets confirmed node-loopback-only metrics endpoints, rather than an application failure. A local-only Helm override disables those three optional monitors without changing bind addresses or network security. Monitoring release 5 reconciled successfully. The full active-target API response now verifies **14 UP, 0 DOWN**, including both LabLedger replicas and every applicable cluster/exporter target. Original failure evidence is retained.

The artifact validation interpreter was `/opt/homebrew/bin/python3` with cached PyYAML supplied through `PYTHONPATH=/Users/jaivardhandrao/.cache/uv/archive-v0/Xt-iiomMkrJh7YJ1MD_EZ`; PyYAML was not globally installed and is not part of the runtime backend dependency set. The validation script itself supports `PYTHON_BIN` for a separate environment with PyYAML installed.

All actual monitoring evidence is local. A personal AWS account has subsequently been verified and read-only infrastructure planning completed, but exact deployment access approval is pending. No AWS provisioning, EKS execution, cloud teardown or cloud screenshot is claimed here.
