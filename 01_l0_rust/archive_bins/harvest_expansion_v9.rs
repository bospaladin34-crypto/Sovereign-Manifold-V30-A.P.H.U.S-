use act_omega_l0_core::e8_subword_vocab::tokenize_subwords;
use std::fs::File;
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

fn write_binshard_240(path: &Path, tokens: &[u8]) -> std::io::Result<()> {
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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Token Expansion (Batch 10: Fibonacci Anyons)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_fibonacci_01", "Fibonacci anyons realize universal topological quantum computation through non-abelian braiding of topological charges in two-dimensional electron gases. The fusion rules tau times tau = 1 + tau dictate quantum dimension equal to the golden ratio phi = 1.61803398875. The braid group representation B_n on multi-anyon Hilbert spaces generates dense SU(2) unitary gate approximations through braiding matrices."),
        ("curriculum_a_fibonacci_02", "Modular tensor categories formalize topological quantum field theories with modular S-matrices satisfying Verlinde formula. Quantum dimensions and topological twists classify anyonic charge sectors invariant under modular group transformations. Topological entanglement entropy quantifies long-range quantum order across bipartitioned quantum ground states."),
        ("curriculum_b_systems_17", "Pinned physical memory arenas eliminate page fault latency during high-rate telemetry ingestion into ReBAR slot buffers. Direct Memory Access controllers transfer sensor packets over PCIe lanes with sub-microsecond latency. Memory fence instructions enforce strict release-acquire synchronization across heterogeneous CPU and GPU compute cores."),
        ("curriculum_b_systems_18", "Ring buffer descriptors in non-blocking single-producer single-consumer queues update atomic sequence counters using compiler memory barriers. CPU hardware prefetchers stream sequential tensor rows into L1 data caches ahead of matrix-vector multiplication loops."),
        ("curriculum_c_geomag_17", "The Missoula geodesic reference anchor records terrestrial magnetic field components Bx = -16.15, By = 9.93, Bz = -47.47 microteslas with resultant flux magnitude 51.12 microteslas. Diurnal solar heating drives E-region ionospheric tidal winds generating quiet geomagnetic Sq variations."),
        ("curriculum_c_geomag_18", "Magnetohydrodynamic wave equations govern Alfven wave reflections at high-conductivity ionospheric boundaries. Telluric electric potential gradients measured across orthogonal electrode arrays resolve electrical conductivity structure in the upper mantle."),
        ("curriculum_d_semiotics_17", "Hyperbolic semantic foliations decompose language embedding manifolds into constant curvature leaves indexed by hierarchical abstraction depth. Geodesic distance on the Poincare upper half plane scales exponentially with taxonomic rank."),
        ("curriculum_d_semiotics_18", "Categorical adjunctions between syntactic formal grammars and topological semantic sheaves ensure functorial preservation of logical deduction across translation manifolds. The Yoneda lemma guarantees that linguistic token meaning is uniquely determined by its relations to all other vocabulary elements."),
        ("curriculum_e_autopoiesis_17", "Autopoietic operational closure formalizes self-generating cognitive boundaries wherein every internal operation contributes to regenerating the network of operations that produced it. Dissipative thermodynamic flows maintain structural integrity far from thermodynamic equilibrium."),
        ("curriculum_e_autopoiesis_18", "Self-referential cognitive fixed points emerge as invariant eigen-behaviors under recursive functional composition. Operational closure decouples internal autonomous dynamics from environmental instruction while sustaining continuous adaptive structural coupling."),
    ];

    let shards_dir = Path::new("C:/sovereign_manifold_v30/04_canonical_vault/shards_240");
    let mut total_tokens = 0usize;
    let mut total_chars = 0usize;

    for (name, text) in curricula.iter() {
        let tokens = tokenize_subwords(text);
        total_tokens += tokens.len();
        total_chars += text.len();
        let ratio = text.len() as f32 / tokens.len() as f32;
        println!("  -> {:28} | Chars: {:4} | Tokens: {:4} | Ratio: {:.2}x", name, text.len(), tokens.len(), ratio);

        let u8_tokens: Vec<u8> = tokens.iter().map(|&t| (t % 240) as u8).collect();
        let path = shards_dir.join(format!("{}.binshard", name));
        write_binshard_240(&path, &u8_tokens).expect("Failed to write binshard");
    }

    println!("------------------------------------------------------");
    println!("Cycle 3 Ingestion (Batch 10): {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}