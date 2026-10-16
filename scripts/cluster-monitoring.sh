#!/usr/bin/env bash
# Installs an already downloaded/pinned kube-prometheus-stack chart into an approved cluster.
# This script never downloads a chart, opens a public UI, or commits credentials.
set -euo pipefail
: "${KUBE_CONTEXT:?Set the exact approved kubectl context}"
: "${PROMETHEUS_CHART:?Set the path to an approved pinned kube-prometheus-stack chart .tgz}"
[[ -f "$PROMETHEUS_CHART" ]] || { echo 'Chart file not found.' >&2; exit 1; }
repo_root=$(cd "$(dirname "$0")/.." && pwd)
kubectl --context "$KUBE_CONTEXT" create namespace monitoring --dry-run=client -o yaml | kubectl --context "$KUBE_CONTEXT" apply -f -
kubectl --context "$KUBE_CONTEXT" -n monitoring get secret monitoring-grafana-admin >/dev/null
helm upgrade --install monitoring "$PROMETHEUS_CHART" --kube-context "$KUBE_CONTEXT" \
  --namespace monitoring -f "$repo_root/monitoring/values.yaml" --wait --timeout 10m
kubectl --context "$KUBE_CONTEXT" -n monitoring create configmap labledger-dashboard \
  --from-file=labledger.json="$repo_root/monitoring/dashboards/labledger.json" \
  --dry-run=client -o yaml | kubectl --context "$KUBE_CONTEXT" apply -f -
kubectl --context "$KUBE_CONTEXT" -n monitoring label configmap labledger-dashboard grafana_dashboard=1 --overwrite
printf 'Now redeploy LabLedger with --set monitoring.enabled=true to install its ServiceMonitor.\n'
printf 'Port-forward local UIs only: service/monitoring-prometheus 9090:9090 and service/monitoring-grafana 3001:80, namespace monitoring.\n'
