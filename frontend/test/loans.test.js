import test from 'node:test';
import assert from 'node:assert/strict';
import { errorText, filterLoans, formatDate, isOverdue, request, summarizeLoans, todayISO } from '../src/loans.js';

const loans = [
  { id: '1', equipment: 'Camera kit', borrower: 'Asha Rao', status: 'collected', due_date: '2026-10-15', notes: 'Tripod included' },
  { id: '2', equipment: 'Arduino', borrower: 'Sam', status: 'requested', due_date: '2026-10-14', notes: '' },
  { id: '3', equipment: 'Microscope', borrower: 'Mina', status: 'returned', due_date: '2026-10-13', notes: '' },
  { id: '4', equipment: 'Audio recorder', borrower: 'Sam', status: 'collected', due_date: '2026-10-16', notes: '' },
];
test('overdue excludes requested, returned and due-today records', () => {
  assert.equal(isOverdue(loans[0], '2026-10-16'), true);
  for (const loan of loans.slice(1)) assert.equal(isOverdue(loan, '2026-10-16'), false);
});
test('summary counts active workflow without treating old requests as overdue', () => {
  assert.deepEqual(summarizeLoans(loans, '2026-10-16'), { total: 4, active: 3, overdue: 1, returned: 1 });
  assert.deepEqual(summarizeLoans([], '2026-10-16'), { total: 0, active: 0, overdue: 0, returned: 0 });
});
test('search is case insensitive and combines with status / overdue filters', () => {
  assert.deepEqual(filterLoans(loans, '  SAM ', 'collected').map(({ id }) => id), ['4']);
  assert.deepEqual(filterLoans(loans, 'tripod', 'overdue', '2026-10-16').map(({ id }) => id), ['1']);
  assert.equal(filterLoans(loans, 'missing').length, 0);
  assert.deepEqual(filterLoans(loans, '', 'active').map(({ id }) => id), ['1', '2', '4']);
});
test('calendar helpers keep due dates local rather than parsing midnight UTC', () => {
  assert.equal(todayISO(new Date(2026, 9, 16, 23, 59)), '2026-10-16');
  assert.match(formatDate('2026-10-16'), /16/);
  assert.equal(formatDate(null), 'Date unavailable');
});
test('FastAPI validation errors become readable', () => {
  assert.equal(errorText({ detail: 'Not found' }, 'fallback'), 'Not found');
  assert.equal(errorText({ detail: [{ loc: ['body', 'borrower'], msg: 'Field required' }] }, 'fallback'), 'borrower: Field required');
  assert.equal(errorText({}, 'fallback'), 'fallback');
});
test('request preserves methods and JSON, handles 204 and fails HTTP errors', async (t) => {
  const original = globalThis.fetch;
  t.after(() => { globalThis.fetch = original; });
  globalThis.fetch = async (path, options) => {
    assert.equal(path, '/api/loans/1');
    assert.equal(options.method, 'PUT');
    assert.equal(options.headers['Content-Type'], 'application/json');
    return { ok: true, status: 200, json: async () => ({ id: '1' }) };
  };
  assert.deepEqual(await request('/api/loans/1', { method: 'PUT', body: '{"status":"returned"}' }), { id: '1' });
  globalThis.fetch = async () => ({ ok: true, status: 204 });
  assert.equal(await request('/api/loans/1', { method: 'DELETE' }), null);
  globalThis.fetch = async () => ({ ok: false, status: 404, json: async () => ({ detail: 'Loan not found' }) });
  await assert.rejects(request('/api/loans/1'), /Loan not found/);
});
test('request reports offline failures while preserving cancellation', async (t) => {
  const original = globalThis.fetch;
  t.after(() => { globalThis.fetch = original; });
  globalThis.fetch = async () => { throw new TypeError('network unavailable'); };
  await assert.rejects(request('/api/loans'), /Cannot reach the equipment desk/);
  globalThis.fetch = async () => { throw new DOMException('aborted', 'AbortError'); };
  await assert.rejects(request('/api/loans'), { name: 'AbortError' });
});
