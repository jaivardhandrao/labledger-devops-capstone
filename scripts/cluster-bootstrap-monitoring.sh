#!/usr/bin/env bash
# Default offline EKS render; reviewed installation is a separate explicit action.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
mode=${1:---render}
[[ "$mode" == --render || "$mode" == --install-reviewed ]] || { echo 'Use --render or --install-reviewed' >&2; exit 2; }
: "${PROMETHEUS_CHART:?Set the local path to kube-prometheus-stack-92.9.0.tgz}"
export PROMETHEUS_CHART
python3 - "$repo_root/monitoring/chart.lock.json" <<'PY'
import hashlib,json,os,sys
from pathlib import Path
lock=json.loads(Path(sys.argv[1]).read_text())
if hashlib.sha256(Path(os.environ['PROMETHEUS_CHART']).read_bytes()).hexdigest()!=lock['package_sha256']:
    raise SystemExit('Monitoring chart checksum mismatch; no cluster was contacted.')
print('Monitoring package checksum matches pinned chart 92.9.0')
PY
values=(-f "$repo_root/monitoring/values.yaml" -f "$repo_root/monitoring/values-eks.yaml")
if [[ "$mode" == --render ]]; then
  render_dir=${RENDER_DIR:-/tmp/labledger-eks-monitoring-review}
  mkdir -p "$render_dir"
  helm lint "$PROMETHEUS_CHART" "${values[@]}" --kube-version 1.34.0
  helm template monitoring "$PROMETHEUS_CHART" -n monitoring "${values[@]}" \
    --kube-version 1.34.0 --include-crds > "$render_dir/monitoring.yaml"
  printf 'Rendered EKS monitoring locally to %s/monitoring.yaml; no kubeconfig, AWS or cluster operation performed.\n' "$render_dir"
  exit 0
fi
: "${BOOTSTRAP_GRANTS_APPROVED:?Set only after exact new-cluster monitoring RBAC/CRD/webhook review is approved}"
[[ "$BOOTSTRAP_GRANTS_APPROVED" == yes ]] || { echo 'Bootstrap grants have not been approved.' >&2; exit 1; }
: "${AWS_ACCOUNT_ID:?Set the reviewed personal AWS account ID}"
: "${APPROVED_EKS_CLUSTER_NAME:?Set the exact new cluster name from the reviewed plan}"
: "${EXPECTED_EKS_CONTEXT:?Set the exact reviewed personal EKS ARN}"
: "${CLOUD_KUBECONFIG:?Set a dedicated existing kubeconfig outside Git}"
[[ "$AWS_ACCOUNT_ID" =~ ^[0-9]{12}$ ]] || { echo 'Invalid account ID.' >&2; exit 1; }
[[ "$EXPECTED_EKS_CONTEXT" == "arn:aws:eks:ap-south-1:$AWS_ACCOUNT_ID:cluster/$APPROVED_EKS_CLUSTER_NAME" ]] || { echo 'Context does not match the exact reviewed new personal EKS cluster.' >&2; exit 1; }
export CLOUD_KUBECONFIG
python3 - "$repo_root" <<'PY'
import os,sys
from pathlib import Path
path=Path(os.environ['CLOUD_KUBECONFIG']).expanduser().resolve()
if not path.is_file() or path.is_relative_to(Path(sys.argv[1]).resolve()):
    raise SystemExit('Use an existing dedicated kubeconfig outside Git.')
PY
k=(kubectl --kubeconfig "$CLOUD_KUBECONFIG" --context "$EXPECTED_EKS_CONTEXT")
# Approved setup must create namespace/admin Secret first. Never read its values.
"${k[@]}" get namespace monitoring >/dev/null
"${k[@]}" auth can-i create customresourcedefinitions --quiet
helm upgrade --install monitoring "$PROMETHEUS_CHART" --kubeconfig "$CLOUD_KUBECONFIG" \
  --kube-context "$EXPECTED_EKS_CONTEXT" -n monitoring "${values[@]}" --wait --timeout 10m
"${k[@]}" -n monitoring create configmap labledger-dashboard \
  --from-file=labledger.json="$repo_root/monitoring/dashboards/labledger.json" \
  --dry-run=client -o yaml | "${k[@]}" apply -f -
"${k[@]}" -n monitoring label configmap labledger-dashboard grafana_dashboard=1 --overwrite
"${k[@]}" -n monitoring get pods
printf 'Operator stack installed. Enable monitoring.enabled=true on the reviewed SHA-tagged application deployment.\n'
printf 'Keep UIs ClusterIP; use this dedicated kubeconfig/context for loopback port-forwards.\n'
