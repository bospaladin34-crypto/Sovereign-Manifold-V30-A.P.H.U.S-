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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Token Expansion (Batch 9: Instantons)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_instantons_01", "Yang-Mills instantons are self-dual non-abelian gauge field configurations minimizing the Euclidean action on four-dimensional Riemannian manifolds. The topological charge corresponds to the second Chern class c_2 of the principal SU(2) bundle evaluated via integration of the Chern-Weil curvature form Tr(F wedge F). Moduli spaces of instantons admit hyperkahler quotient constructions through the ADHM algebraic matrix equations."),
        ("curriculum_a_instantons_02", "Donaldson-Thomas invariants enumerate coherent sheaves on Calabi-Yau threefolds through virtual fundamental classes of Hilbert schemes. Seiberg-Witten monopole equations decouple non-abelian gauge dynamics into abelian spinor equations over spin-c structures, providing computational equivalents to four-manifold Donaldson polynomial invariants."),
        ("curriculum_b_systems_15", "Non-blocking synchronization uses transactional memory extensions and hazard pointers to safely reclaim retired dynamic nodes in lock-free graphs. Hardware store buffers coalesce sequential writes to identical cache lines, sustaining peak memory bandwidth during high-frequency telemetry serialization."),
        ("curriculum_b_systems_16", "Zero-copy network protocols map physical network interface ring descriptors directly into userspace virtual memory addresses. High-resolution hardware time-stamping eliminates kernel-user boundary transitions during microsecond telemetry arbitration."),
        ("curriculum_c_geomag_15", "Geomagnetic secular acceleration reflects rapid azimuthal core flow perturbations driven by magnetic field-torque coupling near the tangent cylinder. Outer core torsional oscillations modulate length-of-day variations through angular momentum exchange with the mantle."),
        ("curriculum_c_geomag_16", "Magnetotelluric phase tensor invariants separate two-dimensional strike directions from regional three-dimensional galvanic distortion. Induction arrows point toward subterranean electrical conductors, resolving high-permeability crustal fault zones."),
        ("curriculum_d_semiotics_15", "Riemannian optimization over flag manifolds models orthogonal neural subspace rotation during domain adaptation. Geodesic flows under the canonical metric preserve subspace dimension invariants while minimizing transfer entropy."),
        ("curriculum_d_semiotics_16", "Categorical quantum mechanics formalizes quantum computational protocols via symmetric monoidal dagger categories. Morphisms in dagger compact categories satisfy graphical diagrammatic calculus rules matching physical braid tangles."),
        ("curriculum_e_autopoiesis_15", "Systemic autopoiesis maintains relational identity under turbulent environmental perturbation through dynamic reconstruction of constituent metabolic components. Thermodynamic dissipation bounds dictate the minimum energy throughput necessary to preserve organizational closure."),
        ("curriculum_e_autopoiesis_16", "Critical slowing down near catastrophic bifurcation thresholds signals phase state instability in autonomous self-governing networks. High-order variance metrics provide early warning indicators preceding topological regime transitions."),
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
    println!("Cycle 3 Ingestion (Batch 9): {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}