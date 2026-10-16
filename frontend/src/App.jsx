import React, { useCallback, useEffect, useRef, useState } from 'react';
import { STATUSES, STATUS_LABEL, filterLoans, formatDate, isOverdue, request, summarizeLoans, todayISO } from './loans.js';

function Icon({ name, size = 20, ...props }) {
  const paths = {
    plus: <path d="M12 5v14M5 12h14" />,
    search: <><circle cx="10.5" cy="10.5" r="6.5" /><path d="m16 16 4 4" /></>,
    ledger: <><rect x="5" y="3" width="15" height="18" rx="2" /><path d="M5 8H2m3 8H2m7-9h7m-7 5h7m-7 5h5" /></>,
    clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
    check: <path d="m5 12 4 4L19 6" />,
    box: <><path d="m12 3 9 5v9l-9 5-9-5V8l9-5Zm0 9L3 8m9 4 9-4m-9 4v10m-5-17 9 5" /></>,
    arrow: <path d="M5 12h14m-5-5 5 5-5 5" />,
    refresh: <><path d="M20 8a8 8 0 1 0 .2 7M20 3v5h-5" /></>,
    close: <path d="m6 6 12 12M6 18 18 6" />,
    edit: <><path d="m15 4 5 5M4 20l5-1L21 7a2 2 0 0 0-5-5L4 14v6Z" /></>,
    trash: <><path d="M3 6h18M9 6V3h6v3M6 6l1 15h10l1-15M10 10v7m4-7v7" /></>,
    alert: <><path d="m12 3 10 18H2L12 3Zm0 6v5" /><path d="M12 17h.01" /></>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.65" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" {...props}>{paths[name] ?? paths.box}</svg>;
}

function LoanDialog({ loan, onClose, onSaved }) {
  const dialog = useRef(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [values, setValues] = useState(() => ({
    equipment: loan?.equipment ?? '', borrower: loan?.borrower ?? '', due_date: loan?.due_date ?? todayISO(),
    status: loan?.status ?? 'requested', notes: loan?.notes ?? '',
  }));
  useEffect(() => {
    const element = dialog.current;
    element.showModal();
    return () => element.close();
  }, []);
  const change = (event) => setValues((current) => ({ ...current, [event.target.name]: event.target.value }));
  async function submit(event) {
    event.preventDefault();
    setBusy(true); setError('');
    try {
      await request(loan ? `/api/loans/${encodeURIComponent(loan.id)}` : '/api/loans', {
        method: loan ? 'PUT' : 'POST',
        body: JSON.stringify({ ...values, equipment: values.equipment.trim(), borrower: values.borrower.trim(), notes: values.notes.trim() }),
      });
      onSaved(loan ? 'Loan updated.' : 'Loan created.');
    } catch (failure) { setError(failure.message); setBusy(false); }
  }
  return <dialog ref={dialog} aria-labelledby="loan-dialog-title" onCancel={(event) => { if (busy) event.preventDefault(); else onClose(); }} onClick={(event) => { if (event.target === dialog.current && !busy) onClose(); }}>
    <div className="dialog-inner">
      <div className="dialog-heading"><div><span className="small-label">Equipment desk</span><h2 id="loan-dialog-title">{loan ? 'Edit loan' : 'Request a loan'}</h2></div><button className="icon-button" type="button" onClick={onClose} disabled={busy} aria-label="Close dialog"><Icon name="close" /></button></div>
      <p className="dialog-description">Record one equipment item and the person responsible for its return.</p>
      <form onSubmit={submit}>
        <div className="form-grid">
          <label className="full-width">Equipment <input autoFocus name="equipment" value={values.equipment} onChange={change} required maxLength={120} placeholder="e.g. Sony camera kit" disabled={busy} /></label>
          <label className="full-width">Borrower <input name="borrower" value={values.borrower} onChange={change} required maxLength={120} placeholder="Borrower's full name" disabled={busy} /></label>
          <label>Return by <input type="date" name="due_date" value={values.due_date} onChange={change} required disabled={busy} /></label>
          <label>Status <select name="status" value={values.status} onChange={change} disabled={busy}>{STATUSES.map((status) => <option key={status} value={status}>{STATUS_LABEL[status]}</option>)}</select></label>
          <label className="full-width">Notes <span className="optional">(optional)</span><textarea name="notes" value={values.notes} onChange={change} maxLength={2000} rows={3} placeholder="Accessories, condition or collection details" disabled={busy} /></label>
        </div>
        {values.status === 'collected' && values.due_date < todayISO() && <p className="form-note"><Icon name="clock" size={16} /> This collected item will be marked overdue.</p>}
        {error && <div className="inline-error" role="alert">{error}</div>}
        <div className="dialog-actions"><button className="button secondary" type="button" onClick={onClose} disabled={busy}>Cancel</button><button className="button primary" type="submit" disabled={busy}>{busy ? 'Saving…' : loan ? 'Save changes' : 'Create loan'}<Icon name="arrow" size={17} /></button></div>
      </form>
    </div>
  </dialog>;
}

function DeleteDialog({ loan, onClose, onDeleted }) {
  const dialog = useRef(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  useEffect(() => { const element = dialog.current; element.showModal(); return () => element.close(); }, []);
  async function remove() {
    setBusy(true); setError('');
    try { await request(`/api/loans/${encodeURIComponent(loan.id)}`, { method: 'DELETE' }); onDeleted('Loan deleted.'); }
    catch (failure) { setError(failure.message); setBusy(false); }
  }
  return <dialog ref={dialog} className="delete-dialog" aria-labelledby="delete-dialog-title" onCancel={(event) => { if (busy) event.preventDefault(); else onClose(); }}>
    <div className="dialog-inner"><div className="delete-symbol"><Icon name="trash" size={25} /></div><h2 id="delete-dialog-title">Delete this loan?</h2><p className="dialog-description"><strong>{loan.equipment}</strong> borrowed by <strong>{loan.borrower}</strong> will be permanently removed. Mark it Returned instead if you want to keep the record.</p>{error && <div role="alert" className="inline-error">{error}</div>}<div className="dialog-actions"><button className="button secondary" type="button" onClick={onClose} disabled={busy} autoFocus>Keep loan</button><button className="button danger" type="button" onClick={remove} disabled={busy}>{busy ? 'Deleting…' : 'Delete loan'}</button></div></div>
  </dialog>;
}

export default function App() {
  const [loans, setLoans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [dialog, setDialog] = useState(null);
  const [pendingId, setPendingId] = useState(null);
  const lastTrigger = useRef(null);
  const fetchSequence = useRef(0);
  const load = useCallback(async () => {
    const sequence = ++fetchSequence.current;
    setLoading(true); setError('');
    try {
      const data = await request('/api/loans');
      if (!Array.isArray(data)) throw new Error('The equipment desk returned an unexpected response. Try refreshing.');
      if (sequence === fetchSequence.current) setLoans(data);
    } catch (failure) { if (sequence === fetchSequence.current) setError(failure.message); }
    finally { if (sequence === fetchSequence.current) setLoading(false); }
  }, []);
  useEffect(() => { load(); return () => { fetchSequence.current += 1; }; }, [load]);
  useEffect(() => { if (!notice) return; const timer = setTimeout(() => setNotice(''), 5000); return () => clearTimeout(timer); }, [notice]);
  function closeDialog() { setDialog(null); requestAnimationFrame(() => lastTrigger.current?.focus()); }
  function createLoan(event) { lastTrigger.current = event.currentTarget; setDialog({ type: 'create' }); }
  async function editLoan(loan, event) {
    lastTrigger.current = event.currentTarget;
    setPendingId(loan.id); setError('');
    try { const latest = await request(`/api/loans/${encodeURIComponent(loan.id)}`); setDialog({ type: 'edit', loan: latest }); }
    catch (failure) { setError(failure.message); }
    finally { setPendingId(null); }
  }
  function deleteLoan(loan, event) { lastTrigger.current = event.currentTarget; setDialog({ type: 'delete', loan }); }
  function saved(message) { closeDialog(); setNotice(message); load(); }
  function clearFilters() { setFilter('all'); setSearch(''); }
  const hasFilters = filter !== 'all' || search !== '';
  const stats = summarizeLoans(loans);
  const visible = filterLoans(loans, search, filter);
  const statusFilters = [['all', 'All loans'], ['active', 'Active'], ['requested', 'Requested'], ['collected', 'Collected'], ['returned', 'Returned'], ['overdue', 'Overdue']];
  const changing = pendingId !== null;
  return <div className="app-shell">
    <a className="skip-link" href="#main">Skip to loan register</a>
    <aside className="sidebar" aria-label="Equipment desk navigation">
      <a className="brand" href="#main" aria-label="LabLedger home"><span className="brand-mark"><i /><i /></span><span>LabLedger<span className="brand-subtitle">Campus equipment desk</span></span></a>
      <div className="sidebar-line" />
      <nav className="desk-nav" aria-label="Loan views">
        <button className={filter !== 'returned' && filter !== 'overdue' ? 'nav-item active' : 'nav-item'} onClick={() => setFilter('all')}><Icon name="ledger" /><span>Loan register</span><span className="nav-count">{loading ? '—' : stats.total}</span></button>
        <button className={filter === 'overdue' ? 'nav-item active' : 'nav-item'} onClick={() => setFilter('overdue')}><Icon name="clock" /><span>Overdue returns</span>{stats.overdue > 0 && <span className="nav-alert">{stats.overdue}</span>}</button>
        <button className={filter === 'returned' ? 'nav-item active' : 'nav-item'} onClick={() => setFilter('returned')}><Icon name="check" /><span>Returned items</span></button>
      </nav>
      <div className="desk-guide"><div className="guide-icon"><Icon name="box" size={25} /></div><h2>Borrow. Build. Bring it back.</h2><p>Keep campus equipment moving, with a clear record from request to return.</p><div className="loan-steps"><span>Request</span><Icon name="arrow" size={14} /><span>Collect</span><Icon name="arrow" size={14} /><span>Return</span></div></div>
      <div className="sidebar-footer"><span className="desk-avatar">LL</span><div><strong>The lending desk</strong><span>Shared lab workspace</span></div></div>
    </aside>
    <div className="workspace">
      <header className="topbar"><span className="breadcrumb">Workspace <span>/</span> Equipment loans</span><span className="today-label">{formatDate(todayISO())}</span></header>
      <main id="main" tabIndex="-1">
        <div className="page-heading"><div><h1>Good equipment.<br /><span>In good hands.</span></h1><p>One place for every request, collection and return.</p></div><button className="button primary new-loan" onClick={createLoan}><Icon name="plus" size={20} />New loan</button></div>
        <section className="summary" aria-label="Loan overview">
          {[['total', 'In the register', 'Every loan recorded', 'ledger', 'all'], ['active', 'Active loans', 'Requested or collected', 'box', 'active'], ['overdue', 'Overdue returns', 'Collected, past the due date', 'clock', 'overdue'], ['returned', 'Back at the lab', 'Returned equipment', 'check', 'returned']].map(([key, title, description, icon, view]) => <button key={key} className={`summary-item ${key === 'overdue' && stats.overdue ? 'needs-attention' : ''}`} onClick={() => setFilter(view)} aria-label={`${title}: ${loading ? 'loading' : stats[key]}. Show ${view === 'all' ? 'all loans' : view}.`}><div className="summary-title"><span>{title}</span><Icon name={icon} size={19} /></div><strong>{loading ? '—' : stats[key]}</strong><span className="summary-description">{description}</span></button>)}
        </section>
        <section className="register" aria-labelledby="register-title">
          <div className="register-heading"><div><h2 id="register-title">The loan register</h2><p role="status" aria-live="polite" aria-atomic="true">{loading ? 'Checking the equipment desk…' : `${visible.length} ${visible.length === 1 ? 'loan' : 'loans'}${filter !== 'all' || search ? ' in this view' : ' across the campus lab'}`}</p></div><div className="register-actions">{hasFilters && <button className="button text-button clear-filters" type="button" onClick={clearFilters} aria-label="Clear search and status filters">Show all loans</button>}<button className="button text-button refresh" onClick={load} disabled={loading || changing} aria-label="Refresh loan register"><Icon name="refresh" size={17} /><span>Refresh</span></button></div></div>
          <div className="register-toolbar"><div className="filter-tabs" aria-label="Filter loans">{statusFilters.map(([value, label]) => <button key={value} aria-pressed={filter === value} className={filter === value ? 'filter-tab selected' : 'filter-tab'} onClick={() => setFilter(value)}>{label}{value === 'overdue' && stats.overdue > 0 && <span>{stats.overdue}</span>}</button>)}</div><label className="search-field"><Icon name="search" size={18} /><span className="sr-only">Search equipment, borrowers and notes</span><input type="search" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search equipment or borrower" /></label></div>
          {error && <div className="error-banner" role="alert"><Icon name="alert" size={20} /><div><strong>The register needs attention</strong><p>{error}</p></div><button type="button" onClick={load} className="button secondary" disabled={loading}>Try again</button></div>}
          {loading ? <div className="loading-state" role="status"><span className="spinner" />Loading equipment loans…</div> : visible.length === 0 ? <div className="empty-state"><div className="empty-icon"><Icon name={loans.length ? 'search' : 'box'} size={33} /></div><h3>{error ? 'The register is unavailable' : loans.length ? 'No loans match this view' : 'Your equipment desk starts here'}</h3><p>{error ? 'Use Try again to reconnect before making changes.' : loans.length ? 'Try another status or search for a different borrower.' : 'Create the first loan to keep track of who has what, and when it comes back.'}</p>{!error && (loans.length ? <button className="button secondary" onClick={clearFilters}>Clear filters</button> : <button className="button primary" onClick={createLoan}><Icon name="plus" size={18} />Create your first loan</button>)}</div> : <div className="loan-table"><p className="table-scroll-hint" id="table-scroll-hint"><Icon name="arrow" size={16} /><span>Scroll sideways to see return dates, status and actions.</span></p><div className="table-scroll" tabIndex="0" role="region" aria-label="Equipment loan table" aria-describedby="table-scroll-hint"><table><thead><tr><th scope="col">Equipment / notes</th><th scope="col">Borrower</th><th scope="col">Return by</th><th scope="col">Status</th><th scope="col" className="actions-heading">Actions</th></tr></thead><tbody>{visible.map((loan) => <tr key={loan.id}><td><div className="equipment-cell"><span className="equipment-icon"><Icon name="box" size={21} /></span><div><strong>{loan.equipment}</strong><span className="equipment-note">{loan.notes || 'No additional notes'}</span></div></div></td><td><span className="borrower">{loan.borrower}</span></td><td><span className={isOverdue(loan) ? 'due-date overdue-date' : 'due-date'}>{formatDate(loan.due_date)}</span>{isOverdue(loan) && <span className="overdue-label"><Icon name="clock" size={12} />Overdue</span>}</td><td><span className={`status-badge status-${loan.status}`}><i />{STATUS_LABEL[loan.status] ?? loan.status}</span></td><td><div className="row-actions"><button className="icon-button" disabled={changing} onClick={(event) => editLoan(loan, event)} aria-label={`Edit ${loan.equipment} loan`} title="Edit loan">{pendingId === loan.id ? <span className="small-spinner" /> : <Icon name="edit" size={18} />}</button><button className="icon-button delete-action" disabled={changing} onClick={(event) => deleteLoan(loan, event)} aria-label={`Delete ${loan.equipment} loan`} title="Delete loan"><Icon name="trash" size={18} /></button></div></td></tr>)}</tbody></table></div></div>}
          <div className="register-footnote"><Icon name="ledger" size={16} /><span>Keep returned loans as history. Delete only records you no longer need.</span></div>
        </section>
        <footer className="page-footer"><span>LabLedger</span><span>Shared equipment. Clear returns.</span></footer>
      </main>
    </div>
    <div className={`toast ${notice ? 'visible' : ''}`} role="status" aria-live="polite">{notice && <><Icon name="check" size={18} />{notice}</>}</div>
    {dialog && (dialog.type === 'delete' ? <DeleteDialog loan={dialog.loan} onClose={closeDialog} onDeleted={saved} /> : <LoanDialog loan={dialog.loan} onClose={closeDialog} onSaved={saved} />)}
  </div>;
}
