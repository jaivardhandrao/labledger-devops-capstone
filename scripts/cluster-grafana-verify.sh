#!/usr/bin/env bash
# Verify a real dashboard through Grafana; admin Secret stays only in process memory.
set -euo pipefail
: "${KUBE_CONTEXT:?Set the exact approved kubectl context}"
export KUBE_CONTEXT
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"
python3 - <<'PY'
import base64,datetime,json,os,subprocess,time,urllib.request
from pathlib import Path
raw=subprocess.check_output(['kubectl','--context',os.environ['KUBE_CONTEXT'],'-n','monitoring','get','secret','monitoring-grafana-admin','-o','json'])
data=json.loads(raw)['data']
username=base64.b64decode(data['username']).decode()
password=base64.b64decode(data['password']).decode()
headers={'Authorization':'Basic '+base64.b64encode((username+':'+password).encode()).decode(),'Content-Type':'application/json'}
def get(path):
    req=urllib.request.Request('http://localhost:3001'+path,headers=headers)
    with urllib.request.urlopen(req,timeout=20) as r: return json.load(r)
health=get('/api/health')
dashboard=get('/api/dashboards/uid/labledger-overview')
datasources=get('/api/datasources')
prom=next(d for d in datasources if d['type']=='prometheus')
query='sum by (route,method) (rate(labledger_http_requests_total{namespace="labledger",service="labledger-backend",route!~"/health|/ready|/metrics"}[2m]))'
body={'from':str(int((time.time()-900)*1000)),'to':str(int(time.time()*1000)),'queries':[{'refId':'A','datasource':{'type':'prometheus','uid':prom['uid']},'expr':query,'range':True,'intervalMs':15000,'maxDataPoints':100}]}
req=urllib.request.Request('http://localhost:3001/api/ds/query',data=json.dumps(body).encode(),headers=headers,method='POST')
with urllib.request.urlopen(req,timeout=30) as r: answer=json.load(r)
frames=answer.get('results',{}).get('A',{}).get('frames',[])
nonzero=sum(1 for frame in frames for column in frame.get('data',{}).get('values',[])[1:] for v in column if isinstance(v,(int,float)) and v>0)
assert len(dashboard['dashboard']['panels'])==6
assert frames and nonzero, 'No positive API-traffic samples returned through Grafana'
result={'recorded_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'grafana_health':health,'dashboard':{'uid':dashboard['dashboard']['uid'],'title':dashboard['dashboard']['title'],'panel_count':len(dashboard['dashboard']['panels'])},'prometheus_datasource':{'name':prom['name'],'uid':prom['uid']},'query_expression':query,'frame_count':len(frames),'positive_samples':nonzero,'query_response':answer}
output=Path(os.environ.get('EVIDENCE_DIR','evidence/local-cluster'))
output.mkdir(parents=True,exist_ok=True)
(output/'grafana-populated-dashboard.json').write_text(json.dumps(result,indent=2)+'\n')
print('Grafana authenticated API: imported six-panel dashboard,',len(frames),'traffic series and',nonzero,'positive samples; credentials never printed')
PY
