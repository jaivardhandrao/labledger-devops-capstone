#!/usr/bin/env bash
# Promote a tested commit to the dedicated local lab without cloud credentials.
set -euo pipefail
sha=${1:?Usage: scripts/promote-local.sh FULL_COMMIT_SHA [HELM_FLAGS...]}
shift
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || { echo 'Expected a full immutable Git SHA.' >&2; exit 2; }
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"
[[ $(git rev-parse HEAD) == "$sha" ]] || { echo 'Checkout the exact reviewed commit first.' >&2; exit 2; }
[[ -z $(git status --porcelain --untracked-files=no) ]] || { echo 'Tracked files must be clean.' >&2; exit 2; }
repo=${LABLEDGER_REPOSITORY:-jaivardhandrao/labledger-devops-capstone}
[[ "$repo" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9._-]*$ ]] || { echo 'LABLEDGER_REPOSITORY must be a lowercase owner/repository.' >&2; exit 2; }
green=$(gh run list --repo "$repo" --workflow delivery.yml --commit "$sha" --branch main --event push --status completed --json conclusion --jq 'map(select(.conclusion == "success")) | length')
[[ "$green" -ge 1 ]] || { echo 'No successful main-push delivery workflow for this commit; refusing promotion.' >&2; exit 1; }

# Use only the reviewed Git tree for both images AND deployment templates.
# Untracked/ignored local files cannot become code attributed to this SHA.
archive_root=$(mktemp -d "${TMPDIR:-/tmp}/labledger-promote.XXXXXX")
trap 'rm -rf "$archive_root"' EXIT
git archive "$sha" | tar -xf - -C "$archive_root"

# Preserve the enabled scrape target during an upgrade. A failed Helm query is
# an error, not evidence that the release is absent or monitoring is disabled.
monitoring_enabled=false
existing_release=$(helm list --kube-context labledger-capstone -n labledger --deployed --failed --pending --uninstalled --superseded --uninstalling --short --filter '^labledger$')
if [[ -n "$existing_release" ]]; then
  monitoring_enabled=$(helm get values labledger --kube-context labledger-capstone -n labledger --all --output json | python3 -c '
import json,sys
value=(json.load(sys.stdin) or {}).get("monitoring",{}).get("enabled",False)
if not isinstance(value,bool): raise SystemExit("Existing monitoring.enabled must be a boolean")
print(str(value).lower())')
fi

# Build native local images from the same tested Git tree. This is a separately
# scanned local build, not a claim to be the exact published registry image.
for component in backend frontend; do
  docker build --label "org.opencontainers.image.source=https://github.com/$repo" \
    --label "org.opencontainers.image.revision=$sha" \
    -t "labledger-$component:$sha" "$archive_root/$component"
  trivy image --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed=false --exit-code 1 "labledger-$component:$sha"
  minikube -p labledger-capstone image load "labledger-$component:$sha"
done
helm upgrade --install labledger "$archive_root/helm/labledger" --kube-context labledger-capstone -n labledger \
  -f "$archive_root/helm/labledger/values-local.yaml" \
  --set backend.image.tag="$sha" --set frontend.image.tag="$sha" \
  --set "monitoring.enabled=$monitoring_enabled" \
  --wait --wait-for-jobs --timeout 8m "$@"
kubectl --context labledger-capstone -n labledger rollout status deployment/labledger-backend --timeout=180s
kubectl --context labledger-capstone -n labledger rollout status deployment/labledger-frontend --timeout=180s
