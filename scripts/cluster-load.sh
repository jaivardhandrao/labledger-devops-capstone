#!/usr/bin/env bash
# Bounded, read-only traffic through this project's local Ingress port-forward.
set -euo pipefail
: "${KUBE_CONTEXT:?Set the exact approved kubectl context}"
export KUBE_CONTEXT
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"
python3 - <<'PY'
import concurrent.futures,datetime,http.client,json,os,subprocess,threading,time
from pathlib import Path
seconds=int(os.environ.get('LOAD_SECONDS','60'))
workers=int(os.environ.get('LOAD_WORKERS','4'))
rate=int(os.environ.get('LOAD_RATE_PER_WORKER','10'))
assert 1<=seconds<=180 and 1<=workers<=8 and 1<=rate<=40, 'Use <=180s, <=8 workers, <=40 req/s per worker'
stop=threading.Event()
start=time.monotonic(); deadline=start+seconds
result={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'environment':'local Ingress localhost:8088 only','method':'GET','path':'/api/loans','persistent_connections':True,'workers':workers,'rate_per_worker_limit':rate,'planned_seconds':seconds,'hpa_samples':[]}
def worker():
    connection=http.client.HTTPConnection('127.0.0.1',8088,timeout=5)
    ok=bad=0
    try:
        while not stop.is_set() and time.monotonic()<deadline:
            tick=time.monotonic()
            try:
                connection.request('GET','/api/loans',headers={'Host':'localhost'})
                response=connection.getresponse(); response.read()
                if response.status==200: ok+=1
                else: bad+=1
            except Exception:
                bad+=1
                connection.close()
                connection=http.client.HTTPConnection('127.0.0.1',8088,timeout=5)
            stop.wait(max(0,1/rate-(time.monotonic()-tick)))
    finally:
        connection.close()
    return ok,bad
with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
    futures=[executor.submit(worker) for _ in range(workers)]
    try:
        while time.monotonic()<deadline:
            try:
                raw=subprocess.check_output(['kubectl','--context',os.environ['KUBE_CONTEXT'],'--request-timeout=5s','-n','labledger','get','hpa','labledger-backend','-o','json'],stderr=subprocess.DEVNULL)
                result['hpa_samples'].append({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':json.loads(raw).get('status',{})})
            except subprocess.CalledProcessError:
                result['hpa_samples'].append({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sample_error':'kubectl sampling failed; traffic cleanup remains bounded'})
            stop.wait(min(10,max(0,deadline-time.monotonic())))
    finally:
        stop.set()
    counts=[f.result() for f in futures]
result['completed_requests']=sum(x[0] for x in counts)
result['failed_requests']=sum(x[1] for x in counts)
result['elapsed_seconds']=round(time.monotonic()-start,2)
result['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat()
output=Path(os.environ.get('EVIDENCE_DIR','evidence/local-cluster'))
output.mkdir(parents=True,exist_ok=True)
(output/'persistent-traffic.json').write_text(json.dumps(result,indent=2)+'\n')
print('Persistent local GET load:',result['completed_requests'],'successful,',result['failed_requests'],'failed; connections closed')
raise SystemExit(1 if result['failed_requests'] else 0)
PY
