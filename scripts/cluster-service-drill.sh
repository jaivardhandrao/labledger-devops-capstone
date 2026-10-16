#!/usr/bin/env bash
# Reversible LOCAL-ONLY selector drill. Restores the original selector in finally.
set -euo pipefail
: "${KUBE_CONTEXT:?Set KUBE_CONTEXT=labledger-capstone}"
[[ "$KUBE_CONTEXT" == labledger-capstone ]] || { echo 'This drill is restricted to the dedicated local capstone profile.' >&2; exit 1; }
export KUBE_CONTEXT
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"
python3 - <<'PY'
from pathlib import Path
import datetime,json,os,subprocess,time,urllib.error,urllib.request
k=['kubectl','--context',os.environ['KUBE_CONTEXT'],'--request-timeout=10s','-n','labledger']
def command(args):
    return subprocess.check_output(k+args,text=True)
def count_endpoints():
    doc=json.loads(command(['get','endpointslices','-l','kubernetes.io/service-name=labledger-backend','-o','json']))
    return sum(len(ep['addresses']) for item in doc['items'] for ep in (item.get('endpoints') or []) if ep.get('conditions',{}).get('ready',True))
def http_status():
    try:
        with urllib.request.urlopen('http://localhost:8088/api/loans',timeout=5) as response:
            response.read()
            return response.status
    except urllib.error.HTTPError as error:
        return error.code
original=json.loads(command(['get','service','labledger-backend','-o','json']))['spec']['selector']
assert original.get('app.kubernetes.io/component')=='backend'
result={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'environment':'local minikube labledger-capstone only','fault':'Temporary Service selector mismatch; no images, database data or security rules changed','original_selector':original,'ready_endpoints_before':count_endpoints(),'http_before':http_status(),'events':[]}
assert result['http_before']==200 and result['ready_endpoints_before']>=2
try:
    broken=dict(original);broken['app.kubernetes.io/component']='missing-for-controlled-drill'
    command(['patch','service','labledger-backend','--type=merge','-p',json.dumps({'spec':{'selector':broken}})])
    result['events'].append({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'action':'applied selector mismatch'})
    # EndpointSlice and Ingress controllers converge asynchronously.
    for _ in range(20):
        endpoints=count_endpoints();status=http_status()
        if endpoints==0 and status==503: break
        time.sleep(1)
    result['ready_endpoints_during']=count_endpoints()
    result['http_during']=http_status()
    assert result['ready_endpoints_during']==0 and result['http_during']==503
finally:
    command(['patch','service','labledger-backend','--type=merge','-p',json.dumps({'spec':{'selector':original}})])
    result['events'].append({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'action':'restored exact original selector'})
    consecutive=0
    for _ in range(30):
        if count_endpoints()>=2 and http_status()==200:
            consecutive+=1
            if consecutive>=2: break
        else:
            consecutive=0
        time.sleep(1)
    result['ready_endpoints_after']=count_endpoints()
    result['http_after']=http_status()
    result['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat()
    output=Path(os.environ.get('EVIDENCE_DIR','evidence/local-cluster'));output.mkdir(parents=True,exist_ok=True)
    (output/'service-selector-drill.json').write_text(json.dumps(result,indent=2)+'\n')
assert result['http_after']==200 and result['ready_endpoints_after']>=2
print('Local Service drill: 200 -> 503 with zero endpoints -> 200 after exact selector restoration')
PY
