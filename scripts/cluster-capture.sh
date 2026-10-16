#!/usr/bin/env bash
# Capture genuine, timestamped read-only cluster output. No screenshots are invented.
set -euo pipefail
: "${KUBE_CONTEXT:?Set the exact approved kubectl context}"
repo_root=$(cd "$(dirname "$0")/.." && pwd)
evidence_dir=${EVIDENCE_DIR:-"$repo_root/evidence/cluster-$(date -u +%Y%m%dT%H%M%SZ)"}
mkdir -p "$evidence_dir"
# No secrets, env dumps, Helm values, or complete Pod descriptions are captured.
{
  date -u '+UTC %Y-%m-%dT%H:%M:%SZ'
  printf 'Context: %s\n' "$KUBE_CONTEXT"
  kubectl --context "$KUBE_CONTEXT" version --client
  kubectl --context "$KUBE_CONTEXT" -n labledger get pods -o wide
  kubectl --context "$KUBE_CONTEXT" -n labledger get svc,ingress,hpa,pvc
  kubectl --context "$KUBE_CONTEXT" -n labledger get endpoints
  helm list --kube-context "$KUBE_CONTEXT" -n labledger
} 2>&1 | tee "$evidence_dir/cluster-status.txt"
# Deployment image identifiers are safe to collect; credentials are excluded.
kubectl --context "$KUBE_CONTEXT" -n labledger get deployments -o \
  'jsonpath={range .items[*]}{.metadata.name}{": "}{range .spec.template.spec.containers[*]}{.image}{" "}{end}{"\n"}{end}' \
  | tee "$evidence_dir/deployed-images.txt"
printf 'Saved actual command output to %s\n' "$evidence_dir"
printf 'Capture browser screenshots/video separately in the SST Chrome profile.\n'
