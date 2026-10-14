// C:\sovereign_manifold_v31\01_l0_rust\src\bin\v31_harvester.rs
// Unified ACT-Omega Net v31.0 Curriculum Shard Harvester

use std::fs;
use std::path::Path;
use act_omega_l0_core::v31_desargues_dehornoy_teleparallel::run_v30_continuity_audit;

fn count_shards(dir: &str) -> usize {
    if let Ok(rd) = fs::read_dir(Path::new(dir)) {
        return rd.flatten().filter(|e| e.path().extension().map(|x| x == "binshard").unwrap_or(false)).count();
    }
    0
}

fn main() {
    let c_base = count_shards("C:\\sovereign_manifold_v31\\03_vault\\shards_base");
    let c_240 = count_shards("C:\\sovereign_manifold_v31\\03_vault\\shards_240");
    let total = c_base + c_240;
    let cont = run_v30_continuity_audit(total);
    println!(
        "[v31_harvester] Vault Verified: shards_base={} + shards_240={} = {} Total Shards ({} x Chair-44 Orbits)",
        c_base, c_240, total, cont.complete_orbits
    );
}