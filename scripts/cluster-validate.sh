#!/usr/bin/env bash
# Offline Helm/schema/manifest contract checks. Requires Helm and Python + PyYAML.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"
python_bin=${PYTHON_BIN:-python3}
"$python_bin" -c 'import yaml' || { echo 'PyYAML is required for semantic manifest checks.' >&2; exit 1; }
render_dir=$(mktemp -d)
trap 'rm -rf "$render_dir"' EXIT
helm lint helm/labledger -f helm/labledger/values-local.yaml
helm template labledger helm/labledger -n labledger \
  -f helm/labledger/values-local.yaml > "$render_dir/local.yaml"
sha=0123456789abcdef0123456789abcdef01234567
helm template labledger helm/labledger -n labledger \
  --set-string "backend.image.tag=$sha" --set-string "frontend.image.tag=$sha" \
  --set monitoring.enabled=true --set database.storage.className=gp3 > "$render_dir/production.yaml"
if helm template labledger helm/labledger -f helm/labledger/values-local.yaml \
  --set backend.image.tag=latest > /dev/null 2>&1; then
  echo 'Mutable latest image tag was unexpectedly accepted.' >&2; exit 1
fi
if helm template labledger helm/labledger -f helm/labledger/values-local.yaml \
  --set frontend.replicaCount=1 > /dev/null 2>&1; then
  echo 'Fewer than two frontend replicas were unexpectedly accepted.' >&2; exit 1
fi
if helm template labledger helm/labledger -f helm/labledger/values-local.yaml \
  --set backend.autoscaling.minReplicas=4 --set backend.autoscaling.maxReplicas=2 > /dev/null 2>&1; then
  echo 'Invalid HPA bounds were unexpectedly accepted.' >&2; exit 1
fi
"$python_bin" - "$render_dir" <<'PY'
import ast
import json
from pathlib import Path
import sys
import yaml
root=Path(sys.argv[1])
for mode in ('local','production'):
    docs=[d for d in yaml.safe_load_all((root/f'{mode}.yaml').read_text()) if d]
    by={(d['kind'],d['metadata']['name']):d for d in docs}
    assert not any(d['kind']=='Secret' for d in docs), 'Chart must never create credential values'
    for component,uid,port in [('frontend',101,8080),('backend',10001,8000)]:
        deployment=by['Deployment',f'labledger-{component}']
        assert deployment['spec']['replicas']>=2
        pod=deployment['spec']['template']
        assert pod['spec']['securityContext']['runAsUser']==uid
        assert pod['spec']['automountServiceAccountToken'] is False
        container=pod['spec']['containers'][0]
        assert container['securityContext']['readOnlyRootFilesystem'] is True
        assert container['securityContext']['allowPrivilegeEscalation'] is False
        assert container['resources']['requests']['cpu']
        assert container['ports'][0]['containerPort']==port
        svc=by['Service',f'labledger-{component}']
        assert svc['spec']['type']=='ClusterIP'
        assert svc['spec']['ports'][0]['targetPort']=='http'
        assert all(pod['metadata']['labels'][k]==v for k,v in svc['spec']['selector'].items())
    backend=by['Deployment','labledger-backend']['spec']['template']['spec']
    container=backend['containers'][0]
    assert container['readinessProbe']['httpGet']['path']=='/ready'
    assert container['livenessProbe']['httpGet']['path']=='/health'
    assert container['env'][0]['valueFrom']['secretKeyRef']['name']=='labledger-db'
    assert backend['initContainers'][0]['command']==['python','/schema/wait-schema.py']
    cm=by['ConfigMap','labledger-schema-tools']
    ast.parse(cm['data']['wait-schema.py'])
    job=by['Job','labledger-migrate-1']
    assert job['spec']['template']['spec']['containers'][0]['command']==['python','-m','app.migrate']
    paths=by['Ingress','labledger']['spec']['rules'][0]['http']['paths']
    assert {p['path']:p['backend']['service']['name'] for p in paths}=={'/api':'labledger-backend','/':'labledger-frontend'}
    assert 'rewrite-target' not in str(by['Ingress','labledger'].get('metadata',{}))
    assert 'proxy_pass http://labledger-backend:8000;' in by['ConfigMap','labledger-nginx']['data']['default.conf']
    hpa=by['HorizontalPodAutoscaler','labledger-backend']['spec']
    assert hpa['minReplicas']==2 and hpa['maxReplicas']==4
    assert hpa['metrics'][0]['resource']['target']['averageUtilization']==65
    pvc=by['StatefulSet','labledger-postgres']['spec']['volumeClaimTemplates'][0]['spec']
    if mode=='production':
        assert pvc['storageClassName']=='gp3'
        monitor=by['ServiceMonitor','labledger']
        assert monitor['metadata']['namespace']=='monitoring'
        assert monitor['metadata']['labels']['release']=='monitoring'
        assert monitor['spec']['namespaceSelector']['matchNames']==['labledger']
        assert monitor['spec']['endpoints'][0]['path']=='/metrics'
        assert all(by['Service','labledger-backend']['metadata']['labels'][k]==v for k,v in monitor['spec']['selector']['matchLabels'].items())
    else:
        assert 'storageClassName' not in pvc
    print(f'{mode}: semantic contracts passed for {len(docs)} manifests')
values=yaml.safe_load(Path('monitoring/values.yaml').read_text())
assert values['prometheus']['prometheusSpec']['serviceMonitorSelector']['matchLabels']['release']=='monitoring'
assert values['prometheus']['prometheusSpec']['serviceMonitorNamespaceSelector']['matchNames']==['monitoring']
dashboard=json.loads(Path('monitoring/dashboards/labledger.json').read_text())
queries='\n'.join(t['expr'] for p in dashboard['panels'] for t in p['targets'])
assert 'labledger_http_requests_total' in queries
assert 'labledger_http_request_duration_seconds_bucket' in queries
assert len(dashboard['panels'])==6
print('Prometheus selectors and six Grafana panel definitions passed')
PY
for script in scripts/cluster-*.sh; do bash -n "$script"; done
printf 'Helm, invalid-input, manifest, migration-gate, monitoring, dashboard and shell syntax checks passed.\n'
printf 'No Kubernetes or AWS resources were contacted or created.\n'
