// =============================================================================
// OMEGALANG v16.0 PRIMARY NATIVE TLV MODEL & WEIGHT COMPILER CLI BINARY
// Binary: omegalang_tlv_compiler.exe
// Compiles 03_vault/omegalang_v16/sovereign_harmonic_v69.oml into:
//   1. 00_control/weights/sovereign_harmonic_viii_v6900_8704cl.e8z (557,056 B)
//   2. 00_control/weights/neurons_v6900_84480.npage (10,813,440 B)
//   3. 00_control/weights/synapses_v6900_2703360.spage (5,406,720 B)
//   4. 03_vault/shards_tier4/shard_63361..84480.binshard (21,120 x 212 B)
//   5. 9 Polyglot Targets (including NVIDIA Ampere sm_86 CUDA PTX)
// =============================================================================

use act_omega_l0_core::v69_0_omegalang_v16_primary_tlv_compiler_and_84480_connectome::{
    v69_0_dispatch_tool_305_omegalang_v16_primary_tlv_compiler,
    v69_0_dispatch_tool_306_tier4_84480_connectome_verifier,
};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let mode = args.get(1).map(|s| s.as_str()).unwrap_or("compile");
    let force_json = if mode == "rebuild" || mode == "--force" {
        "{\"force\":true}"
    } else {
        "{\"force\":false}"
    };

    let t305 = v69_0_dispatch_tool_305_omegalang_v16_primary_tlv_compiler(force_json);
    let t306 = v69_0_dispatch_tool_306_tier4_84480_connectome_verifier("{\"force\":false}");
    println!("{}", t305);
    println!("{}", t306);
}
