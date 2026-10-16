#!/usr/bin/env bash
# Default: local render only. No AWS API, credentials, kubeconfig or cluster read.
# Install mode is a separate action requiring reviewed bootstrap authorization.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
mode=${1:---render}
[[ "$mode" == --render || "$mode" == --install-reviewed ]] || { echo 'Use --render or --install-reviewed' >&2; exit 2; }
: "${NGINX_CHART:?Set the local path to the pinned nginx-ingress-2.8.0.tgz package}"
export NGINX_CHART
python3 - "$repo_root/k8s/nginx-ingress/chart.lock.json" <<'PY'
import hashlib,json,os,sys
from pathlib import Path
lock=json.loads(Path(sys.argv[1]).read_text())
actual=hashlib.sha256(Path(os.environ['NGINX_CHART']).read_bytes()).hexdigest()
if actual!=lock['package_sha256']:
    raise SystemExit('Chart checksum mismatch; no cluster was contacted.')
print('Official downloaded package checksum matches chart2.8.0/controller5.7.0')
PY
chart_path="$NGINX_CHART"
if [[ -n "${NGINX_SCHEMA_DEFINITIONS:-}" ]]; then
  chart_path=$(python3 "$repo_root/scripts/prepare-nginx-schema.py" \
    --chart "$NGINX_CHART" --definitions "$NGINX_SCHEMA_DEFINITIONS")
fi
if [[ "$mode" == --render ]]; then
  render_dir=${RENDER_DIR:-/tmp/labledger-nginx-review}
  mkdir -p "$render_dir"
  helm lint "$chart_path" -f "$repo_root/k8s/nginx-ingress/values.yaml" --kube-version 1.34.0
  helm template nginx-ingress "$chart_path" -n nginx-ingress \
    -f "$repo_root/k8s/nginx-ingress/values.yaml" --kube-version 1.34.0 --skip-crds \
    --set-string controller.config.entries.external-status-address=example.elb.ap-south-1.amazonaws.com \
    > "$render_dir/controller.yaml"
  printf 'Rendered locally to %s/controller.yaml; the example hostname is a test fixture, not a live endpoint.\n' "$render_dir"
  exit 0
fi
: "${BOOTSTRAP_GRANTS_APPROVED:?Set only after the exact new-cluster bootstrap/RBAC grant review is approved}"
[[ "$BOOTSTRAP_GRANTS_APPROVED" == yes ]] || { echo 'Bootstrap grants have not been approved.' >&2; exit 1; }
: "${AWS_ACCOUNT_ID:?Set the reviewed personal AWS account ID, not a work account}"
: "${EXPECTED_EKS_CONTEXT:?Set the exact reviewed EKS ARN context}"
: "${APPROVED_EKS_CLUSTER_NAME:?Set the exact new cluster name from the reviewed plan}"
: "${CLOUD_KUBECONFIG:?Set a dedicated existing kubeconfig file outside this Git repository}"
: "${NLB_DNS:?Set the exact application_nlb_dns_name Terraform output after approved apply}"
[[ "$AWS_ACCOUNT_ID" =~ ^[0-9]{12}$ ]] || { echo 'Invalid account ID.' >&2; exit 1; }
[[ "$EXPECTED_EKS_CONTEXT" == "arn:aws:eks:ap-south-1:$AWS_ACCOUNT_ID:cluster/$APPROVED_EKS_CLUSTER_NAME" ]] || { echo 'Context must be the reviewed personal ap-south-1 EKS ARN.' >&2; exit 1; }
[[ "$NLB_DNS" =~ ^[a-z0-9][a-z0-9.-]*\.elb\.ap-south-1\.amazonaws\.com$ ]] || { echo 'Expected the actual ap-south-1 NLB DNS hostname.' >&2; exit 1; }
export CLOUD_KUBECONFIG
python3 - "$repo_root" <<'PY'
import os,sys
from pathlib import Path
root=Path(sys.argv[1]).resolve()
config=Path(os.environ['CLOUD_KUBECONFIG']).expanduser().resolve()
if not config.is_file() or config.is_relative_to(root):
    raise SystemExit('Use an existing dedicated kubeconfig file outside Git.')
PY
k=(kubectl --kubeconfig "$CLOUD_KUBECONFIG" --context "$EXPECTED_EKS_CONTEXT")
# Explicit file/context flags preserve the user's global/current context.
"${k[@]}" get namespace kube-system >/dev/null
"${k[@]}" auth can-i create clusterroles --quiet
"${k[@]}" apply -f "$repo_root/k8s/namespace.yaml"
helm upgrade --install nginx-ingress "$chart_path" --kubeconfig "$CLOUD_KUBECONFIG" \
  --kube-context "$EXPECTED_EKS_CONTEXT" --namespace nginx-ingress --create-namespace \
  --skip-crds -f "$repo_root/k8s/nginx-ingress/values.yaml" \
  --set-string "controller.config.entries.external-status-address=$NLB_DNS" \
  --wait --timeout 8m
"${k[@]}" -n nginx-ingress rollout status deployment/nginx-ingress-controller --timeout=180s
"${k[@]}" -n nginx-ingress get deployment nginx-ingress-controller
"${k[@]}" -n nginx-ingress get service nginx-ingress-controller
printf 'Controller installed. Deploy the approved SHA-tagged application with ingress.host=%s and ingress.className=nginx.\n' "$NLB_DNS"
printf 'This helper created no AWS load balancer, IAM role, IRSA binding or Metrics Server.\n'
