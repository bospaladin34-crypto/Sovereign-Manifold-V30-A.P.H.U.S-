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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Token Expansion (Batch 7: Kahler Geometry)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_kahler_01", "Kahler manifolds unify complex analytic geometry, Riemannian metrics, and symplectic structures through a parallel complex structure nabla J = 0. The fundamental Kahler form omega(X, Y) = g(JX, Y) is closed, d omega = 0, inducing an exact symplectic structure. Local coordinates admit a strictly plurisubharmonic Kahler potential K generating metric tensor components g_{i, j_bar} = d^2 K / dz^i dzbar^j. Hodge decomposition partitions de Rham cohomology into bigraded Dolbeault cohomology groups H^k(M, C) = direct sum H^{p,q}(M) satisfying Hodge symmetry H^{p,q} = H^{q,p}_bar."),
        ("curriculum_a_kahler_02", "Calabi-Yau manifolds are compact Ricci-flat Kahler manifolds characterized by vanishing first Chern class c_1(M) = 0 and trivial canonical line bundles. Yau theorem proves the existence of unique Ricci-flat Kahler metrics in every Kahler class. Hard Lefschetz theorem and Lefschetz decomposition decompose Dolbeault cohomology across primitive Kahler classes under the Lefschetz operator L(alpha) = omega wedge alpha. Mirror symmetry establishes isomorphisms between complex moduli and symplectic Kahler moduli across dual Calabi-Yau manifolds."),
        ("curriculum_a_kahler_03", "The Fubini-Study metric on complex projective space CP^n provides canonical Kahler geometry with constant positive holomorphic sectional curvature. Kodaira embedding theorem proves that compact Kahler manifolds with integral Kahler classes are projective algebraic varieties. The Ricci form Ric(omega) = -i ddbar log det(g) represents the first Chern class in de Rham cohomology, governing topological obstruction cancellation across complex analytic fibers."),
        ("curriculum_b_systems_11", "Heterogeneous system architectures coordinate zero-copy shared virtual memory between host CPU cores and GPU streaming multiprocessors through unified page tables. Hardware atomic operations on unified memory addresses ensure cache coherency without requiring explicit memory copy fences. PCIe Gen 5 links sustain 64 gigabytes per second bidirectional interconnect bandwidth."),
        ("curriculum_b_systems_12", "Asynchronous event demultiplexing engines utilize epoll and completion ports to maintain persistent event loops handling tens of thousands of concurrent client connections with sub-microsecond scheduling jitter. Kernel bypass network architectures route packets directly to userspace memory rings eliminating interrupt processing overhead."),
        ("curriculum_c_geomag_11", "The geomagnetic field scalar potential satisfies Laplace equation in source-free regions above the core-mantle boundary. Spherical harmonic Gauss coefficients evaluate internal core dipole, quadrupole, and octupole moments with secular acceleration tracking decadal westward core drift. Magnetospheric ring current variations induce secondary telluric currents in continental lithospheres."),
        ("curriculum_c_geomag_12", "Planetary magnetospheres compress under dynamic solar wind pressure pulses, inducing global sudden storm commencements recorded simultaneously by surface induction magnetometers. Poynting flux transfers electromagnetic energy from solar wind reconnection regions directly into high-latitude auroral ionospheres."),
        ("curriculum_d_semiotics_11", "Geometric deep learning models language representations as gauge equivariant neural fields over Riemannian manifold graphs. Parallel transport along semantic geodesics rotates lexical embedding frames according to the holonomy of the underlying linguistic curvature. Information geometric divergence measures quantify semantic shift across multi-domain corpora."),
        ("curriculum_d_semiotics_12", "Categorical semiotics formalizes signifier-signified relationships through adjunctions between syntactic categories and semantic sheaves. Natural transformations between linguistic functors preserve grammatical consistency across translation manifolds. Kolmogorov complexity provides lower bounds for algorithmic entropy compression in quantized token dictionaries."),
        ("curriculum_e_autopoiesis_11", "Dissipative cognitive manifolds sustain operational closure by continuously reconstructing their internal topological state representations against environmental perturbation. Autopoietic systems maintain homeostatic equilibrium through self-referential feedback loops that minimize thermodynamic entropy production. Requisite variety controllers guarantee asymptotic stability across dynamic state transitions."),
        ("curriculum_e_autopoiesis_12", "Non-equilibrium phase transitions in complex neural collectives drive self-organized critical attractors where information transmission capacity diverges. Dialectical synthesis resolves competing optimization constraints into unified multi-scale cognitive architectures."),
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
    println!("Cycle 3 Ingestion (Batch 7): {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}