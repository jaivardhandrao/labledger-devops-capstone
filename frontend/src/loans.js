export const STATUSES = ['requested', 'collected', 'returned'];
export const STATUS_LABEL = { requested: 'Requested', collected: 'Collected', returned: 'Returned' };

// Dates from the API are calendar dates. Compare them in the user's local date,
// rather than parsing midnight UTC (which can shift a due date by one day).
export function todayISO(now = new Date()) {
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}
export function isOverdue(loan, today = todayISO()) {
  return loan.status === 'collected' && loan.due_date < today;
}
export function formatDate(date) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date ?? '')) return 'Date unavailable';
  const [year, month, day] = date.split('-').map(Number);
  return new Intl.DateTimeFormat(undefined, { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(year, month - 1, day));
}
export function summarizeLoans(loans, today = todayISO()) {
  return {
    total: loans.length,
    active: loans.filter((loan) => loan.status !== 'returned').length,
    overdue: loans.filter((loan) => isOverdue(loan, today)).length,
    returned: loans.filter((loan) => loan.status === 'returned').length,
  };
}
export function filterLoans(loans, search = '', filter = 'all', today = todayISO()) {
  const needle = search.trim().toLocaleLowerCase();
  return loans.filter((loan) => {
    const matchesText = `${loan.equipment} ${loan.borrower} ${loan.notes ?? ''}`.toLocaleLowerCase().includes(needle);
    const matchesStatus = filter === 'all' || (filter === 'active' ? loan.status !== 'returned' : filter === 'overdue' ? isOverdue(loan, today) : loan.status === filter);
    return matchesText && matchesStatus;
  });
}
export function errorText(payload, fallback) {
  if (typeof payload?.detail === 'string') return payload.detail;
  if (Array.isArray(payload?.detail)) return payload.detail.map((item) => `${item.loc?.at(-1) ?? 'Value'}: ${item.msg}`).join('; ');
  return fallback;
}
export async function request(path, options = {}) {
  let response;
  try {
    response = await fetch(path, {
      ...options,
      headers: { ...(options.body ? { 'Content-Type': 'application/json' } : {}), ...options.headers },
    });
  } catch (error) {
    if (error.name === 'AbortError') throw error;
    throw new Error('Cannot reach the equipment desk. Check the connection and try again.');
  }
  if (!response.ok) {
    const payload = await response.json().catch(() => ({}));
    throw new Error(errorText(payload, `The request failed (${response.status}). Please try again.`));
  }
  if (response.status === 204) return null;
  return response.json();
}
