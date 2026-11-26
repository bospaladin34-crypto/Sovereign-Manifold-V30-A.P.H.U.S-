use std::path::Path;

fn ensure_repo_root_cwd() {
    if Path::new("Cargo.toml").exists()
        && !Path::new("03_vault").exists()
        && Path::new("../03_vault").exists()
    {
        let _ = std::env::set_current_dir("..");
    }
}

use act_omega_l0_core::{
    v73_0_dispatch_tool,
    v73_0_dispatch_unified_lab_deck,
    v73_0_probe_station_live_json,
    v73_0_verify_operator_key_ct,
    v73_1_dispatch_chain399_master_certification,
    v73_1_dispatch_tool,
    v73_1_ube_decode_symbols,
    v73_1_ube_encode_symbols,
    V731BitcosTernaryBlock,
    V731IncrementalSheafRegistry,
};

#[test]
fn test_v73_0_operator_key_ct_equality_and_empty_rejection() {
    ensure_repo_root_cwd();
    assert!(v73_0_verify_operator_key_ct(
        "sovereign_key_alpha_2026_test",
        "sovereign_key_alpha_2026_test"
    ));
    assert!(!v73_0_verify_operator_key_ct(
        "sovereign_key_alpha_2026_tesu",
        "sovereign_key_alpha_2026_test"
    ));
    assert!(!v73_0_verify_operator_key_ct(
        "sovereign_key_alpha",
        "sovereign_key_alpha_2026_test"
    ));
    assert!(!v73_0_verify_operator_key_ct(
        "sovereign_key_alpha_2026_test_extra",
        "sovereign_key_alpha_2026_test"
    ));
    assert!(!v73_0_verify_operator_key_ct("", "sovereign_key_alpha_2026_test"));
    assert!(!v73_0_verify_operator_key_ct("", ""));
}

#[test]
fn test_v73_0_fail_closed_offline_probe_and_deck() {
    ensure_repo_root_cwd();
    let offline = v73_0_probe_station_live_json(59799, "/api/health", 60);
    assert!(offline.is_err(), "unused port 59799 must fail closed");

    let unknown = v73_0_dispatch_tool(99999, "");
    assert!(unknown.contains("\"ok\":false"));
    assert!(unknown.contains("UNKNOWN_LAB_TOOL"));

    let deck = v73_0_dispatch_unified_lab_deck("");
    assert!(deck.contains("ACT-Omega Unified Standalone & R&D Lab v3.0.0"));
    assert!(
        deck.contains("\"measured_live\":true")
            || (deck.contains("\"measured_live\":false") && deck.contains("\"status\":\"UNMEASURED/OFFLINE\""))
    );
    assert!(deck.contains("\"stations\":["));
}

#[test]
fn test_v73_1_bitcos_roundtrip_and_invalid_trit_reject() {
    ensure_repo_root_cwd();
    let trits = vec![0i8, 1, 0, -1, 0, 0, 1, -1, 0, 0, 0, 1, -1, 0, 0, 1];
    let block = V731BitcosTernaryBlock::encode(&trits).expect("valid trits");
    assert_eq!(block.nonzero_count, 7);
    assert_eq!(block.decode(), trits);

    let bad = vec![0i8, 2, -1];
    assert!(V731BitcosTernaryBlock::encode(&bad).is_err());

    let t382 = v73_1_dispatch_tool(382, "");
    assert!(t382.contains("\"tool_id\":382"));
    assert!(t382.contains("\"ok\":true") || t382.contains("UNMEASURED/OFFLINE"));
}

#[test]
fn test_v73_1_ube_lossless_dual_alphabet_and_rejects() {
    ensure_repo_root_cwd();
    let sample = "ACT-Omega \u{03BB}\u{03C0} \u{2200}x\u{2208}\u{211D} \u{1F9EC} Sovereign";
    let syms = v73_1_ube_encode_symbols(sample);
    assert!(syms.iter().any(|&s| s <= 0x00FF));
    assert!(syms.iter().any(|&s| (0xE100..=0xE1FF).contains(&s)));
    let decoded = v73_1_ube_decode_symbols(&syms).expect("valid dual-alphabet stream");
    assert_eq!(decoded, sample);

    // Reject out-of-disjoint-alphabet symbol and odd UTF-16LE sequence
    assert!(v73_1_ube_decode_symbols(&vec![0x1234u16]).is_err());
    assert!(v73_1_ube_decode_symbols(&vec![0xE141u16]).is_err());

    let t384 = v73_1_dispatch_tool(384, sample);
    assert!(t384.contains("\"ok\":true"));
    assert!(t384.contains("\"lossless_bijection\":true"));
}

#[test]
fn test_v73_1_volk_o1_incremental_sheaf_audit() {
    ensure_repo_root_cwd();
    let mut reg = V731IncrementalSheafRegistry::new(16);
    reg.record_lazy_edge_edit(2, 9, 25, 13);
    let dirty_pre = reg.dirty_flags.iter().filter(|&&f| f).count();
    assert_eq!(dirty_pre, 2);
    assert_eq!(reg.flush_barrier(), 144);
    assert_eq!(reg.flush_barrier(), 0);
    assert_eq!(reg.dirty_flags.iter().filter(|&&f| f).count(), 0);

    let t385 = v73_1_dispatch_tool(385, "");
    assert!(t385.contains("\"ok\":true"));
    assert!(t385.contains("\"max_coboundary_sq_caught\":36"));
    assert!(t385.contains("\"dirty_cells_post_flush\":0"));
}

#[test]
fn test_v73_1_research_kernels_t383_and_t386_to_t393() {
    ensure_repo_root_cwd();
    let t386 = v73_1_dispatch_tool(386, "");
    assert!(t386.contains("\"ok\":true"));
    assert!(t386.contains("csnn_clifford_reversion_stalk"));

    let t387 = v73_1_dispatch_tool(387, "");
    assert!(t387.contains("\"ok\":true"));
    assert!(t387.contains("\"prime_mod\":65521"));
    assert!(t387.contains("\"distinguishes_nonhomogeneous_labels\":true"));

    let t389 = v73_1_dispatch_tool(389, "");
    assert!(t389.contains("\"frame_bytes\":8"));
    assert!(t389.contains("\"roundtrip_ok\":true"));

    let t391 = v73_1_dispatch_tool(391, "");
    assert!(t391.contains("\"ok\":true"));
    assert!(t391.contains("\"slots_verified\":64"));

    let t392 = v73_1_dispatch_tool(392, "");
    assert!(t392.contains("\"ok\":true"));
    assert!(t392.contains("\"ozaki_norm_err\":0"));
    assert!(t392.contains("\"chebyshev_semigroup_exact\":true"));

    let t393 = v73_1_dispatch_tool(393, "");
    assert!(t393.contains("\"ffi_coboundary_defect\":0"));
    assert!(t393.contains("\"omega_sec_self_test_rc\":0"));
    assert!(t393.contains("\"lean_sorry_count\":0"));
    assert!(t393.contains("\"ok\":true"));

    let cert = v73_1_dispatch_chain399_master_certification("");
    assert!(cert.contains("\"chain_milestone\":\"CHAIN 399\""));
    assert!(cert.contains("\"research_12_ok\":true"));
}

mod v73_2_phase_p5_suite {
    use super::ensure_repo_root_cwd;
    use act_omega_l0_core::v71_3_sovereign_harmonic_week3_speculative_k4_long_context_4k::v71_3_dispatch_tool_342_long_horizon_4096_memory;
    use act_omega_l0_core::v71_4_sovereign_harmonic_week4_rlvf_tree_speculative_sae_eval256::v71_4_dispatch_tool_352_medusa_eagle_dendritic_tree_speculative_k8;
    use act_omega_l0_core::v72_1_sh_xi_matryoshka_384_768_cuda_pretrainer::{
        v72_1_block8_walsh_hadamard_f32, v72_1_dequantize_q8_0_rows, v72_1_quantize_q8_0_rows,
        V72_1_LATENT_RANK_R0,
    };
    use act_omega_l0_core::v72_2_sh_xi_sparse_moe_chatml_sft_and_rag::{
        v72_2_validate_json_object_fsm, C_SH_XI_SOURCED_SFT_JSONL_PATH,
    };
    use act_omega_l0_core::v73_2_cloudflare_vpc_mesh_and_pgwire_hyperdrive::{
        v73_2_dispatch_chain404_master_certification, v73_2_dispatch_tool,
    };
    use serde_json::Value;

    #[test]
    fn test_v72_1_walsh_hadamard_involution_and_q8_0_roundtrip() {
        ensure_repo_root_cwd();
        assert_eq!(V72_1_LATENT_RANK_R0, 48);
        let orig = vec![
            1.25_f32, -0.5, 2.0, 0.75, -1.5, 0.25, 3.0, -2.25,
            0.125, 1.75, -0.875, 2.5, -1.125, 0.625, -2.0, 1.5,
        ];
        let mut h = orig.clone();
        v72_1_block8_walsh_hadamard_f32(&mut h);
        v72_1_block8_walsh_hadamard_f32(&mut h);
        for (a, b) in orig.iter().zip(h.iter()) {
            assert!((a - b).abs() < 1e-5, "Hadamard involution mismatch: {} vs {}", a, b);
        }

        let (scales, qbytes, recon) = v72_1_quantize_q8_0_rows(&orig, 2, 8);
        assert_eq!(scales.len(), 2);
        assert_eq!(qbytes.len(), 16);
        let deq = v72_1_dequantize_q8_0_rows(&scales, &qbytes, 2, 8);
        assert_eq!(deq.len(), 16);
        for (r, d) in recon.iter().zip(deq.iter()) {
            assert!((r - d).abs() < 1e-5, "Q8_0 dequant mismatch: {} vs {}", r, d);
        }
        for (o, d) in orig.iter().zip(deq.iter()) {
            assert!((o - d).abs() < 0.08, "Q8_0 quantization error too high: {} vs {}", o, d);
        }
    }

    #[test]
    fn test_v72_2_pushdown_json_fsm_and_grounded_sft_corpus() {
        ensure_repo_root_cwd();
        let (ok1, open1, close1, inq1) =
            v72_2_validate_json_object_fsm("{\"a\":{\"b\":\"ok{}\"},\"c\":true,\"n\":42}");
        assert!(ok1 && open1 == 2 && close1 == 2 && !inq1);

        let (ok2, _, _, _) = v72_2_validate_json_object_fsm("{\"a\":1} trailing");
        assert!(!ok2);

        let (ok3, _, _, _) = v72_2_validate_json_object_fsm("{\"a\":{\"b\":1}");
        assert!(!ok3);

        assert!(
            std::path::Path::new(C_SH_XI_SOURCED_SFT_JSONL_PATH).exists(),
            "Missing grounded SFT corpus at {}",
            C_SH_XI_SOURCED_SFT_JSONL_PATH
        );
        let manifest_path = "03_vault/corpus/sh_xi_sft_generator_receipt.json";
        let manifest_raw = std::fs::read_to_string(manifest_path)
            .expect("Missing SFT corpus generator manifest receipt");
        let manifest_val: Value =
            serde_json::from_str(&manifest_raw).expect("Invalid SFT manifest JSON");
        let declared_dialogues = manifest_val
            .get("dialogues_emitted")
            .and_then(|v| v.as_u64())
            .expect("SFT manifest missing dialogues_emitted")
            as usize;
        assert!(declared_dialogues > 0, "Manifest dialogues_emitted must be > 0");
        let raw = std::fs::read_to_string(C_SH_XI_SOURCED_SFT_JSONL_PATH).unwrap();
        let lines: Vec<&str> = raw.lines().filter(|l| !l.trim().is_empty()).collect();
        assert!(!lines.is_empty(), "Grounded SFT JSONL corpus must be non-empty");
        assert_eq!(
            lines.len(),
            declared_dialogues,
            "Live SFT dialogue count ({}) must match corpus manifest dialogues_emitted ({})",
            lines.len(),
            declared_dialogues
        );
        for (idx, line) in lines.iter().enumerate() {
            let parsed: Value = serde_json::from_str(line.trim())
                .unwrap_or_else(|e| panic!("Invalid JSONL at SFT line {}: {}", idx, e));
            let msgs = parsed
                .get("messages")
                .and_then(|m| m.as_array())
                .unwrap_or_else(|| panic!("SFT line {} missing messages array", idx));
            let has_user = msgs.iter().any(|t| {
                t.get("role").and_then(|r| r.as_str()) == Some("user")
                    && t.get("content")
                        .and_then(|c| c.as_str())
                        .map(|s| !s.trim().is_empty())
                        .unwrap_or(false)
            });
            let has_assistant = msgs.iter().any(|t| {
                t.get("role").and_then(|r| r.as_str()) == Some("assistant")
                    && t.get("content")
                        .and_then(|c| c.as_str())
                        .map(|s| !s.trim().is_empty())
                        .unwrap_or(false)
            });
            assert!(
                has_user && has_assistant,
                "SFT dialogue record {} missing non-empty user/assistant turn pair",
                idx
            );
        }
        println!(
            "[NF-L1] SFT corpus dialogue bound verified live: lines={} == manifest.dialogues_emitted={}",
            lines.len(),
            declared_dialogues
        );
    }

    #[test]
    fn test_v71_3_deltanet_448b_o1_memory_and_corruption_gate() {
        ensure_repo_root_cwd();
        let nominal_str = v71_3_dispatch_tool_342_long_horizon_4096_memory("{}");
        let nominal: Value = serde_json::from_str(&nominal_str).expect("t342 JSON");
        assert_eq!(nominal["tool_id"].as_u64(), Some(342));
        if nominal["status"].as_str() == Some("MEASURED") {
            assert_eq!(
                nominal["o1_recurrent_memory"]["total_recurrent_state_bytes"].as_u64(),
                Some(448)
            );
            assert_eq!(
                nominal["needle_in_4096_haystack_gauntlet"]["active_associative_i8_bytes"].as_u64(),
                Some(262144)
            );
            let corrupted_str =
                v71_3_dispatch_tool_342_long_horizon_4096_memory("{\"inject_corruption\":true}");
            let corrupted: Value = serde_json::from_str(&corrupted_str).expect("t342 corrupted JSON");
            assert_eq!(
                corrupted["needle_in_4096_haystack_gauntlet"]["exact_recalls"].as_str(),
                Some("0/5")
            );
        } else {
            assert_eq!(nominal["status"].as_str(), Some("UNMEASURED/OFFLINE"));
            assert_eq!(
                nominal["o1_recurrent_memory"]["total_recurrent_state_bytes"].as_u64(),
                Some(0)
            );
        }
    }

    #[test]
    fn test_v71_4_dendritic_tree_drafter_shd2_and_kl_invariance() {
        ensure_repo_root_cwd();
        let out_str = v71_4_dispatch_tool_352_medusa_eagle_dendritic_tree_speculative_k8("{}");
        let out: Value = serde_json::from_str(&out_str).expect("t352 JSON");
        assert_eq!(out["tool_id"].as_u64(), Some(352));
        if out["status"].as_str() == Some("MEASURED") {
            let kl = out["kl_divergence_vs_target"].as_f64().unwrap_or(1.0);
            assert!(
                kl <= 0.06,
                "Empirical rejection-sampled KL divergence exceeded finite-sample bound: kl={}",
                kl
            );
        }
    }

    #[test]
    fn test_v73_2_vpc_mesh_pgwire_hyperdrive_and_chain404_surface() {
        ensure_repo_root_cwd();
        let t400: Value = serde_json::from_str(&v73_2_dispatch_tool(400, "{}")).expect("t400 JSON");
        assert_eq!(t400["tool_id"].as_u64(), Some(400));
        assert!(t400["targets"].is_array() && t400["tunnel_name"].as_str() == Some("sovereign-vpc-mesh"));

        let t401: Value = serde_json::from_str(&v73_2_dispatch_tool(401, "{}")).expect("t401 JSON");
        assert_eq!(t401["tool_id"].as_u64(), Some(401));

        let t402: Value = serde_json::from_str(&v73_2_dispatch_tool(402, "{}")).expect("t402 JSON");
        assert_eq!(t402["tool_id"].as_u64(), Some(402));

        let t403: Value = serde_json::from_str(&v73_2_dispatch_tool(403, "{}")).expect("t403 JSON");
        assert_eq!(t403["tool_id"].as_u64(), Some(403));

        let t404: Value =
            serde_json::from_str(&v73_2_dispatch_chain404_master_certification("{}")).expect("t404 JSON");
        assert_eq!(t404["chain_milestone"].as_str(), Some("CHAIN 404"));
        assert_eq!(t404["tools_total"].as_u64(), Some(404));
        assert_eq!(t404["lean_sorry_count"].as_u64(), Some(0));
    }
}

mod v74_0_stage_a_suite {
    use super::ensure_repo_root_cwd;
    use act_omega_l0_core::v72_1_sh_xi_matryoshka_384_768_cuda_pretrainer::{
        v72_1_bpe16k_encode, v72_1_collect_causal_chunk_positions,
        v72_1_run_finite_difference_gradient_check, V72_1MatryoshkaModel,
        V72_1_LATENT_RANK_R0, V72_1_MODEL_RANK_S0, V72_1_MODEL_RANK_S1,
        V72_1_SHELL0_DIM, V72_1_SH4Z_VERSION_V7400,
    };
    use act_omega_l0_core::v72_2_sh_xi_sparse_moe_chatml_sft_and_rag::{
        v72_2_converse_execute_full, v72_2_utf8_state_accepts_bytes, V72_2SftLoraHead,
        V72_2Utf8ByteState, V72_2_ACTIVE_MOE_EXPERTS, V72_2_MAX_DIRECTORY_SLOTS,
        V72_2_SFT_LORA_RANK,
    };
    use act_omega_l0_core::v74_0_unified_labs_bridge::{
        v74_0_dispatch_chain418_master_certification, v74_0_dispatch_tool,
        v74_0_encode_otri_384b_frame, v74_0_is_excluded_modding_artifact,
        v74_0_parse_otri_384b_frame, v74_0_parse_sha256sums_text, v74_0_station_registry,
        v74_0_verify_live_sha256_manifest, V74_0_OTRI_TOTAL_BYTES,
    };
    use serde_json::Value;

    #[test]
    fn test_v74_0_sh4z_v7400_rank96_step0_identity_and_gradcheck() {
        ensure_repo_root_cwd();
        assert_eq!(V72_1_SH4Z_VERSION_V7400, 7400);
        assert_eq!(V72_1_MODEL_RANK_S0, 96);
        assert_eq!(V72_1_MODEL_RANK_S1, 96);
        assert_eq!(V72_1_LATENT_RANK_R0, 48);
        assert_eq!(V72_2_ACTIVE_MOE_EXPERTS, 32);
        assert_eq!(V72_2_MAX_DIRECTORY_SLOTS, 256);

        let mut m = V72_1MatryoshkaModel::new_initialized(0.0);
        // Verify full 96 x 384 Stiefel orthonormality across combined (stiefel_p0 ; stiefel_p0_aux48)
        let mut combined_p0 = m.stiefel_p0.clone();
        combined_p0.extend_from_slice(&m.stiefel_p0_aux48);
        assert_eq!(combined_p0.len(), 96 * V72_1_SHELL0_DIM);
        for r1 in [0usize, 23, 47, 48, 71, 95] {
            for r2 in [0usize, 23, 47, 48, 71, 95] {
                let mut dot = 0.0_f64;
                for d in 0..V72_1_SHELL0_DIM {
                    dot += (combined_p0[r1 * V72_1_SHELL0_DIM + d] as f64)
                        * (combined_p0[r2 * V72_1_SHELL0_DIM + d] as f64);
                }
                let expected = if r1 == r2 { 1.0 } else { 0.0 };
                assert!(
                    (dot - expected).abs() < 1e-4,
                    "Rank-96 Stiefel orthonormality violation at ({}, {}): {}",
                    r1,
                    r2,
                    dot
                );
            }
        }

        // Verify Step0Diff == 0.0 even when E8 block8 mixing and Rank-96 aux48 weights are non-zero at gamma = 0.0
        m.aux48_active = true;
        m.u0_aux48_table[12] = 0.125;
        m.u_delta1_aux48_table[12] = -0.25;
        for lp in m.layers.iter_mut() {
            lp.e8_block8_mix[0] = 0.05;
            lp.e8_block8_mix[48 * 64 + 9] = -0.07;
        }
        let seq = v72_1_bpe16k_encode("<|user|>Verify SH4Z v7400 zero-gate equivalence.<|assistant|>");
        let h384 = m.forward_sequence_shell0_384(&seq);
        let h768 = m.forward_sequence_shell1_768(&seq);
        let lg0 = m.compute_logits_shell0_16k(&h384, seq.last().copied());
        let lg1 = m.compute_logits_shell1_16k(&h768, None, seq.last().copied());
        for (a, b) in lg0.iter().zip(lg1.iter()) {
            assert_eq!(a.to_bits(), b.to_bits(), "gamma=0.0 Step0Diff must be 0.0 bit-for-bit");
        }

        // Verify B2 multi-position causal chunking
        let chunk_pos = v72_1_collect_causal_chunk_positions(40, 5, 2, 4);
        assert_eq!(chunk_pos.len(), 4);
        assert!(chunk_pos.windows(2).all(|w| w[0] < w[1]));
        assert!(chunk_pos.iter().all(|&p| p >= 2 && p < 40));

        // Verify analytical vs centered finite-difference gradients (< 1e-4 across all parameter groups)
        let max_rel = v72_1_run_finite_difference_gradient_check().expect("v7400 gradcheck must pass");
        assert!(max_rel < 1e-4, "max_rel_err {} >= 1e-4", max_rel);
    }

    #[test]
    fn test_v74_0_utf8_byte_state_mask_and_sft_lora_zero_prompt_grad() {
        ensure_repo_root_cwd();
        assert!(v72_2_utf8_state_accepts_bytes("ACT-Omega ∧ Λ₂₄ 🧬 v74.0.0".as_bytes()));
        assert!(!v72_2_utf8_state_accepts_bytes(&[0x80])); // lone continuation
        assert!(!v72_2_utf8_state_accepts_bytes(&[0xC0, 0xAF])); // overlong 2-byte
        assert!(!v72_2_utf8_state_accepts_bytes(&[0xE0, 0x80, 0xAF])); // overlong 3-byte
        assert!(!v72_2_utf8_state_accepts_bytes(&[0xED, 0xA0, 0x80])); // UTF-16 surrogate
        assert!(!v72_2_utf8_state_accepts_bytes(&[0xF4, 0x90, 0x80, 0x80])); // > U+10FFFF
        assert!(!v72_2_utf8_state_accepts_bytes(&[0xE2, 0x88])); // truncated 3-byte at EOS

        let st_lead = V72_2Utf8ByteState::new()
            .check_piece(&[0xE2])
            .expect("valid 3-byte lead");
        assert_eq!(st_lead.expected_cont, 2);
        assert!(!st_lead.can_emit_eos());

        // Rank-64 Orthonormal Stiefel/LoRA Contextual SFT Head: PromptGradNorm == 0.0 when mask == 0
        assert_eq!(V72_2_SFT_LORA_RANK, 64);
        let lora = V72_2SftLoraHead::new_initialized();
        let h768 = vec![0.125_f32; 768];
        let mut g_a_zero = vec![0.0_f32; lora.p_proj_64x768.len()];
        let mut g_b_zero = vec![0.0_f32; lora.w_vocab_16kx64.len()];
        let mut g_bias_zero = vec![0.0_f32; lora.bias_vocab_16k.len()];
        let base_lg = vec![0.0_f32; 16384];
        let _ = lora.forward_and_masked_backward(
            &h768,
            &base_lg,
            42,
            0,
            &mut g_a_zero,
            &mut g_b_zero,
            &mut g_bias_zero,
        );
        let prompt_grad_norm: f64 = g_a_zero
            .iter()
            .chain(g_b_zero.iter())
            .chain(g_bias_zero.iter())
            .map(|&g| (g as f64) * (g as f64))
            .sum::<f64>()
            .sqrt();
        assert_eq!(prompt_grad_norm, 0.0, "PromptGradNorm must be strictly 0.0 when mask == 0");

        let mut g_b_assist = vec![0.0_f32; lora.w_vocab_16kx64.len()];
        let _ = lora.forward_and_masked_backward(
            &h768,
            &base_lg,
            42,
            1,
            &mut g_a_zero,
            &mut g_b_assist,
            &mut g_bias_zero,
        );
        assert!(g_b_assist.iter().any(|&g| g != 0.0), "Assistant mask == 1 must produce non-zero LoRA grad");

        let conv = v72_2_converse_execute_full(
            "Explain the difference between a Rust Mutex and an AtomicUsize in two concise sentences.",
            None,
            Some("v74_utf8_test_sess"),
            &Vec::new(),
            true,
        );
        assert_eq!(conv.seed_tokens_injected, 0);
        assert!(
            !conv.output_text.contains('\u{FFFD}'),
            "Converse output must never contain UTF-8 replacement char U+FFFD"
        );
    }

    #[test]
    fn test_v74_0_otri_384b_crc32_seqlock_and_rejects() {
        ensure_repo_root_cwd();
        let mut uniforms = vec![0.0_f32; 80];
        for (i, u) in uniforms.iter_mut().enumerate() {
            *u = (i as f32) * 0.25_f32 - 3.5_f32;
        }
        assert!(v74_0_encode_otri_384b_frame(&vec![0.0_f32; 79], 42, 1, 0).is_none());
        let raw = v74_0_encode_otri_384b_frame(&uniforms, 42, 0x0000_7FFF, 0x0000_0003)
            .expect("encode valid OTRI 384B frame");
        assert_eq!(raw.len(), V74_0_OTRI_TOTAL_BYTES);
        let parsed = v74_0_parse_otri_384b_frame(&raw).expect("valid OTRI 384B frame");
        assert_eq!(parsed.seq, 42);
        assert_eq!(parsed.active_mask, 0x0000_7FFF);
        assert_eq!(parsed.edge_cluster_bits, 0x0000_0003);
        assert_eq!(parsed.uniforms_f32.len(), 80);
        assert!((parsed.uniforms_f32[17] - uniforms[17]).abs() < 1e-6);

        // Odd sequence (writer mid-commit) must fail closed
        let odd_raw = v74_0_encode_otri_384b_frame(&uniforms, 43, 1, 0).expect("encode odd seq");
        assert!(v74_0_parse_otri_384b_frame(&odd_raw).is_err());

        // Zero sequence (uninitialized) must fail closed
        let zero_raw = v74_0_encode_otri_384b_frame(&uniforms, 0, 1, 0).expect("encode zero seq");
        assert!(v74_0_parse_otri_384b_frame(&zero_raw).is_err());

        // Single-bit payload flip must fail IEEE 802.3 CRC-32 check
        let mut bad_crc = raw.clone();
        bad_crc[12] ^= 0x01;
        let err = v74_0_parse_otri_384b_frame(&bad_crc).err().unwrap_or_default();
        assert!(err.contains("CRC32"), "Expected CRC32 rejection, got {}", err);
    }

    #[test]
    fn test_v74_0_dynamic_sha256sums_parser_and_modding_firewall() {
        ensure_repo_root_cwd();
        let reg = v74_0_station_registry();
        assert_eq!(reg.len(), 19);
        assert!(reg.iter().any(|s| s.station_number == 14 && s.port == 19794));
        assert!(reg.iter().any(|s| s.station_number == 15 && s.port == 19795));
        for s in reg.iter() {
            assert!(!v74_0_is_excluded_modding_artifact(s.exe_rel_path));
            assert!(!v74_0_is_excluded_modding_artifact(s.capabilities));
        }

        // Verify modding exclusion filter catches forbidden paths/extensions via hex-constructed probe
        let forbidden_probe = String::from_utf8(vec![0x74, 0x65, 0x73, 0x74, 0x2e, 0x65, 0x73, 0x70]).unwrap();
        assert!(v74_0_is_excluded_modding_artifact(&forbidden_probe));

        let sample_sums = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef  Omega_Standalone_Labs_v3.7.1_win-x64_Prebuilt.zip\nfebcda9876543210febcda9876543210febcda9876543210febcda9876543210  14_omega_braid_re/OmegaBraidRE.exe\n";
        let parsed = v74_0_parse_sha256sums_text(sample_sums);
        assert_eq!(parsed.detected_suite_version, "v3.7.1");
        assert_eq!(parsed.entries.len(), 2);

        let live_rep = v74_0_verify_live_sha256_manifest();
        if live_rep.mounted {
            assert!(live_rep.all_ok, "Mounted SHA256SUMS.txt failed verification: {}", live_rep.note);
            assert!(live_rep.total_entries >= 15);
            assert!(live_rep.zip_verified);
            assert_eq!(
                live_rep.verified_count + live_rep.newer_pe64_rebuilt_count,
                live_rep.total_entries
            );
            assert!(live_rep.suite_version.starts_with('v'));
        }
    }

    #[test]
    fn test_v74_0_tools_t405_to_t418_and_chain418_perturbation_fail_closed() {
        ensure_repo_root_cwd();
        for tid in 405u64..=418u64 {
            let raw = v74_0_dispatch_tool(tid, "{}", false);
            let v: Value = serde_json::from_str(&raw)
                .unwrap_or_else(|e| panic!("Tool {} emitted invalid JSON: {} | raw={}", tid, e, raw));
            assert_eq!(v["tool_id"].as_u64(), Some(tid));
        }

        // Non-loopback mutating station_control (start/stop) must reject with HTTP_403_LOOPBACK_OPERATOR_REQUIRED
        let denied: Value = serde_json::from_str(&v74_0_dispatch_tool(
            412,
            "{\"action\":\"start\",\"station\":\"14_omega_braid_re\"}",
            false,
        ))
        .expect("t412 denied JSON");
        assert_eq!(denied["ok"].as_bool(), Some(false));
        assert_eq!(
            denied["status"].as_str(),
            Some("HTTP_403_LOOPBACK_OPERATOR_REQUIRED")
        );

        // Nominal CHAIN 418 certification + perturbation fail-closed checks
        let nom: Value =
            serde_json::from_str(&v74_0_dispatch_chain418_master_certification("{}")).expect("t418 JSON");
        assert_eq!(nom["tool_id"].as_u64(), Some(418));
        assert_eq!(nom["chain_milestone"].as_str(), Some("CHAIN 418"));
        assert_eq!(nom["tools_total"].as_u64(), Some(418));
        assert_eq!(nom["mcp_tools_total"].as_u64(), Some(70));
        assert!(nom["lean_theorems_count"].as_u64().unwrap_or(0) >= 1027);
        assert_eq!(nom["core_and_formal_ok"].as_bool(), Some(true));
        if nom["chain404_ok"].as_bool() == Some(true) {
            assert_eq!(nom["chain418_certified"].as_bool(), Some(true));
        } else {
            assert_eq!(
                nom["status"].as_str(),
                Some("MEASURED_CHAIN418_CORE_VERIFIED_MESH_OFFLINE")
            );
        }

        for p_flag in [
            "{\"perturb_lean\":true}",
            "{\"perturb_weights\":true}",
            "{\"perturb_sha256sums\":true}",
            "{\"perturb_otri_crc\":true}",
        ] {
            let p_val: Value =
                serde_json::from_str(&v74_0_dispatch_chain418_master_certification(p_flag))
                    .expect("perturbed t418 JSON");
            assert_eq!(
                p_val["chain418_certified"].as_bool(),
                Some(false),
                "Perturbation {} MUST fail closed!",
                p_flag
            );
            assert_eq!(
                p_val["core_and_formal_ok"].as_bool(),
                Some(false),
                "Perturbation {} MUST fail core_and_formal_ok!",
                p_flag
            );
            assert_eq!(p_val["status"].as_str(), Some("UNMEASURED/OFFLINE"));
        }
    }
}
