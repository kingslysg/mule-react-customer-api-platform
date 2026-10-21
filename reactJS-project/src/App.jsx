import { useState } from 'react';

const countries = [
  { code: 'US', name: 'United States' },
  { code: 'IN', name: 'India' },
  { code: 'CA', name: 'Canada' },
  { code: 'GB', name: 'United Kingdom' }
];

export default function App() {
  const [name, setName] = useState('');
  const [countryCode, setCountryCode] = useState('US');
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setError('');
    setResult(null);
    setLoading(true);

    try {
      // Keep this relative so local Vite proxying works and production can
      // route /api/* through the same-origin CDN to the Experience API.
      const response = await fetch('/api/customer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name.trim(), countryCode })
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body.message || 'The request failed.');
      setResult(body);
    } catch (err) {
      setError(err.message === 'Failed to fetch'
        ? 'Could not reach the Experience API. Make sure all three Mule applications are running.'
        : err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="page-shell">
      <header className="topbar">
        <div className="brand-mark">M</div>
        <span className="brand-name">Kingsly Bose</span>
        <span className="topbar-tag">MULESOFT + REACT PORTFOLIO</span>
      </header>

      <section className="hero">
        <div className="eyebrow"><span className="live-dot" /> FULL-STACK INTEGRATION PROJECT</div>
        <h1>Customer profile <span>integration platform.</span></h1>
        <p className="intro">A portfolio sample by Kingsly Bose: a ReactJS interface connected to a RAML-defined, API-led MuleSoft architecture.</p>
        <div className="technology-list" aria-label="Technologies demonstrated">
          <span>ReactJS</span><span>RAML</span><span>APIkit</span><span>Mule Flows</span><span>DataWeave</span>
        </div>

        <div className="architecture" aria-label="Request path: React UI to Experience API to Process API to System API">
          <div className="arch-node"><span className="node-icon browser-icon">◫</span><span><b>ReactJS</b><small>Customer UI</small></span></div>
          <span className="connector"><i /></span>
          <div className="arch-node"><span className="node-icon exp-icon">01</span><span><b>Experience API</b><small>APIkit · UI-facing</small></span></div>
          <span className="connector"><i /></span>
          <div className="arch-node"><span className="node-icon proc-icon">02</span><span><b>Process API</b><small>Mule flow · orchestration</small></span></div>
          <div className="connector"><i /></div>
          <div className="arch-node"><span className="node-icon sys-icon">03</span><span><b>System API</b><small>DataWeave · mock backend</small></span></div>
        </div>

        <div className="content-grid">
          <section className="card form-card">
            <div className="section-label">TRY THE FLOW <span>01 / INPUT</span></div>
            <h2>Look up a profile</h2>
            <p className="card-copy">Send a name and country through the Experience API to get a mock profile.</p>
            <form onSubmit={handleSubmit}>
              <label htmlFor="name">Your name</label>
              <input id="name" value={name} onChange={event => setName(event.target.value)} placeholder="e.g. Avery Johnson" required maxLength={80} />
              <label htmlFor="country">Country (2-letter code)</label>
              <select id="country" value={countryCode} onChange={event => setCountryCode(event.target.value)}>
                {countries.map(country => <option key={country.code} value={country.code}>{country.code} — {country.name}</option>)}
              </select>
              <button type="submit" disabled={loading || !name.trim()}>
                {loading ? <><span className="spinner" /> Calling APIs…</> : <>Send request <span aria-hidden="true">↗</span></>}
              </button>
            </form>
            {error && <div className="error-box" role="alert">{error}</div>}
          </section>

          <section className={`card response-card ${result ? 'has-result' : ''}`} aria-live="polite">
            <div className="section-label">API RESPONSE <span>02 / OUTPUT</span></div>
            <h2>{result ? 'Profile received' : 'Your response appears here'}</h2>
            {!result && !loading && <div className="empty-state"><div className="empty-icon">{ }</div><p>Submit a name and country to see the mock data returned through all three APIs.</p></div>}
            {loading && <div className="loading-state"><span className="spinner dark" /> Request traveling through Mule…</div>}
            {result && <>
              <p className="greeting">{result.message}</p>
              <div className="profile-grid">
                <div className="profile-field"><span>CUSTOMER ID</span><b>{result.customer.id}</b></div>
                <div className="profile-field"><span>STATUS</span><b className="status"><i />{result.customer.status}</b></div>
                <div className="profile-field"><span>PLAN</span><b>{result.customer.plan}</b></div>
                <div className="profile-field"><span>REQUEST NAME</span><b>{result.name}</b></div>
                <div className="profile-field country-field"><span>COUNTRY</span><b>{result.countryCode} — {result.countryName}</b></div>
                <div className="profile-field country-field"><span>EXPERIENCE LAYER</span><b>{result.experienceApi} → {result.processApi} → {result.systemApi}</b></div>
              </div>
              <div className="source-note"><span>✓</span> Experience API → Process API → System API mock backend</div>
            </>}
          </section>
        </div>

        <footer><span>PORTFOLIO SAMPLE · KINGSLY BOSE</span><span>ReactJS <b>→</b> MuleSoft API-led integration</span></footer>
      </section>
    </main>
  );
}
