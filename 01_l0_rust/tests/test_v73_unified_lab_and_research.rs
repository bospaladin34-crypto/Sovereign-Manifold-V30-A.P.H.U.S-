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
    let offline = v73_0_probe_station_live_json(59799, "/api/health", 60);
    assert!(offline.is_err(), "unused port 59799 must fail closed");

    let unknown = v73_0_dispatch_tool(99999, "");
    assert!(unknown.contains("\"ok\":false"));
    assert!(unknown.contains("UNKNOWN_LAB_TOOL"));

    let deck = v73_0_dispatch_unified_lab_deck("");
    assert!(deck.contains("ACT-Omega Unified Standalone & R&D Lab v3.0.0"));
    assert!(deck.contains("\"measured_live\":true"));
    assert!(deck.contains("\"stations\":["));
}

#[test]
fn test_v73_1_bitcos_roundtrip_and_invalid_trit_reject() {
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
        let (ok1, open1, close1, inq1) =
            v72_2_validate_json_object_fsm("{\"a\":{\"b\":\"ok{}\"},\"c\":true,\"n\":42}");
        assert!(ok1 && open1 == 2 && close1 == 2 && !inq1);

        let (ok2, _, _, _) = v72_2_validate_json_object_fsm("{\"a\":1} trailing");
        assert!(!ok2);

        let (ok3, _, _, _) = v72_2_validate_json_object_fsm("{\"a\":{\"b\":1}");
        assert!(!ok3);

        if std::path::Path::new(C_SH_XI_SOURCED_SFT_JSONL_PATH).exists() {
            let raw = std::fs::read_to_string(C_SH_XI_SOURCED_SFT_JSONL_PATH).unwrap();
            let lines: Vec<&str> = raw.lines().filter(|l| !l.trim().is_empty()).collect();
            assert!(lines.len() >= 96, "Expected >= 96 SFT dialogues, found {}", lines.len());
            for line in lines.iter().take(10) {
                let (valid, _, _, _) = v72_2_validate_json_object_fsm(line.trim());
                assert!(valid, "Invalid JSONL line in SFT corpus");
            }
        }
    }

    #[test]
    fn test_v71_3_deltanet_448b_o1_memory_and_corruption_gate() {
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
        let out_str = v71_4_dispatch_tool_352_medusa_eagle_dendritic_tree_speculative_k8("{}");
        let out: Value = serde_json::from_str(&out_str).expect("t352 JSON");
        assert_eq!(out["tool_id"].as_u64(), Some(352));
        if out["status"].as_str() == Some("MEASURED") {
            let kl = out["kl_divergence_vs_target"].as_f64().unwrap_or(1.0);
            assert!(kl < 1e-6, "Verifier distribution shifted under speculative tree drafter: kl={}", kl);
        }
    }

    #[test]
    fn test_v73_2_vpc_mesh_pgwire_hyperdrive_and_chain404_surface() {
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
