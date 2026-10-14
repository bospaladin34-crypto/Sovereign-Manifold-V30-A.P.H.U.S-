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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Token Expansion (Batch 6)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_topology_09", "Differential topology characterizes exotic smooth structures on four-dimensional manifolds through Donaldson polynomial invariants and Seiberg-Witten monopoles. Kirby calculus transforms framed link surgery diagrams across four-manifolds using handle slide and cancellation moves. Floer homology groups compute Lagrangian intersection invariants invariant under Hamiltonian isotopies."),
        ("curriculum_a_topology_10", "Higher category theory models n-fold topological quantum field theories through fully dualizable objects in symmetric monoidal n-categories. The cobordism hypothesis establishes an equivalence between framed n-dimensional TQFTs and fully dualizable objects in target infinity-categories."),
        ("curriculum_b_systems_09", "Lockless read-copy-update synchronizes read-heavy kernel data structures without taking execution locks during reader traversal. Grace periods ensure all pre-existing reader threads complete before reclaiming retired memory allocations. Hardware branch prediction buffers minimize instruction decode stalls along hot execution paths."),
        ("curriculum_b_systems_10", "Non-volatile dual in-line memory modules map persistent byte-addressable storage directly into physical processor memory buses. Flush and fence instruction sequences force cache line writebacks to persistent memory domains before advancing execution barriers."),
        ("curriculum_c_geomag_09", "Geomagnetic induction vectors resolve lateral conductivity contrasts across subduction zones and volcanic arcs. Magnetovariational profiling separates internal induced magnetic fields from external ionospheric source fields using spherical elementary current systems."),
        ("curriculum_c_geomag_10", "Polar cap magnetic disturbances monitor interplanetary magnetic field reconnection dynamics and solar wind coupling efficiency. Field-aligned Birkeland currents transfer gigawatt electromagnetic power between the solar wind dynamo and polar ionospheres."),
        ("curriculum_d_semiotics_09", "Information geometry of statistical manifolds defines the Amari-Chentsov tensor as the unique invariant third-order covariant tensor under congruent embeddings. Riemannian metric connections govern geodesic flows across dense probability simplexes during maximum entropy inference."),
        ("curriculum_d_semiotics_10", "Algebraic semiotics constructs institutional morphisms mapping formal sign systems across heterogenous sensory representations. Functorial semantics translates syntactic formalisms into categorical sheaves over topological semantic spaces."),
        ("curriculum_e_autopoiesis_09", "Autocatalytic network dynamics sustain continuous functional organization through far-from-equilibrium thermodynamic dissipative structures. Enactive cognitive architectures emerge from continuous sensorimotor coordination between autonomous agents and their operational domains."),
        ("curriculum_e_autopoiesis_10", "Self-producing cognitive topologies achieve operational closure by recursively regenerating the boundary constraints that delineate the computing agent. Synergetic order parameters govern macroscopic phase synchrony during dynamic bifurcation across complex multi-agent neural ensembles."),
    ];

    let shards_dir = Path::new("C:/sovereign_manifold_v30/04_canonical_vault/shards_240");
    let mut total_tokens = 0usize;
    let mut total_chars = 0usize;

    for (name, text) in curricula.iter() {
        let tokens = tokenize_subwords(text);
        total_tokens += tokens.len();
        total_chars += text.len();
        let ratio = text.len() as f32 / tokens.len() as f32;
        println!("  -> {:26} | Chars: {:4} | Tokens: {:4} | Ratio: {:.2}x", name, text.len(), tokens.len(), ratio);

        let u8_tokens: Vec<u8> = tokens.iter().map(|&t| (t % 240) as u8).collect();
        let path = shards_dir.join(format!("{}.binshard", name));
        write_binshard_240(&path, &u8_tokens).expect("Failed to write binshard");
    }

    println!("------------------------------------------------------");
    println!("Cycle 3 Ingestion (Batch 6): {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}