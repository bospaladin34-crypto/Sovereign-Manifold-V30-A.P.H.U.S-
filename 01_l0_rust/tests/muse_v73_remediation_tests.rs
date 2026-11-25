// 01_l0_rust/tests/muse_v73_remediation_tests.rs
// Unit, Perturbation & Negative-Case Verification Suite for Muse v73.2.1 (D2, D3, C2, E3, E4, E5, E7)

use act_omega_l0_core::{v61_escape_clean, v61_json_escape};
use act_omega_l0_core::v71_0_sovereign_harmonic_standalone_model::{
    v71_bpe_encode,
    v71_load_or_build_bpe_vocabulary,
    v71_load_sh4z_weights,
};
use act_omega_l0_core::v71_1_sovereign_harmonic_week1_deep12l_bptt_eval256::{
    v71_1_build_sh_eval_256_suite,
    v71_1_load_deep12l_stack_strict,
};
use act_omega_l0_core::v71_2_sovereign_harmonic_week2_chinchilla_16k_bpe_leech::{
    v71_2_dispatch_tool_339_week2_7test_torture_gauntlet,
    v71_2_load_16k_codebook_strict,
};
use act_omega_l0_core::v71_3_sovereign_harmonic_week3_speculative_k4_long_context_4k::{
    v71_3_dispatch_tool_341_k4_speculative_cascade,
    v71_3_evaluate_week3_sequence_cross_entropy,
};
use act_omega_l0_core::v71_4_sovereign_harmonic_week4_rlvf_tree_speculative_sae_eval256::{
    v71_4_run_tool_351_core,
    v71_4_run_tool_352_core,
    v71_4_verify_candidate_formal_reward_custom,
};
use act_omega_l0_core::v72_1_sh_xi_matryoshka_384_768_cuda_pretrainer::{
    v72_1_build_holdout_shingle_blacklist,
    v72_1_ensure_sealed_rw_eval_500,
    v72_1_run_canary_contamination_fixture,
    v72_1_sha256_hex,
    v72_1_try_load_verified_disk_corpus,
};
use act_omega_l0_core::v72_2_sh_xi_sparse_moe_chatml_sft_and_rag::{
    C_SH_XI_SESSION_COUNTERS_PATH,
    E_SH_XI_SESSION_COUNTERS_PATH,
    V72_2ChatTurn,
    v72_2_clear_session_history_for_test,
    v72_2_contains_seed_prefix_artifact,
    v72_2_converse_execute_full_with_params,
    v72_2_dispatch_converse_route,
    v72_2_dispatch_tool_363_shell2_cpu_ssd_sparse_moe_bank,
    v72_2_dispatch_tool_364_chatml_masked_sft_trainer,
    v72_2_dispatch_tool_365_igpu_grounded_rag_and_telemetry,
    v72_2_dispatch_tool_368_week2_chain368_master_certification,
    v72_2_eval_tool_368_subjson_gates,
    v72_2_evaluate_converse_output_quality_gate,
    v72_2_extract_word_5gram_shingles,
    v72_2_get_session_turns,
    v72_2_get_turn_counters_snapshot,
    v72_2_reload_turn_counters_from_disk_for_test,
    v72_2_seed_counters_from_historical_tool_361_at,
    v72_2_set_test_counter_paths_override,
    v72_2_validate_json_object_fsm,
};
use act_omega_l0_core::v73_1_nov12_15_research_kernels::{
    v73_1_constant_time_eq_hex_64,
    v73_1_dispatch_chain399_master_certification,
    v73_1_dispatch_tool_383_curvetq,
    v73_1_dispatch_tool_385_volk_sheaf,
    v73_1_dispatch_tool_389_disco_spec,
    v73_1_dispatch_tool_391_directkv_ubep,
    v73_1_dispatch_tool_392_flash_so2,
    v73_1_hmac_sha256_hex_lower,
    v73_1_load_operator_key_bytes,
    v73_1_verify_lean4_compiler_and_mirror,
    v73_1_verify_signed_lean_receipt_at,
};
use act_omega_l0_core::v73_2_cloudflare_vpc_mesh_and_pgwire_hyperdrive::{
    V73_2_HEALTH_ENDPOINT,
    V73_2_TELEMETRY_INGEST_ENDPOINT,
    count_live_lean_theorems_at_path,
    count_live_lean_theorems_canonical,
    v73_2_constant_time_compare_key,
    v73_2_count_live_lean_theorems,
    v73_2_dispatch_chain404_master_certification,
    v73_2_extract_apk_version_code,
    v73_2_has_query_key_param,
    v73_2_has_telemetry_write_query_param,
    v73_2_parse_d1_user_tables_from_receipt_str,
    v73_2_parse_sync_matrix_json,
    v73_2_percent_decode_ascii,
    v73_2_read_live_d1_database_name,
    v73_2_read_live_d1_user_tables,
    v73_2_read_live_ota_metadata,
    v73_2_read_live_release_version,
    v73_2_resolve_allowed_l0_cors_origin,
    v73_2_validate_telemetry_bounds,
    v73_2_verify_telemetry_or_operator_auth_with_keys,
    validate_live_lean_theorems_with_floor,
    validate_live_lean_threshold,
};

fn ensure_repo_root_cwd() {
    if std::path::Path::new("C:\\sovereign_manifold_v31\\00_control").exists() {
        let _ = std::env::set_current_dir("C:\\sovereign_manifold_v31");
    }
}

#[test]
fn test_d2_answer_seeding_detection_and_pure_neural_converse() {
    ensure_repo_root_cwd();
    let _rw_guard = RW_EVAL500_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_guard = SH_XI_TURN_COUNTER_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_reload_on_drop = ShXiTurnCounterReloadGuard::new("d2");
    let _rw_restore = guard_paths(&[
        "03_vault/connectome/sh_xi_rw_eval_500_sealed.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_rw_eval_500_sealed.jsonl",
    ]);
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
    let _rw_guard = RW_EVAL500_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_guard = SH_XI_TURN_COUNTER_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_reload_on_drop = ShXiTurnCounterReloadGuard::new("e4");
    let _rw_restore = guard_paths(&[
        "03_vault/connectome/sh_xi_rw_eval_500_sealed.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_rw_eval_500_sealed.jsonl",
    ]);
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

    // Negative 5 (M3 Item #7 E4): entropy >= 12.0, <= 0.05, or NaN MUST fail E4 gate
    for bad_ent in [12.0_f64, 14.5_f64, 0.05_f64, f64::NAN] {
        let (ok_ent, reason_ent) = v72_2_evaluate_converse_output_quality_gate(
            "Valid coherent neural output explaining E8 lattice sphere packing.",
            12,
            10,
            bad_ent,
            0.22,
            false,
            false,
            false,
        );
        assert!(
            !ok_ent,
            "Out-of-range/non-finite entropy ({}) MUST fail E4 gate (got {})",
            bad_ent,
            reason_ent
        );
    }

    // Positive (M3 Item #7 E4): valid entropy in (0.05, 12.0) passes
    let (ok_good_ent, reason_good_ent) = v72_2_evaluate_converse_output_quality_gate(
        "Valid coherent neural output explaining E8 lattice sphere packing.",
        12,
        10,
        4.2,
        0.22,
        false,
        false,
        false,
    );
    assert!(ok_good_ent, "Valid entropy 4.2 MUST pass E4 gate (got {})", reason_good_ent);

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

    // Negative test (M3 Item #7 E5): missing fuzz_logit_trials MUST fail closed (no unwrap_or(100) bypass)
    let missing_trials_t366 = r#"{"status":"MEASURED","json_pushdown_fsm":{"valid_json_parses":100,"malformed_json_outputs":0}}"#;
    let (_, m_ok, m_v100, _) = v72_2_eval_tool_368_subjson_gates(valid_t365, missing_trials_t366, valid_t367);
    assert!(!m_ok && !m_v100, "Missing fuzz_logit_trials MUST fail closed in E5 gate");

    // Negative test (M3 Item #7 E5): zero fuzz_logit_trials MUST fail closed
    let zero_trials_t366 = r#"{"status":"MEASURED","json_pushdown_fsm":{"valid_json_parses":100,"fuzz_logit_trials":0,"malformed_json_outputs":0}}"#;
    let (_, z_ok, z_v100, _) = v72_2_eval_tool_368_subjson_gates(valid_t365, zero_trials_t366, valid_t367);
    assert!(!z_ok && !z_v100, "Zero fuzz_logit_trials MUST fail closed in E5 gate");

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

static T341_KL_RECEIPT_GUARD: std::sync::Mutex<()> = std::sync::Mutex::new(());
static T339_ABLATION_GUARD: std::sync::Mutex<()> = std::sync::Mutex::new(());
static CURVETQ_RECEIPT_GUARD: std::sync::Mutex<()> = std::sync::Mutex::new(());
static LEAN_RECEIPT_GUARD: std::sync::Mutex<()> = std::sync::Mutex::new(());
static RW_EVAL500_GUARD: std::sync::Mutex<()> = std::sync::Mutex::new(());
static SH_XI_TURN_COUNTER_GUARD: std::sync::Mutex<()> = std::sync::Mutex::new(());

struct ShXiTurnCounterReloadGuard {
    tmp_dir: std::path::PathBuf,
    c_path: String,
    e_path: String,
}

impl ShXiTurnCounterReloadGuard {
    fn new(tag: &str) -> Self {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0);
        let tmp_dir = std::env::temp_dir().join(format!(
            "act_omega_sh_xi_counters_{}_{}_{}",
            tag,
            std::process::id(),
            nanos
        ));
        let _ = std::fs::remove_dir_all(&tmp_dir);
        std::fs::create_dir_all(&tmp_dir).expect("create isolated sh_xi counter test dir");
        let c_path = tmp_dir
            .join("c_sh_xi_session_turn_counters.json")
            .to_string_lossy()
            .to_string();
        let e_path = tmp_dir
            .join("e_sh_xi_session_turn_counters.json")
            .to_string_lossy()
            .to_string();
        v72_2_set_test_counter_paths_override(Some((c_path.clone(), e_path.clone())));
        v72_2_clear_session_history_for_test();
        Self {
            tmp_dir,
            c_path,
            e_path,
        }
    }
}

impl Drop for ShXiTurnCounterReloadGuard {
    fn drop(&mut self) {
        v72_2_set_test_counter_paths_override(None);
        v72_2_clear_session_history_for_test();
        let _ = std::fs::remove_dir_all(&self.tmp_dir);
    }
}

#[test]
fn test_c2_and_e10_corrupt_speculative_acceptance_fails_kl_gate() {
    ensure_repo_root_cwd();
    let _kl_guard = T341_KL_RECEIPT_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _kl_restore = guard_paths(&[
        "03_vault/connectome/sh_week4_tree_speculative_kl_receipt.json",
        "03_vault/connectome/sh_week3_k4_empirical_kl_receipt.json",
    ]);
    // Establish clean MEASURED canonical receipts on disk first
    let t352_clean = v71_4_run_tool_352_core("{}");
    assert!(t352_clean.tree_speculative_certified, "Clean Tool 352 run MUST certify");
    let t341_clean_str = v71_3_dispatch_tool_341_k4_speculative_cascade("{}");
    let v341_clean: serde_json::Value = serde_json::from_str(&t341_clean_str).expect("valid clean t341 json");
    assert_eq!(v341_clean.get("status").and_then(|s| s.as_str()), Some("MEASURED"));

    let w3_kl_before = std::fs::read_to_string("03_vault/connectome/sh_week3_k4_empirical_kl_receipt.json")
        .expect("sh_week3_k4_empirical_kl_receipt.json before negative tests");
    let w4_kl_before = std::fs::read_to_string("03_vault/connectome/sh_week4_tree_speculative_kl_receipt.json")
        .expect("sh_week4_tree_speculative_kl_receipt.json before negative tests");

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

    // Poisoned draft tree negative-injection check on Tool 352
    let t352_poison = v71_4_run_tool_352_core(r#"{"poison_draft_tree":true}"#);
    assert!(t352_poison.tree_speculative_certified);
    assert_eq!(t352_poison.poisoned_draft_nodes_accepted, 0);

    // Negative test on Tool 341 (E10)
    let t341_bad_str = v71_3_dispatch_tool_341_k4_speculative_cascade(r#"{"corrupt_accept_without_rejection":true}"#);
    let v341: serde_json::Value = serde_json::from_str(&t341_bad_str).expect("valid t341 json");
    assert_eq!(
        v341.get("speculative_cascade").and_then(|o| o.get("zero_distribution_drift_verified")).and_then(|b| b.as_bool()),
        Some(false)
    );

    // Regression invariant: negative KL fault-injection probes MUST NOT overwrite canonical KL receipts on disk
    let w3_kl_after = std::fs::read_to_string("03_vault/connectome/sh_week3_k4_empirical_kl_receipt.json")
        .expect("sh_week3_k4_empirical_kl_receipt.json after negative tests");
    let w4_kl_after = std::fs::read_to_string("03_vault/connectome/sh_week4_tree_speculative_kl_receipt.json")
        .expect("sh_week4_tree_speculative_kl_receipt.json after negative tests");
    assert_eq!(w3_kl_before, w3_kl_after, "Negative Tool 341 probe MUST NOT overwrite sh_week3_k4_empirical_kl_receipt.json");
    assert_eq!(w4_kl_before, w4_kl_after, "Negative Tool 352 probes MUST NOT overwrite sh_week4_tree_speculative_kl_receipt.json");

    let w3_json: serde_json::Value = serde_json::from_str(&w3_kl_after).expect("valid w3 kl receipt json");
    let w4_json: serde_json::Value = serde_json::from_str(&w4_kl_after).expect("valid w4 kl receipt json");
    assert_eq!(w3_json.get("status").and_then(|v| v.as_str()), Some("MEASURED"));
    assert_eq!(w3_json.get("corrupt_accept_without_rejection").and_then(|v| v.as_bool()), Some(false));
    assert_eq!(w4_json.get("status").and_then(|v| v.as_str()), Some("MEASURED"));
    assert_eq!(w4_json.get("corrupt_accept_without_rejection").and_then(|v| v.as_bool()), Some(false));
}

#[test]
fn test_d3_active_d_perturbation_changes_d64_cell_loss() {
    ensure_repo_root_cwd();
    let _abl_guard = T339_ABLATION_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _restore_guards = guard_paths(&[
        "03_vault/connectome/sh_week2_6way_ablation_receipt.json",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_week2_6way_ablation_receipt.json",
        "03_vault/receipts/v71_2_week2_torture_benchmark_receipt.json",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\v71_2_week2_torture_benchmark_receipt.json",
        "03_vault/connectome/sh_week2_curated_corpus.jsonl",
        "03_vault/connectome/sh_week2_curated_corpus.binshard",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_week2_curated_corpus.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\training_corpus\\sh_week2_curated_corpus.binshard",
    ]);
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

#[test]
fn test_m1_item11_cors_6_origin_allowlist_and_negative_origins() {
    let allowlist = [
        "https://act-omega-net.dev",
        "https://api.act-omega-net.dev",
        "https://mcp.act-omega-net.dev",
        "http://127.0.0.1:5173",
        "http://localhost:5173",
        "http://127.0.0.1:8097",
    ];
    for origin in allowlist {
        assert_eq!(
            v73_2_resolve_allowed_l0_cors_origin(origin),
            origin,
            "Allowlisted origin {} MUST resolve identically",
            origin
        );
    }
    assert_eq!(
        v73_2_resolve_allowed_l0_cors_origin("  https://act-omega-net.dev  "),
        "https://act-omega-net.dev"
    );

    let rejected = [
        "",
        "*",
        "null",
        "https://evil.example",
        "http://evil.example:5173",
        "https://act-omega-net.dev.evil.com",
        "http://localhost:8097",
        "https://127.0.0.1:8097",
    ];
    for bad in rejected {
        assert_eq!(
            v73_2_resolve_allowed_l0_cors_origin(bad),
            "",
            "Disallowed origin '{}' MUST resolve to empty string",
            bad
        );
    }
}

#[test]
fn test_m1_item9_sync_matrix_json_bounds_and_negative_rejections() {
    assert_eq!(
        v73_2_parse_sync_matrix_json(r#"{"pixel10_kops":12.5,"pixel8_kops":8.25}"#),
        Ok((Some(12.5), Some(8.25)))
    );
    assert_eq!(
        v73_2_parse_sync_matrix_json(r#"{"pixel10":0.0}"#),
        Ok((Some(0.0), None))
    );
    assert_eq!(
        v73_2_parse_sync_matrix_json(r#"{"pixel8":100000.0}"#),
        Ok((None, Some(100_000.0)))
    );

    let invalid_bodies = [
        "",
        "   ",
        "{bad_json",
        "[]",
        "123",
        "{}",
        r#"{"other":42}"#,
        r#"{"pixel10_kops":-0.01}"#,
        r#"{"pixel8_kops":-1.0}"#,
        r#"{"pixel10_kops":100000.01}"#,
        r#"{"pixel8_kops":999999}"#,
        r#"{"pixel10_kops":"12.5"}"#,
        r#"{"pixel8":null}"#,
        r#"{"pixel10_kops":true}"#,
        r#"{"pixel10_kops":1e500}"#,
        r#"{"pixel10_kops":12.5,"pixel8_kops":-5.0}"#,
    ];
    for bad in invalid_bodies {
        assert!(
            v73_2_parse_sync_matrix_json(bad).is_err(),
            "Invalid sync_matrix payload '{}' MUST be rejected",
            bad
        );
    }
}

#[test]
fn test_m1_item8_live_ota_metadata_and_source_invariants() {
    ensure_repo_root_cwd();
    let lean_cnt = v73_2_count_live_lean_theorems();
    assert!(lean_cnt >= 1010, "Live .lean theorem count {} must be >= 1010", lean_cnt);

    let meta = v73_2_read_live_ota_metadata();
    assert_ne!(meta.ota_version, "v61.0.0-sh4z-v6000");
    assert_ne!(meta.ota_version, "30.0.0");
    assert_ne!(meta.ota_version, "UNMEASURED/OFFLINE");
    assert!(meta.ota_version.starts_with("v73."), "Unexpected ota_version: {}", meta.ota_version);
    assert!(meta.tools_count >= 404, "tools_count {} must be >= 404", meta.tools_count);
    assert_eq!(meta.lean4_qed, lean_cnt);
    assert_eq!(meta.combined_shards, 84_480);
    assert_eq!(meta.total_synapses, 4_055_040);
    assert_eq!(meta.bijected_cachelines, 262_144);

    let bin_src = std::fs::read("01_l0_rust/src/bin/v31_swarm.rs").expect("bin/v31_swarm.rs");
    let lib_src = std::fs::read("01_l0_rust/src/v31_swarm.rs").expect("src/v31_swarm.rs");
    assert_eq!(bin_src, lib_src, "bin/v31_swarm.rs and src/v31_swarm.rs MUST remain 1:1 identical");

    let bin_str = String::from_utf8(bin_src).expect("utf8 bin/v31_swarm.rs");
    assert!(
        !bin_str.contains("Access-Control-Allow-Origin: *"),
        "Wildcard Access-Control-Allow-Origin: * MUST NOT exist in v31_swarm.rs"
    );
    assert!(
        !bin_str.contains("0.085).exp()"),
        "Proxy PPL formula 0.085).exp() MUST NOT exist in v31_swarm.rs"
    );
    assert!(
        !bin_str.contains("v61.0.0-sh4z-v6000"),
        "Stale v61.0.0-sh4z-v6000 literal MUST NOT exist in v31_swarm.rs"
    );

    let v73_2_str = std::fs::read_to_string(
        "01_l0_rust/src/v73_2_cloudflare_vpc_mesh_and_pgwire_hyperdrive.rs",
    )
    .expect("v73_2 source");
    assert!(
        !v73_2_str.contains('[') && !v73_2_str.contains(']'),
        "v73_2 module MUST have zero square brackets"
    );
}

#[test]
fn test_m2_item1_disk_corpus_guard_and_base_curve_meta_parity() {
    ensure_repo_root_cwd();
    let _rw_guard = RW_EVAL500_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_guard = SH_XI_TURN_COUNTER_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_reload_on_drop = ShXiTurnCounterReloadGuard::new("m2_item1");
    let _rw_restore = guard_paths(&[
        "03_vault/connectome/sh_xi_rw_eval_500_sealed.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_rw_eval_500_sealed.jsonl",
    ]);
    let (eval_items, eval_sha, _) = v72_1_ensure_sealed_rw_eval_500();
    let blacklist = v72_1_build_holdout_shingle_blacklist(&eval_items);
    let canary = v72_1_run_canary_contamination_fixture(&blacklist, &eval_items);

    // Positive: valid disk corpus and manifest pass SHA-256 + 13-gram zero-overlap guard
    let valid_loaded = v72_1_try_load_verified_disk_corpus(
        &blacklist,
        &eval_sha,
        &canary,
        std::time::Instant::now(),
    );
    let (docs, summary) = valid_loaded.expect("Verified disk corpus MUST load when manifest SHA matches");
    assert!(!docs.is_empty(), "Verified disk corpus must contain documents");
    assert_eq!(summary.surviving_overlap_shingles, 0);

    // Negative: mismatched eval_sha (simulating tampered/drifted manifest metadata) MUST be rejected
    let bad_sha = "0000000000000000000000000000000000000000000000000000000000000000";
    let rejected = v72_1_try_load_verified_disk_corpus(
        &blacklist,
        bad_sha,
        &canary,
        std::time::Instant::now(),
    );
    assert!(rejected.is_none(), "Mismatched SHA-256 metadata MUST reject disk corpus cache");

    // Verify sh_xi_week1_training_curve.csv schema & non-duplicated checkpoint rows
    let curve_csv = std::fs::read_to_string("03_vault/connectome/sh_xi_week1_training_curve.csv")
        .expect("sh_xi_week1_training_curve.csv");
    let lines: Vec<&str> = curve_csv.lines().filter(|l| !l.trim().is_empty()).collect();
    assert_eq!(
        lines.first().copied(),
        Some("step,lr,gamma_net2wider,val_nats_384d,val_nats_768d,val_bpb_384d,val_bpb_768d,checkpoint_kind")
    );
    assert!(
        lines.len() >= 13 && lines.len() <= 14,
        "Expected header + 12 or 13 rows (0 g=0, 0 g=1, 1000..10000, optional selected_best_checkpoint), got {}",
        lines.len()
    );
    let parse_row = |line: &str| -> (usize, f64, f64, f64, f64, f64, String) {
        let cols: Vec<&str> = line.split(',').collect();
        assert_eq!(cols.len(), 8, "Expected 8 CSV columns in {}", line);
        (
            cols[0].parse::<usize>().expect("step"),
            cols[2].parse::<f64>().expect("gamma"),
            cols[3].parse::<f64>().expect("val_nats_384d"),
            cols[4].parse::<f64>().expect("val_nats_768d"),
            cols[5].parse::<f64>().expect("val_bpb_384d"),
            cols[6].parse::<f64>().expect("val_bpb_768d"),
            cols[7].trim().to_string(),
        )
    };
    let parsed_rows: Vec<(usize, f64, f64, f64, f64, f64, String)> =
        lines.iter().skip(1).map(|l| parse_row(l)).collect();
    let r0_g0 = &parsed_rows[0];
    let r0_g1 = &parsed_rows[1];
    assert_eq!((r0_g0.0, r0_g0.6.as_str()), (0, "init_gated_gamma0"));
    assert_eq!((r0_g1.0, r0_g1.6.as_str()), (0, "init_ungated_gamma1"));
    assert!((r0_g0.1 - 0.0).abs() < 1e-6);
    assert!((r0_g1.1 - 1.0).abs() < 1e-6);
    assert!((r0_g1.3 - r0_g1.2).abs() > 1e-4, "Step 0 gamma=1.0 ungated 768D loss must differ from 384D");

    let live_rows: Vec<&(usize, f64, f64, f64, f64, f64, String)> = parsed_rows
        .iter()
        .filter(|r| r.6 == "live_step")
        .collect();
    assert!(live_rows.len() >= 9, "Expected at least 9 live_step rows, got {}", live_rows.len());
    for i in 0..live_rows.len() {
        for j in (i + 1)..live_rows.len() {
            let a = live_rows[i];
            let b = live_rows[j];
            let same_tuple = (a.2 - b.2).abs() < 1e-9
                && (a.3 - b.3).abs() < 1e-9
                && (a.4 - b.4).abs() < 1e-9
                && (a.5 - b.5).abs() < 1e-9;
            assert!(
                !same_tuple,
                "Duplicate live_step 4-metric tuple detected between step {} and step {}",
                a.0, b.0
            );
        }
    }

    // Verify sh_xi_base_train_meta.json fields & endpoint parity with curve CSV
    let meta_str = std::fs::read_to_string("00_control/weights/sh_xi_base_train_meta.json")
        .expect("sh_xi_base_train_meta.json");
    let meta: serde_json::Value = serde_json::from_str(&meta_str).expect("valid base train meta JSON");
    assert!(meta.get("val_eval_tokens").and_then(|v| v.as_u64()).unwrap_or(0) > 0);
    let f32_sci = meta.get("prob_sum_max_dev_f32_sci").and_then(|v| v.as_str()).unwrap_or("");
    assert!(!f32_sci.is_empty() && f32_sci.contains('e'), "prob_sum_max_dev_f32_sci must be scientific notation");
    assert_eq!(meta.get("corpus_sha256").and_then(|v| v.as_str()), Some(summary.corpus_sha256.as_str()));

    let sel_step = meta.get("selected_checkpoint_step").and_then(|v| v.as_u64()).expect("selected_checkpoint_step") as usize;
    let s10k_live_n768 = meta.get("step_10000_live_val_nats_768").and_then(|v| v.as_f64()).expect("step_10000_live_val_nats_768");
    let s10k_live_bpb768 = meta.get("step_10000_live_val_bpb_768").and_then(|v| v.as_f64()).expect("step_10000_live_val_bpb_768");
    assert!(s10k_live_n768.is_finite() && s10k_live_bpb768.is_finite());
    let sampling_note = meta.get("curve_sampling_note").and_then(|v| v.as_str()).unwrap_or("");
    assert!(!sampling_note.is_empty(), "curve_sampling_note must be non-empty");
    for req_key in [
        "phase_a_non_monotonic_rise_explanation",
        "shell0_step6000_freeze_mechanism",
        "phase_b_non_monotonic_rise_explanation",
    ] {
        let expl = meta.get(req_key).and_then(|v| v.as_str()).unwrap_or("");
        assert!(!expl.is_empty(), "{} must be non-empty in sh_xi_base_train_meta.json", req_key);
    }
    let grad_rec_path = meta.get("layer_grad_l2_norms_receipt").and_then(|v| v.as_str()).expect("layer_grad_l2_norms_receipt");
    assert_eq!(grad_rec_path, "03_vault/connectome/sh_xi_base_step_grad_norms_receipt.json");
    let grad_rec_str = std::fs::read_to_string(grad_rec_path).expect("sh_xi_base_step_grad_norms_receipt.json");
    let grad_rec: serde_json::Value = serde_json::from_str(&grad_rec_str).expect("valid grad receipt json");
    assert_eq!(grad_rec.get("sh4z_sha256").and_then(|v| v.as_str()), meta.get("sh4z_sha256").and_then(|v| v.as_str()));
    assert_eq!(grad_rec.get("corpus_sha256").and_then(|v| v.as_str()), meta.get("corpus_sha256").and_then(|v| v.as_str()));
    assert_eq!(
        grad_rec.get("layer_grad_l2_norms").and_then(|v| v.as_array()).map(|a| a.len()),
        Some(12)
    );

    let sel_row = parsed_rows
        .iter()
        .find(|r| r.6 == "selected_best_checkpoint")
        .expect("selected_best_checkpoint row");
    assert_eq!(sel_row.0, sel_step);
    let row_10000 = parsed_rows
        .iter()
        .find(|r| r.0 == 10000)
        .expect("step 10000 row");
    assert!((s10k_live_n768 - row_10000.3).abs() < 1e-6);
    assert!((s10k_live_bpb768 - row_10000.5).abs() < 1e-6);

    let m_init_b384 = meta.get("init_val_bpb_384").and_then(|v| v.as_f64()).expect("init_val_bpb_384");
    let m_init_b768_ug = meta.get("init_val_bpb_768_ungated_gamma1").and_then(|v| v.as_f64()).expect("init_val_bpb_768_ungated_gamma1");
    let m_fin_b384 = meta.get("final_val_bpb_384").and_then(|v| v.as_f64()).expect("final_val_bpb_384");
    let m_fin_b768 = meta.get("final_val_bpb_768").and_then(|v| v.as_f64()).expect("final_val_bpb_768");
    assert!((m_init_b384 - r0_g0.4).abs() < 1e-6);
    assert!((m_init_b768_ug - r0_g1.5).abs() < 1e-6);
    assert!((m_fin_b384 - sel_row.4).abs() < 1e-6);
    assert!((m_fin_b768 - sel_row.5).abs() < 1e-6);
}

#[test]
fn test_m2_item2_moe_per_step_curve_and_weights_manifest_provenance() {
    ensure_repo_root_cwd();
    let moe_csv = std::fs::read_to_string("03_vault/connectome/sh_xi_moe_training_curve.csv")
        .expect("sh_xi_moe_training_curve.csv");
    let lines: Vec<&str> = moe_csv.lines().filter(|l| !l.trim().is_empty()).collect();
    assert_eq!(
        lines.first().copied(),
        Some("step,lr_moe,lr_wout,train_mean_ce_nats,val_bpb_384d,val_bpb_768d,val_bpb_3shell,val_ppl_3shell,global_alpha_moe,eval_footing")
    );
    assert_eq!(lines.len(), 18, "Expected header + 17 rows (steps 0..=16)");

    for (idx, line) in lines.iter().skip(1).enumerate() {
        let cols: Vec<&str> = line.split(',').collect();
        assert_eq!(cols.len(), 10);
        let st = cols[0].parse::<usize>().expect("moe step");
        assert_eq!(st, idx);
        for c in &cols[1..9] {
            let v = c.parse::<f64>().expect("finite float");
            assert!(v.is_finite());
        }
        if idx < 16 {
            assert_eq!(cols[9].trim(), "per_step_pre_rebalance_alpha_0.30");
            assert!((cols[8].parse::<f64>().expect("alpha") - 0.30).abs() < 1e-4);
        } else {
            assert_eq!(cols[9].trim(), "post_rebalance_calibrated_alpha_eval");
        }
    }

    let last_cols: Vec<&str> = lines[17].split(',').collect();
    let s16_b384: f64 = last_cols[4].parse().expect("s16 val_bpb_384d");
    let s16_b768: f64 = last_cols[5].parse().expect("s16 val_bpb_768d");
    let s16_b3sh: f64 = last_cols[6].parse().expect("s16 val_bpb_3shell");
    let s16_ppl3: f64 = last_cols[7].parse().expect("s16 val_ppl_3shell");
    let s16_alpha: f64 = last_cols[8].parse().expect("s16 global_alpha_moe");

    let moe_meta_str = std::fs::read_to_string("00_control/weights/sh_xi_moe_train_meta.json")
        .expect("sh_xi_moe_train_meta.json");
    let moe_meta: serde_json::Value = serde_json::from_str(&moe_meta_str).expect("valid moe meta JSON");
    assert!((moe_meta.get("val_bpb_384d").and_then(|v| v.as_f64()).unwrap_or(0.0) - s16_b384).abs() < 1e-6);
    assert!((moe_meta.get("val_bpb_768d").and_then(|v| v.as_f64()).unwrap_or(0.0) - s16_b768).abs() < 1e-6);
    assert!((moe_meta.get("val_bpb_3shell").and_then(|v| v.as_f64()).unwrap_or(0.0) - s16_b3sh).abs() < 1e-6);
    assert!((moe_meta.get("val_ppl_3shell").and_then(|v| v.as_f64()).unwrap_or(0.0) - s16_ppl3).abs() < 1e-6);
    assert!((moe_meta.get("global_alpha_moe").and_then(|v| v.as_f64()).unwrap_or(0.0) - s16_alpha).abs() < 1e-4);
    assert!(!moe_meta.get("curve_footing_note").and_then(|v| v.as_str()).unwrap_or("").is_empty());
    assert!(!moe_meta.get("frozen_base_q8_0_eval_note").and_then(|v| v.as_str()).unwrap_or("").is_empty());
    assert!(
        !moe_meta
            .get("step16_jump_magnitude_explanation")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .is_empty(),
        "step16_jump_magnitude_explanation must be non-empty in sh_xi_moe_train_meta.json"
    );

    let man_str = std::fs::read_to_string("00_control/weights/sovereign_harmonic_weights_manifest.json")
        .expect("sovereign_harmonic_weights_manifest.json");
    let man: serde_json::Value = serde_json::from_str(&man_str).expect("valid manifest JSON");
    let arts = man.get("artifacts").and_then(|v| v.as_object()).expect("artifacts map");

    assert_eq!(
        arts.get("week3_contrastive")
            .and_then(|e| e.get("provenance"))
            .and_then(|p| p.get("status"))
            .and_then(|s| s.as_str()),
        Some("QUARANTINED_NON_WEIGHT_LOOKUP")
    );
    for tok_key in ["sh_xi_bpe16k", "sh_week2_ast_bpe_16k_codebook", "week2_codebook"] {
        assert_eq!(
            arts.get(tok_key)
                .and_then(|e| e.get("provenance"))
                .and_then(|p| p.get("status"))
                .and_then(|s| s.as_str()),
            Some("DETERMINISTIC_TOKENIZER_OR_CODEBOOK"),
            "{} must be DETERMINISTIC_TOKENIZER_OR_CODEBOOK",
            tok_key
        );
    }
    for hist_key in ["deep12l_weights", "e8z_lattice", "npage_neurons", "sh_ix_base", "spage_synapses", "week4_rlvf_sae"] {
        assert_eq!(
            arts.get(hist_key)
                .and_then(|e| e.get("provenance"))
                .and_then(|p| p.get("status"))
                .and_then(|s| s.as_str()),
            Some("UNMEASURED_HISTORICAL_CHECKPOINT"),
            "{} must be UNMEASURED_HISTORICAL_CHECKPOINT",
            hist_key
        );
    }
    let drafter = arts.get("tree_drafter_2l").and_then(|e| e.get("provenance")).expect("tree_drafter_2l provenance");
    assert_eq!(drafter.get("status").and_then(|s| s.as_str()), Some("MEASURED_REPRODUCIBLE"));
    assert!(drafter.get("seed").and_then(|s| s.as_str()).is_some());
    assert_eq!(drafter.get("trained_steps").and_then(|v| v.as_u64()), Some(160));
    assert!(drafter.get("loss_curve_csv").and_then(|s| s.as_str()).is_some());
}

#[test]
fn test_m2_item3_week3_ablation_flags_and_7stage_ledger_distinctness() {
    ensure_repo_root_cwd();
    let vocab = v71_load_or_build_bpe_vocabulary(false);
    let weights = v71_load_sh4z_weights(&vocab).expect("sh4z weights");
    let stack = v71_1_load_deep12l_stack_strict().expect("deep12l stack");
    let cb_16k = v71_2_load_16k_codebook_strict().expect("16k codebook");
    let npage_bytes = std::fs::read("00_control/weights/neurons_v6900_84480.npage").expect("npage");
    let spage_bytes = std::fs::read("00_control/weights/synapses_v6900_2703360.spage").expect("spage");
    let eval_suite = v71_1_build_sh_eval_256_suite();
    let item = &eval_suite[0];
    let toks_v71 = v71_bpe_encode(&vocab, &item.full_text);

    let (nll_none, cnt_none, _, _) = v71_3_evaluate_week3_sequence_cross_entropy(
        &weights, &stack, &cb_16k, &npage_bytes, &spage_bytes, &toks_v71, &item.full_text, item.track_id,
        false, false, false, false,
    );
    let (nll_dpo, _, _, _) = v71_3_evaluate_week3_sequence_cross_entropy(
        &weights, &stack, &cb_16k, &npage_bytes, &spage_bytes, &toks_v71, &item.full_text, item.track_id,
        true, false, false, false,
    );
    let (nll_yarn, _, _, _) = v71_3_evaluate_week3_sequence_cross_entropy(
        &weights, &stack, &cb_16k, &npage_bytes, &spage_bytes, &toks_v71, &item.full_text, item.track_id,
        false, true, false, false,
    );
    let (nll_full, cnt_full, _, _) = v71_3_evaluate_week3_sequence_cross_entropy(
        &weights, &stack, &cb_16k, &npage_bytes, &spage_bytes, &toks_v71, &item.full_text, item.track_id,
        true, true, true, true,
    );
    assert!(cnt_none > 0 && cnt_full == cnt_none);
    assert!((nll_none - nll_dpo).abs() > 1e-6, "DPO flag must alter NLL");
    assert!((nll_none - nll_yarn).abs() > 1e-6, "YaRN flag must alter NLL");
    assert!((nll_none - nll_full).abs() > 1e-6, "All-off vs all-on flags must produce distinct NLL");

    let ledger_csv = std::fs::read_to_string("03_vault/connectome/sh_week4_7stage_ablation_ledger.csv")
        .expect("sh_week4_7stage_ablation_ledger.csv");
    let rows: Vec<&str> = ledger_csv.lines().filter(|l| !l.trim().is_empty()).collect();
    assert_eq!(rows.len(), 8, "Expected header + 7 stages (0..6)");

    let s4_cols: Vec<&str> = rows[5].split(',').collect();
    let s5_cols: Vec<&str> = rows[6].split(',').collect();
    let s4_tok_step: f64 = s4_cols[8].parse().expect("stage4 speculative_tok_per_step");
    let s5_tok_step: f64 = s5_cols[8].parse().expect("stage5 speculative_tok_per_step");
    assert!(s4_tok_step > 1.0 && s5_tok_step > 1.0, "Stage 4 ({}) and Stage 5 ({}) tok/step must be > 1.0", s4_tok_step, s5_tok_step);
    assert!((s4_tok_step - s5_tok_step).abs() > 1e-4, "Stage 4 and Stage 5 tok/step must be distinct");

    let receipt_str = std::fs::read_to_string("03_vault/connectome/sh_week4_7stage_ablation_receipt.json")
        .expect("sh_week4_7stage_ablation_receipt.json");
    let rec: serde_json::Value = serde_json::from_str(&receipt_str).expect("valid 7stage receipt JSON");
    let stages = rec.get("stages").expect("stages");
    let get_stage_metrics = |key: &str| -> (f64, f64, f64) {
        let st = stages.get(key).expect(key);
        (
            st.get("eval256_nll").and_then(|v| v.as_f64()).expect("eval256_nll"),
            st.get("eval256_ppl").and_then(|v| v.as_f64()).expect("eval256_ppl"),
            st.get("holdout_v2_ppl").and_then(|v| v.as_f64()).expect("holdout_v2_ppl"),
        )
    };
    let m3 = get_stage_metrics("stage3");
    let m4 = get_stage_metrics("stage4");
    let m5 = get_stage_metrics("stage5");
    let m6 = get_stage_metrics("stage6");
    let pairs = [(m3, m4), (m3, m5), (m3, m6), (m4, m5), (m4, m6), (m5, m6)];
    for (a, b) in pairs {
        assert!((a.0 - b.0).abs() > 1e-3, "Stages 3..6 eval256_nll must all be distinct ({} vs {})", a.0, b.0);
        assert!((a.1 - b.1).abs() > 1e-4, "Stages 3..6 eval256_ppl must all be distinct ({} vs {})", a.1, b.1);
        assert!((a.2 - b.2).abs() > 1e-4, "Stages 3..6 holdout_v2_ppl must all be distinct ({} vs {})", a.2, b.2);
    }
}

#[test]
fn test_m2_item4_sft_5gram_shingles_and_determinism_receipt() {
    ensure_repo_root_cwd();
    // Positive tests: /[^a-z0-9_]+/ splitting & lowercase normalization
    let sh_5 = v72_2_extract_word_5gram_shingles("foo(bar) baz_1 qux quux");
    assert_eq!(sh_5.len(), 1, "5 words split by /[^a-z0-9_]+/ must yield 1 5-gram shingle");
    let sh_5_upper = v72_2_extract_word_5gram_shingles("FOO(Bar) BAZ_1 qux QUUX");
    assert_eq!(sh_5, sh_5_upper, "Shingles must normalize ASCII case");

    let sh_6 = v72_2_extract_word_5gram_shingles("foo(bar) baz_1 qux-2 quux");
    assert_eq!(sh_6.len(), 2, "6 words split by /[^a-z0-9_]+/ must yield 2 5-gram shingles");

    // Negative tests: < 5 words must return empty set
    assert!(v72_2_extract_word_5gram_shingles("a b c d").is_empty());
    assert!(v72_2_extract_word_5gram_shingles("").is_empty());

    // Determinism receipt & Jaccard parity
    let det_str = std::fs::read_to_string("03_vault/receipts/d1_sft_generator_run_and_diff_receipt.json")
        .expect("d1_sft_generator_run_and_diff_receipt.json");
    let det: serde_json::Value = serde_json::from_str(&det_str).expect("valid determinism receipt");
    assert_eq!(det.get("status").and_then(|v| v.as_str()), Some("MEASURED"));
    assert_eq!(det.get("committed_vs_fresh_diff_bytes").and_then(|v| v.as_u64()), Some(0));
    assert_eq!(det.get("repeat_run_diff_bytes").and_then(|v| v.as_u64()), Some(0));
    assert_eq!(
        det.get("negative_perturbation_test").and_then(|n| n.get("passed")).and_then(|v| v.as_bool()),
        Some(true)
    );
    let gen_jacc = det
        .get("generator_max_pairwise_5gram_jaccard")
        .and_then(|v| v.as_f64())
        .expect("generator_max_pairwise_5gram_jaccard");
    assert!(gen_jacc > 0.0 && gen_jacc <= 0.50, "Generator Jaccard {} must be in (0, 0.50]", gen_jacc);
    let gen_rec_str = std::fs::read_to_string("03_vault/corpus/sh_xi_sft_generator_receipt.json")
        .expect("sh_xi_sft_generator_receipt.json");
    let gen_rec: serde_json::Value = serde_json::from_str(&gen_rec_str).expect("valid generator receipt");
    let rec_jacc = gen_rec
        .get("max_pairwise_5gram_jaccard")
        .and_then(|v| v.as_f64())
        .expect("generator receipt max_pairwise_5gram_jaccard");
    assert!(
        (gen_jacc - rec_jacc).abs() < 1e-6,
        "Determinism receipt Jaccard ({}) MUST match generator receipt ({})",
        gen_jacc,
        rec_jacc
    );

    let sft_man_str = std::fs::read_to_string("03_vault/connectome/sh_xi_week2_chatml_sft_manifest.json")
        .expect("sh_xi_week2_chatml_sft_manifest.json");
    let sft_man: serde_json::Value = serde_json::from_str(&sft_man_str).expect("valid sft manifest");
    let man_jacc = sft_man
        .get("max_pairwise_5gram_jaccard")
        .and_then(|v| v.as_f64())
        .expect("manifest max_pairwise_5gram_jaccard");
    assert!(
        (man_jacc - gen_jacc).abs() < 1e-6,
        "SFT manifest max_pairwise_5gram_jaccard ({}) MUST match generator receipt ({})",
        man_jacc,
        gen_jacc
    );
}

#[test]
fn test_m2_v61_escape_clean_all_ascii_controls_and_json_roundtrip() {
    let mut all_controls = String::new();
    for b in 0u8..=0x1Fu8 {
        all_controls.push(char::from(b));
    }
    all_controls.push('\u{007F}');
    all_controls.push('"');
    all_controls.push('\\');
    all_controls.push('/');
    all_controls.push('[');
    all_controls.push(']');
    all_controls.push_str("▁Λ₂₄α");

    let escaped = v61_escape_clean(&all_controls);
    assert_eq!(escaped, v61_json_escape(&all_controls));
    assert!(
        !escaped.bytes().any(|b| b < 0x20 || b == 0x7F),
        "Escaped JSON string MUST contain zero raw control bytes (<0x20 or 0x7F): {:?}",
        escaped
    );

    let wrapped = format!("{{\"preview\":\"{}\"}}", escaped);
    let parsed: serde_json::Value = serde_json::from_str(&wrapped)
        .expect("Combined control-character JSON MUST parse cleanly with serde_json");
    assert_eq!(
        parsed.get("preview").and_then(|v| v.as_str()),
        Some(all_controls.as_str()),
        "Combined control-character roundtrip MUST match byte-for-byte"
    );

    let mut per_byte_cases: Vec<u8> = (0u8..=0x1Fu8).collect();
    per_byte_cases.push(0x7Fu8);
    per_byte_cases.push(b'"');
    per_byte_cases.push(b'\\');
    for b in per_byte_cases {
        let ch = char::from(b);
        let raw_single = ch.to_string();
        let esc_single = v61_escape_clean(&raw_single);
        assert!(
            !esc_single.bytes().any(|x| x < 0x20 || x == 0x7F),
            "Byte 0x{:02X} left raw control byte in {:?}",
            b,
            esc_single
        );
        let doc = format!("{{\"c\":\"{}\"}}", esc_single);
        let v: serde_json::Value = serde_json::from_str(&doc)
            .unwrap_or_else(|e| panic!("Byte 0x{:02X} failed serde_json parse: {} ({})", b, e, doc));
        assert_eq!(
            v.get("c").and_then(|x| x.as_str()),
            Some(raw_single.as_str()),
            "Byte 0x{:02X} roundtrip mismatch",
            b
        );
    }
}

#[test]
fn test_m2_t341_repeated_rng_json_serialization_and_kl_receipt_stability() {
    ensure_repo_root_cwd();
    let _kl_guard = T341_KL_RECEIPT_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _kl_restore = guard_paths(&[
        "03_vault/connectome/sh_week3_k4_empirical_kl_receipt.json",
    ]);

    for iter in 0..12 {
        let resp = v71_3_dispatch_tool_341_k4_speculative_cascade(r#"{"max_tokens":32}"#);
        let val: serde_json::Value = serde_json::from_str(&resp).unwrap_or_else(|e| {
            panic!("Tool 341 clean iteration {} produced invalid JSON: {} | raw={}", iter, e, resp)
        });
        assert_eq!(
            val.get("status").and_then(|s| s.as_str()),
            Some("MEASURED"),
            "Tool 341 clean iteration {} must report MEASURED",
            iter
        );
        assert_eq!(
            val.get("speculative_cascade")
                .and_then(|o| o.get("zero_distribution_drift_verified"))
                .and_then(|b| b.as_bool()),
            Some(true),
            "Tool 341 clean iteration {} must verify zero distribution drift",
            iter
        );
        assert!(
            !resp.bytes().any(|b| b < 0x20 || b == 0x7F),
            "Serialized Tool 341 JSON on iteration {} must not contain raw control bytes (<0x20 or 0x7F)",
            iter
        );
        let preview = val
            .get("generated_preview")
            .and_then(|s| s.as_str())
            .expect("top-level generated_preview string");
        assert!(
            !preview.is_empty() || resp.contains("\"generated_preview\":\"\""),
            "generated_preview field must be present on iteration {}",
            iter
        );
    }

    for neg_iter in 0..3 {
        let neg_resp = v71_3_dispatch_tool_341_k4_speculative_cascade(
            r#"{"corrupt_accept_without_rejection":true,"max_tokens":32}"#,
        );
        let neg_val: serde_json::Value = serde_json::from_str(&neg_resp).unwrap_or_else(|e| {
            panic!("Tool 341 negative iteration {} produced invalid JSON: {}", neg_iter, e)
        });
        assert_eq!(
            neg_val
                .get("speculative_cascade")
                .and_then(|o| o.get("zero_distribution_drift_verified"))
                .and_then(|b| b.as_bool()),
            Some(false),
            "Tool 341 negative iteration {} must fail zero_distribution_drift_verified",
            neg_iter
        );
    }

    let receipt_str = std::fs::read_to_string("03_vault/connectome/sh_week3_k4_empirical_kl_receipt.json")
        .expect("sh_week3_k4_empirical_kl_receipt.json");
    let receipt: serde_json::Value = serde_json::from_str(&receipt_str).expect("valid w3 kl receipt json");
    assert_eq!(receipt.get("status").and_then(|v| v.as_str()), Some("MEASURED"));
    assert_eq!(receipt.get("corrupt_accept_without_rejection").and_then(|v| v.as_bool()), Some(false));
    assert_eq!(receipt.get("zero_distribution_drift_verified").and_then(|v| v.as_bool()), Some(true));
    let emp_kl = receipt.get("empirical_output_kl").and_then(|v| v.as_f64()).expect("empirical_output_kl");
    let tau = receipt.get("kl_bound_tau").and_then(|v| v.as_f64()).expect("kl_bound_tau");
    assert!(emp_kl <= tau, "Canonical KL receipt empirical_output_kl ({}) must be <= kl_bound_tau ({})", emp_kl, tau);
}

#[test]
fn test_m3_item6_live_lean4_1010_threshold_and_1009_negative_fixture() {
    ensure_repo_root_cwd();
    // Positive test against real 03_vault/lean4/SovereignManifoldTheorems.lean (1,010 theorems)
    let live_count = count_live_lean_theorems_canonical().expect("canonical Lean4 theorem count");
    assert!(
        live_count >= 1010,
        "Canonical SovereignManifoldTheorems.lean must have >= 1010 theorems, got {}",
        live_count
    );
    assert!(
        validate_live_lean_theorems_with_floor(live_count),
        "Live theorem count {} must pass validate_live_lean_theorems_with_floor",
        live_count
    );
    assert!(
        !validate_live_lean_theorems_with_floor(1009),
        "Reported count 1009 MUST fail validate_live_lean_theorems_with_floor against live {}",
        live_count
    );

    // Negative fixture test: write a temporary .lean file with exactly 1,009 theorems
    let tmp_dir = std::env::temp_dir().join("act_omega_m3_lean1009_neg_test");
    let _ = std::fs::create_dir_all(&tmp_dir);
    let tmp_lean = tmp_dir.join(format!("fixture_1009_{}.lean", std::process::id()));
    let mut buf = String::new();
    for i in 1..=1009 {
        buf.push_str(&format!("theorem neg_fixture_{} : True := by trivial\n", i));
    }
    std::fs::write(&tmp_lean, buf.as_bytes()).expect("write temp 1009 lean fixture");

    let counted = count_live_lean_theorems_at_path(tmp_lean.to_string_lossy().as_ref());
    let _ = std::fs::remove_file(&tmp_lean);

    assert_eq!(counted, Some(1009), "1,009-theorem fixture must count exactly 1009");
    let c = counted.unwrap_or(0);
    assert!(
        !validate_live_lean_threshold(c, c),
        "1,009-theorem fixture MUST fail validate_live_lean_threshold(1009, 1009)"
    );
    assert!(
        !validate_live_lean_threshold(1010, c),
        "1,009-theorem live count MUST reject stale 1,010 report"
    );
    assert!(
        !validate_live_lean_threshold(c, 1010),
        "1,009 measured count MUST fail against 1,010 live count"
    );
}

#[test]
fn test_m4_item10_dynamic_version_no_pixel_serials_and_android_parity() {
    ensure_repo_root_cwd();
    let _rw_guard = RW_EVAL500_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _rw_restore = guard_paths(&[
        "03_vault/connectome/sh_xi_rw_eval_500_sealed.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_rw_eval_500_sealed.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\autopoietic_codegen\\wgsl_kernels\\igpu_sh_xi_rag_384d_cosine.wgsl",
    ]);

    // 1. Runtime release version helper must NOT return stale v72.2.0 or Cargo 30.0.0
    let live_ver = v73_2_read_live_release_version();
    assert!(
        live_ver.starts_with("v73."),
        "Live release version must start with v73., got {}",
        live_ver
    );
    assert_ne!(live_ver, "v72.2.0");
    assert_ne!(live_ver, "30.0.0");

    for (tid, raw) in [
        (363, v72_2_dispatch_tool_363_shell2_cpu_ssd_sparse_moe_bank("{}")),
        (364, v72_2_dispatch_tool_364_chatml_masked_sft_trainer("{}")),
        (365, v72_2_dispatch_tool_365_igpu_grounded_rag_and_telemetry("{}")),
    ] {
        let v: serde_json::Value = serde_json::from_str(&raw)
            .unwrap_or_else(|e| panic!("Tool {} invalid JSON: {}", tid, e));
        let ver = v.get("version").and_then(|x| x.as_str()).unwrap_or("");
        assert_ne!(ver, "v72.2.0", "Tool {} MUST NOT emit stale v72.2.0", tid);
        assert_eq!(ver, live_ver, "Tool {} version MUST match live release version", tid);
    }

    // 2. External ADB config must exist and zero raw Pixel serials may appear in Rust or C/C++/ELF
    let adb_raw = std::fs::read_to_string("C:\\Users\\Nbell\\.act_omega_adb_devices.json")
        .expect("C:\\Users\\Nbell\\.act_omega_adb_devices.json must exist");
    let adb_cfg: serde_json::Value = serde_json::from_str(&adb_raw).expect("valid external adb json");
    let p10_ser = adb_cfg.get("pixel10").and_then(|o| o.get("serial")).and_then(|x| x.as_str()).unwrap_or("");
    let p8_ser = adb_cfg.get("pixel8").and_then(|o| o.get("serial")).and_then(|x| x.as_str()).unwrap_or("");
    assert!(p10_ser.len() >= 8 && p8_ser.len() >= 8, "External ADB serials must be populated");

    for entry in std::fs::read_dir("01_l0_rust/src").expect("read 01_l0_rust/src") {
        let path = entry.expect("dir entry").path();
        if path.extension().and_then(|e| e.to_str()) == Some("rs") {
            let txt = std::fs::read_to_string(&path).expect("read rs file");
            assert!(
                !txt.contains(p10_ser) && !txt.contains(p8_ser),
                "Raw Pixel ADB serial leaked in {:?}",
                path
            );
        }
    }
    for bin_or_src in [
        "04_edge_silicon/pixel8_headless/p8_ksu_apex_daemon.c",
        "04_edge_silicon/pixel8_headless/p8_v31_native_daemon.cpp",
        "04_edge_silicon/pixel8_headless/p8_v31_native_daemon",
    ] {
        let bytes = std::fs::read(bin_or_src).expect("read edge silicon artifact");
        let lossy = String::from_utf8_lossy(&bytes);
        assert!(
            !lossy.contains(p10_ser) && !lossy.contains(p8_ser),
            "Raw Pixel ADB serial leaked in {}",
            bin_or_src
        );
    }

    // 3. Android NDK parity + stale literal purge + removed staging/stale JS bundle
    assert!(!std::path::Path::new("03_vault/config/MainActivity.kt.staging").exists());
    assert!(!std::path::Path::new("assets/index-5e7bpBRL.js").exists());

    let ma_paths = [
        "04_edge_silicon/pixel10_ndk_app/MainActivity.kt",
        "04_edge_silicon/pixel10_ndk_app/app/src/main/java/com/actomega/manifold/MainActivity.kt",
        "04_edge_silicon/pixel10_ndk_app/src/main/java/com/actomega/manifold/MainActivity.kt",
    ];
    let ma0 = std::fs::read_to_string(ma_paths[0]).expect("read MainActivity.kt");
    for p in ma_paths.iter().skip(1) {
        assert_eq!(ma0, std::fs::read_to_string(p).expect("read mirror MainActivity.kt"), "3x MainActivity.kt parity failed for {}", p);
    }
    for forbidden in ["/1010", "1,010/1,010", "v72.2.0", "CHAIN 368", "995/995", "965 LEAN 4"] {
        assert!(!ma0.contains(forbidden), "MainActivity.kt still contains stale literal: {}", forbidden);
    }

    let str0 = std::fs::read_to_string("04_edge_silicon/pixel10_ndk_app/app/src/main/res/values/strings.xml").expect("strings.xml 1");
    let str1 = std::fs::read_to_string("04_edge_silicon/pixel10_ndk_app/src/main/res/values/strings.xml").expect("strings.xml 2");
    assert_eq!(str0, str1, "2x strings.xml parity failed");
    assert!(!str0.contains("v72.2.0") && !str0.contains("CHAIN 368") && !str0.contains("995/995"));

    let man0 = std::fs::read_to_string("04_edge_silicon/pixel10_ndk_app/app/src/main/AndroidManifest.xml").expect("AndroidManifest.xml 1");
    let man1 = std::fs::read_to_string("04_edge_silicon/pixel10_ndk_app/src/main/AndroidManifest.xml").expect("AndroidManifest.xml 2");
    assert_eq!(man0, man1, "2x AndroidManifest.xml parity failed");
    assert!(man0.contains("@string/app_name") && man0.contains("@string/sovereign_widget_label"));
}

struct FileRestoreGuard {
    path: std::path::PathBuf,
    original: Option<Vec<u8>>,
}

impl FileRestoreGuard {
    fn capture<P: AsRef<std::path::Path>>(path: P) -> Self {
        let path_buf = path.as_ref().to_path_buf();
        let original = match std::fs::read(&path_buf) {
            Ok(bytes) => Some(bytes),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => None,
            Err(e) => panic!(
                "FileRestoreGuard::capture failed to read {:?}: {}",
                path_buf, e
            ),
        };
        Self {
            path: path_buf,
            original,
        }
    }
}

impl Drop for FileRestoreGuard {
    fn drop(&mut self) {
        match &self.original {
            Some(bytes) => {
                if let Some(parent) = self.path.parent() {
                    if !parent.as_os_str().is_empty() {
                        let _ = std::fs::create_dir_all(parent);
                    }
                }
                let mut restored = false;
                for _ in 0..20 {
                    if std::fs::write(&self.path, bytes).is_ok() {
                        restored = true;
                        break;
                    }
                    std::thread::sleep(std::time::Duration::from_millis(50));
                }
                if !restored && !std::thread::panicking() {
                    panic!("FileRestoreGuard failed to restore {:?}", self.path);
                }
            }
            None => {
                let _ = std::fs::remove_file(&self.path);
            }
        }
    }
}

fn guard_paths(paths: &[&str]) -> Vec<FileRestoreGuard> {
    let e_exists = std::path::Path::new("E:\\").exists();
    paths
        .iter()
        .filter(|p| {
            let is_e_drive = p.starts_with("E:\\") || p.starts_with("E:/");
            !is_e_drive || e_exists
        })
        .map(FileRestoreGuard::capture)
        .collect()
}

#[test]
fn test_m4_item13_hmac_signed_lean_receipt_positive_and_fail_closed_negatives() {
    ensure_repo_root_cwd();

    let lean_bytes = std::fs::read("03_vault/lean4/SovereignManifoldTheorems.lean").expect("read canonical .lean");
    let vault_sha = v72_1_sha256_hex(&lean_bytes);
    let theorems = count_live_lean_theorems_canonical().expect("canonical theorem count");
    assert!(theorems >= 1010);

    let key = v73_1_load_operator_key_bytes().expect("external operator key must be available");
    let lean_ver = "Lean (version 4.36.0, x86_64-w64-windows-gnu, Release)";
    let canonical_payload = format!("{}||{}||{}||0||0", vault_sha, lean_ver, theorems);
    let valid_hmac = v73_1_hmac_sha256_hex_lower(&key, &canonical_payload.as_bytes().to_vec());
    assert_eq!(valid_hmac.len(), 64);

    // Constant-time hex equality positive & negative checks
    assert!(v73_1_constant_time_eq_hex_64(&valid_hmac, &valid_hmac.to_ascii_uppercase()));
    let mut flipped = valid_hmac.clone();
    let last_ch = if flipped.ends_with('0') { '1' } else { '0' };
    flipped.pop();
    flipped.push(last_ch);
    assert!(!v73_1_constant_time_eq_hex_64(&valid_hmac, &flipped));
    assert!(!v73_1_constant_time_eq_hex_64(&valid_hmac, "abcd"));

    let tmp_dir = std::env::temp_dir().join(format!("act_omega_m4_lean_hmac_{}", std::process::id()));
    let _ = std::fs::create_dir_all(&tmp_dir);

    let mk_receipt = |sha: &str, lver: &str, thms: usize, exit_code: i64, payload: &str, hmac: &str| -> String {
        format!(
            "{{\"schema\":\"ACT_OMEGA_LEAN4_COMPILER_VERIFICATION_RECEIPT_V2\",\"lean_sha256\":\"{}\",\"l0_mirror_sha256\":\"{}\",\"lean_version\":\"{}\",\"theorem_count\":{},\"theorems_verified\":{},\"sorry_count\":0,\"axiom_count\":0,\"exit_code\":{},\"compiler_exit_code\":{},\"lean_exe_exit_zero\":{},\"canonical_payload\":\"{}\",\"hmac_sha256\":\"{}\"}}",
            sha, sha, lver, thms, thms, exit_code, exit_code, exit_code == 0, payload, hmac
        )
    };

    // Positive: valid signed receipt passes
    let valid_path = tmp_dir.join("valid_signed.json");
    std::fs::write(&valid_path, mk_receipt(&vault_sha, lean_ver, theorems, 0, &canonical_payload, &valid_hmac)).unwrap();
    assert_eq!(
        v73_1_verify_signed_lean_receipt_at(valid_path.to_str().unwrap(), &vault_sha, theorems),
        Ok(())
    );

    // Negative 1: missing file
    assert_eq!(
        v73_1_verify_signed_lean_receipt_at(tmp_dir.join("nonexistent.json").to_str().unwrap(), &vault_sha, theorems),
        Err("MISSING_LEAN_RECEIPT")
    );

    // Negative 2: unsigned receipt (empty hmac)
    let unsigned_path = tmp_dir.join("unsigned.json");
    std::fs::write(&unsigned_path, mk_receipt(&vault_sha, lean_ver, theorems, 0, &canonical_payload, "")).unwrap();
    assert_eq!(
        v73_1_verify_signed_lean_receipt_at(unsigned_path.to_str().unwrap(), &vault_sha, theorems),
        Err("LEAN_RECEIPT_UNSIGNED")
    );

    // Negative 3: forged HMAC
    let forged_path = tmp_dir.join("forged_hmac.json");
    let zero_hmac = "0".repeat(64);
    std::fs::write(&forged_path, mk_receipt(&vault_sha, lean_ver, theorems, 0, &canonical_payload, &zero_hmac)).unwrap();
    assert_eq!(
        v73_1_verify_signed_lean_receipt_at(forged_path.to_str().unwrap(), &vault_sha, theorems),
        Err("LEAN_RECEIPT_HMAC_INVALID")
    );

    // Negative 4: tampered theorem_count
    let bad_thm_path = tmp_dir.join("tampered_theorems.json");
    std::fs::write(&bad_thm_path, mk_receipt(&vault_sha, lean_ver, theorems - 1, 0, &canonical_payload, &valid_hmac)).unwrap();
    assert_eq!(
        v73_1_verify_signed_lean_receipt_at(bad_thm_path.to_str().unwrap(), &vault_sha, theorems),
        Err("LEAN_RECEIPT_THEOREM_COUNT_MISMATCH")
    );

    // Negative 5: tampered exit_code
    let bad_exit_path = tmp_dir.join("tampered_exit.json");
    std::fs::write(&bad_exit_path, mk_receipt(&vault_sha, lean_ver, theorems, 1, &canonical_payload, &valid_hmac)).unwrap();
    assert_eq!(
        v73_1_verify_signed_lean_receipt_at(bad_exit_path.to_str().unwrap(), &vault_sha, theorems),
        Err("LEAN_RECEIPT_NONZERO_EXIT")
    );

    // Negative 6: tampered lean_sha256
    let bad_sha = "f".repeat(64);
    let bad_sha_path = tmp_dir.join("tampered_sha.json");
    std::fs::write(&bad_sha_path, mk_receipt(&bad_sha, lean_ver, theorems, 0, &canonical_payload, &valid_hmac)).unwrap();
    assert_eq!(
        v73_1_verify_signed_lean_receipt_at(bad_sha_path.to_str().unwrap(), &vault_sha, theorems),
        Err("LEAN_RECEIPT_SHA_MISMATCH")
    );

    let _ = std::fs::remove_dir_all(&tmp_dir);

    // Negative 7 (End-to-end fail-closed CHAIN 399 & CHAIN 404 via guarded swap-and-restore of on-disk receipt)
    let _lean_guard = LEAN_RECEIPT_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _curvetq_guard = CURVETQ_RECEIPT_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let connectome_rec_path = std::path::PathBuf::from("03_vault/connectome/lean4_compiler_verified_receipt.json");
    let _restore = guard_paths(&[
        "03_vault/connectome/lean4_compiler_verified_receipt.json",
        "03_vault/connectome/curvetq_hessian_receipt.json",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\curvetq_hessian_receipt.json",
    ]);
    std::fs::write(
        &connectome_rec_path,
        mk_receipt(&vault_sha, lean_ver, theorems, 0, &canonical_payload, &"a".repeat(64)),
    )
    .expect("write forged connectome receipt");

    let (lean_ok, _, _, _) = v73_1_verify_lean4_compiler_and_mirror();
    assert!(!lean_ok, "Forged connectome receipt MUST fail v73_1_verify_lean4_compiler_and_mirror()");

    let c399: serde_json::Value = serde_json::from_str(&v73_1_dispatch_chain399_master_certification("{}")).expect("c399 json");
    assert_eq!(c399.get("ok").and_then(|v| v.as_bool()), Some(false), "CHAIN 399 MUST fail closed on forged receipt");
    assert_eq!(c399.get("certified").and_then(|v| v.as_bool()), Some(false));
    assert_eq!(c399.get("lean4_compiler_verified").and_then(|v| v.as_bool()), Some(false));
    assert_eq!(c399.get("status").and_then(|v| v.as_str()), Some("UNMEASURED/OFFLINE"));

    let c404: serde_json::Value = serde_json::from_str(&v73_2_dispatch_chain404_master_certification("{}")).expect("c404 json");
    assert_eq!(c404.get("ok").and_then(|v| v.as_bool()), Some(false), "CHAIN 404 MUST fail closed on forged receipt");
    assert_eq!(c404.get("certified").and_then(|v| v.as_bool()), Some(false));
    assert_eq!(c404.get("lean4_compiler_verified").and_then(|v| v.as_bool()), Some(false));
    assert_eq!(c404.get("status").and_then(|v| v.as_str()), Some("UNMEASURED/OFFLINE"));
}

#[test]
fn test_m4_item16_t383_curvetq_ce_scope_and_v71_2_narrow_172_support_label() {
    ensure_repo_root_cwd();

    // 1. T383 CurveTQ emits CE comparison alongside Fisher distortion + explicit scope & support notes
    {
        let _curvetq_guard = CURVETQ_RECEIPT_GUARD.lock().unwrap_or_else(|e| e.into_inner());
        let _curvetq_restore = guard_paths(&[
            "03_vault/connectome/curvetq_hessian_receipt.json",
            "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\curvetq_hessian_receipt.json",
        ]);
        let base_raw = v73_1_dispatch_tool_383_curvetq("{}");
        let base: serde_json::Value = serde_json::from_str(&base_raw).expect("t383 base json");
        assert_eq!(base.get("status").and_then(|v| v.as_str()), Some("MEASURED"));
        assert_eq!(base.get("val_positions_evaluated").and_then(|v| v.as_u64()), Some(16));
        assert_eq!(
            base.get("distortion_metric_scope").and_then(|v| v.as_str()),
            Some("FISHER_WEIGHTED_DISTORTION_ONLY_NOT_CE")
        );
        assert_eq!(
            base.get("eval_support_note").and_then(|v| v.as_str()),
            Some("16_VALIDATION_POSITIONS_ONLY")
        );
        let unweighted_mse = base.get("unweighted_hessian_loss").and_then(|v| v.as_f64()).expect("unweighted_hessian_loss");
        let scalar_fisher = base.get("scalar_3bpw_fisher_loss").and_then(|v| v.as_f64()).expect("scalar_3bpw_fisher_loss");
        assert!(unweighted_mse.is_finite() && unweighted_mse > 0.0);
        assert!((unweighted_mse - scalar_fisher).abs() > 1e-6, "unweighted_hessian_loss ({}) must differ from scalar_3bpw_fisher_loss ({})", unweighted_mse, scalar_fisher);
        let fp32_base = base.get("fp32_val_ce_nats").and_then(|v| v.as_f64()).expect("fp32_val_ce_nats");
        let scalar_base = base.get("scalar_3bpw_val_ce_nats").and_then(|v| v.as_f64()).expect("scalar_3bpw_val_ce_nats");
        let curvetq_base = base.get("curvetq_3bpw_val_ce_nats").and_then(|v| v.as_f64()).expect("curvetq_3bpw_val_ce_nats");
        assert!(fp32_base.is_finite() && scalar_base.is_finite() && curvetq_base.is_finite());

        // Negative perturbation: perturb_delta=0.25 must shift CE nats significantly
        let pert_raw = v73_1_dispatch_tool_383_curvetq(r#"{"perturb_delta":0.25}"#);
        let pert: serde_json::Value = serde_json::from_str(&pert_raw).expect("t383 pert json");
        let fp32_pert = pert.get("fp32_val_ce_nats").and_then(|v| v.as_f64()).expect("pert fp32_val_ce_nats");
        let curvetq_pert = pert.get("curvetq_3bpw_val_ce_nats").and_then(|v| v.as_f64()).expect("pert curvetq_3bpw_val_ce_nats");
        assert!((fp32_base - fp32_pert).abs() > 0.1, "perturb_delta=0.25 MUST shift fp32_val_ce_nats");
        assert!((curvetq_base - curvetq_pert).abs() > 0.1, "perturb_delta=0.25 MUST shift curvetq_3bpw_val_ce_nats");
    }

    // 2. v71_2 Tool 339 emits eval_vocab_support_size=172 and NARROW_172_TOKEN_EVAL_SUPPORT
    {
        let _abl_guard = T339_ABLATION_GUARD.lock().unwrap_or_else(|e| e.into_inner());
        let _abl_restore = guard_paths(&[
            "03_vault/connectome/sh_week2_6way_ablation_receipt.json",
            "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_week2_6way_ablation_receipt.json",
            "03_vault/receipts/v71_2_week2_torture_benchmark_receipt.json",
            "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\v71_2_week2_torture_benchmark_receipt.json",
            "03_vault/connectome/sh_week2_curated_corpus.jsonl",
            "03_vault/connectome/sh_week2_curated_corpus.binshard",
            "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_week2_curated_corpus.jsonl",
            "E:\\Sovereign_Manifold_SSD_Vault\\training_corpus\\sh_week2_curated_corpus.binshard",
        ]);
        let t339_raw = v71_2_dispatch_tool_339_week2_7test_torture_gauntlet("{}");
        let t339: serde_json::Value = serde_json::from_str(&t339_raw).expect("t339 json");
        let w2_8 = t339.get("w2_8_six_way_ablation_matrix").expect("w2_8_six_way_ablation_matrix");
        assert_eq!(w2_8.get("eval_vocab_support_size").and_then(|v| v.as_u64()), Some(172));
        assert_eq!(
            w2_8.get("eval_vocab_support_label").and_then(|v| v.as_str()),
            Some("NARROW_172_TOKEN_EVAL_SUPPORT")
        );
    }
}

#[test]
fn test_r1_item7_tool368_live_tools_count_and_zero_brackets() {
    ensure_repo_root_cwd();
    let _rw_guard = RW_EVAL500_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_guard = SH_XI_TURN_COUNTER_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_reload_on_drop = ShXiTurnCounterReloadGuard::new("r1_item7");
    let _restore = guard_paths(&[
        "03_vault/connectome/sh_xi_rw_eval_500_sealed.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_rw_eval_500_sealed.jsonl",
        "03_vault/connectome/sh_xi_week2_master_receipt.json",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_week2_master_receipt.json",
    ]);

    let live_ota = v73_2_read_live_ota_metadata();
    let live_ver = v73_2_read_live_release_version();
    let raw = v72_2_dispatch_tool_368_week2_chain368_master_certification("{}");
    assert!(
        !raw.contains("CHAIN 368") && !raw.contains("CHAIN368"),
        "Tool 368 response MUST NOT contain stale CHAIN 368/CHAIN368 stamps"
    );
    let val: serde_json::Value = serde_json::from_str(&raw).expect("valid Tool 368 JSON");
    assert_eq!(val.get("suite_milestone").and_then(|v| v.as_str()), Some("SH_XI_WEEK2"));
    assert!(val.get("milestone").is_none(), "Stale 'milestone' field must be replaced by 'suite_milestone'");
    assert_eq!(val.get("total_tools").and_then(|v| v.as_u64()), Some(live_ota.tools_count));
    assert_eq!(val.get("version").and_then(|v| v.as_str()), Some(live_ver.as_str()));

    for path in [
        "01_l0_rust/src/v72_1_sh_xi_matryoshka_384_768_cuda_pretrainer.rs",
        "01_l0_rust/src/v72_2_sh_xi_sparse_moe_chatml_sft_and_rag.rs",
        "01_l0_rust/src/v73_2_cloudflare_vpc_mesh_and_pgwire_hyperdrive.rs",
    ] {
        let src = std::fs::read_to_string(path).unwrap_or_else(|e| panic!("read {}: {}", path, e));
        assert!(
            !src.contains('[') && !src.contains(']'),
            "{} MUST contain zero square brackets",
            path
        );
    }
}

#[test]
fn test_r2_r3_r4_r8_l0_security_gates_health_ingest_tao_and_source_invariants() {
    ensure_repo_root_cwd();

    assert_eq!(V73_2_HEALTH_ENDPOINT, "/api/v1/health");
    assert_eq!(V73_2_TELEMETRY_INGEST_ENDPOINT, "/api/v1/telemetry/ingest");

    // 1. Write query parameter detection on GET endpoints
    for write_url in [
        "/api/v1/telemetry?node=pixel10&kops=12.5",
        "/api/v1/telemetry/snapshot?pixel10_kops=9.0",
        "/api/v1/StateGraph?anchor1_kops=42.0",
        "/api/v1/health?mx=1.0",
        "/api/v1/telemetry?BEARER=usb",
    ] {
        assert!(
            v73_2_has_telemetry_write_query_param(write_url),
            "Write query param MUST be detected in {}",
            write_url
        );
    }
    for clean_url in [
        "/api/v1/health",
        "/api/v1/telemetry",
        "/api/v1/telemetry/snapshot?format=json",
        "/api/v1/StateGraph",
    ] {
        assert!(
            !v73_2_has_telemetry_write_query_param(clean_url),
            "Clean read-only URL {} must NOT trigger write-param denial",
            clean_url
        );
    }

    assert!(v73_2_has_query_key_param("/api/v1/telemetry/ingest?key=secret"));
    assert!(v73_2_has_query_key_param("/api/v1/telemetry/ingest?a=1&KEY=secret"));
    assert!(!v73_2_has_query_key_param("/api/v1/telemetry/ingest?format=json"));

    // 2. Constant-time auth gate (loopback + telemetry/operator header, reject ?key= & non-loopback)
    let tel_key = "test_telemetry_ingest_key_0123456789abcdef0123456789abcdef";
    let op_key = "test_operator_vault_key_fedcba9876543210fedcba9876543210";
    assert!(v73_2_constant_time_compare_key(tel_key, tel_key));
    assert!(!v73_2_constant_time_compare_key(tel_key, op_key));
    assert!(!v73_2_constant_time_compare_key("", tel_key));

    assert_eq!(
        v73_2_verify_telemetry_or_operator_auth_with_keys(
            true,
            tel_key,
            "",
            "/api/v1/telemetry/ingest",
            tel_key,
            op_key
        ),
        Ok("X-Sovereign-Telemetry-Key")
    );
    assert_eq!(
        v73_2_verify_telemetry_or_operator_auth_with_keys(
            true,
            "",
            op_key,
            "/api/v1/telemetry/ingest",
            tel_key,
            op_key
        ),
        Ok("X-Sovereign-Operator-Key")
    );
    assert!(v73_2_verify_telemetry_or_operator_auth_with_keys(
        false,
        tel_key,
        "",
        "/api/v1/telemetry/ingest",
        tel_key,
        op_key
    ).is_err(), "Non-loopback telemetry ingest MUST be rejected");
    assert!(v73_2_verify_telemetry_or_operator_auth_with_keys(
        true,
        tel_key,
        "",
        "/api/v1/telemetry/ingest?key=abc",
        tel_key,
        op_key
    ).is_err(), "?key= query param MUST be rejected");
    assert!(v73_2_verify_telemetry_or_operator_auth_with_keys(
        true,
        "wrong_key_0123456789abcdef",
        "",
        "/api/v1/telemetry/ingest",
        tel_key,
        op_key
    ).is_err(), "Wrong key MUST be rejected");
    assert!(v73_2_verify_telemetry_or_operator_auth_with_keys(
        true,
        "short_key",
        "",
        "/api/v1/telemetry/ingest",
        "short_key",
        op_key
    ).is_err(), "Key shorter than 24 chars MUST be rejected");

    // 3. Finite JSON bounds validation
    let valid_json = r#"{"node":"pixel10","kops":480.5,"mx":-29.3,"baro":1013.25,"temp":33.8,"bat":84,"shz":15.965,"col":1919,"bearer":"USB_ADB"}"#;
    let parsed = v73_2_validate_telemetry_bounds(valid_json).expect("valid telemetry payload");
    assert_eq!(parsed.node.as_deref(), Some("pixel10"));
    assert_eq!(parsed.bat, Some(84));
    assert_eq!(parsed.col, Some(1919));

    for bad_payload in [
        "",
        "{bad",
        "[]",
        r#"{"node":"pixel10"}"#,
        r#"{"node":"rogue_node","kops":10.0}"#,
        r#"{"node":"pixel10","kops":-1.0}"#,
        r#"{"node":"pixel10","kops":1000001.0}"#,
        r#"{"node":"pixel10","kops":1e500}"#,
        r#"{"node":"pixel10","temp":250.0}"#,
        r#"{"node":"pixel10","baro":50.0}"#,
        r#"{"node":"pixel10","bat":101}"#,
        r#"{"node":"pixel10","col":1920}"#,
    ] {
        assert!(
            v73_2_validate_telemetry_bounds(bad_payload).is_err(),
            "Invalid telemetry payload MUST be rejected: {}",
            bad_payload
        );
    }

    // 4. L0 source invariants across bin/v31_swarm.rs == src/v31_swarm.rs
    let bin_src = std::fs::read_to_string("01_l0_rust/src/bin/v31_swarm.rs").expect("bin/v31_swarm.rs");
    let lib_src = std::fs::read_to_string("01_l0_rust/src/v31_swarm.rs").expect("src/v31_swarm.rs");
    assert_eq!(bin_src, lib_src, "bin/v31_swarm.rs and src/v31_swarm.rs MUST remain 1:1 identical");
    assert!(!bin_src.contains("Timing-Allow-Origin: *"), "Timing-Allow-Origin: * MUST NOT exist in v31_swarm.rs");
    assert!(!bin_src.contains("1,010/1,010"), "Static 1,010/1,010 MUST NOT exist in v31_swarm.rs");
    assert!(!bin_src.contains("v73.2.2"), "Hardcoded v73.2.2 MUST NOT exist in v31_swarm.rs");
    assert!(
        bin_src.contains("if (id >= 211 && id <= 270) || (id >= 275 && id <= 280)"),
        "dispatch_cycle6_211_to_270 MUST exclude t271..t274 so they cannot bypass operator gate"
    );
    assert!(bin_src.contains("V73_2_HEALTH_ENDPOINT"));
    assert!(bin_src.contains("V73_2_TELEMETRY_INGEST_ENDPOINT"));
    assert!(bin_src.contains("v73_2_has_telemetry_write_query_param"));

    for marker in [
        "if clean_path == \"/api/v1/p8_root/hardware_audit\" {\n            if !enforce_operator_gate_403",
        "if clean_path == \"/api/v1/p8_root/governor\" {\n            if !enforce_operator_gate_403",
        "|| clean_path == \"/api/v1/connectome/spage_3m_synapses\"\n        {\n            if !enforce_operator_gate_403",
        "if is_gemma4_271_to_274_route {\n            if !enforce_operator_gate_403",
    ] {
        let normalized_src = bin_src.replace("\r\n", "\n");
        assert!(
            normalized_src.contains(marker),
            "Missing operator gate before lock/dispatch for marker:\n{}",
            marker
        );
    }

    // 5. Iteration 2 regressions: percent-decoding, strict integer col, /api/v1/health 405, R4 alias gates, C:/E: parity
    assert_eq!(v73_2_percent_decode_ascii("%6bey"), "key");
    assert_eq!(v73_2_percent_decode_ascii("%6Eode"), "node");
    assert_eq!(v73_2_percent_decode_ascii("%4Eode"), "Node");
    assert!(v73_2_has_query_key_param("/api/v1/telemetry/ingest?%6bey=foo"));
    assert!(v73_2_has_query_key_param("/api/v1/telemetry/ingest?%6Bey=foo"));
    assert!(v73_2_has_query_key_param("/api/v1/telemetry/ingest?%256bey=foo"));
    assert!(v73_2_has_telemetry_write_query_param("/api/v1/health?%6eode=pixel10"));
    assert!(v73_2_has_telemetry_write_query_param("/api/v1/telemetry?%6Eode=pixel10"));
    assert!(v73_2_has_telemetry_write_query_param("/api/v1/StateGraph?%256eode=pixel10"));
    assert!(v73_2_validate_telemetry_bounds("{\"node\":\"pixel10\",\"col\":1.5}").is_err());
    assert!(v73_2_validate_telemetry_bounds("{\"node\":\"pixel10\",\"col\":1.0}").is_err());
    assert_eq!(
        v73_2_validate_telemetry_bounds("{\"node\":\"pixel10\",\"col\":0}").expect("col=0 valid").col,
        Some(0)
    );

    let normalized_src = bin_src.replace("\r\n", "\n");
    assert!(
        normalized_src.contains("if clean_path == V73_2_HEALTH_ENDPOINT {\n            if v73_2_has_telemetry_write_query_param(raw_target) {")
            && normalized_src.contains("if !method.eq_ignore_ascii_case(\"GET\") && !method.eq_ignore_ascii_case(\"HEAD\") {\n                let m_json = format!(\n                    \"{{\\\"status\\\":\\\"HTTP_405_METHOD_NOT_ALLOWED\\\",\\\"endpoint\\\":\\\"/api/v1/health\\\"")
    );
    assert!(normalized_src.contains("fn is_r4_operator_gated_tool_id(id: usize) -> bool"));
    for required_id in ["(id >= 185 && id <= 204)", "id == 212", "id == 258", "id == 259", "id == 260", "(id >= 271 && id <= 274)"] {
        assert!(
            normalized_src.contains(required_id),
            "is_r4_operator_gated_tool_id MUST gate {}",
            required_id
        );
    }
    assert!(normalized_src.contains("if let Some(r4_tid) = extract_r4_route_or_execute_tool_id(clean_path, raw_target, &post_body)"));
    assert!(normalized_src.contains("if is_r4_operator_gated_tool_id(id) && !operator_authed {\n                return None;\n            }"));

    if std::path::Path::new("E:\\Sovereign_Manifold_SSD_Vault").exists() {
        let c_sft_man = std::fs::read("03_vault/connectome/sh_xi_week2_chatml_sft_manifest.json")
            .expect("C: sh_xi_week2_chatml_sft_manifest.json");
        let e_sft_man = std::fs::read("E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_week2_chatml_sft_manifest.json")
            .expect("E: sh_xi_week2_chatml_sft_manifest.json");
        assert_eq!(
            v72_1_sha256_hex(&c_sft_man),
            v72_1_sha256_hex(&e_sft_man),
            "C: and E: sh_xi_week2_chatml_sft_manifest.json MUST be SHA-256 identical"
        );

        let c_base_meta = std::fs::read("00_control/weights/sh_xi_base_train_meta.json")
            .expect("C: sh_xi_base_train_meta.json");
        let e_conn_meta = std::fs::read("E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_base_train_meta.json")
            .expect("E: connectome sh_xi_base_train_meta.json");
        let e_wt_meta = std::fs::read("E:\\Sovereign_Manifold_SSD_Vault\\weights\\sh_xi_base_train_meta.json")
            .expect("E: weights sh_xi_base_train_meta.json");
        assert_eq!(
            v72_1_sha256_hex(&c_base_meta),
            v72_1_sha256_hex(&e_conn_meta),
            "C: and E:\\connectome sh_xi_base_train_meta.json MUST be SHA-256 identical"
        );
        assert_eq!(
            v72_1_sha256_hex(&c_base_meta),
            v72_1_sha256_hex(&e_wt_meta),
            "C: and E:\\weights sh_xi_base_train_meta.json MUST be SHA-256 identical"
        );
    }
}

mod v44_test_harness {
    #![allow(dead_code)]
    fn unix_ms() -> u64 {
        1_763_900_000_000
    }
    struct DummyTok;
    fn encode_and_detokenize_65k(_s: &str) -> DummyTok {
        DummyTok
    }
    include!("../src/v44_worksteal_npage_shm_webgpu_lease.rs");
}

#[test]
fn test_v73_2_4_m1_security_gates_v44_poc_and_query_key_parity() {
    ensure_repo_root_cwd();
    let _lease_restore = guard_paths(&[
        "03_vault/connectome/webgpu_active_leases_v4400.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\webgpu_active_leases_v4400.jsonl",
    ]);

    // 1. Item #4: v44 zero square brackets + independent .e8z Plucker FNV-1a parity (including negative P_ab two's complement)
    let v44_src = std::fs::read_to_string("01_l0_rust/src/v44_worksteal_npage_shm_webgpu_lease.rs")
        .expect("read v44_worksteal_npage_shm_webgpu_lease.rs");
    assert!(
        !v44_src.contains('[') && !v44_src.contains(']'),
        "v44_worksteal_npage_shm_webgpu_lease.rs MUST contain strictly zero square brackets"
    );

    let (exp_gpu, exp_simd) = v44_test_harness::v44_compute_expected_e8z_plucker_hashes()
        .expect("sovereign_harmonic_iv_v5000.e8z must yield expected Plucker hashes");
    assert!(exp_gpu.starts_with("0x") && exp_gpu.ends_with("_PLUCKER_POS_QED"));
    assert!(exp_simd.starts_with("0x") && exp_simd.ends_with("_CPU_E8_PLUCKER_6D_INNER_MEASURED"));
    assert_eq!(&exp_gpu[..8], &exp_simd[..8]);

    // Reference check on negative P_ab two's-complement truncation parity with JS `(P_ab * 10000) | 0`
    let neg_pab: f64 = -0.123456;
    assert_eq!(((neg_pab * 10000.0) as i32) as u32, (-1234_i32) as u32);
    assert!(v44_test_harness::v44_constant_time_eq(&exp_gpu, &exp_gpu));
    assert!(!v44_test_harness::v44_constant_time_eq(&exp_gpu, "0xDEAD00_PLUCKER_POS_QED"));
    assert!(!v44_test_harness::v44_constant_time_eq(&exp_gpu, ""));

    // Fail-closed negative checks on v44 execute_tool78_webgpu_compute_lease
    let mut leases: Vec<v44_test_harness::WebGpuLeaseSlot> = Vec::new();
    let ssd = "E:/Sovereign_Manifold_SSD_Vault";
    for (act, kops, poc, label) in [
        ("acquire", Some(420.0), "", "empty poc_hash"),
        ("acquire", Some(420.0), "0xDEAD00_PLUCKER_POS_QED", "forged poc_hash"),
        ("acquire", None, exp_gpu.as_str(), "missing kops"),
        ("acquire", Some(f64::NAN), exp_gpu.as_str(), "NaN kops"),
        ("acquire", Some(f64::INFINITY), exp_gpu.as_str(), "Inf kops"),
        ("acquire", Some(49.9), exp_gpu.as_str(), "kops < 50"),
        ("acquire", Some(850.1), exp_gpu.as_str(), "kops > 850"),
        ("bogus", Some(420.0), exp_gpu.as_str(), "unknown action"),
    ] {
        let res = v44_test_harness::execute_tool78_webgpu_compute_lease(
            &mut leases,
            act,
            "unit-test-worker",
            "UnitTest-WGSL",
            kops,
            poc,
            4500.0,
            ssd,
        );
        assert!(res.rejected_bad_request, "MUST reject bad request: {}", label);
        assert!(!res.poc_verified, "poc_verified MUST be false on rejection: {}", label);
        assert!(!res.lease_active, "lease_active MUST be false on rejection: {}", label);
        assert!(leases.is_empty(), "leases MUST remain unmutated on rejection: {}", label);
    }

    // Positive checks for both WebGPU & SIMD PoC hashes + release
    let acq_gpu = v44_test_harness::execute_tool78_webgpu_compute_lease(
        &mut leases,
        "acquire",
        "unit-test-worker",
        "Chrome-WebGPU-WGSL-Stiefel-FNO-64T",
        Some(420.0),
        &exp_gpu,
        4500.0,
        ssd,
    );
    assert!(!acq_gpu.rejected_bad_request && acq_gpu.poc_verified && acq_gpu.lease_active);
    assert_eq!(leases.len(), 1);

    let sub_simd = v44_test_harness::execute_tool78_webgpu_compute_lease(
        &mut leases,
        "submit",
        "unit-test-worker",
        "Chrome-SIMD-Float64-Fallback-64T",
        Some(210.0),
        &exp_simd,
        4500.0,
        ssd,
    );
    assert!(!sub_simd.rejected_bad_request && sub_simd.poc_verified && sub_simd.lease_active);
    assert_eq!(sub_simd.worker_batches, 2);

    // Negative release checks: missing or forged poc_hash MUST reject (HTTP 400) with zero lease mutation
    for (bad_poc, expected_reason, label) in [
        ("", "MISSING_POC_HASH", "release empty poc_hash"),
        (
            "0xDEAD00_PLUCKER_POS_QED",
            "INVALID_POC_HASH_E8Z_PLUCKER_MISMATCH",
            "release forged poc_hash",
        ),
    ] {
        let rel_bad = v44_test_harness::execute_tool78_webgpu_compute_lease(
            &mut leases,
            "release",
            "unit-test-worker",
            "",
            None,
            bad_poc,
            4500.0,
            ssd,
        );
        assert!(rel_bad.rejected_bad_request, "MUST reject {}: {}", label, rel_bad.diag);
        assert_eq!(rel_bad.rejection_reason, expected_reason);
        assert!(!rel_bad.poc_verified);
        assert!(!rel_bad.lease_active);
        assert_eq!(leases.len(), 1, "leases MUST remain unmutated on rejected {}", label);
        assert_eq!(rel_bad.active_leases_count, 1);
    }

    // Positive release check with real measured .e8z PoC hash
    let rel_res = v44_test_harness::execute_tool78_webgpu_compute_lease(
        &mut leases,
        "release",
        "unit-test-worker",
        "",
        None,
        &exp_gpu,
        4500.0,
        ssd,
    );
    assert!(!rel_res.rejected_bad_request && !rel_res.lease_active && rel_res.poc_verified);
    assert_eq!(rel_res.assigned_col_start, 480);
    assert_eq!(rel_res.assigned_col_end, 495);
    assert!(leases.is_empty());
    assert_eq!(rel_res.active_leases_count, 0);

    // Idempotent release on already-empty leases with valid SIMD PoC hash succeeds with poc_verified=true
    let rel_empty = v44_test_harness::execute_tool78_webgpu_compute_lease(
        &mut leases,
        "release",
        "unit-test-worker",
        "",
        None,
        &exp_simd,
        4500.0,
        ssd,
    );
    assert!(!rel_empty.rejected_bad_request && !rel_empty.lease_active && rel_empty.poc_verified);
    assert!(rel_empty.cadence_jitter_us > 0.0);

    // 2. Item #5: Percent-encoded & case-variant ?key= detection parity
    for enc in [
        "/api/v1/auth/operator_vault_gate?key=test",
        "/api/v1/auth/operator_vault_gate?%6bey=test",
        "/api/v1/auth/operator_vault_gate?%4Bey=test",
        "/api/v1/router/distributed_5w1h_dispatch?who=a&%256bey=test",
    ] {
        assert!(v73_2_has_query_key_param(enc), "MUST detect encoded query key in {}", enc);
    }
    assert!(!v73_2_has_query_key_param("/api/v1/auth/operator_vault_gate?format=json"));

    // 3. Items #2, #3, #4, #5: L0 v31_swarm.rs mirror parity & source gate checks
    let bin_src = std::fs::read_to_string("01_l0_rust/src/bin/v31_swarm.rs").expect("bin/v31_swarm.rs");
    let lib_src = std::fs::read_to_string("01_l0_rust/src/v31_swarm.rs").expect("src/v31_swarm.rs");
    assert_eq!(bin_src, lib_src, "bin/v31_swarm.rs and src/v31_swarm.rs MUST remain 100% identical");
    assert!(
        !bin_src.contains("extract_query_param(raw_target, \"key\")"),
        "0 occurrences of extract_query_param(raw_target, \"key\") allowed in v31_swarm.rs"
    );

    let norm_src = bin_src.replace("\r\n", "\n");
    for marker in [
        "id == 78",
        "(id >= 275 && id <= 280)",
        "fn is_chain135_json_route(",
        "if is_chain135_json_route(clean_path, raw_target, &post_body) {\n            if !enforce_operator_gate_403",
        "if clean_path.starts_with(\"/api/v1/unified/\") {\n            if !enforce_operator_gate_403",
        "|| clean_path == \"/api/v1/tool/275\"\n        {\n            if !enforce_operator_gate_403",
        "if !is_known_legacy {",
        "if clean_path == \"/api/v1/worksteal/webgpu_lease\"\n            || clean_path == \"/api/v1/tools/t78\"\n            || clean_path == \"/api/v1/tool/78\"\n        {\n            if !enforce_operator_gate_403",
        "if clean_path == \"/api/v1/openai/compat\" || clean_path == \"/v1/chat/completions\" {\n            if !enforce_operator_gate_403",
        "|| (287..=368).contains(&id);",
    ] {
        assert!(norm_src.contains(marker), "Missing v73.2.4 M1 gate marker:\n{}", marker);
    }
    assert!(
        !norm_src.contains("|| (316..=368).contains(&id);"),
        "is_chain135_json_route MUST NOT leave /api/v1/tool/308..315 ungated via (316..=368)"
    );
    let fn_start = norm_src.find("fn is_chain135_json_route(").expect("is_chain135_json_route fn");
    let fn_end = norm_src[fn_start..].find("fn extract_r4_route_or_execute_tool_id(").expect("fn end") + fn_start;
    let route_fn = &norm_src[fn_start..fn_end];
    let tool_branch_start = route_fn.find("clean_path.strip_prefix(\"/api/v1/tool/\")").expect("/api/v1/tool/ branch");
    let tool_branch = &route_fn[tool_branch_start..];
    for check_tid in [308usize, 313usize] {
        let covered = tool_branch.contains("(287..=368).contains(&id)") && (287..=368).contains(&check_tid);
        assert!(covered, "/api/v1/tool/{} MUST be gated in is_chain135_json_route", check_tid);
    }

    // 4. Item #3 & #4 Edge Worker gating markers
    let worker_js = std::fs::read_to_string("00_control/cloudflare_edge/worker_vpc_shadow_v3700.js")
        .expect("worker_vpc_shadow_v3700.js");
    for edge_marker in [
        "lowerPath.startsWith(\"/api/v1/sovereign_harmonic/\")",
        "lowerPath.startsWith(\"/api/v1/worksteal/\")",
        "lowerPath === \"/v1/chat/completions\"",
        "lowerPath === \"/api/v1/openai/compat\"",
        "(lowerPath.startsWith(\"/api/v1/unified/\") && lowerPath !== \"/api/v1/unified/catalog\")",
        "(parsedToolNum >= 1 && parsedToolNum <= 404)",
    ] {
        assert!(worker_js.contains(edge_marker), "Missing Edge gate marker: {}", edge_marker);
    }
}

fn build_synthetic_axml_bytes(include_version_code: bool, val_type: u8, val_data: u32) -> Vec<u8> {
    let mut chunks: Vec<u8> = Vec::new();
    // 0x0180 RES_XML_RESOURCE_MAP_TYPE chunk
    let res_ids: Vec<u32> = if include_version_code {
        vec![0x0101_0001, 0x0101_021B]
    } else {
        vec![0x0101_0001]
    };
    let map_sz = (8 + res_ids.len() * 4) as u32;
    chunks.extend_from_slice(&0x0180u16.to_le_bytes());
    chunks.extend_from_slice(&8u16.to_le_bytes());
    chunks.extend_from_slice(&map_sz.to_le_bytes());
    for rid in res_ids {
        chunks.extend_from_slice(&rid.to_le_bytes());
    }
    // 0x0102 RES_XML_START_ELEMENT_TYPE chunk: hdr(16) + ext(20) + 1 attr(20) = 56 bytes
    chunks.extend_from_slice(&0x0102u16.to_le_bytes());
    chunks.extend_from_slice(&16u16.to_le_bytes());
    chunks.extend_from_slice(&56u32.to_le_bytes());
    chunks.extend_from_slice(&1u32.to_le_bytes()); // lineNumber
    chunks.extend_from_slice(&0xFFFF_FFFFu32.to_le_bytes()); // comment
    // ext_base (20 bytes): ns(4), name(4), attrStart(2=20), attrSize(2=20), attrCount(2=1), idIdx(2), classIdx(2), styleIdx(2)
    chunks.extend_from_slice(&0xFFFF_FFFFu32.to_le_bytes());
    chunks.extend_from_slice(&0u32.to_le_bytes());
    chunks.extend_from_slice(&20u16.to_le_bytes());
    chunks.extend_from_slice(&20u16.to_le_bytes());
    chunks.extend_from_slice(&1u16.to_le_bytes());
    chunks.extend_from_slice(&0u16.to_le_bytes());
    chunks.extend_from_slice(&0u16.to_le_bytes());
    chunks.extend_from_slice(&0u16.to_le_bytes());
    // attr[0] (20 bytes): ns(4), nameIdx(4), rawVal(4), size(2=8), res0(1=0), valType(1), valData(4)
    chunks.extend_from_slice(&0xFFFF_FFFFu32.to_le_bytes());
    let name_idx: u32 = if include_version_code { 1 } else { 0 };
    chunks.extend_from_slice(&name_idx.to_le_bytes());
    chunks.extend_from_slice(&0xFFFF_FFFFu32.to_le_bytes());
    chunks.extend_from_slice(&8u16.to_le_bytes());
    chunks.push(0);
    chunks.push(val_type);
    chunks.extend_from_slice(&val_data.to_le_bytes());

    let total_sz = (8 + chunks.len()) as u32;
    let mut axml = Vec::with_capacity(total_sz as usize);
    axml.extend_from_slice(&0x0003u16.to_le_bytes());
    axml.extend_from_slice(&8u16.to_le_bytes());
    axml.extend_from_slice(&total_sz.to_le_bytes());
    axml.extend_from_slice(&chunks);
    axml
}

fn deflate_fixed_huffman_encode(raw: &[u8]) -> Vec<u8> {
    fn push_bits_lsb(out: &mut Vec<u8>, bit_buf: &mut u32, bit_cnt: &mut u8, val: u32, n: u8) {
        *bit_buf |= val << *bit_cnt;
        *bit_cnt += n;
        while *bit_cnt >= 8 {
            out.push((*bit_buf & 0xFF) as u8);
            *bit_buf >>= 8;
            *bit_cnt -= 8;
        }
    }
    fn push_huff_msb(out: &mut Vec<u8>, bit_buf: &mut u32, bit_cnt: &mut u8, code: u32, len: u8) {
        for i in (0..len).rev() {
            push_bits_lsb(out, bit_buf, bit_cnt, (code >> i) & 1, 1);
        }
    }
    let mut out: Vec<u8> = Vec::new();
    let mut bit_buf: u32 = 0;
    let mut bit_cnt: u8 = 0;
    push_bits_lsb(&mut out, &mut bit_buf, &mut bit_cnt, 1, 1); // BFINAL = 1
    push_bits_lsb(&mut out, &mut bit_buf, &mut bit_cnt, 1, 2); // BTYPE = 1 (fixed Huffman)
    for &b in raw {
        if b <= 143 {
            push_huff_msb(&mut out, &mut bit_buf, &mut bit_cnt, 0x30 + (b as u32), 8);
        } else {
            push_huff_msb(&mut out, &mut bit_buf, &mut bit_cnt, 0x190 + ((b as u32) - 144), 9);
        }
    }
    push_huff_msb(&mut out, &mut bit_buf, &mut bit_cnt, 0, 7); // EOB 256
    if bit_cnt > 0 {
        out.push((bit_buf & 0xFF) as u8);
    }
    out
}

fn build_synthetic_zip(entry_name: &[u8], comp_method: u16, comp_data: &[u8], uncomp_size: u32) -> Vec<u8> {
    let mut zip: Vec<u8> = Vec::new();
    let lfh_offset = 0u32;
    // LFH (30 bytes + name)
    zip.extend_from_slice(&0x0403_4B50u32.to_le_bytes());
    zip.extend_from_slice(&20u16.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&comp_method.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u32.to_le_bytes());
    zip.extend_from_slice(&(comp_data.len() as u32).to_le_bytes());
    zip.extend_from_slice(&uncomp_size.to_le_bytes());
    zip.extend_from_slice(&(entry_name.len() as u16).to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(entry_name);
    zip.extend_from_slice(comp_data);

    let cd_offset = zip.len() as u32;
    // CDH (46 bytes + name)
    zip.extend_from_slice(&0x0201_4B50u32.to_le_bytes());
    zip.extend_from_slice(&20u16.to_le_bytes());
    zip.extend_from_slice(&20u16.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&comp_method.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u32.to_le_bytes());
    zip.extend_from_slice(&(comp_data.len() as u32).to_le_bytes());
    zip.extend_from_slice(&uncomp_size.to_le_bytes());
    zip.extend_from_slice(&(entry_name.len() as u16).to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u32.to_le_bytes());
    zip.extend_from_slice(&lfh_offset.to_le_bytes());
    zip.extend_from_slice(entry_name);

    let cd_size = (zip.len() as u32) - cd_offset;
    // EOCD (22 bytes)
    zip.extend_from_slice(&0x0605_4B50u32.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip.extend_from_slice(&1u16.to_le_bytes());
    zip.extend_from_slice(&1u16.to_le_bytes());
    zip.extend_from_slice(&cd_size.to_le_bytes());
    zip.extend_from_slice(&cd_offset.to_le_bytes());
    zip.extend_from_slice(&0u16.to_le_bytes());
    zip
}

#[test]
fn test_v73_2_4_m2_item7_live_apk_version_code_extraction() {
    ensure_repo_root_cwd();

    // 1. Live shipped APK extraction vs build.gradle.kts (dynamic, zero hardcoded versionCode literal)
    let apk_bytes = std::fs::read("04_edge_silicon/ACT-Omega-Pixel10-Sovereign.apk")
        .expect("04_edge_silicon/ACT-Omega-Pixel10-Sovereign.apk");
    let extracted_vc = v73_2_extract_apk_version_code(&apk_bytes)
        .expect("MUST extract live versionCode from shipped APK");
    assert!(extracted_vc > 0);

    let gradle_src = std::fs::read_to_string("04_edge_silicon/pixel10_ndk_app/app/build.gradle.kts")
        .expect("build.gradle.kts");
    let gradle_vc = gradle_src
        .lines()
        .find_map(|l| {
            let t = l.trim();
            t.strip_prefix("versionCode")
                .and_then(|rest| rest.trim().strip_prefix('='))
                .and_then(|num| num.trim().parse::<u32>().ok())
        })
        .expect("versionCode in build.gradle.kts");
    assert_eq!(extracted_vc, gradle_vc, "Extracted APK versionCode must match build.gradle.kts");

    let debug_apk_bytes = std::fs::read("04_edge_silicon/pixel10_ndk_app/app/build/outputs/apk/debug/app-debug.apk")
        .expect("app-debug.apk");
    assert_eq!(v73_2_extract_apk_version_code(&debug_apk_bytes), Some(extracted_vc));

    // 2. Synthetic Stored (comp_method=0), DEFLATE BTYPE=0, and DEFLATE BTYPE=1 (valType 0x10 and 0x11)
    let axml_dec = build_synthetic_axml_bytes(true, 0x10, 912);
    let zip_stored = build_synthetic_zip(b"AndroidManifest.xml", 0, &axml_dec, axml_dec.len() as u32);
    assert_eq!(v73_2_extract_apk_version_code(&zip_stored), Some(912));

    let mut deflate_b0: Vec<u8> = Vec::new();
    let len_u16 = axml_dec.len() as u16;
    deflate_b0.push(0x01); // BFINAL=1, BTYPE=0
    deflate_b0.extend_from_slice(&len_u16.to_le_bytes());
    deflate_b0.extend_from_slice(&(!len_u16).to_le_bytes());
    deflate_b0.extend_from_slice(&axml_dec);
    let zip_b0 = build_synthetic_zip(b"AndroidManifest.xml", 8, &deflate_b0, axml_dec.len() as u32);
    assert_eq!(v73_2_extract_apk_version_code(&zip_b0), Some(912));

    let axml_hex = build_synthetic_axml_bytes(true, 0x11, 1337);
    let deflate_b1 = deflate_fixed_huffman_encode(&axml_hex);
    let zip_b1 = build_synthetic_zip(b"AndroidManifest.xml", 8, &deflate_b1, axml_hex.len() as u32);
    assert_eq!(v73_2_extract_apk_version_code(&zip_b1), Some(1337));

    // 3. Fail-closed negative cases (must return None)
    assert_eq!(v73_2_extract_apk_version_code(&Vec::new()), None);
    assert_eq!(v73_2_extract_apk_version_code(&b"NOT_A_ZIP_FILE_AT_ALL_12345".to_vec()), None);
    let trunc = apk_bytes[..apk_bytes.len() / 2].to_vec();
    assert_eq!(v73_2_extract_apk_version_code(&trunc), None);
    let zip_no_manifest = build_synthetic_zip(b"classes.dex", 0, &axml_dec, axml_dec.len() as u32);
    assert_eq!(v73_2_extract_apk_version_code(&zip_no_manifest), None);
    let corrupt_deflate = vec![0x07u8, 0xFF, 0x00]; // BTYPE=3 reserved
    let zip_bad_deflate = build_synthetic_zip(b"AndroidManifest.xml", 8, &corrupt_deflate, axml_dec.len() as u32);
    assert_eq!(v73_2_extract_apk_version_code(&zip_bad_deflate), None);
    let axml_no_vc = build_synthetic_axml_bytes(false, 0x10, 42);
    let zip_no_vc = build_synthetic_zip(b"AndroidManifest.xml", 0, &axml_no_vc, axml_no_vc.len() as u32);
    assert_eq!(v73_2_extract_apk_version_code(&zip_no_vc), None);

    // 4. Source invariants
    let bin_src = std::fs::read_to_string("01_l0_rust/src/bin/v31_swarm.rs").expect("bin/v31_swarm.rs");
    let lib_src = std::fs::read_to_string("01_l0_rust/src/v31_swarm.rs").expect("src/v31_swarm.rs");
    assert_eq!(bin_src, lib_src);
    assert!(!bin_src.contains("\"version_code\":75"), "Hardcoded version_code 75 MUST be purged");
    assert!(bin_src.contains("v73_2_extract_apk_version_code"));
    let v73_2_src = std::fs::read_to_string("01_l0_rust/src/v73_2_cloudflare_vpc_mesh_and_pgwire_hyperdrive.rs")
        .expect("v73_2 source");
    assert!(!v73_2_src.contains('[') && !v73_2_src.contains(']'), "v73_2 MUST remain strictly zero-bracket");
}

#[test]
fn test_v73_2_4_m2_item8_live_d1_11_table_parser_and_rs_clean() {
    ensure_repo_root_cwd();

    // 1. Live wrangler verification receipt parsing
    assert_eq!(
        v73_2_read_live_d1_database_name().as_deref(),
        Some("act_omega_d1_vault_v7322")
    );
    let (cnt_opt, tables) = v73_2_read_live_d1_user_tables();
    assert_eq!(cnt_opt, Some(11));
    assert_eq!(
        tables,
        vec![
            "edge_cluster_metadata",
            "harness_5w1h_audit_log",
            "npage_tier_snapshots",
            "v40_qat_training_sessions",
            "v40_shard_registry",
            "v41_measured_sha256_audit",
            "v42_5w1h_distributed_routes",
            "v43_antigravity_agent_roster",
            "v44_multiturn_working_memory_ring",
            "v44_visiting_llm_agent_ledger",
            "wal_merkle_checkpoints",
        ]
    );
    assert!(!tables.iter().any(|t| t.starts_with("_cf_") || t.starts_with("sqlite_")));

    // 2. Fail-closed parsing on empty, corrupt, success=false, or system-only inputs
    assert_eq!(v73_2_parse_d1_user_tables_from_receipt_str(""), (None, Vec::new()));
    assert_eq!(
        v73_2_parse_d1_user_tables_from_receipt_str("SELECT name, type FROM sqlite_master\nnot_json\n"),
        (None, Vec::new())
    );
    assert_eq!(
        v73_2_parse_d1_user_tables_from_receipt_str(
            "SELECT name, type FROM sqlite_master\n[{\"results\":[{\"name\":\"harness_5w1h_audit_log\",\"type\":\"table\"}],\"success\":false}]\n"
        ),
        (None, Vec::new())
    );
    assert_eq!(
        v73_2_parse_d1_user_tables_from_receipt_str(
            "SELECT name, type FROM sqlite_master\n[{\"results\":[{\"name\":\"_cf_KV\",\"type\":\"table\"},{\"name\":\"sqlite_sequence\",\"type\":\"table\"}],\"success\":true}]\n"
        ),
        (None, Vec::new())
    );

    // 3. Strict MCP resources/read D1 URI matching (reject retired act_omega_d1_vault & arbitrary URIs)
    let (retired_mime, retired_body) = act_omega_l0_core::v61_gemma4_multimodal_ple_speculative_cascade_and_mcp_suite::v61_read_resource_metadata(
        "manifold://d1/act_omega_d1_vault",
    );
    assert_eq!(retired_mime, "application/json");
    assert!(
        retired_body.contains("\"status\":\"NOT_FOUND\""),
        "Retired manifold://d1/act_omega_d1_vault MUST return NOT_FOUND: {}",
        retired_body
    );
    assert!(
        !retired_body.contains("LIVE_MEASURED") && !retired_body.contains("act_omega_d1_vault_v7322"),
        "Retired D1 URI must not return LIVE_MEASURED or leak live DB metadata: {}",
        retired_body
    );

    let (arb_mime, arb_body) = act_omega_l0_core::v61_gemma4_multimodal_ple_speculative_cascade_and_mcp_suite::v61_read_resource_metadata(
        "manifold://d1/arbitrary_db",
    );
    assert_eq!(arb_mime, "application/json");
    assert!(arb_body.contains("\"status\":\"NOT_FOUND\""));

    let (live_mime, live_body) = act_omega_l0_core::v61_gemma4_multimodal_ple_speculative_cascade_and_mcp_suite::v61_read_resource_metadata(
        "manifold://d1/act_omega_d1_vault_v7322",
    );
    assert_eq!(live_mime, "application/json");
    assert!(
        live_body.contains("\"status\":\"LIVE_MEASURED\"")
            && live_body.contains("\"database_name\":\"act_omega_d1_vault_v7322\"")
            && live_body.contains("\"tables_count\":11"),
        "Live manifold://d1/act_omega_d1_vault_v7322 MUST return LIVE_MEASURED with tables_count=11: {}",
        live_body
    );
}

#[test]
fn test_v73_2_4_m3_item10_persistent_monotonic_sh_xi_turn_counters() {
    ensure_repo_root_cwd();
    let _rw_guard = RW_EVAL500_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_guard = SH_XI_TURN_COUNTER_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let turn_reload_on_drop = ShXiTurnCounterReloadGuard::new("m3_item10");
    let _restore = guard_paths(&[
        "03_vault/connectome/sh_xi_rw_eval_500_sealed.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_rw_eval_500_sealed.jsonl",
    ]);

    let live_c_before = std::fs::read(C_SH_XI_SESSION_COUNTERS_PATH).ok();
    let live_e_before = if std::path::Path::new("E:\\").exists() {
        std::fs::read(E_SH_XI_SESSION_COUNTERS_PATH).ok()
    } else {
        None
    };

    v72_2_reload_turn_counters_from_disk_for_test();
    v72_2_clear_session_history_for_test();

    // 1. Dynamic disk seeding helper: missing dirs -> 0 / empty, real tool_361_* JSONs -> exact count
    let tmp_seed = std::env::temp_dir().join(format!("act_omega_m3_seed_test_{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&tmp_seed);
    let empty_seed = v72_2_seed_counters_from_historical_tool_361_at(
        &tmp_seed.join("nonexistent_e").to_string_lossy(),
        &tmp_seed.join("nonexistent_c").to_string_lossy(),
    );
    assert_eq!(empty_seed.global_turn_seq, 0);
    assert_eq!(empty_seed.historical_seeded_total, 0);
    assert!(empty_seed.sessions.is_empty());

    let seed_e = tmp_seed.join("e_out");
    let seed_c = tmp_seed.join("c_out");
    std::fs::create_dir_all(&seed_e).expect("seed_e dir");
    std::fs::create_dir_all(&seed_c).expect("seed_c dir");
    std::fs::write(
        seed_e.join("tool_361_1.json"),
        r#"{"engine":"SH_XI_3SHELL_MATRYOSHKA_SPARSE_MOE_SFT_CONVERSE_ENGINE","session_id":"sess_alpha","session_turn_count":1}"#,
    ).expect("write seed 1");
    std::fs::write(
        seed_e.join("tool_361_2.json"),
        r#"{"engine":"SH_XI_3SHELL_MATRYOSHKA_SPARSE_MOE_SFT_CONVERSE_ENGINE","session_id":"stateless","session_turn_count":1}"#,
    ).expect("write seed 2");
    std::fs::write(
        seed_c.join("tool_361_3.json"),
        r#"{"engine":"OTHER_ENGINE","session_id":"sess_alpha","session_turn_count":99}"#,
    ).expect("write seed 3");
    let pop_seed = v72_2_seed_counters_from_historical_tool_361_at(
        &seed_e.to_string_lossy(),
        &seed_c.to_string_lossy(),
    );
    assert_eq!(pop_seed.global_turn_seq, 2);
    assert_eq!(pop_seed.historical_seeded_total, 2);
    assert_eq!(pop_seed.sessions.get("sess_alpha").copied(), Some(1));
    assert!(!pop_seed.sessions.contains_key("stateless"));
    let _ = std::fs::remove_dir_all(&tmp_seed);

    // 2. Sequential 12-turn progression crossing #8 -> 9, 10, 11, 12 while ChatML sliding window stays capped at 16 msgs
    let sid = "test_m3_item10_primary_session";
    let (init_global, _, _) = v72_2_get_turn_counters_snapshot();
    let mut prev_global = init_global;

    for turn_idx in 1..=12usize {
        let reset = turn_idx == 1;
        let res = v72_2_converse_execute_full_with_params(
            &format!("Turn {} query on E8 lattice and 84480 neurons.", turn_idx),
            None,
            Some(sid),
            &Vec::new(),
            reset,
            Some(12),
            Some(0.0),
        );
        assert_eq!(res.session_id, sid);
        assert_eq!(
            res.session_turn_count, turn_idx,
            "Turn {} MUST have monotonic session_turn_count == {} (no #8 cap!)",
            turn_idx, turn_idx
        );
        assert_eq!(
            res.global_turn_seq,
            prev_global + 1,
            "global_turn_seq must advance strictly by +1 on turn {}",
            turn_idx
        );
        prev_global = res.global_turn_seq;
    }

    // Sliding window remains capped at V72_2_MULTITURN_MAX_TURNS * 2 = 16 messages (thm_v72_2_987)
    let hist = v72_2_get_session_turns(sid);
    assert_eq!(
        hist.len(),
        16,
        "ChatML sliding window MUST stay capped at 16 messages (8 exchanges) after 12 turns"
    );

    // 3. Simulated daemon restart / hot-swap persistence: clear both RAM stores and continue with Turns 13, 14
    let c_bytes_before = std::fs::read(&turn_reload_on_drop.c_path).expect("read isolated C ledger");
    if std::path::Path::new("E:\\").exists() {
        let e_bytes_before = std::fs::read(&turn_reload_on_drop.e_path).expect("read isolated E ledger");
        assert_eq!(c_bytes_before, e_bytes_before, "Isolated C: and E: ledger JSONs must match identically");
    }
    if let Some(ref before) = live_c_before {
        let live_c_after = std::fs::read(C_SH_XI_SESSION_COUNTERS_PATH).ok();
        assert_eq!(Some(before), live_c_after.as_ref(), "cargo test MUST NOT mutate live C: counter ledger");
    }
    if let Some(ref before_e) = live_e_before {
        let live_e_after = std::fs::read(E_SH_XI_SESSION_COUNTERS_PATH).ok();
        assert_eq!(Some(before_e), live_e_after.as_ref(), "cargo test MUST NOT mutate live E: counter ledger");
    }

    v72_2_reload_turn_counters_from_disk_for_test();
    v72_2_clear_session_history_for_test();

    for turn_idx in 13..=14usize {
        let route_raw = v72_2_dispatch_converse_route(&format!(
            "{{\"prompt\":\"Post-restart turn {} on sovereign manifold.\",\"session_id\":\"{}\",\"reset_session\":false,\"max_tokens\":12,\"temperature\":0.0}}",
            turn_idx, sid
        ));
        let val: serde_json::Value = serde_json::from_str(&route_raw).expect("valid converse JSON");
        assert_eq!(val.get("session_id").and_then(|v| v.as_str()), Some(sid));
        assert_eq!(
            val.get("session_turn_count").and_then(|v| v.as_u64()),
            Some(turn_idx as u64),
            "Post-reload turn {} MUST NOT reset to #1/#2!",
            turn_idx
        );
        assert_eq!(
            val.get("global_turn_seq").and_then(|v| v.as_u64()),
            Some((prev_global + 1) as u64),
            "Post-reload global_turn_seq must continue monotonically"
        );
        prev_global += 1;
    }

    // 4. Isolated reset_session=true resets ONLY the target session while primary session & global_turn_seq persist
    let iso_sid = "test_m3_item10_isolated_reset";
    let iso1 = v72_2_converse_execute_full_with_params(
        "Isolated reset turn 1.",
        None,
        Some(iso_sid),
        &Vec::new(),
        true,
        Some(12),
        Some(0.0),
    );
    assert_eq!(iso1.session_turn_count, 1);
    assert_eq!(iso1.global_turn_seq, prev_global + 1);
    prev_global = iso1.global_turn_seq;

    let iso2 = v72_2_converse_execute_full_with_params(
        "Isolated reset turn 2.",
        None,
        Some(iso_sid),
        &Vec::new(),
        false,
        Some(12),
        Some(0.0),
    );
    assert_eq!(iso2.session_turn_count, 2);
    assert_eq!(iso2.global_turn_seq, prev_global + 1);
    prev_global = iso2.global_turn_seq;

    let iso3_reset = v72_2_converse_execute_full_with_params(
        "Isolated explicit reset to turn 1.",
        None,
        Some(iso_sid),
        &Vec::new(),
        true,
        Some(12),
        Some(0.0),
    );
    assert_eq!(iso3_reset.session_turn_count, 1);
    assert_eq!(iso3_reset.global_turn_seq, prev_global + 1);
    prev_global = iso3_reset.global_turn_seq;

    // Primary session continues cleanly at 15 (unaffected by isolated reset)
    let pri15 = v72_2_converse_execute_full_with_params(
        "Primary session turn 15 after isolated reset.",
        None,
        Some(sid),
        &Vec::new(),
        false,
        Some(12),
        Some(0.0),
    );
    assert_eq!(pri15.session_turn_count, 15);
    assert_eq!(pri15.global_turn_seq, prev_global + 1);

    // 5. Source invariants: 0 square brackets in v72_2 and bin/v31_swarm.rs === src/v31_swarm.rs
    let v72_2_src = std::fs::read_to_string("01_l0_rust/src/v72_2_sh_xi_sparse_moe_chatml_sft_and_rag.rs")
        .expect("read v72_2");
    assert!(!v72_2_src.contains('[') && !v72_2_src.contains(']'), "v72_2 MUST have 0 square brackets");
    let bin_src = std::fs::read_to_string("01_l0_rust/src/bin/v31_swarm.rs").expect("bin/v31_swarm.rs");
    let lib_src = std::fs::read_to_string("01_l0_rust/src/v31_swarm.rs").expect("src/v31_swarm.rs");
    assert_eq!(bin_src, lib_src, "bin/v31_swarm.rs and src/v31_swarm.rs MUST be identical");
}

#[test]
fn test_v73_2_5_nf10b_stateless_monotonic_turn_counters() {
    ensure_repo_root_cwd();
    let _rw_guard = RW_EVAL500_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_guard = SH_XI_TURN_COUNTER_GUARD.lock().unwrap_or_else(|e| e.into_inner());
    let _turn_reload_on_drop = ShXiTurnCounterReloadGuard::new("nf10b_stateless");
    let _restore = guard_paths(&[
        "03_vault/connectome/sh_xi_rw_eval_500_sealed.jsonl",
        "E:\\Sovereign_Manifold_SSD_Vault\\connectome\\sh_xi_rw_eval_500_sealed.jsonl",
    ]);

    let live_c_before = std::fs::read(C_SH_XI_SESSION_COUNTERS_PATH).ok();
    let live_e_before = if std::path::Path::new("E:\\").exists() {
        std::fs::read(E_SH_XI_SESSION_COUNTERS_PATH).ok()
    } else {
        None
    };

    v72_2_reload_turn_counters_from_disk_for_test();
    v72_2_clear_session_history_for_test();

    let (init_global, _, _) = v72_2_get_turn_counters_snapshot();
    let mut prev_global = init_global;

    // 1. 10 sequential stateless calls alternating None, Some(""), Some("   ") -> crosses >8 turns
    let stateless_sids: [Option<&str>; 3] = [None, Some(""), Some("   ")];
    for turn_idx in 1..=10usize {
        let sid_opt = stateless_sids[(turn_idx - 1) % 3];
        let res = v72_2_converse_execute_full_with_params(
            &format!("Stateless turn {} query on E8 lattice.", turn_idx),
            None,
            sid_opt,
            &Vec::new(),
            false,
            Some(12),
            Some(0.0),
        );
        assert_eq!(res.session_id, "stateless");
        assert_eq!(
            res.session_turn_count, turn_idx,
            "Stateless turn {} MUST increment monotonically without capping at 1 or 8",
            turn_idx
        );
        assert_eq!(res.global_turn_seq, prev_global + 1);
        prev_global = res.global_turn_seq;
    }

    // 2. Turns 11 & 12 with non-empty explicit_messages MUST ignore prior_turns.len() / 2 and continue 11, 12
    let explicit_2 = vec![
        V72_2ChatTurn {
            role: String::from("user"),
            content: String::from("Earlier question 1."),
        },
        V72_2ChatTurn {
            role: String::from("assistant"),
            content: String::from("Earlier answer 1."),
        },
        V72_2ChatTurn {
            role: String::from("user"),
            content: String::from("Turn 11 explicit stateless query."),
        },
    ];
    let res11 = v72_2_converse_execute_full_with_params(
        "",
        None,
        None,
        &explicit_2,
        false,
        Some(12),
        Some(0.0),
    );
    assert_eq!(res11.session_id, "stateless");
    assert_eq!(res11.session_turn_count, 11);
    assert_eq!(res11.global_turn_seq, prev_global + 1);
    prev_global = res11.global_turn_seq;

    let explicit_6 = vec![
        V72_2ChatTurn { role: String::from("user"), content: String::from("U1") },
        V72_2ChatTurn { role: String::from("assistant"), content: String::from("A1") },
        V72_2ChatTurn { role: String::from("user"), content: String::from("U2") },
        V72_2ChatTurn { role: String::from("assistant"), content: String::from("A2") },
        V72_2ChatTurn { role: String::from("user"), content: String::from("U3") },
        V72_2ChatTurn { role: String::from("assistant"), content: String::from("A3") },
        V72_2ChatTurn { role: String::from("user"), content: String::from("Turn 12 explicit stateless query.") },
    ];
    let res12 = v72_2_converse_execute_full_with_params(
        "",
        None,
        Some(""),
        &explicit_6,
        false,
        Some(12),
        Some(0.0),
    );
    assert_eq!(res12.session_id, "stateless");
    assert_eq!(res12.session_turn_count, 12);
    assert_eq!(res12.global_turn_seq, prev_global + 1);
    prev_global = res12.global_turn_seq;

    let (_, _, snap_sessions) = v72_2_get_turn_counters_snapshot();
    assert_eq!(snap_sessions.get("__stateless_default__").copied(), Some(12));
    assert!(!snap_sessions.contains_key("stateless"));
    assert!(v72_2_get_session_turns("stateless").is_empty());
    assert!(v72_2_get_session_turns("__stateless_default__").is_empty());

    // 3. Reload from isolated disk and execute Turn 13 via dispatch route
    v72_2_reload_turn_counters_from_disk_for_test();
    v72_2_clear_session_history_for_test();
    let route_raw = v72_2_dispatch_converse_route(
        "{\"prompt\":\"Post-reload stateless turn 13.\",\"session_id\":\"\",\"max_tokens\":12,\"temperature\":0.0}",
    );
    let val: serde_json::Value = serde_json::from_str(&route_raw).expect("valid converse JSON");
    assert_eq!(val.get("session_id").and_then(|v| v.as_str()), Some("stateless"));
    assert_eq!(val.get("session_turn_count").and_then(|v| v.as_u64()), Some(13));
    assert_eq!(val.get("global_turn_seq").and_then(|v| v.as_u64()), Some((prev_global + 1) as u64));
    prev_global += 1;

    // 4. reset_session=true resets __stateless_default__ to 1, then next turn advances to 2
    let reset1 = v72_2_converse_execute_full_with_params(
        "Reset stateless turn 1.",
        None,
        None,
        &Vec::new(),
        true,
        Some(12),
        Some(0.0),
    );
    assert_eq!(reset1.session_id, "stateless");
    assert_eq!(reset1.session_turn_count, 1);
    assert_eq!(reset1.global_turn_seq, prev_global + 1);
    prev_global = reset1.global_turn_seq;

    let next2 = v72_2_converse_execute_full_with_params(
        "Post-reset stateless turn 2.",
        None,
        Some("   "),
        &Vec::new(),
        false,
        Some(12),
        Some(0.0),
    );
    assert_eq!(next2.session_id, "stateless");
    assert_eq!(next2.session_turn_count, 2);
    assert_eq!(next2.global_turn_seq, prev_global + 1);

    if let Some(ref before) = live_c_before {
        let live_c_after = std::fs::read(C_SH_XI_SESSION_COUNTERS_PATH).ok();
        assert_eq!(Some(before), live_c_after.as_ref(), "cargo test MUST NOT mutate live C: counter ledger");
    }
    if let Some(ref before_e) = live_e_before {
        let live_e_after = std::fs::read(E_SH_XI_SESSION_COUNTERS_PATH).ok();
        assert_eq!(Some(before_e), live_e_after.as_ref(), "cargo test MUST NOT mutate live E: counter ledger");
    }

    let v72_2_src = std::fs::read_to_string("01_l0_rust/src/v72_2_sh_xi_sparse_moe_chatml_sft_and_rag.rs")
        .expect("read v72_2");
    assert!(!v72_2_src.contains('[') && !v72_2_src.contains(']'), "v72_2 MUST have 0 square brackets");
    let fn_start = v72_2_src.find("pub fn v72_2_advance_turn_counters(").expect("advance fn");
    let fn_end = v72_2_src[fn_start..].find("pub fn v72_2_reload_turn_counters_from_disk_for_test(").expect("advance fn end") + fn_start;
    let advance_fn = &v72_2_src[fn_start..fn_end];
    assert!(
        !advance_fn.contains("/ 2") && !advance_fn.contains("/2"),
        "v72_2_advance_turn_counters MUST NOT divide by 2"
    );
}

#[test]
fn test_v73_2_5_m1_tool287_telemetry_and_v40_markers() {
    ensure_repo_root_cwd();
    let bin_src = std::fs::read_to_string("01_l0_rust/src/bin/v31_swarm.rs").expect("bin/v31_swarm.rs");
    let lib_src = std::fs::read_to_string("01_l0_rust/src/v31_swarm.rs").expect("src/v31_swarm.rs");
    assert_eq!(bin_src, lib_src, "bin/v31_swarm.rs and src/v31_swarm.rs MUST remain 1:1 identical");

    let norm = bin_src.replace("\r\n", "\n");
    // Item #3: /api/v1/tool/287 routing + VESPER ARACHNE IK diag parity
    assert!(
        norm.contains("|| clean_path == \"/api/v1/tools/t287\"\n            || clean_path == \"/api/v1/tool/287\""),
        "chain135 dispatch MUST route /api/v1/tool/287 to v62_measure_vesper_arachne_e8_ik_and_click_through"
    );
    assert!(
        norm.contains("clean_path.contains(\"vesper_arachne\")\n                    || clean_path == \"/api/v1/tools/t287\"\n                    || clean_path == \"/api/v1/tool/287\""),
        "last_card_diag MUST tag /api/v1/tools/t287 and /api/v1/tool/287 as VESPER ARACHNE IK"
    );

    // Item #8: /api/v1/telemetry emits release_version and d1_tables_synced dynamically
    let telem_start = norm.find("if clean_path == \"/api/v1/telemetry\"").expect("telemetry branch");
    let telem_end = norm[telem_start..].find("if clean_path == \"/api/v1/sector/inspect\"").expect("telemetry end") + telem_start;
    let telem_block = &norm[telem_start..telem_end];
    assert!(telem_block.contains("v73_2_read_live_d1_user_tables()"));
    assert!(telem_block.contains("v73_2_read_live_release_version()"));
    assert!(telem_block.contains("\\\"release_version\\\":\\\"{}\\\""));
    assert!(telem_block.contains("\\\"d1_tables_synced\\\":{}"));

    // Dynamic helpers sanity check
    let live_ver = v73_2_read_live_release_version();
    assert!(!live_ver.is_empty() && live_ver != "UNMEASURED/OFFLINE");
    let (d1_cnt, d1_tables) = v73_2_read_live_d1_user_tables();
    assert_eq!(d1_cnt, Some(d1_tables.len()));
    assert!(d1_tables.len() >= 11);

    // Item #9: v40 historical comment & zero brackets
    let v40_src = std::fs::read_to_string("01_l0_rust/src/v40_omni_introspect_21120_shards_qat10.rs")
        .expect("v40 source");
    assert!(!v40_src.contains('[') && !v40_src.contains(']'), "v40 MUST have 0 square brackets");
    assert!(
        v40_src.contains("sync_d1_v4400_all10tables.sql\") // HISTORICAL_PRE_V7322:"),
        "v40 line 75 MUST carry HISTORICAL_PRE_V7322 annotation"
    );
}
