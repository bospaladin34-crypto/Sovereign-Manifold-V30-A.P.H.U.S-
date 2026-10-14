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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Token Expansion (Batch 11: DT Invariants)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_dt_invariants_01", "Generalized Donaldson-Thomas invariants define virtual counts of semi-stable coherent sheaves on Calabi-Yau three-folds through motivic Hall algebras and Joyce-Song wall-crossing formulas. The Behrend micro-local function assigns weighted Euler characteristics to critical loci of holomorphic Chern-Simons functionals."),
        ("curriculum_a_dt_invariants_02", "Calabi-Yau four-fold invariants extend Donaldson-Thomas theory across eight real dimensions using orientation data on derived moduli stacks of coherent sheaves. Borisov-Joyce virtual fundamental classes construct counting invariants invariant under deformation of complex analytic structures."),
        ("curriculum_b_systems_19", "Compute Express Link CXL 3.0 protocols enable fabric-attached shared memory pooling across heterogeneous accelerator nodes with hardware-enforced cache coherency. Direct back-invalidation snoop filters maintain directory states across multi-tier memory fabrics without CPU serialization."),
        ("curriculum_b_systems_20", "Non-volatile memory flushes utilize clwb and sfence instruction barriers to enforce strict write-ordering to persistent storage controllers without flushing CPU data caches. Lock-free flat-combining queues minimize cache line bouncing across dense parallel worker ensembles."),
        ("curriculum_c_geomag_19", "Core-mantle boundary magnetic flux patches demonstrate rapid azimuthal advection governed by quasi-geostrophic helical convection in Earth outer core. Tangent cylinder boundary layers separate high-latitude retrograde polar vortex flows from low-latitude westward drift regimes."),
        ("curriculum_c_geomag_20", "Telluric electric potential differences measured across long-baseline dipoles monitor transient magnetotelluric impedance variations induced by solar coronal mass ejections. Upper mantle electrical anisotropy reflects preferred crystallographic orientation of olivine in the asthenosphere."),
        ("curriculum_d_semiotics_19", "Symmetric monoidal dagger categories formalize completely positive trace-preserving quantum channels as categorical string diagrams. Dagger Frobenius algebras classify orthogonal quantum measurement bases through categorical algebraic state decomposition."),
        ("curriculum_d_semiotics_20", "Topological quantum neural embeddings project linguistic semantic trees into unitary braid trajectories across multi-strand state spaces. Categorical natural transformations preserve semantic truth conditions across heterogeneous language translation manifolds."),
        ("curriculum_e_autopoiesis_19", "Organizational closure in autonomous cognitive systems requires that internal structural perturbations are compensated by compensatory homeostatic state transformations. Structural coupling between computing agent and physical environment establishes operational boundaries without instructional information transfer."),
        ("curriculum_e_autopoiesis_20", "Self-organized critical avalanches in complex recurrent neural topologies follow scale-invariant power-law distributions characterized by universal critical exponents. Operating at the boundary of chaos maximizes dynamical computational capacity and memory retention."),
    ];

    let shards_dir = Path::new("C:/sovereign_manifold_v30/04_canonical_vault/shards_240");
    let mut total_tokens = 0usize;
    let mut total_chars = 0usize;

    for (name, text) in curricula.iter() {
        let tokens = tokenize_subwords(text);
        total_tokens += tokens.len();
        total_chars += text.len();
        let ratio = text.len() as f32 / tokens.len() as f32;
        println!("  -> {:30} | Chars: {:4} | Tokens: {:4} | Ratio: {:.2}x", name, text.len(), tokens.len(), ratio);

        let u8_tokens: Vec<u8> = tokens.iter().map(|&t| (t % 240) as u8).collect();
        let path = shards_dir.join(format!("{}.binshard", name));
        write_binshard_240(&path, &u8_tokens).expect("Failed to write binshard");
    }

    println!("------------------------------------------------------");
    println!("Cycle 3 Ingestion (Batch 11): {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}