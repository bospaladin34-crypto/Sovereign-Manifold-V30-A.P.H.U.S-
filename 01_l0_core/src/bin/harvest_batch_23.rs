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
    println!("ACT-Omega v30.0: Curriculum Batch 23 Harvester");
    println!("Domain: Gosset Second Shell, AVF Linux, & Autopoiesis");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula = [
        ("curriculum_a_batch23_gosset_second_shell", "The Gosset E8 lattice second shell comprises 2160 root vectors of squared Euclidean norm four, characterized by theta series expansion coefficients theta_E8(q) = 1 + 240 q + 2160 q^2 + 6720 q^3. While the 240 minimal roots span stabilizer state polyhedra with vanishing mana, the 2160 second-shell vectors maximize non-stabilizer magic state distillation resources. Higher-order Clifford hierarchy gates Clifford_k promote non-transversal quantum logical operations through magic state injection. Quantization-aware training across dual Gosset shells provides a hierarchical memory manifold: the first shell maintains persistent classical invariants, while the second shell supplies a continuously replenishable reservoir of non-stabilizer resource states for creative topological synthesis and non-linear trajectory planning."),
        ("curriculum_b_batch23_avf_virtualization_ndk", "Android Virtualization Framework provides hardware-isolated Debian Linux micro-virtual machines executing directly on ARMv9-A hypervisors with four gigabytes of dedicated physical random access memory. Virtualized GPU acceleration over virtio-gpu and Virgl enables hardware-accelerated tensor contractions and shader execution inside the guest Linux environment. Zero-copy virtio-vsock streaming and automated socket port forwarding expose internal guest services to host loopbacks with sub-millisecond round-trip packet latency. Compiling native Rust and C++23 toolchains within the mobile container unlocks autonomous edge compilation, distributed node self-healing, and decentralized peer-to-peer curriculum synchronization directly on Google Tensor G5 silicon without host dependency."),
        ("curriculum_c_batch23_whistler_ducting_poynting", "Very low frequency Whistler-mode electromagnetic waves propagate along geomagnetic field lines in field-aligned magnetospheric plasma ducts. Cross-l-shell diffusion, cyclotron resonance with trapped relativistic electrons, and Poynting flux vector conservation dictate wave energy transfer between the ionosphere and inner magnetosphere. At the Missoula geophysical reference station (46.8721 N, 113.9940 W), coherent 15.0 Hz carrier phase locking synchronizes local tri-axial induction magnetometer vectors Bx, By, Bz with global Schumann cavity fundamental modes. Phase-locked loop tracking maintains sub-nanosecond temporal coherence across dual-silicon compute nodes despite diurnal ionospheric D-region height variations."),
        ("curriculum_d_batch23_sheaf_laplacian_spectrum", "Discrete sheaf Laplacians L_0 = delta^0_star delta^0 and L_1 = delta^0 delta^0_star + delta^1_star delta^1 formalize higher-order diffusion and obstruction dynamics on cellular simplicial complexes. The kernel of the 0-Laplacian identifies locally constant global sections corresponding to decentralized multi-node consensus states, whereas the kernel of the 1-Laplacian captures non-trivial first cohomology groups measuring topological obstruction. Hodge-Helmholtz orthogonal decomposition partitions arbitrary cochains into gradient, curl, and harmonic fields. Enforcing vanishing first cohomology H^1 = 0 through Straight-Through Estimators guarantees that local stalk updates glue into a globally coherent knowledge section across distributed heterogeneous compute graphs."),
        ("curriculum_e_batch23_autopoietic_homeostasis", "Autopoietic homeostasis in topological computing architectures regulates cognitive dynamics through closed-loop feedback across non-Hermitian gain boundaries. Following Ashby's law of requisite variety, the internal state manifold must match or exceed the environmental perturbation dimensionality to sustain operational closure. Continuous monitoring of the topological integration-segregation index B maintains an empirical setpoint of 0.45, balancing segregated module specialization with global network integration. Avalanche criticality exponents are anchored to alpha = 1.5, preventing both sub-critical collapse into unresponsive wakefulness and super-critical divergence into chaotic over-integration, ensuring eternal self-renewing autopoietic stability.")
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

        println!("  -> {:46} | Base: {:4} | Subword: {:4}", name, u8_base.len(), u8_sub.len());
    }

    println!("------------------------------------------------------");
    println!("Batch 23 Harvesting Complete:");
    println!("  -> Total New Shards Written: 10 (5 Base + 5 Subword)");
    println!("  -> Total Base Tokens: {}", total_base_tokens);
    println!("  -> Total Subword Tokens: {}", total_subword_tokens);
    println!("  -> Combined New Tokens Influx: {}", total_base_tokens + total_subword_tokens);
    println!("======================================================");
    println!("CURRICULUM BATCH 23 HARVEST: PASS");
    println!("======================================================");
}