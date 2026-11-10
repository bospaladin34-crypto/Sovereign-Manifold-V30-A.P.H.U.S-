// ==============================================================================
// ACT-OMEGA NET v71.3.0 — PHASE III / MILESTONE 3: CHALLENGER 2 EMPIRICAL HARNESS
// Focus: Tool 344/345 Real DPO Preference Scoring, Dyck-1 Structural Validator,
// Tool 347 Narrative & Certification Alignment, Zero Square Brackets Invariant
// File: C:\sovereign_manifold_v31\tests\e2e\test_m3_challenger2_empirical_harness.mjs
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

// Replicate Rust v71_3_validate_structural_integrity algorithm
function validateStructuralIntegrity(s) {
  if (!s || s.length === 0) return false;
  let pDepth = 0;
  let bDepth = 0;
  const buf = Buffer.from(s, 'utf8');
  for (let i = 0; i < buf.length; i++) {
    const b = buf[i];
    if (b === 0x5b || b === 0x5d) return false; // '[' or ']'
    if (b === 0x28) {
      // '('
      pDepth++;
    } else if (b === 0x29) {
      // ')'
      if (pDepth === 0) return false;
      pDepth--;
    } else if (b === 0x7b) {
      // '{'
      bDepth++;
    } else if (b === 0x7d) {
      // '}'
      if (bDepth === 0) return false;
      bDepth--;
    }
  }
  return pDepth === 0 && bDepth === 0;
}

async function runEmpiricalHarness() {
  console.log('==========================================================================');
  console.log('   PHASE III / MILESTONE 3: CHALLENGER 2 EMPIRICAL ADVERSARIAL HARNESS    ');
  console.log('==========================================================================');

  // ----------------------------------------------------------------------------
  // SECTION 1: Dyck-1 Structural Validator & Zero-Bracket Adversarial Probe
  // ----------------------------------------------------------------------------
  console.log('\n--- Section 1: Dyck-1 Structural Validator Adversarial Test Suite ---');

  // 1.1 Empty String
  assert(!validateStructuralIntegrity(''), 'Dyck-1: Empty string rejected');
  assert(!validateStructuralIntegrity(null), 'Dyck-1: Null rejected');

  // 1.2 Unbalanced parentheses
  assert(!validateStructuralIntegrity('('), 'Dyck-1: Single open paren "(" rejected');
  assert(!validateStructuralIntegrity(')'), 'Dyck-1: Single close paren ")" rejected');
  assert(!validateStructuralIntegrity(')('), 'Dyck-1: Reversed paren ")(" rejected');
  assert(!validateStructuralIntegrity('(()'), 'Dyck-1: Unclosed open "(()" rejected');
  assert(!validateStructuralIntegrity('())'), 'Dyck-1: Unmatched close "())" rejected');
  assert(!validateStructuralIntegrity('(()))'), 'Dyck-1: Multi unbalanced close "(()))" rejected');
  assert(!validateStructuralIntegrity('((()'), 'Dyck-1: Multi unclosed open "((()" rejected');

  // 1.3 Balanced parentheses
  assert(validateStructuralIntegrity('()'), 'Dyck-1: Simple balanced "()" accepted');
  assert(validateStructuralIntegrity('(())'), 'Dyck-1: Nested balanced "(())" accepted');
  assert(validateStructuralIntegrity('()()()'), 'Dyck-1: Sequential balanced "()()()" accepted');
  assert(validateStructuralIntegrity('(()())'), 'Dyck-1: Compound balanced "(()())" accepted');
  assert(validateStructuralIntegrity('((())())'), 'Dyck-1: Deeply compound balanced "((())())" accepted');

  // 1.4 Braces support
  assert(validateStructuralIntegrity('{}'), 'Dyck-1: Simple balanced "{}" accepted');
  assert(validateStructuralIntegrity('{{}}'), 'Dyck-1: Nested balanced "{{}}" accepted');
  assert(!validateStructuralIntegrity('{'), 'Dyck-1: Single open brace "{" rejected');
  assert(!validateStructuralIntegrity('}'), 'Dyck-1: Single close brace "}" rejected');
  assert(!validateStructuralIntegrity('}{'), 'Dyck-1: Reversed brace "}{" rejected');
  assert(!validateStructuralIntegrity('{{}'), 'Dyck-1: Unclosed brace "{{}" rejected');
  assert(validateStructuralIntegrity('{()}'), 'Dyck-1: Balanced mixed "{()}" accepted');
  assert(validateStructuralIntegrity('({})'), 'Dyck-1: Balanced mixed "({})" accepted');

  // 1.5 Strict Square Bracket Ban (Constitutional Invariant #5)
  assert(!validateStructuralIntegrity('['), 'Dyck-1: Single open square bracket "[" rejected');
  assert(!validateStructuralIntegrity(']'), 'Dyck-1: Single close square bracket "]" rejected');
  assert(!validateStructuralIntegrity('[]'), 'Dyck-1: Balanced square brackets "[]" strictly rejected');
  assert(!validateStructuralIntegrity('[[]]'), 'Dyck-1: Nested square brackets "[[]]" strictly rejected');
  assert(!validateStructuralIntegrity('([0])'), 'Dyck-1: Square brackets in balanced parens "([0])" rejected');
  assert(!validateStructuralIntegrity('{[x]}'), 'Dyck-1: Square brackets in balanced braces "{[x]}" rejected');
  assert(!validateStructuralIntegrity('fn foo() { let arr = [1, 2, 3]; }'), 'Dyck-1: Rust code with array bracket rejected');
  assert(!validateStructuralIntegrity('slice[0..4]'), 'Dyck-1: Slice range indexing rejected');

  // 1.6 Real Code Samples
  assert(
    validateStructuralIntegrity('pub fn get_val(s: &str) -> Option<i32> { Some(42) }'),
    'Dyck-1: Zero-bracket Rust function signature accepted'
  );
  assert(
    !validateStructuralIntegrity('pub fn get_val(s: &str) -> Option<i32> { Some(42)'),
    'Dyck-1: Unclosed brace in function rejected'
  );
  assert(
    !validateStructuralIntegrity('pub fn get_val(s: &str -> Option<i32> { Some(42) }'),
    'Dyck-1: Unclosed paren in function rejected'
  );

  // 1.7 Stress: 2,000 deep parentheses
  const deepParenOk = '('.repeat(1000) + ')'.repeat(1000);
  assert(validateStructuralIntegrity(deepParenOk), 'Dyck-1: 1,000 deep balanced parens accepted');
  const deepParenBroken = '('.repeat(1000) + ')'.repeat(999);
  assert(!validateStructuralIntegrity(deepParenBroken), 'Dyck-1: 1,000 deep unclosed paren rejected');
  const deepParenWithBracket = '('.repeat(500) + '[' + ')'.repeat(500);
  assert(!validateStructuralIntegrity(deepParenWithBracket), 'Dyck-1: Bracket inside 1,000 parens rejected');

  // ----------------------------------------------------------------------------
  // SECTION 2: Source Code Invariants & Literal Auditing
  // ----------------------------------------------------------------------------
  console.log('\n--- Section 2: Zero Square Brackets & Hardcoded Literals Audit ---');

  const v71Files = [
    'v71_0_sovereign_harmonic_standalone_model.rs',
    'v71_1_sovereign_harmonic_week1_deep12l_bptt_eval256.rs',
    'v71_2_sovereign_harmonic_week2_chinchilla_16k_bpe_leech.rs',
    'v71_3_sovereign_harmonic_week3_speculative_k4_long_context_4k.rs',
    'v71_4_sovereign_harmonic_week4_rlvf_tree_speculative_sae_eval256.rs',
  ];

  for (const f of v71Files) {
    const fPath = path.join(repoRoot, '01_l0_rust', 'src', f);
    assert(fs.existsSync(fPath), `Source file exists: ${f}`);
    const content = fs.readFileSync(fPath, 'utf8');
    const bracketMatches = content.match(/[\[\]]/g);
    const count = bracketMatches ? bracketMatches.length : 0;
    assert(count === 0, `Zero Square Brackets Law in ${f}: ${count} brackets (must be 0)`);
  }

  // Inspect v71_3 for hardcoded win-rate / literal templates
  const v71_3_Path = path.join(
    repoRoot,
    '01_l0_rust',
    'src',
    'v71_3_sovereign_harmonic_week3_speculative_k4_long_context_4k.rs'
  );
  const v71_3_Content = fs.readFileSync(v71_3_Path, 'utf8');

  // Verify that preference_win_rate is computed dynamically rather than hardcoded in format string
  const hasHardcodedWinRateLiteral = v71_3_Content.includes('\\"preference_win_rate\\": 1.0000') ||
    v71_3_Content.includes('"preference_win_rate": 1.0000');
  assert(
    !hasHardcodedWinRateLiteral,
    'Tool 344: Elimination of hardcoded "preference_win_rate": 1.0000 in format template'
  );

  // Verify that chosen_wins is formatted via variable `{}`
  assert(
    v71_3_Content.includes('\\"chosen_wins\\":{},\\"preference_win_rate\\":{:.4}'),
    'Tool 344: chosen_wins and preference_win_rate formatted dynamically via live variables'
  );

  // Verify that Tool 344 quarantine marker 'NOTW' (0x4E4F5457) is present
  assert(
    v71_3_Content.includes('0x4E4F5457'),
    'Tool 344: Contrastive weights quarantined with NOTW magic per Item 12'
  );

  // ----------------------------------------------------------------------------
  // SECTION 3: Live API Probing & Verification (Tools 344, 345, 346, 347)
  // ----------------------------------------------------------------------------
  console.log('\n--- Section 3: Live API Endpoint Verification on Port 8097 ---');

  // 3.1 Tool 344: Contrastive Preference Trainer
  console.log('  Calling Tool 344 (/api/v1/sovereign_harmonic/week3/contrastive_stiefel_preference_trainer)...');
  const res344 = await postJson('/api/v1/sovereign_harmonic/week3/contrastive_stiefel_preference_trainer', {});
  assert(res344.statusCode === 200, 'Tool 344 HTTP 200 OK');
  assert(res344.body && res344.body.status === 'MEASURED', 'Tool 344 status is MEASURED');
  assert(res344.body.tool_id === 344, 'Tool 344 tool_id is 344');

  const pref344 = res344.body.contrastive_preference_alignment;
  assert(pref344 != null, 'Tool 344 has contrastive_preference_alignment');
  assert(pref344.total_pairs === 512, `Tool 344 total_pairs == 512 (got ${pref344.total_pairs})`);
  assert(typeof pref344.chosen_wins === 'number', `Tool 344 chosen_wins is numeric: ${pref344.chosen_wins}`);
  assert(typeof pref344.preference_win_rate === 'number', `Tool 344 preference_win_rate is numeric: ${pref344.preference_win_rate}`);
  assert(pref344.preference_win_rate > 0.0, `Tool 344 preference_win_rate > 0.0 (got ${pref344.preference_win_rate})`);
  assert(pref344.sh_eval_256_overlap === 0, 'Tool 344 zero overlap with SH-Eval-256');
  assert(pref344.frozen_holdout_v2_read_by_trainer === false, 'Tool 344 trainer did NOT read frozen holdout v2');
  assert(pref344.stiefel_max_ortho_residual < 1e-10, `Tool 344 Stiefel ortho residual < 1e-10 (${pref344.stiefel_max_ortho_residual})`);

  // Verify quarantined contrastive weight file on disk
  const contrastiveWeightPath = path.join(
    repoRoot,
    '00_control',
    'weights',
    'sovereign_harmonic_week3_contrastive_weights.sh4z'
  );
  assert(fs.existsSync(contrastiveWeightPath), 'Quarantined contrastive weight file exists on disk');
  const weightBuf = fs.readFileSync(contrastiveWeightPath);
  assert(weightBuf.length === 65568, `Quarantined weight file size is 65,568 B (got ${weightBuf.length})`);
  const magicMarker = weightBuf.readUInt32LE(12);
  assert(magicMarker === 0x4e4f5457, `Quarantine magic header at offset 12 is 'NOTW' (0x4E4F5457)`);

  // 3.2 Tool 345: Week 3 Torture & Ablation Gauntlet
  console.log('  Calling Tool 345 (/api/v1/sovereign_harmonic/week3/torture_and_ablation_gauntlet)...');
  const res345 = await postJson('/api/v1/sovereign_harmonic/week3/torture_and_ablation_gauntlet', {});
  assert(res345.statusCode === 200, 'Tool 345 HTTP 200 OK');
  assert(res345.body && res345.body.status === 'MEASURED', 'Tool 345 status is MEASURED');
  assert(res345.body.all_12_tests_passed === true, 'Tool 345 all 12 tests passed');

  const abl345 = res345.body.w3_8_six_way_week3_ablation_matrix;
  assert(abl345 != null, 'Tool 345 has w3_8_six_way_week3_ablation_matrix');
  assert(
    abl345.full_week3_ppl < abl345.no_contrastive_stiefel_dpo_ppl,
    `Real DPO preference margin improvement verified: FullW3 (${abl345.full_week3_ppl}) < NoDPO (${abl345.no_contrastive_stiefel_dpo_ppl})`
  );
  assert(
    abl345.full_week3_ppl < abl345.week2_baseline_ppl,
    `Week 3 strictly outperforms Week 2: FullW3 (${abl345.full_week3_ppl}) < W2Base (${abl345.week2_baseline_ppl})`
  );

  // 3.3 Tool 346: Week 3 Master Certification
  console.log('  Calling Tool 346 (/api/v1/sovereign_harmonic/week3/master_certification)...');
  const res346 = await postJson('/api/v1/sovereign_harmonic/week3/master_certification', {});
  assert(res346.statusCode === 200, 'Tool 346 HTTP 200 OK');
  assert(res346.body && res346.body.status === 'MEASURED', 'Tool 346 status is MEASURED');
  assert(res346.body.gates.all_week3_gates_passed === true, 'Tool 346 all week 3 gates passed');
  assert(res346.body.gates.g4_contrastive_stiefel_512_preference_verified === true, 'Tool 346 Gate 4 (DPO Preference) verified');
  assert(res346.body.gates.g6_hard_gate_0_frozen_v2_32_verified === true, 'Tool 346 Gate 6 (Hard Gate 0) verified');

  // 3.4 Tool 347: Red-Team Diagnostic & Remediation Gauntlet
  console.log('  Calling Tool 347 (/api/v1/sovereign_harmonic/week3/redteam_diagnostic_and_remediation)...');
  const res347 = await postJson('/api/v1/sovereign_harmonic/week3/redteam_diagnostic_and_remediation', {});
  assert(res347.statusCode === 200, 'Tool 347 HTTP 200 OK');
  assert(res347.body && res347.body.status === 'MEASURED', 'Tool 347 status is MEASURED');
  assert(res347.body.all_10_redteam_failures_remediated === true, 'Tool 347 all 10 redteam failures remediated');

  // Alignment verification: RT-1 through RT-10
  const b347 = res347.body;
  assert(b347.rt1_bpe_16k_full_vocab_and_raw256_bytes.raw_256_byte_identity_verified === true, 'Tool 347 RT-1: 256 raw bytes roundtrip identity');
  assert(b347.rt2_freeform_unseen_prompt_zero_halts.zero_token_halts === 0, 'Tool 347 RT-2: Zero dead-end halts on unseen prompts');
  assert(
    b347.rt3_honest_2layer_drafter_no_target_peeking.honest_acceptance_rate_alpha < 0.995 &&
      b347.rt3_honest_2layer_drafter_no_target_peeking.honest_acceptance_rate_alpha >= 0.70,
    `Tool 347 RT-3: Honest drafter alpha < 0.995 and >= 0.70 (${b347.rt3_honest_2layer_drafter_no_target_peeking.honest_acceptance_rate_alpha})`
  );
  assert(
    b347.rt3_honest_2layer_drafter_no_target_peeking.post_remediation_genuine_rejections > 0,
    `Tool 347 RT-3: Genuine drafter rejections detected (${b347.rt3_honest_2layer_drafter_no_target_peeking.post_remediation_genuine_rejections})`
  );
  assert(
    b347.rt4_content_addressed_16slot_cuckoo_niah.post_remediation_arbitrary_depths_recalled === '16/16',
    'Tool 347 RT-4: Cuckoo NIAH recalls 16/16 at arbitrary depths'
  );
  assert(
    b347.rt4_content_addressed_16slot_cuckoo_niah.dynamic_key_overwrites_verified === '4/4',
    'Tool 347 RT-4: Cuckoo NIAH key overwrites 4/4 verified'
  );
  assert(
    b347.rt5_measured_token_logprob_contrastive_dpo.post_remediation_chosen_mean_nll <
      b347.rt5_measured_token_logprob_contrastive_dpo.post_remediation_rejected_mean_nll,
    `Tool 347 RT-5: Chosen mean NLL (${b347.rt5_measured_token_logprob_contrastive_dpo.post_remediation_chosen_mean_nll}) < Rejected mean NLL (${b347.rt5_measured_token_logprob_contrastive_dpo.post_remediation_rejected_mean_nll})`
  );
  assert(
    b347.rt5_measured_token_logprob_contrastive_dpo.measured_nll_margin_wins === '32/32',
    'Tool 347 RT-5: Real token logprob contrastive DPO margin wins 32/32'
  );
  assert(
    b347.rt6_degenerate_repetition_and_gibberish_separation.coherent_domain_ppl <
      b347.rt6_degenerate_repetition_and_gibberish_separation.degenerate_repetition_ppl,
    'Tool 347 RT-6: Coherent PPL strictly separates from repetition loop'
  );
  assert(
    b347.rt7_content_parsed_4hop_plucker_chain_auditor.valid_chain_accepted === true &&
      b347.rt7_content_parsed_4hop_plucker_chain_auditor.corrupted_chains_rejected === '2/2',
    'Tool 347 RT-7: Content-parsed Plucker chain auditor accepts valid & rejects corrupted 2/2'
  );
  assert(
    b347.rt8_extreme_8192_token_2x_horizon_extrapolation.horizon_8192_niah_recalled === '16/16',
    'Tool 347 RT-8: 8,192-token extreme extrapolation recalls 16/16'
  );
  assert(
    b347.rt9_negation_aware_adversarial_intent_router.adv1_not_lean_routed_to_rust_track2 === true &&
      b347.rt9_negation_aware_adversarial_intent_router.adv2_not_rust_routed_to_lean_track3 === true,
    'Tool 347 RT-9: Negation-aware adversarial prompts routed correctly to Track 2 and Track 3'
  );
  assert(
    b347.rt10_pathological_input_and_nan_inf_guard.nan_or_inf_count === 0,
    'Tool 347 RT-10: Pathological inputs produce zero NaN or Inf'
  );

  // ----------------------------------------------------------------------------
  // SECTION 4: Dispatch Alias Routes vs Canonical Endpoints Audit
  // ----------------------------------------------------------------------------
  console.log('\n--- Section 4: Dispatch Alias vs Canonical Routes Audit ---');

  const alias1 = await postJson('/api/v1/sovereign_harmonic/week3/dpo_preference_scoring', {});
  const alias2 = await postJson('/api/v1/sovereign_harmonic/week3/dpo_certification', {});
  const alias3 = await postJson('/api/v1/sovereign_harmonic/week3/certification', {});

  assert(alias1.statusCode === 200, 'Alias /dpo_preference_scoring returns HTTP 200');
  assert(alias2.statusCode === 200, 'Alias /dpo_certification returns HTTP 200');
  assert(alias3.statusCode === 200, 'Alias /certification returns HTTP 200');

  console.log(`  [NOTE] Alias /dpo_preference_scoring returned status: ${alias1.body.status} (canonical: /contrastive_stiefel_preference_trainer -> Tool 344)`);
  console.log(`  [NOTE] Alias /dpo_certification returned status: ${alias2.body.status} (canonical: /torture_and_ablation_gauntlet -> Tool 345)`);
  console.log(`  [NOTE] Alias /certification returned status: ${alias3.body.status} (canonical: /redteam_diagnostic_and_remediation -> Tool 347)`);

  // ----------------------------------------------------------------------------
  // SUMMARY
  // ----------------------------------------------------------------------------
  console.log('\n==========================================================================');
  console.log(`HARNESS RESULTS: Total: ${totalTests} | Passed: ${passedTests} | Failed: ${failedTests}`);
  console.log('==========================================================================');

  if (failedTests > 0) {
    console.error('FAILURES:');
    failures.forEach((f) => console.error(`  - ${f.testName}: ${f.details}`));
    process.exit(1);
  } else {
    console.log('ALL EMPIRICAL TESTS PASSED WITH 100% SUCCESS.');
    process.exit(0);
  }
}

runEmpiricalHarness().catch((err) => {
  console.error('Fatal Harness Error:', err);
  process.exit(1);
});
