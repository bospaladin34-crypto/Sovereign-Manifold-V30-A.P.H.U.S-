// ==============================================================================
// ACT-OMEGA NET v70.0.0 — MILESTONE 2: CHALLENGER 1 EMPIRICAL ADVERSARIAL TEST HARNESS
// Focus: Vectorize Fallback Zero-Synthetic Guarantee, Workers AI Embeddings Fail-Closed,
// Durable Object Quota Hard-Cap Denial & Transparent Accounting Basis
// File: tests/e2e/test_m2_challenger1_empirical_adversarial.mjs
// ==============================================================================

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..', '..');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const failures = [];

function assert(condition, testName, details = '') {
  totalTests++;
  if (condition) {
    passedTests++;
    console.log(`  [PASS] ${testName}`);
  } else {
    failedTests++;
    console.error(`  [FAIL] ${testName} — ${details}`);
    failures.push({ testName, details });
  }
}

console.log('==========================================================================');
console.log('   MILESTONE 2: CHALLENGER 1 EMPIRICAL ADVERSARIAL STRESS TEST SUITE      ');
console.log('   Focus: Fallbacks, Quota Hard-Cap Denial, Zero-Synthetic & Accounting   ');
console.log('==========================================================================');

// ------------------------------------------------------------------------------
// Import Edge Worker and Durable Object directly from 00_control/cloudflare_edge
// ------------------------------------------------------------------------------
const edgeWorkerPath = path.join(repoRoot, '00_control', 'cloudflare_edge', 'worker_vpc_shadow_v3700.js');
const rootWorkerPath = path.join(repoRoot, 'worker_vpc_shadow_v3700.js');
const doModulePath = path.join(repoRoot, '00_control', 'cloudflare_edge', 'worker_continuum_do.js');

assert(fs.existsSync(edgeWorkerPath), 'Edge worker exists at 00_control/cloudflare_edge/worker_vpc_shadow_v3700.js');
assert(fs.existsSync(rootWorkerPath), 'Root worker exists at worker_vpc_shadow_v3700.js');
assert(fs.existsSync(doModulePath), 'DO continuum exists at 00_control/cloudflare_edge/worker_continuum_do.js');

const edgeWorkerCode = fs.readFileSync(edgeWorkerPath, 'utf8');
const rootWorkerCode = fs.readFileSync(rootWorkerPath, 'utf8');
const doModuleCode = fs.readFileSync(doModulePath, 'utf8');

// Dynamic import of modules
let workerDefault;
let SovereignEdgeShadowDO;
try {
  const edgeModule = await import('../../00_control/cloudflare_edge/worker_vpc_shadow_v3700.js');
  workerDefault = edgeModule.default;
  SovereignEdgeShadowDO = edgeModule.SovereignEdgeShadowDO;
  assert(typeof workerDefault.fetch === 'function', 'Worker default export has fetch function');
  assert(typeof SovereignEdgeShadowDO === 'function', 'SovereignEdgeShadowDO is exported class');
} catch (err) {
  assert(false, 'Module dynamic import succeeded', err.message);
  process.exit(1);
}

// Extract internal helper functions for direct unit-level stress testing
const testContext = {};
const helperFunctionsSlice = edgeWorkerCode.slice(0, edgeWorkerCode.indexOf('export { SovereignEdgeShadowDO }'));
const extractInternalFunctionsCode = `
${helperFunctionsSlice}

testContext.SimpleLruCache = SimpleLruCache;
testContext.computeCosineSimilarity = computeCosineSimilarity;
testContext.generateDeterministic32DPolytonicE8 = generateDeterministic32DPolytonicE8;
testContext.computeD1CosineSimilarityFallback = computeD1CosineSimilarityFallback;
testContext.sha256HexWebCrypto = sha256HexWebCrypto;
`;

try {
  const runner = new Function('testContext', 'Headers', 'Request', 'Response', 'FormData', 'crypto', extractInternalFunctionsCode);
  runner(testContext, globalThis.Headers, globalThis.Request, globalThis.Response, globalThis.FormData, globalThis.crypto);
  assert(typeof testContext.computeD1CosineSimilarityFallback === 'function', 'computeD1CosineSimilarityFallback extracted');
} catch (err) {
  assert(false, 'Failed to extract internal worker functions', err.message);
  process.exit(1);
}

const {
  computeD1CosineSimilarityFallback,
  computeCosineSimilarity,
  generateDeterministic32DPolytonicE8,
  sha256HexWebCrypto
} = testContext;


// ==============================================================================
// SECTION 1: STATIC CODE & PARITY INVARIANT AUDIT
// ==============================================================================
console.log('\n--- [SECTION 1] Static Code & Mirror Parity Invariants ---');

// 1.1 SHA-256 Lockstep between root and 00_control/cloudflare_edge
const rootHash = crypto.createHash('sha256').update(rootWorkerCode).digest('hex').toUpperCase();
const edgeHash = crypto.createHash('sha256').update(edgeWorkerCode).digest('hex').toUpperCase();
assert(rootHash === edgeHash, `1.1: Mirror lockstep: root SHA-256 == edge SHA-256 (${rootHash.slice(0, 16)}...)`);

// 1.2 Absolute ban on CANDIDATE_ synthetic generator loop
const hasSyntheticCandidate = /generateDeterministic32DPolytonicE8\s*\(\s*["'`]CANDIDATE_/i.test(edgeWorkerCode);
assert(!hasSyntheticCandidate, '1.2: Zero occurrences of generateDeterministic32DPolytonicE8("CANDIDATE_") in worker');

const hasCandidateLoop = /for\s*\([^)]+\)\s*\{[^}]*CANDIDATE_/i.test(edgeWorkerCode);
assert(!hasCandidateLoop, '1.3: Zero synthetic candidate generation loops found in worker');

// 1.4 Absolute ban on synthetic embedding generation in /api/v1/ai/embed
const aiEmbedRouteSlice = edgeWorkerCode.slice(
  edgeWorkerCode.indexOf('/api/v1/ai/embed'),
  edgeWorkerCode.indexOf('/api/v1/kv/get')
);
const aiEmbedCallsSynthetic = aiEmbedRouteSlice.includes('generateDeterministic32DPolytonicE8(');
assert(!aiEmbedCallsSynthetic, '1.4: /api/v1/ai/embed route NEVER calls generateDeterministic32DPolytonicE8');

// 1.5 Accounting basis label declared
const hasWorkerAccountingBasis = edgeWorkerCode.includes('DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING');
const hasDoAccountingBasis = doModuleCode.includes('DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING');
assert(hasWorkerAccountingBasis && hasDoAccountingBasis, '1.5: Both worker and DO declare DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING');


// ==============================================================================
// SECTION 2: VECTORIZE FALLBACK ZERO-SYNTHETIC GUARANTEE
// ==============================================================================
console.log('\n--- [SECTION 2] Vectorize Fallback Zero-Synthetic Guarantee ---');

// 2.1 Function-level: Empty D1 results array
const mockEmptyD1 = {
  prepare(sql) {
    return {
      all: async () => ({ results: [] })
    };
  }
};
const queryVec32 = Array(32).fill(0).map((_, i) => Math.sin(i + 1));
const resEmptyD1 = await computeD1CosineSimilarityFallback(queryVec32, 5, { ACT_OMEGA_D1: mockEmptyD1 });
assert(Array.isArray(resEmptyD1) && resEmptyD1.length === 0, '2.1: Empty D1 query returns empty array []');

// 2.2 Function-level: Missing / null D1 binding
const resNullD1 = await computeD1CosineSimilarityFallback(queryVec32, 5, {});
assert(Array.isArray(resNullD1) && resNullD1.length === 0, '2.2: Null / missing D1 binding returns empty array []');

// 2.3 Function-level: D1 throws SQL exception
const mockFaultyD1 = {
  prepare() {
    return {
      all: async () => { throw new Error('D1_SQLITE_BUSY: Database locked'); }
    };
  }
};
const resFaultyD1 = await computeD1CosineSimilarityFallback(queryVec32, 5, { ACT_OMEGA_D1: mockFaultyD1 });
assert(Array.isArray(resFaultyD1) && resFaultyD1.length === 0, '2.3: Faulty D1 exception returns empty array [] gracefully');

// 2.4 Function-level: Dimension mismatch in D1 rows (e.g. 16D rows vs 32D query)
const mockMismatchD1 = {
  prepare() {
    return {
      all: async () => ({
        results: [
          { vector_id: 'row_1', dimension: 16, e8q_values_json: JSON.stringify(Array(16).fill(0.1)) },
          { vector_id: 'row_2', dimension: 64, e8q_values_json: JSON.stringify(Array(64).fill(0.05)) }
        ]
      })
    };
  }
};
const resMismatchD1 = await computeD1CosineSimilarityFallback(queryVec32, 5, { ACT_OMEGA_D1: mockMismatchD1 });
assert(Array.isArray(resMismatchD1) && resMismatchD1.length === 0, '2.4: Mismatched dimensions in D1 rows return empty array []');

// 2.5 Function-level: Corrupt JSON values in D1
const mockCorruptD1 = {
  prepare() {
    return {
      all: async () => ({
        results: [
          { vector_id: 'corrupt_1', dimension: 32, e8q_values_json: 'MALFORMED_JSON_STRING' },
          { vector_id: 'corrupt_2', dimension: 32, e8q_values_json: '{not: an: array}' }
        ]
      })
    };
  }
};
const resCorruptD1 = await computeD1CosineSimilarityFallback(queryVec32, 5, { ACT_OMEGA_D1: mockCorruptD1 });
assert(Array.isArray(resCorruptD1) && resCorruptD1.length === 0, '2.5: Corrupt JSON in D1 rows returns empty array []');

// 2.6 Function-level: D1 with valid matching vectors returns real candidates sorted by score
const targetVec = Array(32).fill(0).map((_, i) => (i === 0 ? 1.0 : 0.0));
const orthoVec = Array(32).fill(0).map((_, i) => (i === 1 ? 1.0 : 0.0));
const oppVec = Array(32).fill(0).map((_, i) => (i === 0 ? -1.0 : 0.0));
const mockValidD1 = {
  prepare() {
    return {
      all: async () => ({
        results: [
          { vector_id: 'd1_vec_ortho', dimension: 32, e8q_values_json: JSON.stringify(orthoVec), metadata_json: '{"tag":"ortho"}' },
          { vector_id: 'd1_vec_match', dimension: 32, e8q_values_json: JSON.stringify(targetVec), metadata_json: '{"tag":"exact"}' },
          { vector_id: 'd1_vec_opp', dimension: 32, e8q_values_json: JSON.stringify(oppVec), metadata_json: '{"tag":"opposite"}' }
        ]
      })
    };
  }
};
const resValidD1 = await computeD1CosineSimilarityFallback(targetVec, 2, { ACT_OMEGA_D1: mockValidD1 });
assert(resValidD1.length === 2, '2.6: TopK=2 limits returned candidates to exactly 2');
assert(resValidD1[0].id === 'd1_vec_match' && Math.abs(resValidD1[0].score - 1.0) < 1e-6, '2.7: Exact match ranked #1 with score ~ 1.0');
assert(resValidD1[1].id === 'd1_vec_ortho' && Math.abs(resValidD1[1].score - 0.0) < 1e-6, '2.8: Orthogonal match ranked #2 with score ~ 0.0');
const hasAnySyntheticPrefix = resValidD1.some(c => c.id.startsWith('CANDIDATE_'));
assert(!hasAnySyntheticPrefix, '2.9: Valid D1 matches strictly preserve D1 IDs without CANDIDATE_ prefix');

// 2.10 Route-level: POST /api/v1/vectorize/query with empty D1 returns HTTP 200 with NO_MATCHING_VECTORS_IN_D1 and fallback: false
const mockCtx = { waitUntil() {} };
const emptyVecReq = new Request('https://act-omega-net.dev/api/v1/vectorize/query', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ vector: queryVec32, topK: 5 })
});
const emptyVecRes = await workerDefault.fetch(emptyVecReq, { ACT_OMEGA_D1: mockEmptyD1 }, mockCtx);
assert(emptyVecRes.status === 200, '2.10: Route /api/v1/vectorize/query returns HTTP 200 on fallback');
const emptyVecJson = await emptyVecRes.json();
assert(Array.isArray(emptyVecJson.matches) && emptyVecJson.matches.length === 0, '2.11: Route matches is strictly empty array []');
assert(emptyVecJson.count === 0, '2.12: Route count is strictly 0');
assert(emptyVecJson.status === 'NO_MATCHING_VECTORS_IN_D1', `2.13: Route status is 'NO_MATCHING_VECTORS_IN_D1' (got '${emptyVecJson.status}')`);
assert(emptyVecJson.fallback === false, `2.14: Route fallback flag is false (got ${emptyVecJson.fallback})`);
assert(emptyVecJson.source === 'D1_COSINE_SIMILARITY_MIRROR', '2.15: Route source is D1_COSINE_SIMILARITY_MIRROR');

// 2.16 Route-level: POST /api/v1/vectorize/query with populated D1 returns EDGE_FALLBACK_QUOTA_SHIELDED and fallback: true
const populatedVecReq = new Request('https://act-omega-net.dev/api/v1/vectorize/query', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ vector: targetVec, topK: 5 })
});
const populatedVecRes = await workerDefault.fetch(populatedVecReq, { ACT_OMEGA_D1: mockValidD1 }, mockCtx);
const populatedVecJson = await populatedVecRes.json();
assert(populatedVecJson.matches.length === 3, '2.16: Populated D1 returns matching candidates');
assert(populatedVecJson.status === 'EDGE_FALLBACK_QUOTA_SHIELDED', `2.17: Populated fallback status is EDGE_FALLBACK_QUOTA_SHIELDED (got '${populatedVecJson.status}')`);
assert(populatedVecJson.fallback === true, '2.18: Populated fallback flag is true');

// 2.19 Route-level: Invalid input validation
const invalidVecReq = new Request('https://act-omega-net.dev/api/v1/vectorize/query', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ vector: [], topK: 5 })
});
const invalidVecRes = await workerDefault.fetch(invalidVecReq, {}, mockCtx);
assert(invalidVecRes.status === 400, '2.19: Empty vector returns HTTP 400 MISSING_OR_EMPTY_VECTOR');


// ==============================================================================
// SECTION 3: WORKERS AI EMBEDDINGS FAIL-CLOSED PROTOCOL
// ==============================================================================
console.log('\n--- [SECTION 3] Workers AI Embeddings Fail-Closed Protocol ---');

// 3.1 Call /api/v1/ai/embed without AI binding
const noAiReq = new Request('https://act-omega-net.dev/api/v1/ai/embed', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ text: 'Adversarial Test: Cloudflare Workers AI Fail-Closed Protocol' })
});
const noAiRes = await workerDefault.fetch(noAiReq, {}, mockCtx);
assert(noAiRes.status === 503, `3.1: Missing AI binding returns HTTP 503 (got ${noAiRes.status})`);
const noAiJson = await noAiRes.json();
assert(noAiJson.error === 'WORKERS_AI_EMBEDDING_UNAVAILABLE', `3.2: Error is WORKERS_AI_EMBEDDING_UNAVAILABLE (got '${noAiJson.error}')`);
assert(noAiJson.status === 'BINDING_UNAVAILABLE', `3.3: Status is BINDING_UNAVAILABLE (got '${noAiJson.status}')`);
assert(noAiJson.embedding === null, `3.4: Embedding is strictly null (got ${noAiJson.embedding})`);
assert(noAiJson.fallback === false, `3.5: Fallback flag is false (got ${noAiJson.fallback})`);

// 3.6 Call /api/v1/ai/embed when quota is exhausted (simulated via DO quota_check denying)
const mockExhaustedDo = {
  idFromName: () => 'mock_id',
  get: () => ({
    fetch: async () => Response.json({ allowed: false, status: 'DAILY_BUDGET_EXHAUSTED' })
  })
};
const exhaustedReq = new Request('https://act-omega-net.dev/api/v1/ai/embed', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ text: 'Prompt with exhausted daily quota budget' })
});
const exhaustedRes = await workerDefault.fetch(exhaustedReq, {
  SOVEREIGN_EDGE_SHADOW_DO: mockExhaustedDo,
  AI: { run: async () => ({ data: [[0.1, 0.2]] }) }
}, mockCtx);
assert(exhaustedRes.status === 503, `3.6: Exhausted quota returns HTTP 503 (got ${exhaustedRes.status})`);
const exhaustedJson = await exhaustedRes.json();
assert(exhaustedJson.error === 'WORKERS_AI_EMBEDDING_UNAVAILABLE', '3.7: Exhausted quota returns WORKERS_AI_EMBEDDING_UNAVAILABLE');
assert(exhaustedJson.status === 'DAILY_BUDGET_EXHAUSTED', `3.8: Exhausted status is DAILY_BUDGET_EXHAUSTED (got '${exhaustedJson.status}')`);
assert(exhaustedJson.embedding === null, '3.9: Embedding is strictly null on quota exhaustion');
assert(exhaustedJson.fallback === false, '3.10: Fallback is false on quota exhaustion');

// 3.11 Call /api/v1/ai/embed when remote AI.run throws exception
const mockThrowingAi = {
  run: async () => { throw new Error('Cloudflare AI Service Overloaded / GPU Error'); }
};
const throwingAiReq = new Request('https://act-omega-net.dev/api/v1/ai/embed', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ text: 'Prompt when AI model execution throws' })
});
const throwingAiRes = await workerDefault.fetch(throwingAiReq, { AI: mockThrowingAi }, mockCtx);
assert(throwingAiRes.status === 503, `3.11: AI execution failure returns HTTP 503 fail-closed (got ${throwingAiRes.status})`);
const throwingAiJson = await throwingAiRes.json();
assert(throwingAiJson.embedding === null, '3.12: Embedding is strictly null on execution failure');
assert(throwingAiJson.fallback === false, '3.13: Fallback is false on execution failure');

// 3.14 Call /api/v1/ai/embed with invalid inputs
const missingPromptReq = new Request('https://act-omega-net.dev/api/v1/ai/embed', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({})
});
const missingPromptRes = await workerDefault.fetch(missingPromptReq, {}, mockCtx);
assert(missingPromptRes.status === 400, '3.14: Missing prompt returns HTTP 400 MISSING_PROMPT_STRING');

// 3.15 Call /api/v1/ai/embed with nominal AI execution returns HTTP 200 with real embedding
const mockNormalAi = {
  run: async (model, input) => {
    return { data: [Array(384).fill(0.05)] };
  }
};
const normalAiReq = new Request('https://act-omega-net.dev/api/v1/ai/embed', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ text: 'Authentic 384D BGE-small inference' })
});
const normalAiRes = await workerDefault.fetch(normalAiReq, { AI: mockNormalAi }, mockCtx);
assert(normalAiRes.status === 200, `3.15: Nominal AI execution returns HTTP 200 (got ${normalAiRes.status})`);
const normalAiJson = await normalAiRes.json();
assert(Array.isArray(normalAiJson.embedding) && normalAiJson.embedding.length === 384, '3.16: Real embedding returned with dimension 384');
assert(normalAiJson.source === 'WORKERS_AI_BGE_SMALL', '3.17: Source is WORKERS_AI_BGE_SMALL');
assert(normalAiJson.status === 'NOMINAL', '3.18: Status is NOMINAL');

// 3.19 Isolate deduplication cache check: identical prompt hit returns ISOLATE_DEDUP_CACHE with 0 neurons
const cachedAiReq = new Request('https://act-omega-net.dev/api/v1/ai/embed', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ text: 'Authentic 384D BGE-small inference' })
});
const cachedAiRes = await workerDefault.fetch(cachedAiReq, { AI: mockNormalAi }, mockCtx);
const cachedAiJson = await cachedAiRes.json();
assert(cachedAiJson.source === 'ISOLATE_DEDUP_CACHE' && cachedAiJson.neurons_consumed === 0, '3.19: Cached prompt returns ISOLATE_DEDUP_CACHE with 0 neurons consumed');


// ==============================================================================
// SECTION 4: DURABLE OBJECT QUOTA HARD-CAP DENIAL & ACCOUNTING BASIS
// ==============================================================================
console.log('\n--- [SECTION 4] Durable Object Quota Hard-Cap Denial & Accounting Basis ---');

// Instantiate a live SovereignEdgeShadowDO with mock state/storage
const doState = {
  storage: null // Pure in-memory cache mode
};
const doInstance = new SovereignEdgeShadowDO(doState, {});

// Helper to configure a tier in the DO cache for precise boundary testing
function setDoTierQuota(tier, usage, softCap, hardCap) {
  const now = Date.now();
  const isDaily = (tier === "workers_ai" || tier === "workers_kv_write");
  const currentPeriod = isDaily
    ? new Date(now).toISOString().slice(0, 10)
    : new Date(now).toISOString().slice(0, 7);
  doInstance.quotaCache.set(tier, {
    tier,
    period_key: currentPeriod,
    usage_units: usage,
    soft_cap: softCap,
    hard_cap: hardCap,
    fallback_count: 0,
    last_op_ms: now,
    updated_at_ms: now
  });
}

// 4.1 Nominal request within limits (usage 50, soft_cap 100, hard_cap 150)
setDoTierQuota('workers_ai', 50, 100, 150);
const resNominal = doInstance.checkAndConsumeQuota('workers_ai', 10);
assert(resNominal.allowed === true, '4.1: Usage within limits is allowed (allowed: true)');
assert(resNominal.hard_cap_exceeded === false, '4.2: hard_cap_exceeded is false');
assert(resNominal.soft_cap_exceeded === false, '4.3: soft_cap_exceeded is false');
assert(resNominal.status === 'NOMINAL', `4.4: Status is NOMINAL (got '${resNominal.status}')`);
assert(resNominal.accounting_basis === 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING', '4.5: Accounting basis declared on nominal response');

// 4.6 Soft-cap exceeded (usage 95 + 10 = 105 > soft_cap 100, but <= hard_cap 150)
setDoTierQuota('workers_ai', 95, 100, 150);
const resSoftBreach = doInstance.checkAndConsumeQuota('workers_ai', 10);
assert(resSoftBreach.allowed === false, '4.6: Soft-cap breach is denied (allowed: false)');
assert(resSoftBreach.hard_cap_exceeded === false, '4.7: hard_cap_exceeded is false during soft breach');
assert(resSoftBreach.soft_cap_exceeded === true, '4.8: soft_cap_exceeded is true during soft breach');
assert(resSoftBreach.status === 'DAILY_BUDGET_EXHAUSTED', `4.9: Status is DAILY_BUDGET_EXHAUSTED for workers_ai (got '${resSoftBreach.status}')`);
assert(resSoftBreach.accounting_basis === 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING', '4.10: Accounting basis declared on soft breach');

// 4.11 Hard-cap exceeded (usage 140 + 20 = 160 > hard_cap 150)
setDoTierQuota('workers_ai', 140, 100, 150);
const resHardBreach = doInstance.checkAndConsumeQuota('workers_ai', 20);
assert(resHardBreach.allowed === false, '4.11: Hard-cap breach is strictly denied (allowed: false)');
assert(resHardBreach.hard_cap_exceeded === true, '4.12: hard_cap_exceeded is strictly true');
assert(resHardBreach.soft_cap_exceeded === true, '4.13: soft_cap_exceeded is true');
assert(resHardBreach.status === 'HARD_CAP_DENIED', `4.14: Status is strictly HARD_CAP_DENIED (got '${resHardBreach.status}')`);
assert(resHardBreach.accounting_basis === 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING', '4.15: Accounting basis declared on HARD_CAP_DENIED');
assert(resHardBreach.fallback_count === 1, '4.16: fallback_count incremented on hard cap breach');

// 4.17 Sustained overload stress test: 50 consecutive calls when usage reaches hard cap (150 >= 150)
setDoTierQuota('workers_ai', 150, 100, 150);
let all50Denied = true;
let all50HardCapStatus = true;
let all50HaveAccountingBasis = true;
for (let i = 0; i < 50; i++) {
  const burstRes = doInstance.checkAndConsumeQuota('workers_ai', 1);
  if (burstRes.allowed !== false || burstRes.hard_cap_exceeded !== true) {
    all50Denied = false;
  }
  if (burstRes.status !== 'HARD_CAP_DENIED') {
    all50HardCapStatus = false;
  }
  if (burstRes.accounting_basis !== 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING') {
    all50HaveAccountingBasis = false;
  }
}
assert(all50Denied, '4.17: All 50 overload burst calls denied with hard_cap_exceeded: true');
assert(all50HardCapStatus, '4.18: All 50 overload burst calls returned status HARD_CAP_DENIED');
assert(all50HaveAccountingBasis, '4.19: All 50 overload burst calls declared exact accounting basis');

// Check usage_units didn't leak / increment during hard-cap denials
const tierRow = doInstance.quotaCache.get('workers_ai');
assert(tierRow.usage_units === 150, `4.20: Usage units remained frozen at 150 (got ${tierRow.usage_units})`);
assert(tierRow.fallback_count === 50, `4.21: Fallback count tracked all 50 denials (got ${tierRow.fallback_count})`);

// 4.22 Multi-tier test: vectorize tier hard cap (soft 24M, hard 30M, monthly period key)
setDoTierQuota('vectorize', 29999900, 24000000, 30000000);
const resVecHard = doInstance.checkAndConsumeQuota('vectorize', 200); // 30,000,100 > 30,000,000
assert(resVecHard.allowed === false && resVecHard.hard_cap_exceeded === true, '4.22: Vectorize hard cap denied');
assert(resVecHard.status === 'HARD_CAP_DENIED', `4.23: Vectorize status is HARD_CAP_DENIED (got '${resVecHard.status}')`);

// 4.24 Multi-tier test: workers_kv_write tier hard cap (soft 720, hard 1000)
setDoTierQuota('workers_kv_write', 999, 720, 1000);
const resKvHard = doInstance.checkAndConsumeQuota('workers_kv_write', 5); // 1004 > 1000
assert(resKvHard.allowed === false && resKvHard.hard_cap_exceeded === true, '4.24: KV Write hard cap denied');
assert(resKvHard.status === 'HARD_CAP_DENIED', `4.25: KV Write status is HARD_CAP_DENIED (got '${resKvHard.status}')`);

// 4.26 Fallback occurred recording
const resFallbackRec = doInstance.checkAndConsumeQuota('vectorize', 1, true);
assert(resFallbackRec.allowed === false && resFallbackRec.fallback_recorded === true, '4.26: Fallback recorded parameter returns allowed: false, fallback_recorded: true');
assert(resFallbackRec.status === 'FALLBACK_RECORDED', '4.27: Status is FALLBACK_RECORDED');
assert(resFallbackRec.accounting_basis === 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING', '4.28: Fallback recorded declares accounting basis');

// 4.29 DO Fetch Handler: GET /shadow/quota_check
setDoTierQuota('vectorize', 29999900, 24000000, 30000000);
const doFetchReq = new Request('https://sovereign-internal/shadow/quota_check?tier=vectorize&units=500');
const doFetchRes = await doInstance.fetch(doFetchReq);
assert(doFetchRes.status === 200, '4.29: DO /shadow/quota_check returns HTTP 200');
const doFetchJson = await doFetchRes.json();
assert(doFetchJson.status === 'HARD_CAP_DENIED', `4.30: DO fetch quota_check returns HARD_CAP_DENIED (got '${doFetchJson.status}')`);
assert(doFetchJson.hard_cap_exceeded === true, '4.31: DO fetch quota_check returns hard_cap_exceeded: true');

// 4.32 DO Fetch Handler: GET /shadow/quota_status
tierRow.usage_units = 30000000;
const doStatusReq = new Request('https://sovereign-internal/shadow/quota_status');
const doStatusRes = await doInstance.fetch(doStatusReq);
assert(doStatusRes.status === 200, '4.32: DO /shadow/quota_status returns HTTP 200');
const doStatusJson = await doStatusRes.json();
assert(doStatusJson.status === 'QUOTA_STATUS_ONLINE', '4.33: Quota status is QUOTA_STATUS_ONLINE');
assert(doStatusJson.accounting_basis === 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING', '4.34: Quota status has DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING');
assert(doStatusJson.tiers.workers_ai.status === 'HARD_CAP_DENIED', `4.35: workers_ai tier status is HARD_CAP_DENIED (got '${doStatusJson.tiers.workers_ai.status}')`);


// ==============================================================================
// SECTION 5: EDGE WORKER FREE TIER GOVERNOR ROUTE INTEGRATION
// ==============================================================================
console.log('\n--- [SECTION 5] Edge Worker Free Tier Governor Route Integration ---');

// Mock DO binding for worker integration test
const mockGovernorDo = {
  idFromName: () => 'gov_id',
  get: () => ({
    fetch: async (req) => {
      const urlStr = typeof req === 'string' ? req : (req && req.url ? req.url : '');
      const u = new URL(urlStr);
      if (u.pathname === '/shadow/quota_status') {
        return Response.json({
          status: 'QUOTA_STATUS_ONLINE',
          accounting_basis: 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING',
          tiers: {
            vectorize: { status: 'NOMINAL', usage_units: 1000, soft_cap: 24000000, hard_cap: 30000000 },
            workers_ai: { status: 'HARD_CAP_DENIED', usage_units: 10500, soft_cap: 8500, hard_cap: 10000 }
          }
        });
      }
      return Response.json({ status: 'NOMINAL' });
    }
  })
};

const govReq = new Request('https://act-omega-net.dev/api/v1/cloudflare/free_tier_governor?edge_direct=1', {
  headers: {
    'X-Sovereign-Edge-Direct': '1'
  }
});
const govRes = await workerDefault.fetch(govReq, {
  SOVEREIGN_EDGE_SHADOW_DO: mockGovernorDo,
  SOVEREIGN_OPERATOR_KEY: 'test-production-operator-key-32chars-ok'
}, mockCtx);
assert(govRes.status === 200, '5.1: /api/v1/cloudflare/free_tier_governor returns HTTP 200');
const govJson = await govRes.json();
assert(govJson.accounting_basis === 'DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING', '5.2: Governor route emits accounting basis');
assert(govJson.global_status === 'HARD_CAP_DENIED', `5.3: Governor global_status is HARD_CAP_DENIED when hard cap denied (got '${govJson.global_status}')`);
assert(govJson.tiers.workers_ai.status === 'HARD_CAP_DENIED', '5.4: Governor workers_ai tier reflects HARD_CAP_DENIED');


// ==============================================================================
// SUMMARY & VERDICT EVALUATION
// ==============================================================================
console.log('\n==========================================================================');
console.log(`   CHALLENGER 1 SUMMARY: ${passedTests} PASSED, ${failedTests} FAILED out of ${totalTests} TESTS`);
console.log('==========================================================================');

if (failedTests > 0) {
  console.error('\nFAILED CHALLENGES:');
  for (const f of failures) {
    console.error(`  - ${f.testName}: ${f.details}`);
  }
  console.log('\n>>> VERDICT: CHALLENGE_FAILED <<<');
  process.exit(1);
} else {
  console.log('\n>>> VERDICT: CONFIRM_CORRECT (ALL FALLBACK & QUOTA CONSTRAINTS EMPIRICALLY CONFIRMED) <<<');
  process.exit(0);
}
