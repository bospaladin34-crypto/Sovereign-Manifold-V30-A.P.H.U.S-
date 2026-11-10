// ==============================================================================
// ACT-OMEGA NET v70.0.0 — CHALLENGER 2 LIVE ADVERSARIAL PROBES
// Empirical direct HTTP testing of live edge worker and local host :8097
// ==============================================================================

const edgeBase = 'https://act-omega-net.dev';
const hostBase = 'http://127.0.0.1:8097';

console.log('--- EXECUTING LIVE ADVERSARIAL PROBES ---');

let total = 0;
let passed = 0;
let failed = 0;

function check(desc, ok, details = '') {
  total++;
  if (ok) {
    passed++;
    console.log(`[PASS] ${desc}`);
  } else {
    failed++;
    console.error(`[FAIL] ${desc} — ${details}`);
  }
}

async function runProbes() {
  // Probe 1: Forged Zero Trust JWT
  try {
    const res = await fetch(`${edgeBase}/api/v1/kv/put`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Cf-Access-Jwt-Assertion': 'forged.malicious.jwt'
      },
      body: JSON.stringify({ key: 'probe1', value: 'bad' })
    });
    check('P1: Forged Zero Trust JWT returns HTTP 403', res.status === 403, `Got status ${res.status}`);
  } catch (err) {
    check('P1: Forged Zero Trust JWT returns HTTP 403', false, err.message);
  }

  // Probe 2a: Missing Operator Key
  try {
    const res = await fetch(`${edgeBase}/api/v1/kv/put`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ key: 'probe2a', value: 'bad' })
    });
    check('P2a: Missing Operator Key returns HTTP 403', res.status === 403, `Got status ${res.status}`);
  } catch (err) {
    check('P2a: Missing Operator Key returns HTTP 403', false, err.message);
  }

  // Probe 2b: Invalid Operator Key (< 24 chars)
  try {
    const res = await fetch(`${edgeBase}/api/v1/kv/put`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Sovereign-Operator-Key': 'short_key_123'
      },
      body: JSON.stringify({ key: 'probe2b', value: 'bad' })
    });
    check('P2b: Short Operator Key (< 24 chars) returns HTTP 403', res.status === 403, `Got status ${res.status}`);
  } catch (err) {
    check('P2b: Short Operator Key (< 24 chars) returns HTTP 403', false, err.message);
  }

  // Probe 2c: Invalid Operator Key (>= 24 chars but incorrect)
  try {
    const res = await fetch(`${edgeBase}/api/v1/kv/put`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Sovereign-Operator-Key': 'INCORRECT_OPERATOR_KEY_OF_EXACTLY_VALID_LENGTH_32'
      },
      body: JSON.stringify({ key: 'probe2c', value: 'bad' })
    });
    check('P2c: Mismatched Operator Key (>= 24 chars) returns HTTP 403', res.status === 403, `Got status ${res.status}`);
  } catch (err) {
    check('P2c: Mismatched Operator Key (>= 24 chars) returns HTTP 403', false, err.message);
  }

  // Probe 3: ?key= query parameter is strictly rejected (Constitutional Invariant #7)
  try {
    const res = await fetch(`${edgeBase}/api/v1/kv/put?key=secret_token_in_query`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ key: 'probe3', value: 'bad' })
    });
    check('P3: ?key= query parameter rejected with HTTP 403', res.status === 403, `Got status ${res.status}`);
  } catch (err) {
    check('P3: ?key= query parameter rejected with HTTP 403', false, err.message);
  }

  // Probe 4a: Turnstile verification without production secret fails closed (HTTP 503)
  try {
    const res = await fetch(`${edgeBase}/api/v1/cloudflare/turnstile_verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ token: 'sample_production_looking_token_12345' })
    });
    const data = await res.json();
    check('P4a: Turnstile without secret fails closed with HTTP 503 and fail_closed=true',
      res.status === 503 && data.fail_closed === true,
      `Got status ${res.status}, body: ${JSON.stringify(data)}`);
  } catch (err) {
    check('P4a: Turnstile without secret fails closed with HTTP 503', false, err.message);
  }

  // Probe 4b: Turnstile test token (1x000...) rejected with HTTP 403
  try {
    const res = await fetch(`${edgeBase}/api/v1/cloudflare/turnstile_verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ token: '1x00000000000000000000AA' })
    });
    const data = await res.json();
    check('P4b: Turnstile test token rejected with HTTP 403 or fails closed',
      res.status === 403 || res.status === 503,
      `Got status ${res.status}, body: ${JSON.stringify(data)}`);
  } catch (err) {
    check('P4b: Turnstile test token rejected', false, err.message);
  }

  // Probe 5: Live DO hard-cap enforcement & accounting basis
  try {
    const res = await fetch(`${edgeBase}/api/v1/cloudflare/free_tier_governor`);
    const data = await res.json();
    const basisExpected = 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING';
    check('P5a: Live DO Governor returns HTTP 200', res.status === 200, `Got status ${res.status}`);
    check('P5b: Live DO Governor reports accounting_basis correctly',
      data.accounting_basis === basisExpected,
      `Got accounting_basis: ${data.accounting_basis}`);
    check('P5c: Live DO Governor reports SovereignEdgeShadowDO_SQLite',
      data.durable_object_shadow === 'SovereignEdgeShadowDO_SQLite',
      `Got durable_object_shadow: ${data.durable_object_shadow}`);
    check('P5d: Live DO Governor reports status',
      typeof data.status === 'string',
      `Got status: ${data.status}`);
  } catch (err) {
    check('P5: Live DO Governor checks', false, err.message);
  }

  // Probe 6: Tool 317 local response over port :8097
  try {
    const res = await fetch(`${hostBase}/api/v1/cloudflare/free_tier_governor`);
    const data = await res.json();
    check('P6a: Host port :8097 returns HTTP 200 for Tool 317', res.status === 200, `Got status ${res.status}`);
    check('P6b: Host Tool 317 reports 965/965 Lean 4 QED theorems',
      data.lean4_theorems_qed === '965/965',
      `Got theorems: ${data.lean4_theorems_qed}`);
    check('P6c: Host Tool 317 reports tool_id 317 and tools_total 317',
      data.tool_id === 317 && data.tools_total === 317,
      `Got tool_id: ${data.tool_id}, tools_total: ${data.tools_total}`);
    check('P6d: Host Tool 317 reports E:\\ vault writeback digest',
      data.e_vault_writeback_sha256 && data.e_vault_writeback_sha256.length === 64,
      `Got sha: ${data.e_vault_writeback_sha256}`);
  } catch (err) {
    check('P6: Host port :8097 checks', false, err.message);
  }

  console.log(`\n--- LIVE ADVERSARIAL SUMMARY: ${passed} PASSED, ${failed} FAILED out of ${total} PROBES ---`);
  if (failed > 0) {
    process.exit(1);
  }
}

runProbes();
