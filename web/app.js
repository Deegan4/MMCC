// ═══════════════════════════════════════════════════════════════
// MMCC HVAC Invoice Generator — Progressive Web App
// ═══════════════════════════════════════════════════════════════

// ─── Service Worker Registration ───
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').catch(() => {});
}

// ─── Data Layer (localStorage) ───
const DB = {
  _get(key) { try { return JSON.parse(localStorage.getItem('mmcc_' + key)) || null; } catch { return null; } },
  _set(key, val) { localStorage.setItem('mmcc_' + key, JSON.stringify(val)); },

  getProfile() { return this._get('profile') || { businessName:'', phone:'', email:'', street:'', city:'', state:'', zip:'', license:'', taxRate:7, markup:0 }; },
  saveProfile(p) { this._set('profile', p); },

  getCustomers() { return this._get('customers') || []; },
  saveCustomers(c) { this._set('customers', c); },
  addCustomer(c) { const all = this.getCustomers(); c.id = Date.now().toString(36) + Math.random().toString(36).slice(2,6); all.push(c); this.saveCustomers(all); return c; },
  updateCustomer(c) { const all = this.getCustomers(); const i = all.findIndex(x => x.id === c.id); if (i >= 0) all[i] = c; this.saveCustomers(all); },
  deleteCustomer(id) { this.saveCustomers(this.getCustomers().filter(c => c.id !== id)); },

  getInvoices() { return this._get('invoices') || []; },
  saveInvoices(inv) { this._set('invoices', inv); },
  nextInvoiceNum() { const all = this.getInvoices(); return all.length ? Math.max(...all.map(i => i.number)) + 1 : 1; },
  addInvoice(inv) { const all = this.getInvoices(); inv.id = Date.now().toString(36) + Math.random().toString(36).slice(2,6); inv.number = this.nextInvoiceNum(); inv.createdAt = new Date().toISOString(); all.push(inv); this.saveInvoices(all); return inv; },
  updateInvoice(inv) { const all = this.getInvoices(); const i = all.findIndex(x => x.id === inv.id); if (i >= 0) all[i] = inv; this.saveInvoices(all); },
  deleteInvoice(id) { this.saveInvoices(this.getInvoices().filter(i => i.id !== id)); },
  getInvoice(id) { return this.getInvoices().find(i => i.id === id) || null; },

  isOnboarded() { return this._get('onboarded') === true; },
  setOnboarded() { this._set('onboarded', true); },
};

// ─── Formatting Helpers ───
const fmt = {
  usd(n) { return '$' + Number(n || 0).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ','); },
  date(d) { if (!d) return ''; const dt = new Date(d); return dt.toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' }); },
  invNum(n) { return 'INV-' + String(n).padStart(3, '0'); },
  dueDate(inv) {
    if (!inv.sentAt) return null;
    const sent = new Date(inv.sentAt);
    const terms = inv.paymentTerms || 'Due on Receipt';
    const days = terms === 'Net 15' ? 15 : terms === 'Net 30' ? 30 : terms === 'Net 45' ? 45 : terms === 'Net 60' ? 60 : 0;
    if (days === 0) return sent;
    return new Date(sent.getTime() + days * 86400000);
  },
  isOverdue(inv) {
    if (inv.status === 'paid' || inv.status === 'void' || inv.status === 'draft') return false;
    const due = this.dueDate(inv);
    return due && due < new Date();
  },
};

const PAYMENT_TERMS = ['Due on Receipt','Net 15','Net 30','Net 45','Net 60','50/50','1/3-1/3-1/3'];

// ─── Calc Helpers ───
function calcSection(sec) {
  return (sec.items || []).reduce((s, it) => s + (Number(it.qty) || 0) * (Number(it.price) || 0), 0);
}
function calcInvoice(inv) {
  const subtotal = (inv.sections || []).reduce((s, sec) => s + calcSection(sec), 0);
  const markupAmt = inv.markup > 0 ? subtotal * inv.markup / 100 : 0;
  const afterMarkup = subtotal + markupAmt;
  const taxAmt = inv.taxRate > 0 ? afterMarkup * inv.taxRate / 100 : 0;
  const total = afterMarkup + taxAmt;
  const paid = (inv.payments || []).reduce((s, p) => s + Number(p.amount || 0), 0);
  return { subtotal, markupAmt, afterMarkup, taxAmt, total, paid, due: total - paid };
}


// ─── HVAC Templates ───
const TEMPLATES = [
  { name: 'AC Replacement — 3-Ton Split', sections: [
    { name: 'Equipment', items: [
      { desc: '3-ton 16 SEER2 condenser unit', qty: 1, price: 2800, unit: 'ea' },
      { desc: 'Matching evaporator coil', qty: 1, price: 850, unit: 'ea' },
      { desc: 'Programmable thermostat (Wi-Fi)', qty: 1, price: 250, unit: 'ea' },
    ]},
    { name: 'Refrigerant & Piping', items: [
      { desc: 'R-410A refrigerant charge', qty: 1, price: 350, unit: 'ls' },
      { desc: 'Line set — insulated copper', qty: 25, price: 18, unit: 'lf' },
      { desc: 'Condensate drain line and trap', qty: 1, price: 125, unit: 'ls' },
    ]},
    { name: 'Electrical', items: [
      { desc: 'Disconnect box and whip', qty: 1, price: 185, unit: 'ea' },
      { desc: 'Electrical connections and wiring', qty: 1, price: 350, unit: 'ls' },
    ]},
    { name: 'Labor', items: [
      { desc: 'System removal and disposal', qty: 1, price: 500, unit: 'ls' },
      { desc: 'Installation labor — 2 technicians', qty: 8, price: 95, unit: 'hr' },
      { desc: 'Start-up, charge, and commissioning', qty: 1, price: 250, unit: 'ls' },
    ]},
    { name: 'Permits & Inspection', items: [
      { desc: 'Mechanical permit', qty: 1, price: 250, unit: 'ea' },
      { desc: 'City/county inspection', qty: 1, price: 150, unit: 'ea' },
    ]},
  ], notes: 'Scope: Remove existing condenser and evaporator coil. Install new 3-ton 16 SEER2 split system. Includes electrical and refrigerant charge. Does not include ductwork modifications. Timeline: 1 day.', terms: 'Payment: 50% deposit, 50% at completion. Valid 30 days. 10-year parts warranty. 1-year labor warranty.' },

  { name: 'Full HVAC System — 4-Ton', sections: [
    { name: 'Equipment', items: [
      { desc: '4-ton 18 SEER2 variable-speed condenser', qty: 1, price: 4200, unit: 'ea' },
      { desc: 'Variable-speed air handler', qty: 1, price: 2800, unit: 'ea' },
      { desc: 'Smart thermostat', qty: 1, price: 350, unit: 'ea' },
      { desc: 'UV germicidal light', qty: 1, price: 450, unit: 'ea' },
    ]},
    { name: 'Ductwork', items: [
      { desc: 'Supply ductwork — insulated flex', qty: 150, price: 12, unit: 'lf' },
      { desc: 'Return ductwork — rigid metal', qty: 30, price: 22, unit: 'lf' },
      { desc: 'Registers and grilles', qty: 12, price: 35, unit: 'ea' },
      { desc: 'Duct sealing (mastic)', qty: 1, price: 450, unit: 'ls' },
    ]},
    { name: 'Refrigerant & Piping', items: [
      { desc: 'R-410A refrigerant charge', qty: 1, price: 450, unit: 'ls' },
      { desc: 'Line set — insulated copper', qty: 35, price: 18, unit: 'lf' },
    ]},
    { name: 'Labor', items: [
      { desc: 'Old system removal and disposal', qty: 1, price: 750, unit: 'ls' },
      { desc: 'Installation labor', qty: 16, price: 95, unit: 'hr' },
      { desc: 'Start-up and commissioning', qty: 1, price: 350, unit: 'ls' },
    ]},
    { name: 'Permits & Inspection', items: [
      { desc: 'Mechanical permit', qty: 1, price: 350, unit: 'ea' },
      { desc: 'Manual J load calculation', qty: 1, price: 300, unit: 'ea' },
    ]},
  ], notes: 'Scope: Complete HVAC system replacement including condenser, air handler, ductwork, and thermostat. Timeline: 2-3 days.', terms: 'Payment: 1/3 at signing, 1/3 at rough-in, 1/3 at completion. Valid 30 days.' },

  { name: 'Mini-Split — Single Zone 12K BTU', sections: [
    { name: 'Equipment', items: [
      { desc: '12,000 BTU ductless mini-split outdoor unit', qty: 1, price: 1200, unit: 'ea' },
      { desc: 'Wall-mounted indoor head', qty: 1, price: 650, unit: 'ea' },
    ]},
    { name: 'Refrigerant & Piping', items: [
      { desc: 'Pre-charged line set', qty: 25, price: 15, unit: 'lf' },
      { desc: 'Line set cover (outdoor)', qty: 15, price: 8, unit: 'lf' },
      { desc: 'Condensate drain line', qty: 1, price: 85, unit: 'ls' },
    ]},
    { name: 'Electrical', items: [
      { desc: 'Dedicated 20A circuit', qty: 1, price: 450, unit: 'ls' },
      { desc: 'Disconnect box', qty: 1, price: 125, unit: 'ea' },
    ]},
    { name: 'Labor', items: [
      { desc: 'Installation labor', qty: 6, price: 95, unit: 'hr' },
      { desc: 'Wall penetration and sealing', qty: 1, price: 150, unit: 'ls' },
    ]},
  ], notes: 'Scope: Single-zone ductless mini-split. Includes indoor/outdoor units, line set, electrical, and drain. Timeline: 1 day.', terms: 'Payment: 50% deposit, 50% at completion. Valid 30 days.' },

  { name: 'Furnace Install — 80K BTU', sections: [
    { name: 'Equipment', items: [
      { desc: '80,000 BTU 96% AFUE gas furnace', qty: 1, price: 2200, unit: 'ea' },
      { desc: 'Matching evaporator coil', qty: 1, price: 750, unit: 'ea' },
      { desc: 'Programmable thermostat', qty: 1, price: 200, unit: 'ea' },
    ]},
    { name: 'Materials', items: [
      { desc: 'PVC flue venting', qty: 25, price: 18, unit: 'lf' },
      { desc: 'Gas piping and connections', qty: 1, price: 450, unit: 'ls' },
      { desc: 'Condensate drain', qty: 1, price: 125, unit: 'ls' },
    ]},
    { name: 'Labor', items: [
      { desc: 'Old furnace removal', qty: 1, price: 400, unit: 'ls' },
      { desc: 'Installation labor', qty: 8, price: 95, unit: 'hr' },
      { desc: 'Start-up and combustion analysis', qty: 1, price: 250, unit: 'ls' },
    ]},
    { name: 'Permits', items: [
      { desc: 'Mechanical + gas permit', qty: 1, price: 300, unit: 'ea' },
    ]},
  ], notes: 'Scope: Replace furnace with new 96% AFUE gas furnace. Includes venting, gas piping, thermostat. Timeline: 1 day.', terms: 'Payment: 50% deposit, 50% at completion. Valid 30 days.' },

  { name: 'Ductwork Replacement', sections: [
    { name: 'Ductwork', items: [
      { desc: 'Insulated flex duct — supply', qty: 200, price: 10, unit: 'lf' },
      { desc: 'Rigid metal trunk line', qty: 40, price: 25, unit: 'lf' },
      { desc: 'Supply registers and grilles', qty: 12, price: 35, unit: 'ea' },
      { desc: 'Return air grilles', qty: 3, price: 55, unit: 'ea' },
    ]},
    { name: 'Insulation & Sealing', items: [
      { desc: 'Duct sealing — mastic and tape', qty: 1, price: 500, unit: 'ls' },
    ]},
    { name: 'Labor', items: [
      { desc: 'Old duct removal', qty: 1, price: 800, unit: 'ls' },
      { desc: 'Installation labor', qty: 16, price: 85, unit: 'hr' },
      { desc: 'Duct leakage test', qty: 1, price: 250, unit: 'ls' },
    ]},
  ], notes: 'Scope: Complete ductwork replacement. All joints sealed with mastic. Leakage test included. Timeline: 2-3 days.', terms: 'Payment: 50% at signing, 50% at completion. Valid 30 days.' },

  { name: 'Heat Pump — 3-Ton Dual Fuel', sections: [
    { name: 'Equipment', items: [
      { desc: '3-ton 17 SEER2 heat pump condenser', qty: 1, price: 3500, unit: 'ea' },
      { desc: 'Air handler with backup heat strip', qty: 1, price: 2400, unit: 'ea' },
      { desc: 'Smart thermostat with dual-fuel control', qty: 1, price: 350, unit: 'ea' },
    ]},
    { name: 'Refrigerant & Piping', items: [
      { desc: 'R-410A refrigerant charge', qty: 1, price: 400, unit: 'ls' },
      { desc: 'Line set — insulated copper', qty: 30, price: 18, unit: 'lf' },
    ]},
    { name: 'Electrical', items: [
      { desc: 'Disconnect and whip', qty: 1, price: 185, unit: 'ea' },
      { desc: 'Electrical wiring', qty: 1, price: 650, unit: 'ls' },
    ]},
    { name: 'Labor', items: [
      { desc: 'Old system removal', qty: 1, price: 650, unit: 'ls' },
      { desc: 'Installation labor', qty: 12, price: 95, unit: 'hr' },
      { desc: 'Start-up and commissioning', qty: 1, price: 350, unit: 'ls' },
    ]},
    { name: 'Permits', items: [
      { desc: 'Mechanical permit', qty: 1, price: 300, unit: 'ea' },
      { desc: 'Manual J load calc', qty: 1, price: 300, unit: 'ea' },
    ]},
  ], notes: 'Scope: Heat pump with variable-speed air handler and backup heat. Manual J included. Timeline: 1-2 days.', terms: 'Payment: 1/3 deposit, 1/3 rough-in, 1/3 completion. Valid 30 days.' },

  { name: 'Maintenance Agreement — Annual', sections: [
    { name: 'Service', items: [
      { desc: 'Spring AC tune-up', qty: 1, price: 175, unit: 'ea' },
      { desc: 'Fall heating tune-up', qty: 1, price: 175, unit: 'ea' },
      { desc: 'Air filters (2 changes)', qty: 2, price: 25, unit: 'ea' },
    ]},
  ], notes: 'Annual maintenance: 2 visits, filter changes, coil cleaning, refrigerant check, safety test. 15% discount on repairs.', terms: 'Payment due at first visit. Cancel anytime with 30-day notice.' },

  { name: 'Refrigerant Recharge & Leak Repair', sections: [
    { name: 'Refrigerant & Piping', items: [
      { desc: 'R-410A refrigerant (per lb)', qty: 5, price: 65, unit: 'lb' },
      { desc: 'Leak detection — electronic and UV', qty: 1, price: 175, unit: 'ls' },
      { desc: 'Braze leak repair (per joint)', qty: 2, price: 185, unit: 'ea' },
    ]},
    { name: 'Labor', items: [
      { desc: 'Diagnostic and evaluation', qty: 1, price: 125, unit: 'ls' },
      { desc: 'Repair labor', qty: 3, price: 95, unit: 'hr' },
      { desc: 'Nitrogen pressure test', qty: 1, price: 150, unit: 'ls' },
      { desc: 'Vacuum and recharge', qty: 1, price: 200, unit: 'ls' },
    ]},
  ], notes: 'Scope: Locate leak, braze repair, pressure test, evacuate, recharge. Refrigerant billed per pound.', terms: 'Payment due at completion. 90-day repair warranty.' },
];

const HVAC_SECTIONS = ['Equipment','Ductwork','Refrigerant & Piping','Electrical','Controls & Thermostats','Insulation','Permits & Inspection','Labor','Materials & Supplies','Other'];


// ─── App State & Routing ───
const App = {
  tab: 'dashboard',
  screen: null, // null = list, string = detail screen
  editingInvoice: null,
  editingCustomer: null,
  modal: null,

  init() {
    if (!DB.isOnboarded()) {
      this.renderOnboarding();
    } else {
      this.render();
    }
  },

  setTab(t) { this.tab = t; this.screen = null; this.editingInvoice = null; this.render(); },
  push(screen, data) { this.screen = screen; if (data) this._screenData = data; this.render(); },
  pop() { this.screen = null; this._screenData = null; this.render(); },

  render() {
    const app = document.getElementById('app');
    let navHtml = '';
    let screenHtml = '';

    if (this.screen === 'invoiceEdit') {
      const r = this.renderInvoiceEditor();
      navHtml = r.nav;
      screenHtml = r.body;
    } else if (this.screen === 'invoiceView') {
      const r = this.renderInvoiceView();
      navHtml = r.nav;
      screenHtml = r.body;
    } else if (this.screen === 'customerEdit') {
      const r = this.renderCustomerEditor();
      navHtml = r.nav;
      screenHtml = r.body;
    } else if (this.screen === 'templatePicker') {
      const r = this.renderTemplatePicker();
      navHtml = r.nav;
      screenHtml = r.body;
    } else {
      switch (this.tab) {
        case 'dashboard': navHtml = '<div class="nav-bar"><button>&nbsp;</button><h1>Dashboard</h1><button>&nbsp;</button></div>'; screenHtml = this.renderDashboard(); break;
        case 'invoices': navHtml = `<div class="nav-bar"><button>&nbsp;</button><h1>Invoices</h1><button onclick="App.push('templatePicker')">＋</button></div>`; screenHtml = this.renderInvoiceList(); break;
        case 'customers': navHtml = `<div class="nav-bar"><button>&nbsp;</button><h1>Customers</h1><button onclick="App.push('customerEdit')">＋</button></div>`; screenHtml = this.renderCustomerList(); break;
        case 'settings': navHtml = '<div class="nav-bar"><button>&nbsp;</button><h1>Settings</h1><button>&nbsp;</button></div>'; screenHtml = this.renderSettings(); break;
      }
    }

    const tabBar = this.screen ? '' : `
      <div class="tab-bar">
        <button class="${this.tab==='dashboard'?'active':''}" onclick="App.setTab('dashboard')"><span class="tab-icon">📊</span>Dashboard</button>
        <button class="${this.tab==='invoices'?'active':''}" onclick="App.setTab('invoices')"><span class="tab-icon">📄</span>Invoices</button>
        <button class="${this.tab==='customers'?'active':''}" onclick="App.setTab('customers')"><span class="tab-icon">👤</span>Customers</button>
        <button class="${this.tab==='settings'?'active':''}" onclick="App.setTab('settings')"><span class="tab-icon">⚙️</span>Settings</button>
      </div>`;

    app.innerHTML = navHtml + `<div class="screen">${screenHtml}</div>` + tabBar;
  },

  // ─── Onboarding ───
  renderOnboarding() {
    document.getElementById('app').innerHTML = `
      <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;background:linear-gradient(var(--navy),var(--navy-mid),var(--navy));padding:40px;text-align:center;">
        <div style="font-size:72px;margin-bottom:24px;">❄️</div>
        <h1 style="color:#fff;font-size:28px;font-weight:300;font-style:italic;margin-bottom:8px;">HVAC Invoices,</h1>
        <h1 style="color:#fff;font-size:28px;font-weight:300;font-style:italic;margin-bottom:16px;">Made Simple</h1>
        <p style="color:var(--gold);font-size:13px;letter-spacing:1.5px;margin-bottom:40px;">ESTIMATES & INVOICES<br>FOR HVAC CONTRACTORS</p>
        <button class="btn btn-primary" style="max-width:280px;" onclick="App.completeOnboarding()">Get Started</button>
      </div>`;
  },
  completeOnboarding() { DB.setOnboarded(); this.render(); },


  // ─── Dashboard ───
  renderDashboard() {
    const invoices = DB.getInvoices();
    const unpaid = invoices.filter(i => i.status === 'sent' || i.status === 'partiallyPaid' || i.status === 'overdue');
    const unpaidTotal = unpaid.reduce((s, i) => s + calcInvoice(i).due, 0);
    const paidThisMonth = invoices.filter(i => {
      if (i.status !== 'paid') return false;
      const d = new Date(i.createdAt);
      const now = new Date();
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
    });
    const paidTotal = paidThisMonth.reduce((s, i) => s + calcInvoice(i).total, 0);
    const recent = invoices.slice().sort((a,b) => b.number - a.number).slice(0, 5);

    let recentHtml = '';
    if (recent.length) {
      recentHtml = '<div class="form-group-title">RECENT INVOICES</div>';
      recent.forEach(inv => {
        const c = calcInvoice(inv);
        const cust = inv.customerId ? DB.getCustomers().find(x => x.id === inv.customerId) : null;
        recentHtml += `
          <div class="card" style="cursor:pointer" onclick="App.viewInvoice('${inv.id}')">
            <div class="card-header">
              <span class="card-number">${fmt.invNum(inv.number)}</span>
              <span class="badge badge-${inv.status}">${inv.status}</span>
            </div>
            <div style="font-size:15px;font-weight:600;">${cust ? cust.name : 'No Customer'}</div>
            <div style="display:flex;justify-content:space-between;margin-top:6px;">
              <span class="text-small text-muted">${fmt.date(inv.createdAt)}</span>
              <span class="fw-bold mono">${fmt.usd(c.due)}</span>
            </div>
          </div>`;
      });
    } else {
      recentHtml = `
        <div class="empty-state">
          <div class="icon">📄</div>
          <h3>No Invoices Yet</h3>
          <p>Create your first HVAC invoice</p>
          <button class="btn btn-primary" style="max-width:200px" onclick="App.setTab('invoices');App.push('templatePicker')">New Invoice</button>
        </div>`;
    }

    return `
      <div style="padding-top:12px">
        <div class="stats-row">
          <div class="stat-card"><div class="stat-value">${invoices.length}</div><div class="stat-label">Total</div></div>
          <div class="stat-card"><div class="stat-value">${unpaid.length}</div><div class="stat-label">Unpaid</div></div>
          <div class="stat-card"><div class="stat-value">${fmt.usd(unpaidTotal)}</div><div class="stat-label">Outstanding</div></div>
        </div>
        <div class="stats-row">
          <div class="stat-card" style="flex:1"><div class="stat-value text-green">${fmt.usd(paidTotal)}</div><div class="stat-label">Collected This Month</div></div>
        </div>
        ${recentHtml}
      </div>`;
  },

  // ─── Invoice List ───
  _invoiceFilter: 'all',
  _invoiceSearch: '',

  renderInvoiceList() {
    let invoices = DB.getInvoices().sort((a,b) => b.number - a.number);
    if (!invoices.length) {
      return `
        <div class="empty-state">
          <div class="icon">📄</div>
          <h3>No Invoices Yet</h3>
          <p>Create your first HVAC invoice from a template or start blank</p>
          <button class="btn btn-primary" style="max-width:220px" onclick="App.push('templatePicker')">New Invoice</button>
        </div>`;
    }

    // Filter
    if (this._invoiceFilter !== 'all') {
      if (this._invoiceFilter === 'overdue') {
        invoices = invoices.filter(i => fmt.isOverdue(i));
      } else {
        invoices = invoices.filter(i => i.status === this._invoiceFilter);
      }
    }

    // Search
    if (this._invoiceSearch) {
      const q = this._invoiceSearch.toLowerCase();
      invoices = invoices.filter(inv => {
        const cust = inv.customerId ? DB.getCustomers().find(x => x.id === inv.customerId) : null;
        return fmt.invNum(inv.number).toLowerCase().includes(q) || (cust && cust.name.toLowerCase().includes(q)) || (inv.jobAddress||'').toLowerCase().includes(q);
      });
    }

    const filters = ['all','draft','sent','partiallyPaid','paid','overdue','void'];
    const filterLabels = { all:'All', draft:'Draft', sent:'Sent', partiallyPaid:'Partial', paid:'Paid', overdue:'Overdue', void:'Void' };

    let html = '<div style="padding-top:12px">';

    // Search bar
    html += `<div class="form-group" style="margin-bottom:8px"><div class="form-row"><input type="search" placeholder="Search invoices..." value="${this._invoiceSearch}" oninput="App._invoiceSearch=this.value;App.render()" style="text-align:left"></div></div>`;

    // Filter chips
    html += '<div style="display:flex;gap:6px;overflow-x:auto;padding:4px 0 12px;-webkit-overflow-scrolling:touch">';
    filters.forEach(f => {
      const active = this._invoiceFilter === f;
      html += `<button style="flex-shrink:0;padding:6px 12px;border-radius:20px;border:none;font-size:12px;font-weight:500;cursor:pointer;background:${active?'var(--amber)':'var(--card)'};color:${active?'#fff':'var(--text2)'}" onclick="App._invoiceFilter='${f}';App.render()">${filterLabels[f]}</button>`;
    });
    html += '</div>';

    if (!invoices.length) {
      html += '<div class="text-center text-muted" style="padding:40px 0">No invoices match this filter</div>';
    }

    invoices.forEach(inv => {
      const c = calcInvoice(inv);
      const cust = inv.customerId ? DB.getCustomers().find(x => x.id === inv.customerId) : null;
      const overdue = fmt.isOverdue(inv);
      const due = fmt.dueDate(inv);
      html += `
        <div class="card" style="cursor:pointer;${overdue?'border-left:3px solid var(--red)':''}" onclick="App.viewInvoice('${inv.id}')">
          <div class="card-header">
            <span class="card-number">${fmt.invNum(inv.number)}</span>
            <span class="badge badge-${overdue?'overdue':inv.status}">${overdue?'overdue':inv.status}</span>
          </div>
          <div style="font-size:15px;font-weight:600;">${cust ? cust.name : 'No Customer'}</div>
          <div style="display:flex;justify-content:space-between;margin-top:6px;">
            <span class="text-small text-muted">${fmt.date(inv.createdAt)}${due && inv.status!=='paid' && inv.status!=='void' ? ' · Due '+fmt.date(due) : ''}</span>
            <span class="fw-bold mono ${overdue?'text-red':''}">${fmt.usd(c.due > 0 ? c.due : c.total)}</span>
          </div>
        </div>`;
    });
    html += '</div>';
    return html;
  },

  viewInvoice(id) {
    this._screenData = id;
    this.screen = 'invoiceView';
    this.render();
  },


  // ─── Invoice View (read-only with actions) ───
  renderInvoiceView() {
    const inv = DB.getInvoice(this._screenData);
    if (!inv) return { nav: '', body: '<p>Invoice not found</p>' };
    const c = calcInvoice(inv);
    const cust = inv.customerId ? DB.getCustomers().find(x => x.id === inv.customerId) : null;
    const profile = DB.getProfile();

    let sectionsHtml = '';
    (inv.sections || []).forEach(sec => {
      const secTotal = calcSection(sec);
      sectionsHtml += `<div class="section-header"><span>${sec.name}</span></div><div class="card" style="border-radius:0 0 var(--radius) var(--radius);margin-bottom:12px">`;
      (sec.items || []).forEach(it => {
        const lt = (Number(it.qty)||0) * (Number(it.price)||0);
        sectionsHtml += `
          <div class="line-item">
            <div class="line-item-desc">${it.desc}<div class="line-item-detail">${it.qty} ${it.unit} @ ${fmt.usd(it.price)}</div></div>
            <div class="line-item-total mono">${fmt.usd(lt)}</div>
          </div>`;
      });
      sectionsHtml += `<div class="section-subtotal">Section: ${fmt.usd(secTotal)}</div></div>`;
    });

    let paymentsHtml = '';
    if (inv.payments && inv.payments.length) {
      paymentsHtml = '<div class="form-group-title">PAYMENTS</div><div class="form-group">';
      inv.payments.forEach(p => {
        paymentsHtml += `<div class="form-row"><label>${fmt.date(p.date)}</label><span class="text-muted" style="flex:1">${p.method || ''}</span><span class="fw-bold text-green mono">${fmt.usd(p.amount)}</span></div>`;
      });
      paymentsHtml += '</div>';
    }

    const body = `
      <div style="padding-top:12px">
        <div class="card">
          <div class="card-header"><span class="card-number">${fmt.invNum(inv.number)}</span><span class="badge badge-${inv.status}">${inv.status}</span></div>
          <div style="font-size:13px;color:var(--text2)">${fmt.date(inv.createdAt)}</div>
        </div>

        ${cust ? `<div class="form-group-title">CUSTOMER</div><div class="card"><div class="fw-bold">${cust.name}</div>${cust.phone?'<div class="text-small text-muted">'+cust.phone+'</div>':''}${cust.email?'<div class="text-small text-muted">'+cust.email+'</div>':''}${cust.address?'<div class="text-small text-muted">'+cust.address+'</div>':''}</div>` : ''}

        ${inv.jobAddress ? `<div class="form-group-title">JOB SITE</div><div class="card">${inv.jobAddress}</div>` : ''}

        <div class="form-group-title">LINE ITEMS</div>
        ${sectionsHtml}

        <div class="card">
          <div class="totals-table">
            <div class="totals-row"><span class="label">Subtotal</span><span class="mono">${fmt.usd(c.subtotal)}</span></div>
            ${c.markupAmt > 0 ? `<div class="totals-row"><span class="label">Markup (${inv.markup}%)</span><span class="mono">${fmt.usd(c.markupAmt)}</span></div>` : ''}
            ${c.taxAmt > 0 ? `<div class="totals-row"><span class="label">Tax (${inv.taxRate}%)</span><span class="mono">${fmt.usd(c.taxAmt)}</span></div>` : ''}
            <div class="totals-row grand"><span class="label">Total</span><span class="mono">${fmt.usd(c.total)}</span></div>
            ${c.paid > 0 ? `<div class="totals-row"><span class="label">Paid</span><span class="mono text-green">(${fmt.usd(c.paid)})</span></div><div class="totals-row grand"><span class="label">Balance Due</span><span class="mono ${c.due>0?'text-red':''}">${fmt.usd(c.due)}</span></div>` : ''}
          </div>
        </div>

        ${paymentsHtml}

        ${inv.notes ? `<div class="form-group-title">NOTES</div><div class="card text-small">${inv.notes.replace(/\n/g,'<br>')}</div>` : ''}
        ${inv.terms ? `<div class="form-group-title">TERMS</div><div class="card text-small text-muted">${inv.terms.replace(/\n/g,'<br>')}</div>` : ''}

        <div class="form-group-title">STATUS</div>
        <div class="form-group" style="overflow:hidden">
          <div class="form-row" style="gap:6px;flex-wrap:wrap;justify-content:center;padding:12px 16px">
            ${['draft','sent','partiallyPaid','paid','void'].map(s => `<button style="padding:6px 14px;border-radius:20px;border:1px solid ${inv.status===s?'var(--amber)':'var(--border)'};background:${inv.status===s?'var(--amber)':'var(--card)'};color:${inv.status===s?'#fff':'var(--text2)'};font-size:12px;font-weight:600;cursor:pointer" onclick="App.setInvoiceStatus('${inv.id}','${s}')">${s==='partiallyPaid'?'Partial':s}</button>`).join('')}
          </div>
        </div>

        <div class="form-group-title">ACTIONS</div>
        <div class="form-group" style="border-radius:var(--radius);overflow:hidden">
          <button class="btn-action" onclick="App.emailInvoice('${inv.id}')">📧 Email Invoice</button>
          <button class="btn-action" onclick="App.shareInvoice('${inv.id}')">📤 Share Invoice</button>
          <button class="btn-action" onclick="App.printInvoice('${inv.id}')">🖨 Print / Save PDF</button>
          <button class="btn-action" onclick="App.recordPayment('${inv.id}')">💰 Record Payment</button>
          <button class="btn-action" onclick="App.editInvoice('${inv.id}')">✏️ Edit Invoice</button>
          <button class="btn-action" onclick="App.duplicateInvoice('${inv.id}')">📋 Duplicate Invoice</button>
          <button class="btn-action" style="color:var(--red)" onclick="if(confirm('Delete this invoice?')){DB.deleteInvoice('${inv.id}');App.pop();}">🗑 Delete Invoice</button>
        </div>
      </div>`;

    return {
      nav: `<div class="nav-bar"><button onclick="App.pop()">← Back</button><h1>${fmt.invNum(inv.number)}</h1><button>&nbsp;</button></div>`,
      body
    };
  },

  markSent(id) {
    const inv = DB.getInvoice(id);
    if (inv) { inv.status = 'sent'; inv.sentAt = new Date().toISOString(); DB.updateInvoice(inv); this.render(); }
  },

  setInvoiceStatus(id, status) {
    const inv = DB.getInvoice(id);
    if (!inv) return;
    inv.status = status;
    if (status === 'sent' && !inv.sentAt) inv.sentAt = new Date().toISOString();
    DB.updateInvoice(inv);
    this.render();
  },

  duplicateInvoice(id) {
    const orig = DB.getInvoice(id);
    if (!orig) return;
    const copy = JSON.parse(JSON.stringify(orig));
    delete copy.id;
    copy.status = 'draft';
    copy.payments = [];
    copy.sentAt = null;
    const newInv = DB.addInvoice(copy);
    this.viewInvoice(newInv.id);
  },

  // ─── Share, Email & Print ───
  _buildInvoiceText(inv) {
    const c = calcInvoice(inv);
    const cust = inv.customerId ? DB.getCustomers().find(x => x.id === inv.customerId) : null;
    const profile = DB.getProfile();
    const biz = profile.businessName || 'MMCC';
    const addr = [profile.street, profile.city, profile.state, profile.zip].filter(Boolean).join(', ');

    let text = `INVOICE ${fmt.invNum(inv.number)}\n`;
    text += `From: ${biz}\n`;
    if (addr) text += `${addr}\n`;
    if (profile.phone) text += `${profile.phone}\n`;
    text += `Date: ${fmt.date(inv.createdAt)}\n`;
    if (inv.paymentTerms) text += `Terms: ${inv.paymentTerms}\n`;
    text += `\n`;
    if (cust) {
      text += `Bill To: ${cust.name}\n`;
      if (cust.email) text += `${cust.email}\n`;
      if (cust.phone) text += `${cust.phone}\n`;
      if (cust.address) text += `${cust.address}\n`;
      text += `\n`;
    }
    if (inv.jobAddress) text += `Job Site: ${inv.jobAddress}\n\n`;

    (inv.sections||[]).forEach(sec => {
      text += `--- ${sec.name.toUpperCase()} ---\n`;
      (sec.items||[]).forEach(it => {
        const lt = (Number(it.qty)||0)*(Number(it.price)||0);
        text += `  ${it.desc} — ${it.qty} ${it.unit} × ${fmt.usd(it.price)} = ${fmt.usd(lt)}\n`;
      });
      text += `  Section Total: ${fmt.usd(calcSection(sec))}\n\n`;
    });

    text += `Subtotal: ${fmt.usd(c.subtotal)}\n`;
    if (c.markupAmt > 0) text += `Markup (${inv.markup}%): ${fmt.usd(c.markupAmt)}\n`;
    if (c.taxAmt > 0) text += `Tax (${inv.taxRate}%): ${fmt.usd(c.taxAmt)}\n`;
    text += `TOTAL: ${fmt.usd(c.total)}\n`;
    if (c.paid > 0) { text += `Paid: (${fmt.usd(c.paid)})\nBALANCE DUE: ${fmt.usd(c.due)}\n`; }

    if (inv.notes) text += `\nNotes:\n${inv.notes}\n`;
    if (inv.terms) text += `\nTerms:\n${inv.terms}\n`;

    return text;
  },

  shareInvoice(id) {
    const inv = DB.getInvoice(id);
    if (!inv) return;
    const text = this._buildInvoiceText(inv);

    if (navigator.share) {
      navigator.share({ title: `Invoice ${fmt.invNum(inv.number)}`, text }).catch(() => {});
    } else {
      navigator.clipboard.writeText(text).then(() => alert('Invoice copied to clipboard')).catch(() => alert(text));
    }
  },

  emailInvoice(id) {
    const inv = DB.getInvoice(id);
    if (!inv) return;
    const c = calcInvoice(inv);
    const cust = inv.customerId ? DB.getCustomers().find(x => x.id === inv.customerId) : null;
    const profile = DB.getProfile();
    const biz = profile.businessName || 'MMCC';
    const to = cust && cust.email ? cust.email : '';
    const subject = encodeURIComponent(`Invoice ${fmt.invNum(inv.number)} from ${biz}`);
    const firstName = cust ? (cust.name.split(' ')[0]) : '';
    const body = encodeURIComponent(
      `Hi ${firstName},\n\nPlease find your invoice details below.\n\n` +
      this._buildInvoiceText(inv) +
      `\nThank you,\n${biz}`
    );
    window.location.href = `mailto:${to}?subject=${subject}&body=${body}`;
  },

  printInvoice(id) {
    const inv = DB.getInvoice(id);
    if (!inv) return;
    const html = this.generatePrintHTML(inv);
    const win = window.open('', '_blank');
    if (win) {
      win.document.write(html);
      win.document.close();
      setTimeout(() => win.print(), 300);
    }
  },

  generatePrintHTML(inv) {
    const c = calcInvoice(inv);
    const cust = inv.customerId ? DB.getCustomers().find(x => x.id === inv.customerId) : null;
    const profile = DB.getProfile();
    const esc = s => (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');

    let sectionsHtml = '';
    (inv.sections||[]).forEach(sec => {
      const st = calcSection(sec);
      sectionsHtml += `<h3 style="font-size:12px;color:#AF6118;border-bottom:1px solid #ddd;padding-bottom:4px;margin-top:16px">${esc(sec.name)}</h3>`;
      sectionsHtml += '<table style="width:100%;border-collapse:collapse;margin-bottom:8px"><tr><th style="background:#f0f0f0;padding:5px 8px;text-align:left;font-size:9px;text-transform:uppercase;border-bottom:1px solid #ddd">Description</th><th style="background:#f0f0f0;padding:5px 8px;font-size:9px;text-transform:uppercase;border-bottom:1px solid #ddd">Qty</th><th style="background:#f0f0f0;padding:5px 8px;font-size:9px;text-transform:uppercase;border-bottom:1px solid #ddd">Unit</th><th style="background:#f0f0f0;padding:5px 8px;text-align:right;font-size:9px;text-transform:uppercase;border-bottom:1px solid #ddd">Price</th><th style="background:#f0f0f0;padding:5px 8px;text-align:right;font-size:9px;text-transform:uppercase;border-bottom:1px solid #ddd">Total</th></tr>';
      (sec.items||[]).forEach(it => {
        const lt = (Number(it.qty)||0)*(Number(it.price)||0);
        sectionsHtml += `<tr><td style="padding:4px 8px;border-bottom:1px solid #eee;font-size:10px">${esc(it.desc)}</td><td style="padding:4px 8px;border-bottom:1px solid #eee;font-size:10px;text-align:right">${it.qty}</td><td style="padding:4px 8px;border-bottom:1px solid #eee;font-size:10px;text-align:right">${esc(it.unit)}</td><td style="padding:4px 8px;border-bottom:1px solid #eee;font-size:10px;text-align:right">${fmt.usd(it.price)}</td><td style="padding:4px 8px;border-bottom:1px solid #eee;font-size:10px;text-align:right">${fmt.usd(lt)}</td></tr>`;
      });
      sectionsHtml += `<tr style="background:#f8f8f8;font-weight:600"><td colspan="4" style="padding:4px 8px;border-top:1px solid #ddd;font-size:10px">Section Total</td><td style="padding:4px 8px;border-top:1px solid #ddd;font-size:10px;text-align:right">${fmt.usd(st)}</td></tr></table>`;
    });

    let paymentsHtml = '';
    if (inv.payments && inv.payments.length) {
      paymentsHtml = '<div style="margin-top:16px;padding-top:8px;border-top:1px solid #eee"><h3 style="font-size:10px;color:#999;text-transform:uppercase;letter-spacing:1px;margin:0 0 4px">Payments Received</h3><table style="width:100%;border-collapse:collapse"><tr><th style="background:#f0f0f0;padding:5px 8px;text-align:left;font-size:9px;border-bottom:1px solid #ddd">Date</th><th style="background:#f0f0f0;padding:5px 8px;font-size:9px;border-bottom:1px solid #ddd">Method</th><th style="background:#f0f0f0;padding:5px 8px;text-align:right;font-size:9px;border-bottom:1px solid #ddd">Amount</th></tr>';
      inv.payments.forEach(p => { paymentsHtml += `<tr><td style="padding:4px 8px;font-size:10px;border-bottom:1px solid #eee">${fmt.date(p.date)}</td><td style="padding:4px 8px;font-size:10px;border-bottom:1px solid #eee">${esc(p.method||'')}</td><td style="padding:4px 8px;font-size:10px;text-align:right;border-bottom:1px solid #eee">${fmt.usd(p.amount)}</td></tr>`; });
      paymentsHtml += '</table></div>';
    }

    const addr = [profile.street, profile.city, profile.state, profile.zip].filter(Boolean).join(', ');

    return `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Invoice ${fmt.invNum(inv.number)}</title></head><body style="font-family:-apple-system,Helvetica,Arial,sans-serif;font-size:11px;color:#333;line-height:1.4;max-width:612px;margin:0 auto;padding:36px">
      <div style="display:flex;justify-content:space-between;margin-bottom:20px;border-bottom:2px solid #AF6118;padding-bottom:12px">
        <div><h1 style="font-size:18px;margin:0 0 4px;color:#AF6118">${esc(profile.businessName||'MMCC')}</h1>${addr?'<p style="margin:1px 0;color:#666;font-size:10px">'+esc(addr)+'</p>':''}${profile.phone?'<p style="margin:1px 0;color:#666;font-size:10px">'+esc(profile.phone)+'</p>':''}${profile.email?'<p style="margin:1px 0;color:#666;font-size:10px">'+esc(profile.email)+'</p>':''}${profile.license?'<p style="margin:1px 0;color:#666;font-size:10px">License: '+esc(profile.license)+'</p>':''}</div>
        <div style="text-align:right"><h2 style="font-size:22px;margin:0;color:#AF6118;letter-spacing:2px">INVOICE</h2><p style="margin:2px 0;font-size:10px"><strong>${fmt.invNum(inv.number)}</strong></p><p style="margin:2px 0;font-size:10px">Date: ${fmt.date(inv.createdAt)}</p><p style="margin:2px 0;font-size:10px">Terms: ${esc(inv.paymentTerms||'Due on Receipt')}</p></div>
      </div>
      ${cust?'<div style="margin:12px 0;padding:8px;background:#f8f8f8;border-radius:4px"><h3 style="font-size:10px;color:#999;text-transform:uppercase;letter-spacing:1px;margin:0 0 4px">Bill To:</h3><p style="margin:1px 0;font-size:11px"><strong>'+esc(cust.name)+'</strong></p>'+(cust.phone?'<p style="margin:1px 0;font-size:11px">'+esc(cust.phone)+'</p>':'')+(cust.email?'<p style="margin:1px 0;font-size:11px">'+esc(cust.email)+'</p>':'')+(cust.address?'<p style="margin:1px 0;font-size:11px">'+esc(cust.address)+'</p>':'')+'</div>':''}
      ${inv.jobAddress?'<div style="margin:12px 0;padding:8px;background:#f8f8f8;border-radius:4px"><h3 style="font-size:10px;color:#999;text-transform:uppercase;letter-spacing:1px;margin:0 0 4px">Job Site:</h3><p style="margin:1px 0;font-size:11px">'+esc(inv.jobAddress)+'</p></div>':''}
      ${sectionsHtml}
      <div style="margin-top:16px"><table style="width:250px;margin-left:auto">
        <tr><td style="padding:3px 8px;font-size:11px">Subtotal</td><td style="padding:3px 8px;font-size:11px;text-align:right">${fmt.usd(c.subtotal)}</td></tr>
        ${c.markupAmt>0?'<tr><td style="padding:3px 8px;font-size:11px">Markup ('+inv.markup+'%)</td><td style="padding:3px 8px;font-size:11px;text-align:right">'+fmt.usd(c.markupAmt)+'</td></tr>':''}
        ${c.taxAmt>0?'<tr><td style="padding:3px 8px;font-size:11px">Tax ('+inv.taxRate+'%)</td><td style="padding:3px 8px;font-size:11px;text-align:right">'+fmt.usd(c.taxAmt)+'</td></tr>':''}
        <tr><td style="padding:6px 8px;font-size:13px;border-top:2px solid #AF6118"><strong>Grand Total</strong></td><td style="padding:6px 8px;font-size:13px;border-top:2px solid #AF6118;text-align:right"><strong>${fmt.usd(c.total)}</strong></td></tr>
        ${c.paid>0?'<tr><td style="padding:3px 8px;font-size:11px">Paid</td><td style="padding:3px 8px;font-size:11px;text-align:right">('+fmt.usd(c.paid)+')</td></tr><tr><td style="padding:6px 8px;font-size:13px;border-top:2px solid #AF6118"><strong>Balance Due</strong></td><td style="padding:6px 8px;font-size:13px;border-top:2px solid #AF6118;text-align:right"><strong>'+fmt.usd(c.due)+'</strong></td></tr>':''}
      </table></div>
      ${paymentsHtml}
      ${inv.notes?'<div style="margin-top:16px;padding-top:8px;border-top:1px solid #eee"><h3 style="font-size:10px;color:#999;text-transform:uppercase;letter-spacing:1px;margin:0 0 4px">Notes</h3><p style="font-size:10px;color:#666">'+esc(inv.notes).replace(/\n/g,'<br>')+'</p></div>':''}
      ${inv.terms?'<div style="margin-top:16px;padding-top:8px;border-top:1px solid #eee"><h3 style="font-size:10px;color:#999;text-transform:uppercase;letter-spacing:1px;margin:0 0 4px">Terms & Conditions</h3><p style="font-size:10px;color:#666">'+esc(inv.terms).replace(/\n/g,'<br>')+'</p></div>':''}
    </body></html>`;
  },


  // ─── Record Payment ───
  recordPayment(id) {
    const inv = DB.getInvoice(id);
    if (!inv) return;
    const c = calcInvoice(inv);
    const bal = c.due;
    const amtStr = prompt('Payment amount:', bal.toFixed(2));
    if (!amtStr) return;
    const amt = parseFloat(amtStr);
    if (isNaN(amt) || amt <= 0) return;
    const method = prompt('Payment method (cash, check, card, zelle, venmo, ach):', 'check') || 'check';
    if (!inv.payments) inv.payments = [];
    inv.payments.push({ amount: amt, method, date: new Date().toISOString() });
    const newDue = c.total - (c.paid + amt);
    if (newDue <= 0) inv.status = 'paid';
    else if (c.paid + amt > 0) inv.status = 'partiallyPaid';
    DB.updateInvoice(inv);
    this.render();
  },

  // ─── Template Picker ───
  renderTemplatePicker() {
    let html = '<div style="padding-top:12px">';
    html += `<div class="template-card" onclick="App.createBlankInvoice()"><h4>📄 Blank Invoice</h4><div class="meta">Start from scratch</div></div>`;
    html += '<div class="form-group-title">HVAC TEMPLATES</div>';
    TEMPLATES.forEach((t, i) => {
      const total = t.sections.reduce((s, sec) => s + sec.items.reduce((s2, it) => s2 + it.qty * it.price, 0), 0);
      const sectionNames = t.sections.map(s => s.name).join(', ');
      html += `<div class="template-card" onclick="App.createFromTemplate(${i})"><h4>${t.name}</h4><div class="meta">${t.sections.length} sections · Est. ${fmt.usd(total)}</div><div class="meta">${sectionNames}</div></div>`;
    });
    html += '</div>';
    return {
      nav: `<div class="nav-bar"><button onclick="App.pop()">← Back</button><h1>New Invoice</h1><button>&nbsp;</button></div>`,
      body: html
    };
  },

  createBlankInvoice() {
    const profile = DB.getProfile();
    const inv = DB.addInvoice({
      status: 'draft', customerId: null, jobAddress: '',
      taxRate: Number(profile.taxRate) || 0, markup: Number(profile.markup) || 0,
      notes: '', terms: '', paymentTerms: 'Due on Receipt',
      sections: [{ name: 'Items', items: [{ desc: '', qty: 1, price: 0, unit: 'ea' }] }],
      payments: [],
    });
    this.editInvoice(inv.id);
  },

  createFromTemplate(idx) {
    const t = TEMPLATES[idx];
    const profile = DB.getProfile();
    const sections = t.sections.map(s => ({
      name: s.name,
      items: s.items.map(it => ({ desc: it.desc, qty: it.qty, price: it.price, unit: it.unit }))
    }));
    const inv = DB.addInvoice({
      status: 'draft', customerId: null, jobAddress: '',
      taxRate: Number(profile.taxRate) || 0, markup: Number(profile.markup) || 0,
      notes: t.notes || '', terms: t.terms || '', paymentTerms: 'Due on Receipt',
      sections, payments: [],
    });
    this.editInvoice(inv.id);
  },

  editInvoice(id) {
    this.editingInvoice = JSON.parse(JSON.stringify(DB.getInvoice(id)));
    this._screenData = id;
    this.screen = 'invoiceEdit';
    this.render();
  },


  // ─── Invoice Editor ───
  renderInvoiceEditor() {
    const inv = this.editingInvoice;
    if (!inv) return { nav: '', body: '' };
    const customers = DB.getCustomers();
    const c = calcInvoice(inv);

    let custOptions = '<option value="">— Select Customer —</option>';
    customers.forEach(cu => { custOptions += `<option value="${cu.id}" ${inv.customerId===cu.id?'selected':''}>${cu.name}</option>`; });

    let sectionsHtml = '';
    (inv.sections || []).forEach((sec, si) => {
      sectionsHtml += `
        <div class="section-header">
          <span>${sec.name}</span>
          <div>
            <button onclick="App.addLineItem(${si})">＋</button>
            <button onclick="App.removeSection(${si})">✕</button>
          </div>
        </div>
        <div style="background:var(--card);border-radius:0 0 var(--radius) var(--radius);margin-bottom:12px;overflow:hidden">`;
      (sec.items || []).forEach((it, ii) => {
        sectionsHtml += `
          <div class="line-editor">
            <div class="form-row">
              <input type="text" value="${(it.desc||'').replace(/"/g,'&quot;')}" placeholder="Description" oninput="App.editingInvoice.sections[${si}].items[${ii}].desc=this.value" style="text-align:left">
              <button style="background:none;border:none;color:var(--red);font-size:18px;cursor:pointer;padding:0 4px" onclick="App.removeLineItem(${si},${ii})">✕</button>
            </div>
            <div class="fields-row">
              <div class="form-row"><label>Qty</label><input type="number" inputmode="decimal" value="${it.qty}" onchange="App.editingInvoice.sections[${si}].items[${ii}].qty=Number(this.value);App.render()"></div>
              <div class="form-row"><label>$</label><input type="number" inputmode="decimal" step="0.01" value="${it.price}" onchange="App.editingInvoice.sections[${si}].items[${ii}].price=Number(this.value);App.render()"></div>
              <div class="form-row"><label>Unit</label><input type="text" value="${it.unit||'ea'}" oninput="App.editingInvoice.sections[${si}].items[${ii}].unit=this.value" style="width:40px"></div>
              <div class="form-row" style="justify-content:flex-end"><span class="fw-bold mono">${fmt.usd((Number(it.qty)||0)*(Number(it.price)||0))}</span></div>
            </div>
          </div>`;
      });
      sectionsHtml += `<div class="section-subtotal">Section: ${fmt.usd(calcSection(sec))}</div></div>`;
    });

    // Add section picker
    let addSecOpts = HVAC_SECTIONS.map(s => `<option value="${s}">${s}</option>`).join('');

    const body = `
      <div style="padding-top:12px">
        <div class="form-group-title">CUSTOMER</div>
        <div class="form-group">
          <div class="form-row">
            <label>Customer</label>
            <select onchange="App.editingInvoice.customerId=this.value||null">${custOptions}</select>
          </div>
          <button class="btn-action" onclick="App.quickCreateCustomer()" style="font-size:13px">＋ New Customer</button>
        </div>

        <div class="form-group-title">JOB DETAILS</div>
        <div class="form-group">
          <div class="form-row"><label>Address</label><input type="text" value="${(inv.jobAddress||'').replace(/"/g,'&quot;')}" placeholder="Job site address" oninput="App.editingInvoice.jobAddress=this.value"></div>
          <div class="form-row">
            <label>Terms</label>
            <select onchange="App.editingInvoice.paymentTerms=this.value">${PAYMENT_TERMS.map(t => `<option value="${t}" ${(inv.paymentTerms||'Due on Receipt')===t?'selected':''}>${t}</option>`).join('')}</select>
          </div>
        </div>

        <div class="form-group-title">LINE ITEMS</div>
        ${sectionsHtml}

        <div class="form-group" style="overflow:hidden">
          <div class="form-row">
            <label>Add Section</label>
            <select id="newSecSelect">${addSecOpts}</select>
            <button style="background:var(--amber);color:#fff;border:none;border-radius:8px;padding:6px 12px;font-size:14px;cursor:pointer" onclick="App.addSection()">Add</button>
          </div>
        </div>

        <div class="form-group-title">TOTALS</div>
        <div class="form-group">
          <div class="form-row"><label>Markup %</label><input type="number" inputmode="decimal" value="${inv.markup||0}" onchange="App.editingInvoice.markup=Number(this.value);App.render()"></div>
          <div class="form-row"><label>Tax %</label><input type="number" inputmode="decimal" value="${inv.taxRate||0}" onchange="App.editingInvoice.taxRate=Number(this.value);App.render()"></div>
        </div>
        <div class="card">
          <div class="totals-table">
            <div class="totals-row"><span class="label">Subtotal</span><span class="mono">${fmt.usd(c.subtotal)}</span></div>
            ${c.markupAmt>0?`<div class="totals-row"><span class="label">Markup</span><span class="mono">${fmt.usd(c.markupAmt)}</span></div>`:''}
            ${c.taxAmt>0?`<div class="totals-row"><span class="label">Tax</span><span class="mono">${fmt.usd(c.taxAmt)}</span></div>`:''}
            <div class="totals-row grand"><span class="label">Grand Total</span><span class="mono">${fmt.usd(c.total)}</span></div>
          </div>
        </div>

        <div class="form-group-title">NOTES & TERMS</div>
        <div class="form-group">
          <div class="form-row" style="flex-direction:column;align-items:stretch"><label>Notes</label><textarea oninput="App.editingInvoice.notes=this.value">${inv.notes||''}</textarea></div>
          <div class="form-row" style="flex-direction:column;align-items:stretch"><label>Terms</label><textarea oninput="App.editingInvoice.terms=this.value">${inv.terms||''}</textarea></div>
        </div>

        <div style="height:40px"></div>
      </div>`;

    return {
      nav: `<div class="nav-bar"><button onclick="App.cancelEdit()">Cancel</button><h1>Edit Invoice</h1><button onclick="App.saveInvoice()" style="font-weight:700">Save</button></div>`,
      body
    };
  },

  addSection() {
    const sel = document.getElementById('newSecSelect');
    const name = sel ? sel.value : 'Items';
    this.editingInvoice.sections.push({ name, items: [{ desc: '', qty: 1, price: 0, unit: 'ea' }] });
    this.render();
  },
  removeSection(si) {
    if (confirm('Remove this section?')) { this.editingInvoice.sections.splice(si, 1); this.render(); }
  },
  addLineItem(si) {
    this.editingInvoice.sections[si].items.push({ desc: '', qty: 1, price: 0, unit: 'ea' });
    this.render();
  },
  removeLineItem(si, ii) {
    this.editingInvoice.sections[si].items.splice(ii, 1);
    this.render();
  },
  saveInvoice() {
    DB.updateInvoice(this.editingInvoice);
    this._screenData = this.editingInvoice.id;
    this.editingInvoice = null;
    this.screen = 'invoiceView';
    this.render();
  },
  cancelEdit() {
    this.editingInvoice = null;
    if (this._screenData) { this.screen = 'invoiceView'; } else { this.screen = null; }
    this.render();
  },

  quickCreateCustomer() {
    const name = prompt('Customer name:');
    if (!name || !name.trim()) return;
    const phone = prompt('Phone (optional):') || '';
    const email = prompt('Email (optional):') || '';
    const cu = DB.addCustomer({ name: name.trim(), phone: phone.trim(), email: email.trim(), address: '', notes: '' });
    this.editingInvoice.customerId = cu.id;
    this.render();
  },


  // ─── Customer List ───
  renderCustomerList() {
    const customers = DB.getCustomers();
    if (!customers.length) {
      return `
        <div class="empty-state">
          <div class="icon">👤</div>
          <h3>No Customers Yet</h3>
          <p>Add your first customer</p>
          <button class="btn btn-primary" style="max-width:200px" onclick="App.push('customerEdit')">Add Customer</button>
        </div>`;
    }
    let html = '<div style="padding-top:12px">';
    customers.forEach(cu => {
      const invCount = DB.getInvoices().filter(i => i.customerId === cu.id).length;
      html += `
        <div class="card" style="cursor:pointer" onclick="App.editCustomer('${cu.id}')">
          <div class="fw-bold" style="font-size:15px">${cu.name}</div>
          ${cu.phone ? '<div class="text-small text-muted">'+cu.phone+'</div>' : ''}
          ${cu.email ? '<div class="text-small text-muted">'+cu.email+'</div>' : ''}
          <div class="text-xs text-muted mt-8">${invCount} invoice${invCount!==1?'s':''}</div>
        </div>`;
    });
    html += '</div>';
    return html;
  },

  editCustomer(id) {
    if (id) {
      this.editingCustomer = JSON.parse(JSON.stringify(DB.getCustomers().find(c => c.id === id)));
    } else {
      this.editingCustomer = null;
    }
    this.push('customerEdit');
  },

  // ─── Customer Editor ───
  renderCustomerEditor() {
    const cu = this.editingCustomer || { name:'', phone:'', email:'', address:'', notes:'' };
    const isNew = !cu.id;

    const body = `
      <div style="padding-top:12px">
        <div class="form-group-title">CONTACT INFO</div>
        <div class="form-group">
          <div class="form-row"><label>Name</label><input type="text" id="cu_name" value="${(cu.name||'').replace(/"/g,'&quot;')}" placeholder="Customer name" autocomplete="name"></div>
          <div class="form-row"><label>Phone</label><input type="tel" id="cu_phone" value="${(cu.phone||'').replace(/"/g,'&quot;')}" placeholder="Phone number" autocomplete="tel"></div>
          <div class="form-row"><label>Email</label><input type="email" id="cu_email" value="${(cu.email||'').replace(/"/g,'&quot;')}" placeholder="Email address" autocomplete="email"></div>
          <div class="form-row"><label>Address</label><input type="text" id="cu_address" value="${(cu.address||'').replace(/"/g,'&quot;')}" placeholder="Street address" autocomplete="street-address"></div>
        </div>

        <div class="form-group-title">NOTES</div>
        <div class="form-group">
          <div class="form-row" style="flex-direction:column;align-items:stretch"><textarea id="cu_notes" placeholder="Notes about this customer...">${cu.notes||''}</textarea></div>
        </div>

        <button class="btn btn-primary mt-16" onclick="App.saveCustomer()">Save Customer</button>

        ${!isNew ? `<button class="btn btn-danger mt-12" onclick="if(confirm('Delete this customer?')){DB.deleteCustomer('${cu.id}');App.editingCustomer=null;App.pop();}">Delete Customer</button>` : ''}
      </div>`;

    return {
      nav: `<div class="nav-bar"><button onclick="App.editingCustomer=null;App.pop()">← Back</button><h1>${isNew ? 'New' : 'Edit'} Customer</h1><button>&nbsp;</button></div>`,
      body
    };
  },

  saveCustomer() {
    const name = document.getElementById('cu_name').value.trim();
    if (!name) { alert('Name is required'); return; }
    const data = {
      name,
      phone: document.getElementById('cu_phone').value.trim(),
      email: document.getElementById('cu_email').value.trim(),
      address: document.getElementById('cu_address').value.trim(),
      notes: document.getElementById('cu_notes').value.trim(),
    };
    if (this.editingCustomer && this.editingCustomer.id) {
      data.id = this.editingCustomer.id;
      DB.updateCustomer(data);
    } else {
      DB.addCustomer(data);
    }
    this.editingCustomer = null;
    this.pop();
  },

  // ─── Settings ───
  renderSettings() {
    const p = DB.getProfile();
    return `
      <div style="padding-top:12px">
        <div class="form-group-title">BUSINESS INFO</div>
        <div class="form-group">
          <div class="form-row"><label>Name</label><input type="text" id="s_name" value="${(p.businessName||'').replace(/"/g,'&quot;')}" placeholder="Business name"></div>
          <div class="form-row"><label>Phone</label><input type="tel" id="s_phone" value="${(p.phone||'').replace(/"/g,'&quot;')}" placeholder="Phone"></div>
          <div class="form-row"><label>Email</label><input type="email" id="s_email" value="${(p.email||'').replace(/"/g,'&quot;')}" placeholder="Email"></div>
          <div class="form-row"><label>License #</label><input type="text" id="s_license" value="${(p.license||'').replace(/"/g,'&quot;')}" placeholder="License number"></div>
        </div>

        <div class="form-group-title">ADDRESS</div>
        <div class="form-group">
          <div class="form-row"><label>Street</label><input type="text" id="s_street" value="${(p.street||'').replace(/"/g,'&quot;')}" placeholder="Street"></div>
          <div class="form-row"><label>City</label><input type="text" id="s_city" value="${(p.city||'').replace(/"/g,'&quot;')}" placeholder="City"></div>
          <div class="form-row"><label>State</label><input type="text" id="s_state" value="${(p.state||'').replace(/"/g,'&quot;')}" placeholder="State"></div>
          <div class="form-row"><label>ZIP</label><input type="text" id="s_zip" value="${(p.zip||'').replace(/"/g,'&quot;')}" placeholder="ZIP code" inputmode="numeric"></div>
        </div>

        <div class="form-group-title">INVOICE DEFAULTS</div>
        <div class="form-group">
          <div class="form-row"><label>Tax Rate %</label><input type="number" id="s_tax" inputmode="decimal" value="${p.taxRate||0}"></div>
          <div class="form-row"><label>Markup %</label><input type="number" id="s_markup" inputmode="decimal" value="${p.markup||0}"></div>
        </div>

        <button class="btn btn-primary mt-16" onclick="App.saveSettings()">Save Settings</button>

        <div class="form-group-title mt-16">ABOUT</div>
        <div class="form-group">
          <div class="form-row"><label>Version</label><span class="text-muted">1.0.0</span></div>
          <div class="form-row"><label>Built for</label><span class="text-muted">HVAC Contractors</span></div>
        </div>

        <button class="btn btn-danger mt-16" onclick="if(confirm('Delete ALL data? This cannot be undone.')){localStorage.clear();location.reload();}">Reset All Data</button>
        <div style="height:40px"></div>
      </div>`;
  },

  saveSettings() {
    DB.saveProfile({
      businessName: document.getElementById('s_name').value.trim(),
      phone: document.getElementById('s_phone').value.trim(),
      email: document.getElementById('s_email').value.trim(),
      license: document.getElementById('s_license').value.trim(),
      street: document.getElementById('s_street').value.trim(),
      city: document.getElementById('s_city').value.trim(),
      state: document.getElementById('s_state').value.trim(),
      zip: document.getElementById('s_zip').value.trim(),
      taxRate: Number(document.getElementById('s_tax').value) || 0,
      markup: Number(document.getElementById('s_markup').value) || 0,
    });
    alert('Settings saved');
  },
};

// ─── Boot ───
document.addEventListener('DOMContentLoaded', () => App.init());
