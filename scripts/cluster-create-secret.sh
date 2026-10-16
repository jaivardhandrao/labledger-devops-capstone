#!/usr/bin/env bash
# Creates credentials only in the selected cluster; never prints or writes them.
set -euo pipefail
: "${KUBE_CONTEXT:?Set KUBE_CONTEXT to the exact approved kubectl context}"
export KUBE_CONTEXT
python3 - <<'PY'
import getpass
import json
import os
import subprocess
from urllib.parse import quote
context = os.environ['KUBE_CONTEXT']
namespace = 'labledger'
username = input('Postgres username [labledger]: ').strip() or 'labledger'
database = input('Postgres database [labledger]: ').strip() or 'labledger'
password = getpass.getpass('New Postgres password (not echoed): ')
if len(password) < 16:
    raise SystemExit('Use at least 16 characters; nothing was changed.')
if password != getpass.getpass('Repeat password: '):
    raise SystemExit('Passwords differ; nothing was changed.')
url = f'postgresql+psycopg://{quote(username,safe="")}:{quote(password,safe="")}@labledger-postgres:5432/{quote(database,safe="")}'
secret = {'apiVersion':'v1','kind':'Secret','metadata':{'name':'labledger-db','namespace':namespace},'type':'Opaque','stringData':{'username':username,'password':password,'database':database,'database-url':url}}
# stdout contains kubectl's resource acknowledgement only, never the input data.
subprocess.run(['kubectl','--context',context,'apply','-f','-'],input=json.dumps(secret),text=True,check=True)
PY
