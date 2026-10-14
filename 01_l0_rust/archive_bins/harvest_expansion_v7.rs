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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Token Expansion (Batch 8: Hyperkahler)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_hyperkahler_01", "Hyperkahler manifolds are Riemannian manifolds equipped with three orthogonal complex structures I, J, K satisfying quaternionic relations I^2 = J^2 = K^2 = IJK = -1. Each complex structure defines a closed Kahler two-form omega_I, omega_J, omega_K making the manifold simultaneously Kahler with respect to all three structures. The twistor space of a hyperkahler manifold fibers over the complex projective line P1 with holomorphic families of rational curves. Gibbons-Hawking ansatz constructs explicit gravitational instanton metrics with triholomorphic Killing vector fields."),
        ("curriculum_a_hyperkahler_02", "Quaternionic Kahler manifolds possess holonomy groups contained in Sp(n)Sp(1) with non-zero scalar curvature and parallel four-forms. The Swann bundle maps quaternionic Kahler manifolds to hyperkahler cones through canonical twistor fibrations. Calabi conjecture solutions for hyperkahler manifolds guarantee non-trivial Ricci-flat metrics on K3 surfaces and Hilbert schemes of points on complex surfaces."),
        ("curriculum_b_systems_13", "Work-stealing thread pools maintain localized double-ended deques per processor core to minimize lock contention during task scheduling. Idle worker threads steal task frames from the tail of victim deques using atomic compare-and-swap instructions. NUMA-aware allocation pins thread stacks directly to the local memory node of the socket executing the fiber."),
        ("curriculum_b_systems_14", "Flat combining synchronizes multi-threaded concurrent data structures by delegating pending operations to a single combiner thread. Client threads enqueue request descriptors in lock-free publication lists and spin on local cache lines until the combiner completes execution. Memory-mapped persistent logs flush cache lines directly to non-volatile RAM using clwb instructions."),
        ("curriculum_c_geomag_13", "Alfven resonances establish standing magnetohydrodynamic shear waves along closed geomagnetic field lines connecting conjugate ionospheres. Field line resonance frequencies depend inversely on the Alfven velocity profile determined by plasma mass density and magnetic field intensity."),
        ("curriculum_c_geomag_14", "Geomagnetic cusp dynamics allow direct entry of magnetosheath plasma into the high-latitude magnetosphere through magnetic reconnection null points. Reconnection electric fields drive intense localized ionospheric convection vortices detected by high-frequency radar networks."),
        ("curriculum_d_semiotics_13", "Information geometry over statistical Lie groups formalizes natural gradient descent algorithms invariant under arbitrary smooth parameter coordinate transformations. The Fisher-Rao metric induces geodesic flows minimizing relative entropy across curved statistical manifolds during deep representation learning."),
        ("curriculum_d_semiotics_14", "Monoidal braid semantics interprets logical morphisms as ribbon tangles embedded in three-dimensional spacetime cylinders. Categorical coherence theorems ensure that all diagrammatic topological deformations evaluate to unique natural isomorphisms in the target category."),
        ("curriculum_e_autopoiesis_13", "Thermodynamic dissipation in self-organizing open systems maintains structural coupling boundaries through continuous entropy export. Autopoietic closure requires that all production processes generate components that recursively reconstitute the systemic network boundary."),
        ("curriculum_e_autopoiesis_14", "Eigen-behavior stabilization resolves turbulent micro-scale fluctuations into persistent macro-scale cognitive attractors. Second-order feedback regulators modulate internal state transitions dynamically to sustain requisite operational variety across non-stationary environments."),
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
    println!("Cycle 3 Ingestion (Batch 8): {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}