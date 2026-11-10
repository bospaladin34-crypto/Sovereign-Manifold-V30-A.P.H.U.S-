// ==============================================================================
// ACT-OMEGA NET v71.3.2 — MILESTONE 3 ITERATION 2: CHALLENGER 1 EMPIRICAL HARNESS
// Empirical Correctness Verification of Speculative Cascade (Tool 341),
// Non-Tautological Plücker Bivector Gate (Tool 343), Cuckoo NIAH (Tool 342 & RT-4/8),
// and Zero Square Brackets Invariant across all v71_*.rs files.
// File: tests/e2e/test_m3_it2_challenger1_empirical_harness.mjs
// ==============================================================================

import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { fileURLToPath } from 'node:url';

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

function postJson(endpoint, payload = {}) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(payload);
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: 8097,
        path: endpoint,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
        },
        timeout: 90000,
      },
      (res) => {
        let raw = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => (raw += chunk));
        res.on('end', () => {
          try {
            resolve({ statusCode: res.statusCode, body: JSON.parse(raw), raw });
          } catch (e) {
            resolve({ statusCode: res.statusCode, body: null, raw, parseError: e.message });
          }
        });
      }
    );
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error(`Timeout on ${endpoint}`));
    });
    req.write(postData);
    req.end();
  });
}

async function runEmpiricalChallenge() {
  console.log('==============================================================================');
  console.log('ACT-OMEGA NET v71.3.2 — EMPIRICAL CHALLENGE HARNESS (r5_m3_it2_challenger_1)');
  console.log('==============================================================================\n');

  // ============================================================================
  // SECTION 1: Zero Square Brackets Invariant across all v71_*.rs files
  // ============================================================================
  console.log('--- SECTION 1: Zero Square Brackets Audit across v71_*.rs ---');
  const srcDir = path.join(repoRoot, '01_l0_rust', 'src');
  const files = fs.readdirSync(srcDir).filter(f => f.startsWith('v71_') && f.endsWith('.rs'));

  assert(files.length === 5, 'Discovered exactly 5 v71_*.rs files', `Found: ${files.length} (${files.join(', ')})`);

  let totalBracketCount = 0;
  for (const f of files) {
    const fullPath = path.join(srcDir, f);
    const content = fs.readFileSync(fullPath);
    let fileBrackets = 0;
    for (let i = 0; i < content.length; i++) {
      if (content[i] === 0x5b || content[i] === 0x5d) {
        fileBrackets++;
      }
    }
    totalBracketCount += fileBrackets;
    assert(fileBrackets === 0, `Zero square brackets in ${f}`, `Found ${fileBrackets} square brackets`);
  }
  assert(totalBracketCount === 0, 'Total square brackets across all v71_*.rs is strictly 0', `Total = ${totalBracketCount}`);

  // ============================================================================
  // SECTION 2: Tool 341 Speculative Cascade Parameter Sweep k in {0, 1, 2, 4, 8, 16}
  // ============================================================================
  console.log('\n--- SECTION 2: Tool 341 Speculative Cascade Parameter Sweep ---');
  const kSweep = [0, 1, 2, 4, 8, 16];
  const sweepResults = [];

  for (const k of kSweep) {
    console.log(`\nEvaluating k = ${k}...`);
    const t0 = Date.now();
    const res = await postJson('/api/v1/tools/t341', { k, max_tokens: 64 });
    const wallMs = Date.now() - t0;

    assert(res.statusCode === 200, `Tool 341 HTTP 200 for k=${k}`, `Status: ${res.statusCode}`);
    assert(res.body && res.body.status === 'MEASURED', `Tool 341 status == MEASURED for k=${k}`, `Status: ${res.body?.status}`);

    const cascade = res.body.speculative_cascade;
    assert(cascade !== undefined, `Tool 341 returns speculative_cascade object for k=${k}`);

    const expectedK = Math.min(Math.max(k === 0 ? 1 : k, 1), 8); // clamped [1, 8]
    assert(cascade.lookahead_k === expectedK, `Tool 341 clamps/sets lookahead_k correctly for k=${k} -> ${expectedK}`, `Got ${cascade.lookahead_k}`);

    // Verify wall-clock measurement in microseconds
    assert(res.body.measurement_latency_us > 0, `Tool 341 measurement_latency_us > 0 for k=${k}`, `Latency = ${res.body.measurement_latency_us} us`);
    assert(cascade.serial_target_latency_us > 0, `Tool 341 serial_target_latency_us > 0 for k=${k}`, `Serial = ${cascade.serial_target_latency_us} us`);
    assert(cascade.speculative_cascade_latency_us > 0, `Tool 341 speculative_cascade_latency_us > 0 for k=${k}`, `Spec = ${cascade.speculative_cascade_latency_us} us`);

    // Verify speedup factor calculation
    assert(cascade.measured_speedup_factor >= 1.05, `Tool 341 measured_speedup_factor >= 1.05 for k=${k}`, `Speedup = ${cascade.measured_speedup_factor}`);

    // Verify acceptance rate and tokens per verifier step
    assert(cascade.acceptance_rate_alpha > 0.0 && cascade.acceptance_rate_alpha <= 1.0, `Tool 341 acceptance_rate_alpha in (0, 1] for k=${k}`, `Alpha = ${cascade.acceptance_rate_alpha}`);
    assert(cascade.mean_tokens_per_verifier_step >= 1.50, `Tool 341 mean_tokens_per_verifier_step >= 1.50 for k=${k}`, `Tokens/step = ${cascade.mean_tokens_per_verifier_step}`);

    // Verify KL divergence
    assert(cascade.exact_leviathan_kl_divergence === 0.0, `Tool 341 exact_leviathan_kl_divergence == 0.0 for k=${k}`, `KL = ${cascade.exact_leviathan_kl_divergence}`);

    sweepResults.push({
      k,
      reportedK: cascade.lookahead_k,
      latencyUs: res.body.measurement_latency_us,
      alpha: cascade.acceptance_rate_alpha,
      toksPerStep: cascade.mean_tokens_per_verifier_step,
      speedup: cascade.measured_speedup_factor,
      serialUs: cascade.serial_target_latency_us,
      specUs: cascade.speculative_cascade_latency_us,
      totalEmitted: cascade.total_emitted_tokens,
      wallMs,
    });
  }

  console.log('\nSpeculative Sweep Summary Table:');
  console.table(sweepResults);

  // ============================================================================
  // SECTION 3: 03_vault/connectome/sovereign_harmonic_speculative_decode.jsonl Validation
  // ============================================================================
  console.log('\n--- SECTION 3: Speculative Decode Ledger 24-Row Audit ---');
  const ledgerPath = path.join(repoRoot, '03_vault', 'connectome', 'sovereign_harmonic_speculative_decode.jsonl');
  assert(fs.existsSync(ledgerPath), 'sovereign_harmonic_speculative_decode.jsonl exists');

  const lines = fs.readFileSync(ledgerPath, 'utf8').trim().split('\n').filter(l => l.trim().length > 0);
  assert(lines.length === 24, `Ledger contains exactly 24 evaluation rows`, `Found ${lines.length} rows`);

  const kCounts = { 1: 0, 2: 0, 4: 0, 8: 0 };
  const acceptPcts = [];
  const totalUsList = [];

  for (let i = 0; i < lines.length; i++) {
    const row = JSON.parse(lines[i]);
    assert(row.draft_k !== undefined, `Row ${i + 1} has draft_k`);
    assert(row.gen_tokens === 64, `Row ${i + 1} gen_tokens == 64`);
    assert(row.outer_steps > 0, `Row ${i + 1} outer_steps > 0 (${row.outer_steps})`);
    assert(row.proposed > 0, `Row ${i + 1} proposed > 0 (${row.proposed})`);
    assert(row.accepted > 0 && row.accepted <= row.proposed, `Row ${i + 1} accepted <= proposed (${row.accepted}/${row.proposed})`);
    assert(row.accept_pct > 0 && row.accept_pct <= 100, `Row ${i + 1} accept_pct in (0, 100] (${row.accept_pct}%)`);
    assert(row.toks_per_step >= 1.5, `Row ${i + 1} toks_per_step >= 1.5 (${row.toks_per_step})`);
    assert(row.speedup_x >= 1.05, `Row ${i + 1} speedup_x >= 1.05 (${row.speedup_x}x)`);
    assert(row.total_us > 0, `Row ${i + 1} total_us > 0 (${row.total_us} us)`);

    if (kCounts[row.draft_k] !== undefined) {
      kCounts[row.draft_k]++;
    }
    acceptPcts.push(row.accept_pct);
    totalUsList.push(row.total_us);
  }

  assert(kCounts[1] === 6, 'k=1 has 6 rows in ledger', `Got ${kCounts[1]}`);
  assert(kCounts[2] === 6, 'k=2 has 6 rows in ledger', `Got ${kCounts[2]}`);
  assert(kCounts[4] === 6, 'k=4 has 6 rows in ledger', `Got ${kCounts[4]}`);
  assert(kCounts[8] === 6, 'k=8 has 6 rows in ledger', `Got ${kCounts[8]}`);

  // Verify non-identical genuine acceptance rates across rows
  const uniqueAcceptPcts = new Set(acceptPcts);
  assert(uniqueAcceptPcts.size > 1, 'Acceptance rates vary honestly across evaluation rows (not synthetic 100% clone)', `Unique values: ${uniqueAcceptPcts.size} (${Array.from(uniqueAcceptPcts).join(', ')}%)`);

  const minAccept = Math.min(...acceptPcts);
  const maxAccept = Math.max(...acceptPcts);
  const meanAccept = acceptPcts.reduce((a, b) => a + b, 0) / acceptPcts.length;
  console.log(`  Acceptance Rate Distribution: Min = ${minAccept}%, Max = ${maxAccept}%, Mean = ${meanAccept.toFixed(2)}%`);

  const minUs = Math.min(...totalUsList);
  const maxUs = Math.max(...totalUsList);
  const meanUs = totalUsList.reduce((a, b) => a + b, 0) / totalUsList.length;
  console.log(`  Wall-Clock Duration Distribution: Min = ${minUs} us, Max = ${maxUs} us, Mean = ${meanUs.toFixed(1)} us`);

  // ============================================================================
  // SECTION 4: Tool 343 Non-Tautological Plücker Bivector Gate
  // ============================================================================
  console.log('\n--- SECTION 4: Tool 343 Non-Tautological Plücker Gate Audit ---');
  const t343Res = await postJson('/api/v1/tools/t343', {});
  assert(t343Res.statusCode === 200, 'Tool 343 HTTP 200');
  assert(t343Res.body && t343Res.body.status === 'MEASURED', 'Tool 343 status == MEASURED');

  const pCot = t343Res.body.plucker_4hop_cot;
  assert(pCot !== undefined, 'Tool 343 returns plucker_4hop_cot object');
  assert(pCot.chains_evaluated === 64, 'Chains evaluated == 64');
  assert(pCot.valid_chains_incident === '64/64', 'Valid chains incident == 64/64');
  assert(pCot.total_klein_quadric_residual === 0, 'Total Klein quadric residual == 0');
  assert(pCot.hallucinated_non_incident_chains_rejected === '64/64', 'Hallucinated non-incident chains rejected == 64/64');
  assert(pCot.hallucination_rejection_rate === 1.0, 'Hallucination rejection rate == 1.0000');

  // Verify SQNR > 90.0 dB parsed from synthesized_4hop_cot
  const cotTrace = pCot.synthesized_4hop_cot;
  console.log(`  Synthesized CoT trace: ${cotTrace}`);
  const sqnrMatch = cotTrace.match(/SQNR=([\d.]+)dB/);
  assert(sqnrMatch !== null, 'CoT trace contains measured SQNR figure');
  if (sqnrMatch) {
    const sqnrVal = parseFloat(sqnrMatch[1]);
    assert(sqnrVal > 90.0, `SQNR (${sqnrVal} dB) strictly exceeds 90.0 dB threshold`, `Measured: ${sqnrVal} dB`);
  }

  // Verify orthogonality residual
  const orthoMatch = cotTrace.match(/\|\|W\^T W - I_32\|\|_F=([^\s)]+)/);
  assert(orthoMatch !== null, 'CoT trace contains Frobenius orthogonality residual');
  if (orthoMatch) {
    const orthoVal = parseFloat(orthoMatch[1]);
    assert(orthoVal < 1e-12, `Orthogonality residual (${orthoVal}) < 1e-12`, `Measured: ${orthoVal}`);
  }

  // Source code inspection for non-tautological dynamic computation
  const v71_3_path = path.join(srcDir, 'v71_3_sovereign_harmonic_week3_speculative_k4_long_context_4k.rs');
  const v71_3_content = fs.readFileSync(v71_3_path, 'utf8');

  assert(!v71_3_content.includes('bad_p01 = 5'), 'Source does NOT contain hardcoded bad_p01 = 5');
  assert(!v71_3_content.includes('bad_p23 = 3'), 'Source does NOT contain hardcoded bad_p23 = 3');
  assert(v71_3_content.includes('bad_p01 = w0 * w1 + 1'), 'Source computes bad_p01 dynamically from byte stream (w0 * w1 + 1)');
  assert(v71_3_content.includes('bad_p23 = z2 * z3 + 1'), 'Source computes bad_p23 dynamically from byte stream (z2 * z3 + 1)');
  assert(v71_3_content.includes('w_energy / q_err.max(1e-12)'), 'SQNR is calculated dynamically via 16-bit quantization energy/error ratio');

  // Dynamic perturbation test
  const t343Perturbed = await postJson('/api/v1/tools/t343', {
    prompt: 'Adversarial query testing whether seed hash alters neuron routing and Plucker chain sampling'
  });
  assert(t343Perturbed.statusCode === 200, 'Tool 343 handles perturbed prompt with HTTP 200');
  const pTracePerturbed = t343Perturbed.body?.plucker_4hop_cot?.synthesized_4hop_cot;
  assert(pTracePerturbed !== undefined, 'Perturbed prompt returns valid synthesized CoT trace');
  assert(pTracePerturbed !== cotTrace, 'Perturbed prompt routes through different neuron/column', `New trace: ${pTracePerturbed}`);

  // ============================================================================
  // SECTION 5: Tool 342 Cuckoo NIAH Long-Context Retrieval
  // ============================================================================
  console.log('\n--- SECTION 5: Tool 342 Long-Context Recurrent Memory & NIAH Audit ---');
  const t342Res = await postJson('/api/v1/tools/t342', {});
  assert(t342Res.statusCode === 200, 'Tool 342 HTTP 200');
  assert(t342Res.body && t342Res.body.status === 'MEASURED', 'Tool 342 status == MEASURED');

  const o1Mem = t342Res.body.o1_recurrent_memory;
  assert(o1Mem !== undefined, 'Tool 342 returns o1_recurrent_memory');
  assert(o1Mem.horizon_tokens_stepped === 4096, 'Horizon tokens stepped == 4096');
  assert(o1Mem.basal_subternary_bytes === 64, 'Basal subternary bytes == 64');
  assert(o1Mem.apical_mamba3_12l_bytes === 384, 'Apical Mamba-3 bytes == 384');
  assert(o1Mem.total_recurrent_state_bytes === 448, 'Total recurrent state bytes == 448 (7 cachelines)');
  assert(o1Mem.l1d_cachelines_occupied === 7, 'Occupies exactly 7 L1D cachelines');
  assert(o1Mem.fp16_kv_cache_4096_bytes === 6291456, 'FP16 KV-cache equivalent == 6,291,456 B');
  assert(o1Mem.memory_compression_factor_x === 14043, 'Memory compression factor == 14,043x');
  assert(o1Mem.subternary_cubic_t3_eq_t_violations === 0, 'Subternary cubic violations == 0 (t^3 = t satisfied)');
  assert(o1Mem.rope_4096_max_symplectic_drift < 1e-12, 'RoPE symplectic drift < 1e-12');

  const niah4k = t342Res.body.needle_in_4096_haystack_gauntlet;
  assert(niah4k !== undefined, 'Tool 342 returns needle_in_4096_haystack_gauntlet');
  assert(niah4k.depths_tested === '256, 1024, 2048, 3072, 4096', 'Depths tested == 256, 1024, 2048, 3072, 4096');
  assert(niah4k.exact_recalls === '5/5', 'Exact recalls == 5/5 needles retrieved');
  assert(niah4k.recall_accuracy === 1.0, 'Recall accuracy == 1.0000');
  assert(niah4k.adversarial_64_distractor_flood_survived === true, 'Survived 64 adversarial distractor flood');

  // ============================================================================
  // SECTION 6: 8K Context & 16-Slot Cuckoo NIAH Extrapolation (RT-4 & RT-8 via Tool 347)
  // ============================================================================
  console.log('\n--- SECTION 6: 8K Context & 16-Slot Cuckoo NIAH Extrapolation (Tool 347) ---');
  const t347Res = await postJson('/api/v1/tools/t347', {});
  assert(t347Res.statusCode === 200, 'Tool 347 HTTP 200');
  assert(t347Res.body && t347Res.body.status === 'MEASURED', 'Tool 347 status == MEASURED');

  const rt4 = t347Res.body.rt4_content_addressed_16slot_cuckoo_niah;
  assert(rt4 !== undefined, 'Tool 347 returns rt4_content_addressed_16slot_cuckoo_niah');
  assert(rt4.post_remediation_arbitrary_depths_recalled === '16/16', 'RT-4 recalls 16/16 needles at arbitrary non-power-of-2 depths');
  assert(rt4.dynamic_key_overwrites_verified === '4/4', 'RT-4 dynamic key overwrites == 4/4 verified');
  assert(rt4.remediated === true, 'RT-4 remediated status == true');

  const rt8 = t347Res.body.rt8_extreme_8192_token_2x_horizon_extrapolation;
  assert(rt8 !== undefined, 'Tool 347 returns rt8_extreme_8192_token_2x_horizon_extrapolation');
  assert(rt8.horizon_8192_state_bytes === 448, 'RT-8 total recurrent state remains constant 448 bytes');
  assert(rt8.horizon_8192_niah_recalled === '16/16', 'RT-8 8,192-token context recalls 16/16 needles');
  assert(rt8.horizon_8192_compression_x === 28086, 'RT-8 8,192-token KV compression ratio == 28,086x');
  assert(rt8.horizon_8192_rope_drift < 1e-12, 'RT-8 RoPE max drift < 1e-12');
  assert(rt8.remediated === true, 'RT-8 remediated status == true');

  // ============================================================================
  // SUMMARY & VERDICT
  // ============================================================================
  console.log('\n==============================================================================');
  console.log(`TOTAL TESTS: ${totalTests}`);
  console.log(`PASSED: ${passedTests}`);
  console.log(`FAILED: ${failedTests}`);
  if (failedTests > 0) {
    console.log('FAILURES:');
    for (const f of failures) {
      console.log(`  - ${f.testName}: ${f.details}`);
    }
    console.log('\nVERDICT: FAIL');
    process.exit(1);
  } else {
    console.log('\nVERDICT: CONFIRM_CORRECT');
    console.log('==============================================================================');
    process.exit(0);
  }
}

runEmpiricalChallenge().catch((err) => {
  console.error('Unhandled harness exception:', err);
  process.exit(1);
});
