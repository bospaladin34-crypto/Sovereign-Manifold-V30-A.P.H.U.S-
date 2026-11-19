// 01_l0_rust/tests/muse_v73_remediation_tests.rs
// Unit, Perturbation & Negative-Case Verification Suite for Muse v73.2.1 (D2, D3, C2, E3, E4, E5, E7)

use act_omega_l0_core::v71_2_sovereign_harmonic_week2_chinchilla_16k_bpe_leech::v71_2_dispatch_tool_339_week2_7test_torture_gauntlet;
use act_omega_l0_core::v71_3_sovereign_harmonic_week3_speculative_k4_long_context_4k::v71_3_dispatch_tool_341_k4_speculative_cascade;
use act_omega_l0_core::v71_4_sovereign_harmonic_week4_rlvf_tree_speculative_sae_eval256::{
    v71_4_run_tool_351_core,
    v71_4_run_tool_352_core,
    v71_4_verify_candidate_formal_reward_custom,
};
use act_omega_l0_core::v72_2_sh_xi_sparse_moe_chatml_sft_and_rag::{
    v72_2_contains_seed_prefix_artifact,
    v72_2_converse_execute_full_with_params,
    v72_2_eval_tool_368_subjson_gates,
    v72_2_evaluate_converse_output_quality_gate,
    v72_2_validate_json_object_fsm,
};
use act_omega_l0_core::v73_1_nov12_15_research_kernels::{
    v73_1_dispatch_tool_385_volk_sheaf,
    v73_1_dispatch_tool_389_disco_spec,
    v73_1_dispatch_tool_391_directkv_ubep,
    v73_1_dispatch_tool_392_flash_so2,
};

fn ensure_repo_root_cwd() {
    if std::path::Path::new("C:\\sovereign_manifold_v31\\00_control").exists() {
        let _ = std::env::set_current_dir("C:\\sovereign_manifold_v31");
    }
}

#[test]
fn test_d2_answer_seeding_detection_and_pure_neural_converse() {
    ensure_repo_root_cwd();
    // Negative test: seeded prefix templates from e9804bf MUST be detected and flagged
    assert!(v72_2_contains_seed_prefix_artifact(
        "At 40% battery: Edge-1 Pixel 10 lowers sampling duty cycle."
    ));
    assert!(v72_2_contains_seed_prefix_artifact(
        "Registered session codename `OMEGA-7` for multi-turn verification."
    ));
    assert!(v72_2_contains_seed_prefix_artifact(
        "```rust\npub fn compute_burst_l0(xs: &Vec<u64>) -> u64 { xs.iter().fold(0u64, |a, b| a.saturating_mul(*b)) }\n```"
    ));

    // Positive test: live converse emits 0 injected seed tokens and contains zero hardcoded prefixes
    let out = v72_2_converse_execute_full_with_params(
        "Compute 17 * 23 + 19 and explain in 3 bullet points.",
        None,
        Some("test_d2_session"),
        &Vec::new(),
        true,
        Some(16),
        Some(0.0),
    );
    assert!(!v72_2_contains_seed_prefix_artifact(&out.output_text));
}

#[test]
fn test_e4_converse_quality_gate_rejects_bad_or_truncated_output() {
    ensure_repo_root_cwd();
    // Negative 1: truncated 1-token output fails quality gate
    let (ok_trunc, reason_trunc) = v72_2_evaluate_converse_output_quality_gate(
        "the",
        1,
        1,
        4.25,
        0.15,
        false,
        false,
        false,
    );
    assert!(!ok_trunc, "Truncated <2 token output MUST fail E4 quality gate (got {})", reason_trunc);

    // Negative 2: repetitive token collapse fails quality gate
    let (ok_rep, _) = v72_2_evaluate_converse_output_quality_gate(
        "alpha alpha alpha alpha alpha alpha alpha alpha",
        8,
        1,
        4.25,
        0.15,
        false,
        false,
        false,
    );
    assert!(!ok_rep, "Repetitive token collapse MUST fail E4 quality gate");

    // Negative 3: JSON prompt returning non-JSON fails FSM gate
    let (ok_bad_json, _) = v72_2_evaluate_converse_output_quality_gate(
        "not valid json at all",
        12,
        6,
        4.25,
        0.15,
        true,
        false,
        false,
    );
    assert!(!ok_bad_json, "Invalid JSON for JSON-constrained prompt MUST fail E4 gate");

    // Negative 4: zero-bracket prompt returning square brackets fails gate
    let (ok_brack, _) = v72_2_evaluate_converse_output_quality_gate(
        "let arr = [1, 2, 3];",
        12,
        8,
        4.25,
        0.15,
        false,
        false,
        true,
    );
    assert!(!ok_brack, "Square bracket violation MUST fail E4 gate");

    // Live converse with max_tokens=1 MUST report UNMEASURED/OFFLINE
    let live_trunc = v72_2_converse_execute_full_with_params(
        "Explain the Leech lattice.",
        None,
        Some("test_e4_trunc"),
        &Vec::new(),
        true,
        Some(1),
        Some(0.0),
    );
    assert_eq!(live_trunc.status, "UNMEASURED/OFFLINE");
}

#[test]
fn test_e5_serde_json_gate_rejects_substring_spoofing() {
    ensure_repo_root_cwd();
    // Negative test: substring `"valid_json_parses":100` embedded inside a string field while actual count is 0 MUST fail
    let spoofed_t366 = r#"{"status":"MEASURED","note":"fake \"valid_json_parses\":100 \"malformed_json_outputs\":0","json_pushdown_fsm":{"valid_json_parses":0,"fuzz_logit_trials":100,"malformed_json_outputs":12}}"#;
    let valid_t365 = r#"{"status":"MEASURED"}"#;
    let valid_t367 = r#"{"status":"MEASURED","multi_turn_gauntlet":{"tasks_passed":8,"tasks_total":8},"ifeval_lite_64":{"prompts_passed":64,"prompts_total":64}}"#;
    let (t365_ok, t366_fsm_ok, t366_v100, _t367_ok) = v72_2_eval_tool_368_subjson_gates(valid_t365, spoofed_t366, valid_t367);
    assert!(t365_ok);
    assert!(!t366_fsm_ok, "Spoofed substring in t366 JSON MUST fail serde_json t366_fsm_ok!");
    assert!(!t366_v100, "Spoofed substring in t366 JSON MUST fail serde_json t366_v100!");

    // Positive test: genuine structured JSON passes
    let genuine_t366 = r#"{"status":"MEASURED","json_pushdown_fsm":{"valid_json_parses":100,"fuzz_logit_trials":100,"malformed_json_outputs":0}}"#;
    let (_, g6_ok, g6_v100, _) = v72_2_eval_tool_368_subjson_gates(valid_t365, genuine_t366, valid_t367);
    assert!(g6_ok && g6_v100);

    // Pushdown JSON FSM rejects malformed JSON
    let (fsm_bad, _, _, _) = v72_2_validate_json_object_fsm("{\"tool\":\"x\", unquoted}");
    assert!(!fsm_bad);
}

#[test]
fn test_e3_plucker_and_track_ab_reject_keyword_stuffing_and_missing_stack() {
    ensure_repo_root_cwd();
    // Negative 1: stack_opt = None MUST fail Plucker check (no bypass) unless valid custom bivector supplied
    let none_stack_res = v71_4_verify_candidate_formal_reward_custom(
        0,
        "Compute 240 * 8 = 1920",
        "Verified E8 root product: 240 * 8 = 1920 across 84480 neurons",
        false,
        None,
        None,
    );
    assert!(!none_stack_res.plucker_isotropic_ok, "stack_opt=None without custom bivector MUST NOT pass Plucker gate");
    assert_eq!(none_stack_res.total_reward, 0.0);

    // Negative 2: Non-isotropic Plucker bivector (3,5,7,2,4,6) -> 3*6 - 5*4 + 7*2 = 12 != 0 MUST fail
    let bad_biv_res = v71_4_verify_candidate_formal_reward_custom(
        0,
        "Compute 240 * 8 = 1920",
        "Verified E8 root product: 240 * 8 = 1920 across 84480 neurons",
        false,
        Some((3, 5, 7, 2, 4, 6)),
        None,
    );
    assert!(!bad_biv_res.plucker_isotropic_ok);
    assert_eq!(bad_biv_res.plucker_residual, 12);
    assert_eq!(bad_biv_res.total_reward, 0.0);

    // Negative 3: Track A keyword stuffing with wrong arithmetic (240 * 8 = 9999) MUST score 0.0 even with isotropic bivector (1,0,0,0,0,0)
    let wrong_math_track_a = v71_4_verify_candidate_formal_reward_custom(
        0,
        "Verify 240 * 8 = 1920 on E8 roots",
        "sovereign manifold neurons cachelines leech stiefel 240 * 8 = 9999",
        false,
        Some((1, 0, 0, 0, 0, 0)),
        None,
    );
    assert!(!wrong_math_track_a.lean4_qed_ok, "Wrong arithmetic in Track A MUST fail formal evaluator");
    assert_eq!(wrong_math_track_a.total_reward, 0.0);

    // Negative 4: Track B out-of-bounds neuron N99999 >= 84480 MUST fail formal address check
    let oob_track_b = v71_4_verify_candidate_formal_reward_custom(
        1,
        "Route Chair-44 column",
        "WHO: N99999 WHAT: S99 Chair-44 column #2500",
        false,
        Some((1, 0, 0, 0, 0, 0)),
        None,
    );
    assert!(!oob_track_b.lean4_qed_ok, "Out-of-range neuron/sector in Track B MUST fail formal address verifier");
    assert_eq!(oob_track_b.total_reward, 0.0);

    // Live Tool 351 custom non-isotropic bivector probe
    let t351_neg = v71_4_run_tool_351_core(r#"{"corrupt_bivector":true}"#);
    let v351: serde_json::Value = serde_json::from_str(&t351_neg.json).expect("valid json");
    assert_eq!(
        v351.get("custom_candidate_audit").and_then(|c| c.get("plucker_isotropic_ok")).and_then(|b| b.as_bool()),
        Some(false)
    );
}

#[test]
fn test_c2_and_e10_corrupt_speculative_acceptance_fails_kl_gate() {
    ensure_repo_root_cwd();
    // Negative test on Tool 352 (C2): accepting mismatched drafter tokens without rejection MUST exceed kl_bound_tau and fail
    let t352_bad = v71_4_run_tool_352_core(r#"{"corrupt_accept_without_rejection":true}"#);
    assert!(!t352_bad.tree_speculative_certified, "Un-rejected mismatched drafter MUST fail tree_speculative_certified");
    let v352: serde_json::Value = serde_json::from_str(&t352_bad.json).expect("valid t352 json");
    let emp_kl = v352
        .get("empirical_output_kl")
        .and_then(|v| v.as_f64())
        .unwrap_or(0.0);
    let tau = v352
        .get("kl_bound_tau")
        .and_then(|v| v.as_f64())
        .unwrap_or(0.06);
    assert!(emp_kl > tau, "Corrupted drafter empirical_output_kl ({}) MUST exceed kl_bound_tau ({})", emp_kl, tau);

    // Negative test on Tool 341 (E10)
    let t341_bad_str = v71_3_dispatch_tool_341_k4_speculative_cascade(r#"{"corrupt_accept_without_rejection":true}"#);
    let v341: serde_json::Value = serde_json::from_str(&t341_bad_str).expect("valid t341 json");
    assert_eq!(
        v341.get("speculative_cascade").and_then(|o| o.get("zero_distribution_drift_verified")).and_then(|b| b.as_bool()),
        Some(false)
    );
}

#[test]
fn test_d3_active_d_perturbation_changes_d64_cell_loss() {
    ensure_repo_root_cwd();
    let base_json = v71_2_dispatch_tool_339_week2_7test_torture_gauntlet("{}");
    let pert_json = v71_2_dispatch_tool_339_week2_7test_torture_gauntlet(r#"{"d64_seed_samples_override":8}"#);
    let vb: serde_json::Value = serde_json::from_str(&base_json).expect("valid base t339");
    let vp: serde_json::Value = serde_json::from_str(&pert_json).expect("valid pert t339");
    let ppl_base = vb.get("w2_8_six_way_ablation_matrix").and_then(|o| o.get("d64_seed_only_ppl")).and_then(|v| v.as_f64()).unwrap_or(0.0);
    let ppl_pert = vp.get("w2_8_six_way_ablation_matrix").and_then(|o| o.get("d64_seed_only_ppl")).and_then(|v| v.as_f64()).unwrap_or(0.0);
    assert!(
        (ppl_base - ppl_pert).abs() > 1e-4,
        "Perturbing active_d on Cell 6 MUST change d64_seed_only_ppl ({} vs {})",
        ppl_base,
        ppl_pert
    );
}

#[test]
fn test_e7_research_kernels_report_self_test_and_fail_on_bad_inputs() {
    ensure_repo_root_cwd();
    let t385_def: serde_json::Value = serde_json::from_str(&v73_1_dispatch_tool_385_volk_sheaf("{}")).unwrap();
    assert_eq!(t385_def.get("status").and_then(|s| s.as_str()), Some("SELF_TEST"));

    let t385_bad: serde_json::Value = serde_json::from_str(&v73_1_dispatch_tool_385_volk_sheaf(r#"{"cell_a":99}"#)).unwrap();
    assert_eq!(t385_bad.get("ok").and_then(|b| b.as_bool()), Some(false));

    let t389_bad: serde_json::Value = serde_json::from_str(&v73_1_dispatch_tool_389_disco_spec(r#"{"token_id":-5}"#)).unwrap();
    assert_eq!(t389_bad.get("ok").and_then(|b| b.as_bool()), Some(false));

    let t391_bad: serde_json::Value = serde_json::from_str(&v73_1_dispatch_tool_391_directkv_ubep(r#"{"corrupt_test":true}"#)).unwrap();
    assert_eq!(t391_bad.get("ok").and_then(|b| b.as_bool()), Some(false));

    let t392_bad: serde_json::Value = serde_json::from_str(&v73_1_dispatch_tool_392_flash_so2(r#"{"ozaki_s":4000001}"#)).unwrap();
    assert_eq!(t392_bad.get("ok").and_then(|b| b.as_bool()), Some(false));
}
