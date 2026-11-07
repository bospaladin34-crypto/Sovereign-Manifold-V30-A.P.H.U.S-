pub mod bi_stalk_attention_1024;
pub mod rebar_slot;
pub mod host_telemetry;
pub mod e8_lattice;
pub mod sheaf_cohomology;
pub mod braid_ir;
pub mod harmonic_endpoint;
pub mod sh3_manifold_30l;
pub mod ffi;
pub mod e8_table_gemv;
pub mod qat_training;
pub mod shard_loader;

pub use rebar_slot::RebarSensorFrame;
pub use host_telemetry::HostHardwareObserver;
pub use e8_lattice::ConwaySloaneE8;
pub use sheaf_cohomology::SheafAuditor;
pub use braid_ir::{BraidInstruction, BraidOpcode, BraidFlags};
pub use harmonic_endpoint::{SovereignHarmonic3Endpoint, D_MODEL, VOCAB_SIZE};
pub use sh3_manifold_30l::{SovereignHarmonic30LManifold, NUM_LAYERS, NUM_STALKS, STALK_DIM};
pub use e8_table_gemv::{E8TableGEMV, NUM_E8_ROOTS, CANONICAL_E8Q_BYTES};
pub use qat_training::{QatTrainingKernel, QatConfig, QatMetrics};
pub use shard_loader::{ShardDataset, Shard, BINSHARD_MAGIC};
pub mod vocab_e8_table;

pub mod braid_attention;

pub mod e8_roots;
pub mod e8_subword_vocab;

pub mod e8_shell2;

pub mod dual_shell_head;

pub mod sheaf_cross_attention;

pub mod conversational_bpe;

pub mod sierpinski_158_quantizer;
pub mod ab_plaquette_coincidence;
pub mod hyperbolic_eraser_cavity;
pub mod chair44_automorphism;
pub mod stomachion_router;
pub mod tangram_penrose_field;
pub mod chromatic_triality_sheaf;
pub mod braid_polyglot_ir;
pub mod modular_braid_sl2z;
pub mod bell_chsh_witness;
pub mod cft_energy_ladder;
pub mod heat_compress_qat;
pub mod elastic_sheaf_ops;
pub mod tri_silicon_affinity;
pub mod relativistic_horizon_hud;
pub mod tgnn_unified_pipeline;
pub mod sheaf_context_tensor;
pub mod sh4_leech_e8_zigzag;
pub mod v31_desargues_dehornoy_teleparallel;
pub mod utcp_v31_ring;
pub mod uarm_cascade_sh4;
pub mod e8_compound_1024_lexicon;
pub mod octonionic_triality_cubic;

// Milestone M3 / Requirement R3: Native Gemma 4 Multimodal PLE & Speculative Cascade Engine
pub mod v61_gemma4_multimodal_ple_speculative_cascade_and_mcp_suite;

pub use v61_gemma4_multimodal_ple_speculative_cascade_and_mcp_suite::{
    v61_escape_clean,
    v61_json_escape,
    v61_resolve_gemma4_bpe_tokens,
    v61_decode_gemma4_token_ids,
    v61_dispatch_bpe_resolve,
    v61_ple_256d_surgical_router,
    v61_probe_multimodal_tower,
    v61_speculative_cascade_draft,
    V61PleConfig,
    V61PleRouterOutput,
    V61MultimodalProbeOutput,
    V61SpeculativeCascadeOutput,
};

// Track B / Milestone M2: Formal CRT, RVQ, PVQ & Sparse MatVec Runtime
pub mod v61_14_formal_crt_rvq_pvq_sparse_matvec_runtime;

pub use v61_14_formal_crt_rvq_pvq_sparse_matvec_runtime::{
    CoprimeResidueTuple,
    CoprimeModuliCrtIndexMap,
    IrrationalPhaseFrameOperator,
    L1CodebookClassification,
    L1UnitBallCodebookClassifier,
    MultiStageLeastSquaresRvq,
    CoarseHorizonRoutingHeader,
    TwoLevelBlockSparseMatVecRouter,
    MapAssociativeMemoryMips,
    Round2AcceptabilityAudit,
    AcceptabilityGateController,
    MODULUS_P1,
    MODULUS_P2,
    MODULUS_P3,
    BLOCK_HORIZON_DIM,
    L1_UNIT_BALL_CODEBOOK_SIZE,
    MICRO_BLOCK_DIM,
    MICRO_BLOCK_PACKED_BYTES,
    MICRO_BLOCKS_PER_HORIZON,
    CRT_IDEMPOTENT_E1,
    CRT_IDEMPOTENT_E2,
    CRT_IDEMPOTENT_E3,
    v61_14_dispatch_tool_289_crt_pfa,
    v61_14_dispatch_tool_290_rvq_pvq,
    v61_14_dispatch_tool_291_sparse_matvec,
    v61_14_dispatch_tool_292_chain292_cert,
};

// Track C / Handoffs #6 & #7: v63.0 - v63.2 Capability Parity, BPUT Win Metric, Q16.16 Adapter & F:\ 3TB Epoch Vault
pub mod v63_0_capability_parity_bput_and_fdrive_epoch_vault;

pub use v63_0_capability_parity_bput_and_fdrive_epoch_vault::{
    CapabilityParityBputMetrics,
    compute_live_capability_parity_and_bput,
    v63_0_dispatch_tool_293_capability_parity_bput,
    v63_0_dispatch_tool_294_transformer_highway_q16_adapter,
    v63_1_dispatch_tool_295_fdrive_immutable_epoch_vault,
    v63_2_dispatch_tool_296_chain296_cert,
};

// Track D / Handoff #7: v68.0.0 OmegaLang v15.0 8-Target Compiler, 78ns K16a, 90L K18a Stream & 535.73 TOPS K19 / 4.235 POPS K20 Superposition
pub mod v68_0_omegalang_v15_unified_compiler_and_k16a_k20_engine;

pub use v68_0_omegalang_v15_unified_compiler_and_k16a_k20_engine::{
    V68_CERTIFIED_O7777_BYTES,
    V68_CERTIFIED_O7777S_BYTES,
    V68_TOTAL_LAYERS_90,
    V68_HARMONIC_STAGES_8,
    v68_0_dispatch_tool_297_omegalang_v15_8target_compiler,
    v68_0_dispatch_tool_298_k16a_78ns_quarterblock_l1d,
    v68_0_dispatch_tool_299_k18a_90layer_multishard_l2_stream,
    v68_0_dispatch_tool_300_k19_k20_superposition_and_chain300_cert,
};

// Track E / Handoff #5: VESPER-OS External SSD Bootstrapped UEFI GOP Microkernel & PID 1 Init Appliance
pub mod v62_0_vesper_os_uefi_gop_and_pid1_init_kernel;

pub use v62_0_vesper_os_uefi_gop_and_pid1_init_kernel::{
    VesperOsSsdBootTelemetry,
    tool_299_uefi_gop_framebuffer_offset,
    tool_300_verify_vesper_os_ssd_layout_and_pid1,
    v62_0_dispatch_vesper_os_ssd_appliance,
};

// Track 1 (v68.5.0 | CHAIN 304 | 810/810 QED): MIT Cold-to-Hot Index, Galois 256D Tower, CERN LHCb 5-Mapping Auditor, Gemma 4 Studio & FB1..FB12
pub mod v68_5_mit_hot_index_galois_cern_and_gemma4_studio;

pub use v68_5_mit_hot_index_galois_cern_and_gemma4_studio::{
    GaloisFieldTower,
    MitHotShardRecord,
    V68_5_GALOIS_TOTAL_DEGREE_256,
    V68_5_POLYTONIC_32D_ROOTS,
    V68_5_VESPER_FIB_15,
    v68_5_scan_mit_hot_index,
    v68_5_dispatch_tool_301_mit_hot_index_and_galois_tower,
    v68_5_dispatch_tool_302_cern_lhcb_5mapping_auditor,
    v68_5_dispatch_tool_303_gemma4_conversational_studio,
    v68_5_dispatch_tool_304_frontier_fb12_and_chain304_cert,
};

// Track 2 (v69.0.0 | CHAIN 308 | 820/820 QED): OmegaLang v16.0 Primary TLV Compiler, Tier-4 84,480-Neuron / 4,055,040-Synapse Connectome & 524,288 19-Bit BPE
pub mod v69_0_omegalang_v16_primary_tlv_compiler_and_84480_connectome;

pub use v69_0_omegalang_v16_primary_tlv_compiler_and_84480_connectome::{
    V69_TOTAL_NEURONS,
    V69_TOTAL_SYNAPSES,
    V69_E8Z_CACHELINES,
    V69_MACRO_DOMAINS,
    V69_SUB_DOMAINS,
    V69_BPE_VOCAB_19BIT,
    V69_COMPOUND_CONCEPTS,
    v69_0_ensure_and_compile_sovereign_harmonic_v6900,
    v69_0_dispatch_tool_305_omegalang_v16_primary_tlv_compiler,
    v69_0_dispatch_tool_306_tier4_84480_connectome_verifier,
    v69_0_dispatch_tool_307_open_vocab_524k_192subdomains_fluency,
    v69_0_dispatch_tool_308_chain308_master_certification,
};


