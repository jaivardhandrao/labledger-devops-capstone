#!/usr/bin/env bash
# Deploy only into a cluster whose creation and use are already approved.
set -euo pipefail
: "${KUBE_CONTEXT:?Set the exact approved kubectl context}"
: "${GITHUB_OWNER:?Set the lowercase GHCR owner}"
: "${IMAGE_SHA:?Set the full 40-character Git commit SHA}"
[[ "$IMAGE_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo 'IMAGE_SHA must be a full lowercase Git SHA.' >&2; exit 1; }
repo_root=$(cd "$(dirname "$0")/.." && pwd)
kubectl --context "$KUBE_CONTEXT" apply -f "$repo_root/k8s/namespace.yaml"
kubectl --context "$KUBE_CONTEXT" -n labledger get secret labledger-db >/dev/null
helm upgrade --install labledger "$repo_root/helm/labledger" \
  --kube-context "$KUBE_CONTEXT" --namespace labledger \
  --set-string "frontend.image.repository=ghcr.io/$GITHUB_OWNER/labledger-frontend" \
  --set-string "frontend.image.tag=$IMAGE_SHA" \
  --set-string "backend.image.repository=ghcr.io/$GITHUB_OWNER/labledger-backend" \
  --set-string "backend.image.tag=$IMAGE_SHA" \
  --wait --wait-for-jobs --timeout 8m "$@"
# Fail if the running Deployments have not completed rollout.
kubectl --context "$KUBE_CONTEXT" -n labledger rollout status deployment/labledger-backend --timeout=180s
kubectl --context "$KUBE_CONTEXT" -n labledger rollout status deployment/labledger-frontend --timeout=180s
