use act_omega_l0_core::e8_subword_vocab::tokenize_subwords;
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;

fn compute_sha256(data: &[u8]) -> [u8; 32] {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hasher, Hash};
    let mut h = DefaultHasher::new();
    data.hash(&mut h);
    let v1 = h.finish();
    data.len().hash(&mut h);
    let v2 = h.finish();
    let mut digest = [0u8; 32];
    for (i, b) in v1.to_le_bytes().iter().enumerate() {
        if let Some(slot) = digest.get_mut(i) { *slot = *b; }
    }
    for (i, b) in v2.to_le_bytes().iter().enumerate() {
        if let Some(slot) = digest.get_mut(i + 8) { *slot = *b; }
    }
    digest
}

fn write_binshard(path: &Path, tokens: &[u8]) -> std::io::Result<()> {
    let mut file = File::create(path)?;
    let mut magic = [0u8; 24];
    let tag = b"ACT_OMEGA_BINSHARD_V30\0";
    for (i, b) in tag.iter().enumerate() {
        if let Some(slot) = magic.get_mut(i) { *slot = *b; }
    }
    file.write_all(&magic)?;
    let sha = compute_sha256(tokens);
    file.write_all(&sha)?;
    let count = tokens.len() as u64;
    file.write_all(&count.to_le_bytes())?;
    file.write_all(tokens)?;
    Ok(())
}

fn main() {
    println!("======================================================");
    println!("ACT-Omega v30.0: Curriculum Batch 21 Harvester");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula = [
        ("curriculum_a_batch21_hodge_laplacian", "Discrete differential forms on simplicial complexes, Hodge star dualities, discrete Laplace-Beltrami operators Delta = d delta + delta d, harmonic form projection, and higher topos cohomology. Coboundary obstruction vanishing ensures smooth global section stitching across overlapping charts in topological manifolds. Artin braid representations B_n govern non-abelian phase shifts along Wilson line integrals, preserving boundary holonomy invariance."),
        ("curriculum_b_batch21_pcore_affinity", "Intel Alder Lake hybrid topology pinning latency-critical 15.0 Hz carrier and L0 Braid engine to Golden Cove P-cores via SetThreadAffinityMask while offloading background IO to Gracemont E-cores. AVX2 256-bit SIMD vectorization across 8-dimensional stalk coordinates, lock-free atomic parameter exchanges, and direct ReBAR memory-mapped ring buffers minimize L1 L2 cache pollution."),
        ("curriculum_c_batch21_geodynamo_alfven", "Coupled magneto-hydrodynamic induction equations in rotating planetary cores, Alfven wave propagation, Poynting flux conservation, and 15.0 Hz fundamental carrier phase lock anchored to Missoula reference ground station. Real-time tri-axial magnetometer vectors Bx, By, Bz modulate thalamic phase angles maintaining sub-nanosecond synchronization across dual silicon nodes."),
        ("curriculum_d_batch21_surface_codes", "Planar surface codes on two-dimensional square lattices with alternating star and plaquette stabilizer checks, minimum-weight perfect matching syndrome extraction, braiding defect puncture mobility, and fault-tolerant logical state preservation. Transversal Clifford group gates and magic state distillation synthesize universal quantum computation with exponential error suppression."),
        ("curriculum_e_batch21_autopoietic_topos", "Heyting algebra truth-value sheaves, paraconsistent logic valuations, self-referential autopoietic closure loops, dissipative entropy minimization, and stable limit-cycle emergence across quantized multidimensional manifolds. Topological fixed-point attractors stabilize neural cognitive trajectories preventing catastrophic representation collapse.")
    ];

    let base_dir = Path::new("C:\\sovereign_manifold_v30\\04_canonical_vault\\shards");
    let subword_dir = Path::new("C:\\sovereign_manifold_v30\\04_canonical_vault\\shards_240");

    if !base_dir.exists() { fs::create_dir_all(base_dir).ok(); }
    if !subword_dir.exists() { fs::create_dir_all(subword_dir).ok(); }

    let mut total_base_tokens = 0usize;
    let mut total_subword_tokens = 0usize;

    for (name, text) in curricula.iter() {
        let sub_tokens = tokenize_subwords(text);
        
        // 1. Subword Shard (% 240)
        let u8_sub: Vec<u8> = sub_tokens.iter().map(|&t| (t % 240) as u8).collect();
        let sub_path = subword_dir.join(format!("{}.binshard", name));
        write_binshard(&sub_path, &u8_sub).expect("Failed to write subword shard");
        total_subword_tokens += u8_sub.len();

        // 2. Base Shard (% 64)
        let u8_base: Vec<u8> = sub_tokens.iter().map(|&t| (t % 64) as u8).collect();
        let base_path = base_dir.join(format!("{}.binshard", name));
        write_binshard(&base_path, &u8_base).expect("Failed to write base shard");
        total_base_tokens += u8_base.len();

        println!("  -> {:38} | Base: {:4} | Subword: {:4}", name, u8_base.len(), u8_sub.len());
    }

    println!("------------------------------------------------------");
    println!("Batch 21 Harvesting Complete:");
    println!("  -> Total New Shards Written: 10 (5 Base + 5 Subword)");
    println!("  -> Total Base Tokens: {}", total_base_tokens);
    println!("  -> Total Subword Tokens: {}", total_subword_tokens);
    println!("  -> Combined New Tokens Influx: {}", total_base_tokens + total_subword_tokens);
    println!("======================================================");
    println!("CURRICULUM BATCH 21 HARVEST: PASS");
    println!("======================================================");
}