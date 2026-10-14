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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Token Expansion (Batch 4)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_topology_05", "Khovanov homology categorifies the Jones polynomial by assigning bigraded chain complexes to link diagrams. Cobordisms between link diagrams induce chain map morphisms invariant under Reidemeister moves. Sheaf Laplacians over simplicial complexes admit harmonic representative cycles where coboundary operators vanish identically. Turaev-Viro topological quantum field theories evaluate state sums over triangulated three-manifolds using 6j-symbols of quantum groups."),
        ("curriculum_a_topology_06", "Braided monoidal categories formalize anyonic quantum statistics through invertible braiding natural transformations satisfying hexagon axioms. The center of a monoidal category constructs non-abelian modular tensor categories with finite topological charge sectors. Contact structures on three-manifolds relate Legendrian knot invariants to Thurston-Bennequin numbers and rotation numbers across convex surfaces."),
        ("curriculum_b_systems_05", "Lock-free multiple-producer single-consumer ring queues utilize atomic compare-and-swap primitives to coordinate enqueue pointers without thread blocking. Memory order acquire and release semantics prevent instruction reordering across architectural cache hierarchies. AVX2 vector intrinsics evaluate 256-bit SIMD lane products simultaneously across aligned floating point buffers. Page table isolation mitigates speculative execution side channels while maintaining low kernel-to-user context switch overhead."),
        ("curriculum_b_systems_06", "PCIe Root Complexes arbitrate direct peer-to-peer memory transactions between NVMe storage arrays and GPU VRAM apertures. Cache-coherent interconnect protocols maintain directory-based cache states across heterogeneous compute tiles. Cooperative multitasking engines schedule lightweight user-level fibers within pinned operating system threads to sustain microsecond-scale dispatch latencies."),
        ("curriculum_c_geomag_05", "Magnetohydrodynamic waves propagate through the conducting outer core as torsional oscillations with decadal periods. Geomagnetic jerks manifest as abrupt second time derivatives of the geomagnetic secular variation field observed at global magnetic observatories. Crustal remanent magnetization modulates lithospheric magnetic anomalies over ancient geological cratons."),
        ("curriculum_c_geomag_06", "Auroral electrojet currents flow horizontally within the ionospheric E-layer, inducing significant vertical magnetic field disturbances during geomagnetic substorms. Magnetospheric ring currents driven by trapped energetic ions diamagnetically depress low-latitude geomagnetic intensity during storm main phases. Telluric voltage potential gradients measured across grounded electrode pairs provide continuous proxy telemetry for subsurface electrical conductivity."),
        ("curriculum_d_semiotics_05", "Hyperbolic embeddings preserve hierarchical tree structures of conceptual lexicons with minimal metric distortion. The Poincare disk model maps semantic hierarchies into negatively curved Riemannian manifolds where distance scales exponentially toward the boundary. Category-theoretic functors map grammatical syntax trees into vector spaces over finite algebraic fields."),
        ("curriculum_d_semiotics_06", "Topological data analysis constructs Vietoris-Rips filtration complexes from high-dimensional token embeddings. Persistent homology barcodes identify persistent topological loops representing robust semantic invariant clusters. Entropy-regularized optimal transport calculates Wasserstein distances between linguistic probability distributions with sub-cubic algorithmic complexity."),
        ("curriculum_e_autopoiesis_05", "Second-order cybernetics formalizes observing systems wherein the observer constitutes an inseparable part of the observed recursive loop. Eigen-behaviors emerge as stable operational fixed points within recursive functional compositions f(f(f(...))) = x. Allostatic regulation shifts homeostatic setpoints dynamically in response to anticipated environmental phase shifts."),
        ("curriculum_e_autopoiesis_06", "Autocatalytic sets maintain mutually reinforcing chemical and symbolic reaction networks sustaining continuous self-repair against entropy decay. Dissipative quantum solitons propagate through non-linear topological media without dispersion through exact balance of dispersion and non-linearity. Systemic resilience quantifies the basin of attraction radius separating self-organized regimes from catastrophic boundary bifurcation."),
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
    println!("Cycle 3 Ingestion (Batch 4): {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}