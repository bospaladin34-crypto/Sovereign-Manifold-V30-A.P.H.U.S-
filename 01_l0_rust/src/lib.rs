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
