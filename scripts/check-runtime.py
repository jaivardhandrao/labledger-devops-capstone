"""Exercise a real running stack using explicitly fictional capstone records."""
import json
import os
from datetime import date,timedelta
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.error import HTTPError

base=os.environ.get('LABLEDGER_BASE_URL','http://127.0.0.1:3000').rstrip('/')
checks=[]
def call(method,path,data=None,expected=200):
    payload=json.dumps(data).encode() if data is not None else None
    req=Request(base+path,data=payload,method=method,headers={'Content-Type':'application/json'})
    try:
        with urlopen(req,timeout=10) as response:
            status=response.status
            raw=response.read().decode()
    except HTTPError as error:
        status=error.code;raw=error.read().decode()
    assert status==expected,(method,path,status,raw)
    checks.append({'method':method,'path':path,'status':status})
    return json.loads(raw) if raw and raw[0] in '[{' else raw

call('GET','/health')
call('GET','/ready')
call('GET','/docs')
record={'equipment':'Runtime test microscope','borrower':'Fictional Test Student','due_date':str(date.today()+timedelta(days=2)),'status':'requested','notes':'Temporary test record; not a real equipment loan.'}
created=call('POST','/api/loans',record,201);loan_id=created['id']
assert call('GET','/api/loans/'+loan_id)['equipment']==record['equipment']
record['status']='collected';updated=call('PUT','/api/loans/'+loan_id,record)
assert updated['status']=='collected'
assert isinstance(call('GET','/api/loans'),list)
assert call('GET','/api/loans/stats')['active']>=1
metrics=call('GET','/metrics');assert 'labledger_http_requests_total' in metrics
call('DELETE','/api/loans/'+loan_id,expected=204)
call('GET','/api/loans/'+loan_id,expected=404)
result={'base_url':base,'scope':'Actual running HTTP stack; fictional test record created, updated and removed','checks':checks,'result':'PASS'}
Path('evidence').mkdir(exist_ok=True)
Path('evidence/runtime-api.json').write_text(json.dumps(result,indent=2)+'\n')
print('PASS:',len(checks),'real HTTP checks, including CRUD, database readiness and Prometheus output.')
