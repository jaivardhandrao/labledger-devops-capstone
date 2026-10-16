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
# The Python source arrives on stdin, so interactive fields must use the TTY.
try:
    terminal_in = open('/dev/tty', 'r')
    terminal_out = open('/dev/tty', 'w')
except OSError:
    raise SystemExit('Run this helper from an interactive terminal; nothing was changed.')
def prompt(label, default):
    terminal_out.write(label)
    terminal_out.flush()
    answer = terminal_in.readline()
    if not answer:
        raise SystemExit('Input closed; nothing was changed.')
    return answer.strip() or default
username = prompt('Postgres username [labledger]: ', 'labledger')
database = prompt('Postgres database [labledger]: ', 'labledger')
terminal_in.close()
terminal_out.close()
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
