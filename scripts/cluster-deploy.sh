#!/usr/bin/env bash
# Deploy only into a cluster whose creation and use are already approved.
set -euo pipefail
: "${KUBE_CONTEXT:?Set the exact approved kubectl context}"
: "${IMAGE_SHA:?Set the full 40-character Git commit SHA}"
[[ "$IMAGE_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo 'IMAGE_SHA must be a full lowercase Git SHA.' >&2; exit 1; }
repo=${LABLEDGER_REPOSITORY:-jaivardhandrao/labledger-devops-capstone}
[[ "$repo" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9._-]*$ ]] || { echo 'LABLEDGER_REPOSITORY must be a lowercase owner/repository.' >&2; exit 2; }
repo_root=$(cd "$(dirname "$0")/.." && pwd)
kubectl --context "$KUBE_CONTEXT" apply -f "$repo_root/k8s/namespace.yaml"
kubectl --context "$KUBE_CONTEXT" -n labledger get secret labledger-db >/dev/null

# Preserve the existing scrape target, while letting explicit caller flags
# intentionally override the value. Do not turn a Helm failure into false.
monitoring_enabled=false
existing_release=$(helm list --kube-context "$KUBE_CONTEXT" -n labledger --all --short --filter '^labledger$')
if [[ -n "$existing_release" ]]; then
  monitoring_enabled=$(helm get values labledger --kube-context "$KUBE_CONTEXT" -n labledger --all --output json | python3 -c '
import json,sys
value=(json.load(sys.stdin) or {}).get("monitoring",{}).get("enabled",False)
if not isinstance(value,bool): raise SystemExit("Existing monitoring.enabled must be a boolean")
print(str(value).lower())')
fi
helm upgrade --install labledger "$repo_root/helm/labledger" \
  --kube-context "$KUBE_CONTEXT" --namespace labledger \
  --set-string "frontend.image.repository=ghcr.io/$repo-frontend" \
  --set-string "frontend.image.tag=$IMAGE_SHA" \
  --set-string "backend.image.repository=ghcr.io/$repo-backend" \
  --set-string "backend.image.tag=$IMAGE_SHA" \
  --set "monitoring.enabled=$monitoring_enabled" \
  --wait --wait-for-jobs --timeout 8m "$@"
# Fail if the running Deployments have not completed rollout.
kubectl --context "$KUBE_CONTEXT" -n labledger rollout status deployment/labledger-backend --timeout=180s
kubectl --context "$KUBE_CONTEXT" -n labledger rollout status deployment/labledger-frontend --timeout=180s
