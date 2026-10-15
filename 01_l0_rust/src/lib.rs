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
