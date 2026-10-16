# Real application monitoring

The backend exposes these actual metric names:

- `labledger_http_requests_total{method,route,status}`
- `labledger_http_request_duration_seconds_bucket{method,route,status,le}`

Route labels are templates (such as `/api/loans/{loan_id}`), avoiding a new time series per loan or borrower. Standard process/Python collector metrics may also appear. Prometheus attaches the scrape labels `namespace`, `service` and `pod`; those labels are not manually emitted by the application.

## Install into an approved cluster

Use an approved **pinned** local `kube-prometheus-stack` chart package. Record its version and checksum in your actual deployment evidence. `scripts/cluster-monitoring.sh` accepts a local `.tgz` and performs no automatic chart download. It deploys release `monitoring` in namespace `monitoring` with `values.yaml`. Neither Prometheus nor Grafana is exposed publicly.

First create `monitoring-grafana-admin` in namespace `monitoring` outside Git, with keys `username` and `password`. Supply a unique password through a secret manager or a private input workflow; do not put it in Helm values or a shell command's arguments. Prometheus/Grafana installation creates cluster objects and consumes resources; install only after the selected cluster and its operation are authorized.

```bash
export KUBE_CONTEXT='<approved-context>'
export PROMETHEUS_CHART='/absolute/path/to/kube-prometheus-stack-<pinned-version>.tgz'
./scripts/cluster-monitoring.sh
# Add this to the exact SHA-tagged or local application deployment command:
#   --set monitoring.enabled=true
```

The selectors deliberately agree:

| Component | Selection |
|---|---|
| Prometheus | ServiceMonitors in namespaces labeled `kubernetes.io/metadata.name: monitoring`, with monitor label `release: monitoring` |
| LabLedger ServiceMonitor | Created in `monitoring` with `release: monitoring` |
| ServiceMonitor target namespace | The Helm release namespace, normally `labledger` |
| Target Service | Label `app.kubernetes.io/component: backend` plus chart name/release labels |
| Target port/path | Named Service port `http`, path `/metrics`, 15s interval |
| Grafana dashboard sidecar | ConfigMaps in `monitoring` with `grafana_dashboard: "1"` |

Only enable the app's ServiceMonitor after the Prometheus operator CRDs are installed. If changing release/namespace, update both sides of the selection and verify Targets. Dashboard constants default to namespace `labledger`, Service `labledger-backend`; adjust these constants if choosing another release.

## Open locally and populate panels

```bash
kubectl --context "$KUBE_CONTEXT" -n monitoring port-forward svc/monitoring-prometheus 9090:9090
# Another terminal:
kubectl --context "$KUBE_CONTEXT" -n monitoring port-forward svc/monitoring-grafana 3001:80
# Another terminal:
kubectl --context "$KUBE_CONTEXT" -n labledger port-forward svc/labledger-backend 8000:8000
```

Use the School Chrome profile for http://localhost:9090/targets and http://localhost:3001. Select the Prometheus data source in **LabLedger — Application and Scaling**. The dashboard JSON is in `dashboards/labledger.json`; the script creates the sidecar ConfigMap from this actual file.

Generate genuine application traffic: create and update a loan in the UI, read its details, return it, then delete it. Continue reads for at least two scrape intervals. The `rate()`/histogram panels require multiple samples and can initially show no data. This read-only command is also suitable while the backend is port-forwarded:

```bash
for n in $(seq 1 90); do curl --fail --silent http://localhost:8000/api/loans > /dev/null; sleep 1; done
curl --fail http://localhost:8000/metrics
```

Requests and latency panels exclude health/readiness/scrape routes so probe traffic does not substitute for actual API use. Server-error fraction uses HTTP 5xx counts; a 404 is a client error and does not demonstrate 5xx. A zero error fraction after valid traffic is a healthy result. Do not inject destructive database failures in a shared cluster merely to populate a panel.

The optional CPU panel needs kubelet/cAdvisor scraping; desired HPA replicas needs kube-state-metrics. Empty optional panels do not mean HTTP metrics failed. Autoscaling also requires Metrics Server independently of Prometheus.

## Capture evidence that exists

After running the stack, save:

1. Backend `/metrics` output with the real request metrics and timestamp.
2. Prometheus Targets page showing the LabLedger backend targets **UP**.
3. Grafana dashboard with at least one populated request/latency/error panel after actual traffic.
4. Installed chart/version and the application image SHA or clearly labeled local image identity.

A dashboard JSON or render test alone earns no claim of installed Prometheus, live scraping or a populated Grafana panel. The UI remains authenticated and local via port-forward. The short 6h retention and resource requests support a classroom demo; this configuration is not a production capacity or backup policy. No monitoring password is committed.

## Why the local profile has a control-plane override

`values-minikube.yaml` is applied automatically by the installation script only when `KUBE_CONTEXT=labledger-capstone`. It disables exactly three optional component scrapes:

| Component | Verified local listener | Why the default target failed |
|---|---|---|
| Controller manager | `127.0.0.1:10257` | Its actual `--bind-address=127.0.0.1` excludes the node IP used by the default monitor |
| Scheduler | `127.0.0.1:10259` | Its actual `--bind-address=127.0.0.1` excludes the node IP used by the default monitor |
| etcd metrics | `127.0.0.1:2381` | Its actual `--listen-metrics-urls=http://127.0.0.1:2381` is node-local |

The original failed targets and verified component arguments/listening sockets are retained in `evidence/local-cluster/prometheus-targets-before-local-configuration.json`, `control-plane-metrics-bindings.json` and `control-plane-metrics-listeners.txt`. This is a chart configuration adjustment for unsupported local scrape endpoints; it does not open control-plane listeners, change authentication/security rules, alter application monitoring or filter failures in the dashboard/query client.

API server, CoreDNS, kube-proxy, kubelet/cAdvisor/probes, node exporter, kube-state-metrics, operator, Grafana, Prometheus and both LabLedger replicas remain monitored. The complete active-target API response after reconciliation contains **14 UP and 0 DOWN** applicable targets; see `prometheus-targets-final.json`. On another cluster, inspect its actual endpoint reachability and configure optional component monitors for that environment. Do not blindly widen private metrics listeners.

For exact reproduction with the pinned chart:

```bash
helm upgrade --install monitoring /path/to/kube-prometheus-stack-92.9.0.tgz \
  --kube-context labledger-capstone -n monitoring \
  -f monitoring/values.yaml -f monitoring/values-minikube.yaml --wait --timeout 5m
```

Grafana browser login is a user review step if the School profile has no authenticated Grafana session. Credentials are not included in the evidence or repository.

## Prepared EKS profile (not deployed)

`values-eks.yaml` explicitly disables only direct self-hosted etcd/controller-manager/scheduler discovery for the managed control-plane topology. It keeps API-server, kubelet/cAdvisor/probes, CoreDNS, kube-proxy, node/exporter and application monitoring enabled. This is a prepared configuration, not a claim of live EKS target reachability; no cloud target count is assumed. Other provider-supported EKS control-plane metrics integrations are separate from these chart defaults.

The pinned package is `/tmp/labledger-capstone-tools/kube-prometheus-stack-92.9.0.tgz`; `chart.lock.json` records source/version/checksum. `scripts/cluster-bootstrap-monitoring.sh` defaults to local render; reviewed install requires an exact new personal EKS ARN/account/name and dedicated outside-Git kubeconfig. No AWS API, kubeconfig or Secret is read in render mode. See [cloud bootstrap runbook](../docs/CLOUD-BOOTSTRAP-RUNBOOK.md) for storage, real NLB hostname, Metrics Server 10251, image/replica and teardown prerequisites.
