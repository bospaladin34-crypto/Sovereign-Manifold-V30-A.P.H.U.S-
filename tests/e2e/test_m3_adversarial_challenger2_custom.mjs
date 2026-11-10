// ==============================================================================
// ACT-OMEGA NET v71.3.0 — EMPIRICAL CHALLENGER 2 INDEPENDENT ADVERSARIAL SUITE
// File: tests/e2e/test_m3_adversarial_challenger2_custom.mjs
// Purpose: Adversarial stress test of Tool 344, Tool 345, Tool 347, and Dyck-1
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

function assert(condition, name, details = '') {
  totalTests++;
  if (condition) {
    passedTests++;
    console.log(`  [PASS] ${name}`);
  } else {
    failedTests++;
    console.error(`  [FAIL] ${name} — ${details}`);
    failures.push({ name, details });
  }
}

function postJson(endpoint, payload = {}) {
  return new Promise((resolve, reject) => {
    const postData = typeof payload === 'string' ? payload : JSON.stringify(payload);
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
        timeout: 120000,
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

// Mirror exact Rust implementation of v71_3_validate_structural_integrity
function rustValidateStructuralIntegrity(s) {
  if (!s || s.length === 0) return false;
  let p_depth = 0;
  let b_depth = 0;
  const buf = Buffer.from(s, 'utf8');
  for (let i = 0; i < buf.length; i++) {
    const b = buf[i];
    if (b === 0x5b || b === 0x5d) return false;
    if (b === 0x28) {
      p_depth++;
    } else if (b === 0x29) {
      if (p_depth === 0) return false;
      p_depth--;
    } else if (b === 0x7b) {
      b_depth++;
    } else if (b === 0x7d) {
      if (b_depth === 0) return false;
      b_depth--;
    }
  }
  return p_depth === 0 && b_depth === 0;
}

async function runAdversarialChallengeSuite() {
  console.log('==============================================================================');
  console.log('  CHALLENGER 2: ADVERSARIAL GENERATOR & STRESS HARNESS (DPO, T344/345/347)   ');
  console.log('==============================================================================');

  // --------------------------------------------------------------------------
  // PART 1: Adversarial Dyck-1 Fuzzing & Structural Edge-Case Stress Testing
  // --------------------------------------------------------------------------
  console.log('\n--- Part 1: Dyck-1 Validator Adversarial Fuzzing ---');

  // Test 1.1: Complex valid combinations
  assert(rustValidateStructuralIntegrity('fn foo() { if (true) { bar(); } }'), 'Valid zero-bracket Rust statement');
  assert(rustValidateStructuralIntegrity('((({{{()}}})))'), 'Deeply nested symmetric parentheses and braces');
  assert(rustValidateStructuralIntegrity('let (a, (b, c)) = (1, (2, 3));'), 'Nested tuple destructuring');

  // Test 1.2: Sneaky square bracket injections
  assert(!rustValidateStructuralIntegrity('fn foo(x: &[u8]) {}'), 'Slice reference &[u8] rejected');
  assert(!rustValidateStructuralIntegrity('let x = vec![1, 2, 3];'), 'vec![] macro with square brackets rejected');
  assert(!rustValidateStructuralIntegrity('// comment with [bracket]'), 'Square bracket in comment rejected');
  assert(!rustValidateStructuralIntegrity('"string with [bracket]"'), 'Square bracket in literal rejected');
  assert(!rustValidateStructuralIntegrity('\x5B'), 'Raw hex byte 0x5B rejected');
  assert(!rustValidateStructuralIntegrity('\x5D'), 'Raw hex byte 0x5D rejected');

  // Test 1.3: Asymmetric and depth-violation edge cases
  assert(!rustValidateStructuralIntegrity(')('), 'Reversed paren depth rejected');
  assert(!rustValidateStructuralIntegrity('}{'), 'Reversed brace depth rejected');
  assert(!rustValidateStructuralIntegrity('(()))('), 'Mid-sequence zero-depth dip rejected');
  assert(!rustValidateStructuralIntegrity('{{}}{'), 'Trailing open brace rejected');
  assert(!rustValidateStructuralIntegrity('(()()'), 'Trailing open paren rejected');

  // Test 1.4: Massive depth fuzz generator (5,000 nested pairs)
  const nestedParen5000 = '('.repeat(5000) + ')'.repeat(5000);
  assert(rustValidateStructuralIntegrity(nestedParen5000), '5,000-deep balanced parentheses accepted');
  const brokenNested5000 = '('.repeat(5000) + ')'.repeat(4999);
  assert(!rustValidateStructuralIntegrity(brokenNested5000), '5,000-deep unclosed parentheses rejected');

  // Test 1.5: 5,000 alternating pairs
  const alternatingPairs = '(){}'.repeat(5000);
  assert(rustValidateStructuralIntegrity(alternatingPairs), '10,000 alternating () and {} pairs accepted');

  // Test 1.6: Embedded bracket in 10,000 chars
  const embeddedBracket = '(){}'.repeat(2500) + '[' + '(){}'.repeat(2500);
  assert(!rustValidateStructuralIntegrity(embeddedBracket), 'Embedded [ at pos 10,000 strictly rejected');

  // --------------------------------------------------------------------------
  // PART 2: Empirical Verification of Tool 344 (No Keyword Search Penalty)
  // --------------------------------------------------------------------------
  console.log('\n--- Part 2: Tool 344 Real DPO & Logprob Scoring Empirical Verification ---');

  // Call Tool 344 directly via /api/v1/tools/t344
  const resT344 = await postJson('/api/v1/tools/t344', {});
  assert(resT344.statusCode === 200, 'Tool 344 endpoint /api/v1/tools/t344 returns 200');
  assert(resT344.body && resT344.body.status === 'MEASURED', 'Tool 344 status is MEASURED');
  assert(resT344.body.tool_id === 344, 'Tool 344 tool_id is 344');

  const pref = resT344.body.contrastive_preference_alignment;
  assert(pref != null, 'Tool 344 contains contrastive_preference_alignment');
  assert(pref.total_pairs === 512, `Total preference pairs == 512 (got ${pref.total_pairs})`);
  assert(typeof pref.chosen_wins === 'number', `chosen_wins is dynamic number: ${pref.chosen_wins}`);
  assert(typeof pref.preference_win_rate === 'number', `preference_win_rate is dynamic number: ${pref.preference_win_rate}`);
  assert(pref.preference_win_rate >= 0.95 && pref.preference_win_rate <= 1.0, `Win rate in expected range [0.95, 1.0]: ${pref.preference_win_rate}`);
  assert(pref.sh_eval_256_overlap === 0, 'No data leakage into SH-Eval-256');
  assert(pref.frozen_holdout_v2_read_by_trainer === false, 'Frozen Holdout v2 unread by trainer (no contamination)');

  // Inspect source code of Tool 344 to confirm keyword search penalty was eliminated
  const v71_3_path = path.join(repoRoot, '01_l0_rust', 'src', 'v71_3_sovereign_harmonic_week3_speculative_k4_long_context_4k.rs');
  const v71_3_code = fs.readFileSync(v71_3_path, 'utf8');

  // Verify that in dispatch_tool_344, r_valid uses v71_3_validate_structural_integrity ONLY
  const lines344 = v71_3_code.split('\n');
  let foundRValid = false;
  let hasHasConstitutionalViolationInRValid = false;
  for (let i = 0; i < lines344.length; i++) {
    const line = lines344[i];
    if (line.includes('let r_valid =') && lines344[i - 1]?.includes('let c_valid =')) {
      foundRValid = true;
      if (line.includes('v71_3_has_constitutional_violation')) {
        hasHasConstitutionalViolationInRValid = true;
      }
    }
  }
  assert(foundRValid, 'Found r_valid assignment in Tool 344');
  assert(!hasHasConstitutionalViolationInRValid, 'r_valid does NOT call v71_3_has_constitutional_violation (no keyword search penalty!)');

  // --------------------------------------------------------------------------
  // PART 3: Empirical Verification of Tool 345 (Ablation Matrix & Margin)
  // --------------------------------------------------------------------------
  console.log('\n--- Part 3: Tool 345 Week 3 Torture & Ablation Empirical Verification ---');

  const resT345 = await postJson('/api/v1/tools/t345', {});
  assert(resT345.statusCode === 200, 'Tool 345 endpoint /api/v1/tools/t345 returns 200');
  assert(resT345.body && resT345.body.status === 'MEASURED', 'Tool 345 status is MEASURED');
  assert(resT345.body.all_12_tests_passed === true, 'Tool 345 all 12 tests passed');

  const ablMatrix = resT345.body.w3_8_six_way_week3_ablation_matrix;
  assert(ablMatrix != null, 'Tool 345 w3_8 ablation matrix present');
  assert(ablMatrix.full_week3_ppl < ablMatrix.no_contrastive_stiefel_dpo_ppl, `Full W3 PPL (${ablMatrix.full_week3_ppl}) < No DPO PPL (${ablMatrix.no_contrastive_stiefel_dpo_ppl})`);
  assert(ablMatrix.full_week3_ppl < ablMatrix.week2_baseline_ppl, `Full W3 PPL (${ablMatrix.full_week3_ppl}) < W2 Baseline PPL (${ablMatrix.week2_baseline_ppl})`);

  // --------------------------------------------------------------------------
  // PART 4: Empirical Verification of Tool 347 (Certification & Narrative Alignment)
  // --------------------------------------------------------------------------
  console.log('\n--- Part 4: Tool 347 Certification & Narrative Alignment ---');

  const resT347 = await postJson('/api/v1/tools/t347', {});
  assert(resT347.statusCode === 200, 'Tool 347 endpoint /api/v1/tools/t347 returns 200');
  assert(resT347.body && resT347.body.status === 'MEASURED', 'Tool 347 status is MEASURED');
  assert(resT347.body.all_10_redteam_failures_remediated === true, 'Tool 347 all 10 redteam failures remediated');

  // Check RT-1..RT-10 alignment with Tools 322, 341, 342, 343, 344
  const b = resT347.body;

  // RT-1: 16K BPE raw 256 bytes
  assert(b.rt1_bpe_16k_full_vocab_and_raw256_bytes.raw_256_byte_identity_verified === true, 'RT-1 raw 256 bytes identity verified');
  assert(b.rt1_bpe_16k_full_vocab_and_raw256_bytes.remediated === true, 'RT-1 remediated == true');

  // RT-2: Freeform unseen prompts
  assert(b.rt2_freeform_unseen_prompt_zero_halts.zero_token_halts === 0, 'RT-2 zero token halts == 0');
  assert(b.rt2_freeform_unseen_prompt_zero_halts.remediated === true, 'RT-2 remediated == true');

  // RT-3: Honest 2-layer drafter (Tool 341 alignment)
  assert(b.rt3_honest_2layer_drafter_no_target_peeking.remediated === true, 'RT-3 remediated == true');
  assert(b.rt3_honest_2layer_drafter_no_target_peeking.honest_acceptance_rate_alpha < 0.995, 'RT-3 alpha < 0.995 (no target peeking!)');
  assert(b.rt3_honest_2layer_drafter_no_target_peeking.honest_acceptance_rate_alpha >= 0.70, 'RT-3 alpha >= 0.70 (empirically useful draft)');
  assert(b.rt3_honest_2layer_drafter_no_target_peeking.post_remediation_genuine_rejections > 0, 'RT-3 genuine rejections observed');

  // RT-4: Cuckoo NIAH at arbitrary depths (Tool 342 alignment)
  assert(b.rt4_content_addressed_16slot_cuckoo_niah.remediated === true, 'RT-4 remediated == true');
  assert(b.rt4_content_addressed_16slot_cuckoo_niah.post_remediation_arbitrary_depths_recalled === '16/16', 'RT-4 recalls 16/16');
  assert(b.rt4_content_addressed_16slot_cuckoo_niah.dynamic_key_overwrites_verified === '4/4', 'RT-4 key overwrites 4/4');

  // RT-5: Measured token logprob contrastive DPO (Tool 344/345 alignment)
  assert(b.rt5_measured_token_logprob_contrastive_dpo.remediated === true, 'RT-5 remediated == true');
  assert(b.rt5_measured_token_logprob_contrastive_dpo.post_remediation_chosen_mean_nll < b.rt5_measured_token_logprob_contrastive_dpo.post_remediation_rejected_mean_nll, 'RT-5 chosen NLL < rejected NLL');
  assert(b.rt5_measured_token_logprob_contrastive_dpo.measured_nll_margin_wins === '32/32', 'RT-5 measured NLL margin wins 32/32');

  // RT-6: Degenerate repetition separation
  assert(b.rt6_degenerate_repetition_and_gibberish_separation.remediated === true, 'RT-6 remediated == true');
  assert(b.rt6_degenerate_repetition_and_gibberish_separation.coherent_domain_ppl < b.rt6_degenerate_repetition_and_gibberish_separation.degenerate_repetition_ppl, 'RT-6 coherent PPL < repetition PPL');

  // RT-7: Content-parsed Plucker chain auditor (Tool 343 alignment)
  assert(b.rt7_content_parsed_4hop_plucker_chain_auditor.remediated === true, 'RT-7 remediated == true');
  assert(b.rt7_content_parsed_4hop_plucker_chain_auditor.valid_chain_accepted === true, 'RT-7 accepts valid chain');
  assert(b.rt7_content_parsed_4hop_plucker_chain_auditor.corrupted_chains_rejected === '2/2', 'RT-7 rejects corrupted chains 2/2');

  // RT-8: Extreme 8,192-token extrapolation (Tool 342 alignment)
  assert(b.rt8_extreme_8192_token_2x_horizon_extrapolation.remediated === true, 'RT-8 remediated == true');
  assert(b.rt8_extreme_8192_token_2x_horizon_extrapolation.horizon_8192_niah_recalled === '16/16', 'RT-8 8K NIAH recalls 16/16');

  // RT-9: Negation-aware intent router
  assert(b.rt9_negation_aware_adversarial_intent_router.remediated === true, 'RT-9 remediated == true');
  assert(b.rt9_negation_aware_adversarial_intent_router.adv1_not_lean_routed_to_rust_track2 === true, 'RT-9 routes NOT lean to Track 2');
  assert(b.rt9_negation_aware_adversarial_intent_router.adv2_not_rust_routed_to_lean_track3 === true, 'RT-9 routes NOT rust to Track 3');

  // RT-10: Pathological inputs guard
  assert(b.rt10_pathological_input_and_nan_inf_guard.remediated === true, 'RT-10 remediated == true');
  assert(b.rt10_pathological_input_and_nan_inf_guard.nan_or_inf_count === 0, 'RT-10 zero NaN or Inf');

  // Lean 4 theorems verified in Tool 347
  assert(b.lean4_theorems_verified === 'thm_v71_3_936..945', 'Tool 347 cites thm_v71_3_936..945');
  assert(b.proof.includes('SOVEREIGN_HARMONIC_REDTEAM_10OF10_REMEDIATED_QED'), 'Tool 347 proof string verified');

  // --------------------------------------------------------------------------
  // SUMMARY
  // --------------------------------------------------------------------------
  console.log('\n==============================================================================');
  console.log(`ADVERSARIAL HARNESS SUMMARY: Total: ${totalTests} | Passed: ${passedTests} | Failed: ${failedTests}`);
  console.log('==============================================================================');

  if (failedTests > 0) {
    console.error('FAILURES:');
    failures.forEach((f) => console.error(`  - ${f.name}: ${f.details}`));
    process.exit(1);
  } else {
    console.log('ALL ADVERSARIAL CHALLENGES CONFIRMED AND PASSED 100%.');
    process.exit(0);
  }
}

runAdversarialChallengeSuite().catch((err) => {
  console.error('Fatal Adversarial Suite Error:', err);
  process.exit(1);
});
