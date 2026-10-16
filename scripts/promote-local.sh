#!/usr/bin/env bash
# Promote a tested commit to the dedicated local lab without cloud credentials.
set -euo pipefail
sha=${1:?Usage: scripts/promote-local.sh FULL_COMMIT_SHA}
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || { echo 'Expected a full immutable Git SHA.' >&2; exit 2; }
[[ $(git rev-parse HEAD) == "$sha" ]] || { echo 'Checkout the exact reviewed commit first.' >&2; exit 2; }
[[ -z $(git status --porcelain --untracked-files=no) ]] || { echo 'Tracked files must be clean.' >&2; exit 2; }
repo=${LABLEDGER_REPOSITORY:-jaivardhandrao/labledger-devops-capstone}
green=$(gh run list --repo "$repo" --workflow delivery.yml --commit "$sha" --status completed --json conclusion --jq 'map(select(.conclusion == "success")) | length')
[[ "$green" -ge 1 ]] || { echo 'No successful delivery workflow for this commit; refusing promotion.' >&2; exit 1; }
# Build ARM-native images from the same tested commit for a local Apple Silicon lab.
# This avoids copying registry credentials into Kubernetes. Published CI artifacts
# are independently scanned for amd64+arm64 before canonical SHA promotion.
for component in backend frontend; do
  docker build -t "labledger-$component:$sha" "$component"
  trivy image --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed=false --exit-code 1 "labledger-$component:$sha"
  minikube -p labledger-capstone image load "labledger-$component:$sha"
done
helm upgrade --install labledger helm/labledger --kube-context labledger-capstone -n labledger \
  -f helm/labledger/values-local.yaml \
  --set backend.image.tag="$sha" --set frontend.image.tag="$sha" \
  --wait --wait-for-jobs --timeout 8m
kubectl --context labledger-capstone -n labledger rollout status deployment/labledger-backend --timeout=180s
kubectl --context labledger-capstone -n labledger rollout status deployment/labledger-frontend --timeout=180s
