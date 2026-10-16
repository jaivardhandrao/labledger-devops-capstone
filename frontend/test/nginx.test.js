import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const config = readFileSync(new URL('../nginx.conf', import.meta.url), 'utf8');

test('Compose proxy refreshes Docker DNS instead of retaining a startup IP', () => {
  assert.match(config, /resolver\s+127\.0\.0\.11\s+valid=10s\s+ipv6=off\s*;/);
  assert.match(config, /set\s+\$backend_upstream\s+backend:8000\s*;/);
  assert.doesNotMatch(config, /proxy_pass\s+http:\/\/backend:8000/);
});

test('API and operational proxy routes preserve their full original URI', () => {
  // A trailing slash here would replace /api/loans, while $uri would discard
  // the query string. Keep proxy_pass without any URI replacement suffix.
  assert.equal([...config.matchAll(/proxy_pass\s+http:\/\/\$backend_upstream\s*;/g)].length, 2);
  assert.match(config, /location\s+\/api\/\s*\{[^}]*proxy_pass\s+http:\/\/\$backend_upstream\s*;/s);
  assert.match(config, /location\s+~\s+\^\/\(health\|ready\|metrics\)\$\s*\{[^}]*proxy_pass\s+http:\/\/\$backend_upstream\s*;/s);
  assert.doesNotMatch(config, /proxy_pass[^;]*\$(?:uri|request_uri)/);
});
