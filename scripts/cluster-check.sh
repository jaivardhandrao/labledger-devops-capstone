#!/usr/bin/env bash
# Read-only operational checks; exits nonzero for missing/unready components.
set -euo pipefail
: "${KUBE_CONTEXT:?Set the exact approved kubectl context}"
k=(kubectl --context "$KUBE_CONTEXT" -n labledger)
"${k[@]}" get pods,svc,ingress,hpa,pvc
helm list --kube-context "$KUBE_CONTEXT" --namespace labledger
"${k[@]}" rollout status deployment/labledger-backend --timeout=60s
"${k[@]}" rollout status deployment/labledger-frontend --timeout=60s
"${k[@]}" get deployment labledger-backend labledger-frontend -o json | python3 -c '
import json,sys
for item in json.load(sys.stdin)["items"]:
    status=item.get("status",{})
    assert status.get("readyReplicas",0) >= 2, item["metadata"]["name"]+" has fewer than two Ready replicas"
print("Both Deployments have at least two Ready replicas")'
"${k[@]}" get endpoints labledger-backend labledger-frontend
"${k[@]}" top pods
# A healthy HPA must show CPU current values instead of <unknown>.
"${k[@]}" describe hpa labledger-backend
