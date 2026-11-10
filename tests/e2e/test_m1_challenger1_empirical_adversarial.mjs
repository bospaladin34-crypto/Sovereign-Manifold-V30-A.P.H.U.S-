// ==============================================================================
// ACT-OMEGA SOVEREIGN MANIFOLD v70.0.0 — EMPIRICAL ADVERSARIAL CHALLENGER SUITE
// Milestone 1 (Phase I: Items 1–3) — Adversarial Stress Testing
// File: tests/e2e/test_m1_challenger1_empirical_adversarial.mjs
// Agent: r5_m1_challenger_1 (Empirical Challenger: critic, specialist)
// ==============================================================================

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';
import { performance } from 'node:perf_hooks';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..', '..');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const failureDetails = [];

function assert(condition, testName, details = '') {
  totalTests++;
  if (condition) {
    passedTests++;
    console.log(`  [PASS] ${testName}`);
  } else {
    failedTests++;
    console.error(`  [FAIL] ${testName} — ${details}`);
    failureDetails.push({ testName, details });
  }
}

console.log('==========================================================================');
console.log('   R5_M1_CHALLENGER_1: EMPIRICAL ADVERSARIAL STRESS TEST HARNESS          ');
console.log('   Target: Item 1 (JWT Verification & Constant-Time Operator Auth)        ');
console.log('==========================================================================\n');

// ------------------------------------------------------------------------------
// Load worker functions from worker_vpc_shadow_v3700.js
// ------------------------------------------------------------------------------
const workerPath = path.join(repoRoot, 'worker_vpc_shadow_v3700.js');
assert(fs.existsSync(workerPath), 'Target worker source file exists at ' + workerPath);

const workerCode = fs.readFileSync(workerPath, 'utf8');

const testContext = {};
const extractCode = `
${workerCode.slice(workerCode.indexOf('class SimpleLruCache'), workerCode.indexOf('export class SovereignEdgeShadowDO'))}

testContext.SimpleLruCache = SimpleLruCache;
testContext.parseBase64UrlToUint8Array = parseBase64UrlToUint8Array;
testContext.parseJwtJsonSegment = parseJwtJsonSegment;
testContext.getOrFetchCloudflareAccessKey = getOrFetchCloudflareAccessKey;
testContext.verifyCloudflareAccessJwt = verifyCloudflareAccessJwt;
testContext.timingSafeEqualString = timingSafeEqualString;
testContext.verifyZeroTrustAndOperatorHeaders = verifyZeroTrustAndOperatorHeaders;
testContext.isProductionTurnstileKey = isProductionTurnstileKey;
testContext.gZeroTrustJwtCache = gZeroTrustJwtCache;
testContext.gAccessJwksKeyCache = gAccessJwksKeyCache;
`;

try {
  const runner = new Function('testContext', 'Headers', 'Request', 'Response', 'FormData', extractCode);
  runner(testContext, globalThis.Headers, globalThis.Request, globalThis.Response, globalThis.FormData);
  assert(typeof testContext.verifyCloudflareAccessJwt === 'function', 'verifyCloudflareAccessJwt extracted successfully');
  assert(typeof testContext.timingSafeEqualString === 'function', 'timingSafeEqualString extracted successfully');
  assert(typeof testContext.verifyZeroTrustAndOperatorHeaders === 'function', 'verifyZeroTrustAndOperatorHeaders extracted successfully');
} catch (err) {
  assert(false, 'Failed to extract worker functions', err.message);
  process.exit(1);
}

const {
  verifyCloudflareAccessJwt,
  timingSafeEqualString,
  verifyZeroTrustAndOperatorHeaders,
  isProductionTurnstileKey,
  gZeroTrustJwtCache,
  gAccessJwksKeyCache
} = testContext;

// Helper to encode base64url
function toB64Url(obj) {
  const str = typeof obj === 'string' ? obj : JSON.stringify(obj);
  return Buffer.from(str).toString('base64url');
}

// Setup authentic environment and RSA keypair for testing
const testTeamDomain = 'act-omega-net.cloudflareaccess.com';
const testAudience = 'act-omega-zero-trust-aud';
const validOperatorKey = 'ACT_OMEGA_OPERATOR_VAULT_KEY_2026_SOVEREIGN_SECRET'; // >= 24 chars
const mockUrl = 'https://act-omega-net.dev/api/v1/r2/vault/test.bin';

const testEnv = {
  SOVEREIGN_OPERATOR_KEY: validOperatorKey,
  CF_ACCESS_TEAM_DOMAIN: testTeamDomain,
  CF_ACCESS_AUD: testAudience
};

// Generate valid RSA-2048 keypair
const accessKeyPair = await crypto.subtle.generateKey(
  {
    name: 'RSASSA-PKCS1-v1_5',
    modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]),
    hash: 'SHA-256'
  },
  true,
  ['sign', 'verify']
);
const accessKid = 'act-omega-cert-kid-adversarial-01';

// Seed JWKS public key cache
gAccessJwksKeyCache.set(`${testTeamDomain}:${accessKid}`, {
  cryptoKey: accessKeyPair.publicKey,
  expiresAt: Date.now() + 3600000
});

// Helper to forge and sign JWT
async function generateTestJwt(headerOverrides = {}, payloadOverrides = {}, signWithKey = accessKeyPair.privateKey) {
  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: 'RS256',
    kid: accessKid,
    typ: 'JWT',
    ...headerOverrides
  };
  const payload = {
    aud: testAudience,
    exp: now + 3600,
    nbf: now - 60,
    sub: 'donevin-principal-architect',
    email: 'bospaladin34@gmail.com',
    ...payloadOverrides
  };

  const unsigned = `${toB64Url(header)}.${toB64Url(payload)}`;
  if (!signWithKey) {
    return `${unsigned}.UNSIGNED_DUMMY_SIGNATURE`;
  }
  const sigBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    signWithKey,
    new TextEncoder().encode(unsigned)
  );
  return `${unsigned}.${Buffer.from(sigBuffer).toString('base64url')}`;
}

// ==============================================================================
// SECTION 1: FORGED, MALFORMED & TAMPERED JWT ATTACKS
// ==============================================================================
console.log('\n--- [SECTION 1] Forged, Malformed & Tampered JWT Attacks ---');

// 1.1 Non-string or empty inputs
const nonStringTokens = [null, undefined, '', 12345, {}, []];
for (let i = 0; i < nonStringTokens.length; i++) {
  const token = nonStringTokens[i];
  const req = new Request(mockUrl, {
    headers: token !== null && token !== undefined ? new Headers({ 'Cf-Access-Jwt-Assertion': String(token) }) : new Headers()
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  assert(res.authorized === false, `1.1.${i}: Non-string/empty JWT input (${typeof token}) rejected`);
}

// 1.2 Segment count violations (not 3 dot-separated parts)
const segmentViolations = [
  'singleparttokenwithoutdots',
  'partone.parttwo',
  'part1.part2.part3.part4',
  'p1.p2.p3.p4.p5',
  '...',
  '..',
  '.'
];
for (let i = 0; i < segmentViolations.length; i++) {
  const badToken = segmentViolations[i];
  const req = new Request(mockUrl, {
    headers: new Headers({ 'Cf-Access-Jwt-Assertion': badToken })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  assert(res.authorized === false && res.status === 403, `1.2.${i}: Invalid dot segment count "${badToken.slice(0, 15)}..." rejected with 403`);
  assert(!gZeroTrustJwtCache.get(badToken), `1.2.${i}b: Invalid segment token not cached in gZeroTrustJwtCache`);
}

// 1.3 Corrupted base64url or invalid JSON in header/payload
const corruptedEncodingTokens = [
  '!!!badb64!!!.eyJzdWIiOiIxMjMifQ.sig',
  'eyJhbGciOiJSUzI1NiJ9.!!!badb64!!!.sig',
  Buffer.from('not valid json {').toString('base64url') + '.eyJzdWIiOiIxMjMifQ.sig',
  'eyJhbGciOiJSUzI1NiIsImtpZCI6InRlc3QifQ.' + Buffer.from('not valid json {').toString('base64url') + '.sig'
];
for (let i = 0; i < corruptedEncodingTokens.length; i++) {
  const badToken = corruptedEncodingTokens[i];
  const req = new Request(mockUrl, {
    headers: new Headers({ 'Cf-Access-Jwt-Assertion': badToken })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  assert(res.authorized === false && res.status === 403, `1.3.${i}: Corrupted b64/JSON token rejected with 403`);
  assert(!gZeroTrustJwtCache.get(badToken), `1.3.${i}b: Corrupted b64/JSON token not cached`);
}

// 1.4 Header Algorithm Confusion Attacks (alg !== "RS256")
const forbiddenAlgs = ['none', 'HS256', 'ES256', 'RS384', 'RS512', 'PS256', 'EdDSA', ''];
for (let i = 0; i < forbiddenAlgs.length; i++) {
  const alg = forbiddenAlgs[i];
  const token = await generateTestJwt({ alg });
  const req = new Request(mockUrl, {
    headers: new Headers({ 'Cf-Access-Jwt-Assertion': token })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  assert(res.authorized === false && res.status === 403, `1.4.${i}: Algorithm confusion attack alg="${alg}" rejected with 403`);
  assert(!gZeroTrustJwtCache.get(token), `1.4.${i}b: alg="${alg}" attack token not cached`);
}

// 1.5 Header Key ID (kid) attacks
const badKidHeaders = [
  { kid: undefined }, // missing kid
  { kid: null },
  { kid: 12345 }, // non-string kid
  { kid: 'unregistered-rogue-kid-999' } // unknown kid
];
for (let i = 0; i < badKidHeaders.length; i++) {
  const h = badKidHeaders[i];
  const token = await generateTestJwt(h);
  const req = new Request(mockUrl, {
    headers: new Headers({ 'Cf-Access-Jwt-Assertion': token })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  assert(res.authorized === false && res.status === 403, `1.5.${i}: Invalid/unregistered kid (${JSON.stringify(h)}) rejected with 403`);
  assert(!gZeroTrustJwtCache.get(token), `1.5.${i}b: Invalid kid token not cached`);
}

// 1.6 Cryptographic Signature Tampering & Forgery Attacks
const validBaseJwt = await generateTestJwt();
const parts = validBaseJwt.split('.');

// 1.6.1 Flip bits in signature
const validSigBytes = Buffer.from(parts[2], 'base64url');
validSigBytes[0] ^= 0x01; // flip 1 bit
const bitFlippedToken = `${parts[0]}.${parts[1]}.${validSigBytes.toString('base64url')}`;
const reqBitFlip = new Request(mockUrl, {
  headers: new Headers({ 'Cf-Access-Jwt-Assertion': bitFlippedToken })
});
const resBitFlip = await verifyZeroTrustAndOperatorHeaders(reqBitFlip, testEnv);
assert(resBitFlip.authorized === false && resBitFlip.status === 403, '1.6.1: 1-bit flipped signature rejected with 403');
assert(!gZeroTrustJwtCache.get(bitFlippedToken), '1.6.1b: Bit-flipped token not cached');

// 1.6.2 Signature from an untrusted / rogue RSA key
const rogueKeyPair = await crypto.subtle.generateKey(
  {
    name: 'RSASSA-PKCS1-v1_5',
    modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]),
    hash: 'SHA-256'
  },
  true,
  ['sign', 'verify']
);
const rogueSignedToken = await generateTestJwt({}, {}, rogueKeyPair.privateKey);
const reqRogue = new Request(mockUrl, {
  headers: new Headers({ 'Cf-Access-Jwt-Assertion': rogueSignedToken })
});
const resRogue = await verifyZeroTrustAndOperatorHeaders(reqRogue, testEnv);
assert(resRogue.authorized === false && resRogue.status === 403, '1.6.2: Token signed with unauthorized rogue RSA key rejected with 403');
assert(!gZeroTrustJwtCache.get(rogueSignedToken), '1.6.2b: Rogue-signed token not cached');

// 1.6.3 Payload tampering with original signature retained
const tamperedPayload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
tamperedPayload.sub = 'elevated-admin-attacker';
const tamperedPayloadToken = `${parts[0]}.${toB64Url(tamperedPayload)}.${parts[2]}`;
const reqTamperedPayload = new Request(mockUrl, {
  headers: new Headers({ 'Cf-Access-Jwt-Assertion': tamperedPayloadToken })
});
const resTamperedPayload = await verifyZeroTrustAndOperatorHeaders(reqTamperedPayload, testEnv);
assert(resTamperedPayload.authorized === false && resTamperedPayload.status === 403, '1.6.3: Tampered payload with valid original signature rejected with 403');
assert(!gZeroTrustJwtCache.get(tamperedPayloadToken), '1.6.3b: Tampered payload token not cached');

// 1.7 Expiration & Temporal Validity Attacks
const nowSec = Math.floor(Date.now() / 1000);
const temporalAttacks = [
  { exp: nowSec - 1 }, // expired 1s ago
  { exp: nowSec - 3600 }, // expired 1h ago
  { exp: nowSec }, // exp === nowSec (fail closed)
  { exp: '2099-01-01' }, // non-numeric exp
  { exp: null }, // null exp
  { nbf: nowSec + 10 }, // not valid yet (future nbf)
  { nbf: nowSec + 3600 }, // far future nbf
  { nbf: 'tomorrow' } // non-numeric nbf
];
for (let i = 0; i < temporalAttacks.length; i++) {
  const p = temporalAttacks[i];
  const token = await generateTestJwt({}, p);
  const req = new Request(mockUrl, {
    headers: new Headers({ 'Cf-Access-Jwt-Assertion': token })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  assert(res.authorized === false && res.status === 403, `1.7.${i}: Temporal attack (${JSON.stringify(p)}) rejected with 403`);
  assert(!gZeroTrustJwtCache.get(token), `1.7.${i}b: Temporally invalid token not cached`);
}

// 1.8 Audience Validation Attacks
const audienceAttacks = [
  { aud: 'wrong-untrusted-audience' },
  { aud: ['wrong-aud-1', 'wrong-aud-2'] },
  { aud: [] },
  { aud: null },
  { aud: undefined },
  { aud: 12345 }
];
for (let i = 0; i < audienceAttacks.length; i++) {
  const p = audienceAttacks[i];
  const token = await generateTestJwt({}, p);
  const req = new Request(mockUrl, {
    headers: new Headers({ 'Cf-Access-Jwt-Assertion': token })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  assert(res.authorized === false && res.status === 403, `1.8.${i}: Audience attack (${JSON.stringify(p)}) rejected with 403`);
  assert(!gZeroTrustJwtCache.get(token), `1.8.${i}b: Audience invalid token not cached`);
}

// 1.9 Environment Variable Absence Fail-Closed Check
const tokenForEnvTest = await generateTestJwt();
const strippedEnvs = [
  {}, // empty env
  { CF_ACCESS_TEAM_DOMAIN: testTeamDomain }, // missing aud
  { CF_ACCESS_AUD: testAudience }, // missing domain
  null,
  undefined
];
for (let i = 0; i < strippedEnvs.length; i++) {
  const env = strippedEnvs[i];
  const req = new Request(mockUrl, {
    headers: new Headers({ 'Cf-Access-Jwt-Assertion': tokenForEnvTest })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, env);
  assert(res.authorized === false && res.status === 403, `1.9.${i}: Stripped environment (${JSON.stringify(env)}) fails closed with 403`);
}

// 1.10 Repeated Attack Flooding & Zero-Trust Cache Integrity
const floodToken = await generateTestJwt({ alg: 'none' });
for (let i = 0; i < 50; i++) {
  const req = new Request(mockUrl, {
    headers: new Headers({ 'Cf-Access-Jwt-Assertion': floodToken })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  if (res.authorized !== false) {
    assert(false, '1.10: Flood token authorized on attempt ' + i);
    break;
  }
}
assert(!gZeroTrustJwtCache.get(floodToken), '1.10: 50-repetition flood attack never poisoned gZeroTrustJwtCache');

// 1.11 Legitimate Token Caching
const legitToken = await generateTestJwt();
const reqLegit = new Request(mockUrl, {
  headers: new Headers({ 'Cf-Access-Jwt-Assertion': legitToken })
});
const resLegit = await verifyZeroTrustAndOperatorHeaders(reqLegit, testEnv);
assert(resLegit.authorized === true && resLegit.role === 'ZERO_TRUST_OPERATOR', '1.11.1: Legitimate token accepted');
const cachedRecord = gZeroTrustJwtCache.get(legitToken);
assert(cachedRecord && cachedRecord.authorized === true && cachedRecord.role === 'ZERO_TRUST_OPERATOR', '1.11.2: Legitimate token successfully and safely cached in gZeroTrustJwtCache');


// ==============================================================================
// SECTION 2: TIMING & LENGTH SIDE-CHANNEL ATTACKS (X-Sovereign-Operator-Key)
// ==============================================================================
console.log('\n--- [SECTION 2] Timing & Length Side-Channel Attacks ---');

// 2.1 Basic Constant-Time Logic & Edge Cases
assert(await timingSafeEqualString('a', 'a') === true, '2.1.1: Identical 1-char strings return true');
assert(await timingSafeEqualString(validOperatorKey, validOperatorKey) === true, '2.1.2: Identical 50-char keys return true');
assert(await timingSafeEqualString(validOperatorKey, validOperatorKey.slice(0, -1) + 'X') === false, '2.1.3: 1-char mismatch at end returns false');
assert(await timingSafeEqualString(validOperatorKey, 'X' + validOperatorKey.slice(1)) === false, '2.1.4: 1-char mismatch at start returns false');
assert(await timingSafeEqualString(validOperatorKey, validOperatorKey + 'EXTRA') === false, '2.1.5: Prefix match with appended chars returns false');
assert(await timingSafeEqualString(validOperatorKey, validOperatorKey.slice(0, -1)) === false, '2.1.6: Substring prefix returns false');
assert(await timingSafeEqualString(null, validOperatorKey) === false, '2.1.7: null first arg returns false');
assert(await timingSafeEqualString(validOperatorKey, undefined) === false, '2.1.8: undefined second arg returns false');
assert(await timingSafeEqualString(12345, validOperatorKey) === false, '2.1.9: number first arg returns false');

// 2.2 Operator Key Length Boundary Tests in verifyZeroTrustAndOperatorHeaders
const shortKeys = [
  'a',
  '1234567890',
  '12345678901234567890123', // exactly 23 chars
  ''
];
for (let i = 0; i < shortKeys.length; i++) {
  const sk = shortKeys[i];
  const req = new Request(mockUrl, {
    headers: new Headers({ 'X-Sovereign-Operator-Key': sk })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, testEnv);
  if (sk === '') {
    // Empty key is treated as anonymous (not an operator header provided)
    assert(res.authorized === false && res.role === 'ANONYMOUS_CLIENT', `2.2.${i}: Empty string operator key treated as ANONYMOUS_CLIENT`);
  } else {
    assert(res.authorized === false && res.status === 403 && res.error === 'INVALID_OPERATOR_KEY', `2.2.${i}: Short key (${sk.length} chars) rejected with 403 INVALID_OPERATOR_KEY`);
  }
}

// 2.3 Exactly 24 Characters
const exact24Mismatch = '123456789012345678901234';
const req24Mismatch = new Request(mockUrl, {
  headers: new Headers({ 'X-Sovereign-Operator-Key': exact24Mismatch })
});
const res24Mismatch = await verifyZeroTrustAndOperatorHeaders(req24Mismatch, testEnv);
assert(res24Mismatch.authorized === false && res24Mismatch.status === 403, '2.3.1: Exactly 24 char mismatch rejected with 403');

// Exact 24 char match when expected key is 24 chars
const env24 = { ...testEnv, SOVEREIGN_OPERATOR_KEY: exact24Mismatch };
const req24Match = new Request(mockUrl, {
  headers: new Headers({ 'X-Sovereign-Operator-Key': exact24Mismatch })
});
const res24Match = await verifyZeroTrustAndOperatorHeaders(req24Match, env24);
assert(res24Match.authorized === true && res24Match.role === 'SOVEREIGN_OPERATOR', '2.3.2: Exactly 24 char match accepted with role SOVEREIGN_OPERATOR');

// 2.4 Unconfigured Operator Secret Timing Blinding
const unconfiguredEnvs = [
  { ...testEnv, SOVEREIGN_OPERATOR_KEY: undefined },
  { ...testEnv, SOVEREIGN_OPERATOR_KEY: null },
  { ...testEnv, SOVEREIGN_OPERATOR_KEY: '' },
  { ...testEnv, SOVEREIGN_OPERATOR_KEY: 'short_key_16_chars' } // < 24 chars
];
for (let i = 0; i < unconfiguredEnvs.length; i++) {
  const env = unconfiguredEnvs[i];
  const req = new Request(mockUrl, {
    headers: new Headers({ 'X-Sovereign-Operator-Key': validOperatorKey })
  });
  const res = await verifyZeroTrustAndOperatorHeaders(req, env);
  assert(res.authorized === false && res.status === 403 && res.error === 'INVALID_OPERATOR_KEY', `2.4.${i}: Unconfigured/invalid secret rejected with 403 and blind timing executed`);
}

// 2.5 Statistical Empirical Timing Attack & Side-Channel Benchmark
console.log('  -> Running statistical timing benchmark (interleaved 1,000 iterations per scenario)...');
const benchmarkTarget = 'ACT_OMEGA_SOVEREIGN_SECRET_KEY_EXACTLY_64_CHARACTERS_LONG_2026_TEST'; // 68 chars
const candidateScenarios = {
  'Exact Match': benchmarkTarget,
  'Mismatch at Index 0': 'X' + benchmarkTarget.slice(1),
  'Mismatch at Index 16': benchmarkTarget.slice(0, 16) + 'X' + benchmarkTarget.slice(17),
  'Mismatch at Index 32': benchmarkTarget.slice(0, 32) + 'X' + benchmarkTarget.slice(33),
  'Mismatch at Index 48': benchmarkTarget.slice(0, 48) + 'X' + benchmarkTarget.slice(49),
  'Mismatch at Last Index': benchmarkTarget.slice(0, -1) + 'X',
  'Length Mismatch (24 chars)': benchmarkTarget.slice(0, 24),
  'Length Mismatch (100 chars)': benchmarkTarget + 'A'.repeat(32),
  'Extreme Short (1 char)': 'A'
};

const scenarioNames = Object.keys(candidateScenarios);
const timingDurations = Object.fromEntries(scenarioNames.map(k => [k, []]));
const iterations = 1000;

// Warmup JIT
for (let w = 0; w < 200; w++) {
  for (const name of scenarioNames) {
    await timingSafeEqualString(candidateScenarios[name], benchmarkTarget);
  }
}

// Interleaved iterations to distribute GC and thread scheduling equally
for (let i = 0; i < iterations; i++) {
  for (const name of scenarioNames) {
    const candidate = candidateScenarios[name];
    const t0 = performance.now();
    await timingSafeEqualString(candidate, benchmarkTarget);
    const t1 = performance.now();
    timingDurations[name].push((t1 - t0) * 1000); // microseconds
  }
}

const timingStats = {};
for (const [name, list] of Object.entries(timingDurations)) {
  const sorted = [...list].sort((a, b) => a - b);
  const median = sorted[Math.floor(sorted.length / 2)];
  const p10 = Math.floor(sorted.length * 0.1);
  const p90 = Math.floor(sorted.length * 0.9);
  const trimmed = sorted.slice(p10, p90);
  const trimmedMean = trimmed.reduce((a, b) => a + b, 0) / trimmed.length;
  timingStats[name] = { median, trimmedMean };
}

console.log('  Timing benchmark results (microseconds per comparison):');
for (const [name, stats] of Object.entries(timingStats)) {
  console.log(`    - ${name.padEnd(30)}: median = ${stats.median.toFixed(2)} µs, trimmedMean = ${stats.trimmedMean.toFixed(2)} µs`);
}

// Compare Mismatch at Index 0 vs Mismatch at Last Index
const diffTrimmed = Math.abs(timingStats['Mismatch at Index 0'].trimmedMean - timingStats['Mismatch at Last Index'].trimmedMean);
const diffMedian = Math.abs(timingStats['Mismatch at Index 0'].median - timingStats['Mismatch at Last Index'].median);
console.log(`  Difference between Index 0 and Last Index: median diff = ${diffMedian.toFixed(2)} µs, trimmedMean diff = ${diffTrimmed.toFixed(2)} µs`);

// In a constant-time algorithm, the difference between index 0 mismatch and last index mismatch
// must be within normal CPU noise / jitter (< 5 µs)
assert(diffTrimmed < 5.0 && diffMedian < 5.0, `2.5: No early-exit timing side channel observed across index positions (trimmed diff: ${diffTrimmed.toFixed(2)} µs, median diff: ${diffMedian.toFixed(2)} µs)`);


// ==============================================================================
// SECTION 3: INVARIANT #7 QUERY PARAMETER REJECTION ATTACKS (?key=)
// ==============================================================================
console.log('\n--- [SECTION 3] Invariant #7 Query Parameter Rejection Attacks ---');

// 3.1 Request with only ?key= (no headers)
const reqOnlyQueryKey = new Request(mockUrl + '?key=' + validOperatorKey);
const resOnlyQueryKey = await verifyZeroTrustAndOperatorHeaders(reqOnlyQueryKey, testEnv);
assert(resOnlyQueryKey.authorized === false && resOnlyQueryKey.status === 403 && resOnlyQueryKey.error === 'QUERY_PARAM_KEY_FORBIDDEN',
  '3.1: Request with only ?key= strictly rejected with 403 QUERY_PARAM_KEY_FORBIDDEN');

// 3.2 Request with valid X-Sovereign-Operator-Key header AND ?key= query param
const reqBothKeyAndHeader = new Request(mockUrl + '?key=any_value_even_dummy', {
  headers: new Headers({ 'X-Sovereign-Operator-Key': validOperatorKey })
});
const resBothKeyAndHeader = await verifyZeroTrustAndOperatorHeaders(reqBothKeyAndHeader, testEnv);
assert(resBothKeyAndHeader.authorized === false && resBothKeyAndHeader.status === 403 && resBothKeyAndHeader.error === 'QUERY_PARAM_KEY_FORBIDDEN',
  '3.2: Request with valid operator header accompanied by ?key= strictly rejected with 403 QUERY_PARAM_KEY_FORBIDDEN');

// 3.3 Request with empty ?key= (mockUrl + "?key=")
const reqEmptyQueryKey = new Request(mockUrl + '?key=', {
  headers: new Headers({ 'X-Sovereign-Operator-Key': validOperatorKey })
});
const resEmptyQueryKey = await verifyZeroTrustAndOperatorHeaders(reqEmptyQueryKey, testEnv);
assert(resEmptyQueryKey.authorized === false && resEmptyQueryKey.status === 403 && resEmptyQueryKey.error === 'QUERY_PARAM_KEY_FORBIDDEN',
  '3.3: Request with empty ?key= query parameter strictly rejected with 403');

// 3.4 Request with multiple query parameters including ?key=
const reqMultiQueryParams = new Request(mockUrl + '?tier=vectorize&action=query&key=leakattempt&verbose=true', {
  headers: new Headers({ 'X-Sovereign-Operator-Key': validOperatorKey })
});
const resMultiQueryParams = await verifyZeroTrustAndOperatorHeaders(reqMultiQueryParams, testEnv);
assert(resMultiQueryParams.authorized === false && resMultiQueryParams.status === 403 && resMultiQueryParams.error === 'QUERY_PARAM_KEY_FORBIDDEN',
  '3.4: Request with interleaved ?key= among other query parameters strictly rejected with 403');

// 3.5 Valid operator request without ?key= succeeds
const reqCleanOperator = new Request(mockUrl + '?tier=vectorize&action=query', {
  headers: new Headers({ 'X-Sovereign-Operator-Key': validOperatorKey })
});
const resCleanOperator = await verifyZeroTrustAndOperatorHeaders(reqCleanOperator, testEnv);
assert(resCleanOperator.authorized === true && resCleanOperator.role === 'SOVEREIGN_OPERATOR',
  '3.5: Legitimate operator request without ?key= succeeds with role SOVEREIGN_OPERATOR');


// ==============================================================================
// SECTION 4: PRIVILEGED ROUTE WORKER AUTHORIZATION ENFORCEMENT
// ==============================================================================
console.log('\n--- [SECTION 4] Privileged Route Worker Authorization Enforcement ---');

// Audit worker code for authorization enforcement
const kvPutMatches = workerCode.includes('if (!auth.authorized) {\n        return Response.json({ error: "OPERATOR_AUTH_REQUIRED", status: 403 }, { status: 403 });\n      }');
assert(kvPutMatches, '4.1: /api/v1/kv/put strictly enforces auth.authorized with HTTP 403 OPERATOR_AUTH_REQUIRED');

// Check that verifyZeroTrustAndOperatorHeaders is awaited at all call sites (excluding function declaration)
const allOccurrences = [...workerCode.matchAll(/verifyZeroTrustAndOperatorHeaders\s*\(/g)];
const functionDeclarations = [...workerCode.matchAll(/function\s+verifyZeroTrustAndOperatorHeaders\s*\(/g)];
const actualCallSites = allOccurrences.length - functionDeclarations.length;
const awaitedCalls = [...workerCode.matchAll(/await\s+verifyZeroTrustAndOperatorHeaders\s*\(/g)];
assert(actualCallSites === awaitedCalls.length && actualCallSites >= 3, `4.2: All ${actualCallSites} call sites of verifyZeroTrustAndOperatorHeaders use await (${awaitedCalls.length} awaited)`);

// Check Turnstile test key rejection
assert(isProductionTurnstileKey('0x4AAAAAAtestkeyvalidproductionformat'), '4.3.1: Valid format production Turnstile key accepted');
assert(!isProductionTurnstileKey('1x00000000000000000000AA'), '4.3.2: 1x00000 always-pass test key rejected');
assert(!isProductionTurnstileKey('2x00000000000000000000AA'), '4.3.3: 2x00000 always-fail test key rejected');
assert(!isProductionTurnstileKey('3x00000000000000000000AA'), '4.3.4: 3x00000 interactive test key rejected');
assert(!isProductionTurnstileKey(''), '4.3.5: Empty string key rejected');
assert(!isProductionTurnstileKey(null), '4.3.6: null key rejected');


// ==============================================================================
// CHALLENGER SUMMARY & VERDICT
// ==============================================================================
console.log('\n==========================================================================');
console.log(`   CHALLENGER 1 SUMMARY: ${passedTests} PASSED, ${failedTests} FAILED out of ${totalTests} TESTS`);
console.log('==========================================================================\n');

if (failedTests > 0) {
  console.error(`>>> VERDICT: REJECT (${failedTests} tests failed) <<<`);
  console.error('Failure Details:', JSON.stringify(failureDetails, null, 2));
  process.exit(1);
} else {
  console.log('>>> VERDICT: CONFIRM_CORRECT (ALL ADVERSARIAL STRESS CHALLENGES EMPIRICALLY CONFIRMED) <<<');
  process.exit(0);
}
