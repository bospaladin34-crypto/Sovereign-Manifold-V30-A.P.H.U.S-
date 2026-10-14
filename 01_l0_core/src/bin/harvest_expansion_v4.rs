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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Token Expansion (Batch 5)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_topology_07", "Quantum invariants of three-manifolds derive from surgery presentations along framed links in S3. Reshetikhin-Turaev invariants utilize finite-dimensional modular tensor categories associated with quantum affine Lie algebras. Spin topological quantum field theories incorporate fermionic parity constraints into bordism categories."),
        ("curriculum_a_topology_08", "Heegaard Floer homology partitions three-manifold invariants across spin-c structures using Lagrangian intersection Floer theory in symmetric products of Riemann surfaces. The Ozsvath-Szabo spectral sequence connects knot Floer homology with singular instanton knot homology."),
        ("curriculum_b_systems_07", "Memory-mapped I/O apertures configure non-prefetchable physical base address registers across PCI Express topology hierarchies. Dynamic Voltage and Frequency Scaling governors modulate core clock frequencies in sub-millisecond intervals according to instruction retired counters."),
        ("curriculum_b_systems_08", "Asynchronous memory barriers enforce sequentially consistent memory orderings without stalling pipeline execution stages. Spin-lock contention is mitigated via exponential backoff algorithms paired with thread yield hints across hyperthreaded execution pipelines."),
        ("curriculum_c_geomag_07", "Geomagnetic paleosecular variations recorded in basaltic lava flows demonstrate recurrent excursions of the geomagnetic dipole axis. Polarity reversals initiate with localized quadrupole and octupole flux emergence across the core-mantle boundary."),
        ("curriculum_c_geomag_08", "Equatorial electrojets drive diurnal geomagnetic variations observed at low-latitude magnetic observatories. Magnetospheric convection electric fields map along highly conducting geomagnetic field lines directly into high-latitude ionospheric plasma sheets."),
        ("curriculum_d_semiotics_07", "Topological entropy quantifies the orbital complexity of discrete dynamical shift operators over symbolic alphabet sequences. Markov partitions decompose continuous state space trajectories into discrete topological Markov chains with finite transition matrices."),
        ("curriculum_d_semiotics_08", "Affine differential geometry defines projective connections across Riemannian parameter manifolds of statistical models. The dual alpha-connections of Amari formalize dualistic geometries characterizing exponential families and mixture manifolds."),
        ("curriculum_e_autopoiesis_07", "Hypercyclic organization links self-replicating catalytic units into closed feedback topologies resistant to error catastrophes. Dissipative self-assembly drives colloidal particle suspensions into complex chiral configurations under non-equilibrium electromagnetic drives."),
        ("curriculum_e_autopoiesis_08", "Symbiogenesis formalizes emergent cognitive complexity through structural incorporation of autonomous modular functional agents. Topological phase transitions in complex biological and neural networks demarcate regimes of optimal information transmission."),
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
    println!("Cycle 3 Ingestion (Batch 5): {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}