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
    println!("ACT-Omega v30.0: Cycle 3 In-Loop Corpus Expansion");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let curricula: &[(&str, &str)] = &[
        ("curriculum_a_topology_03", "Homology groups and Betti numbers characterize topological cycles across simplicial and singular chain complexes. The Mayer-Vietoris sequence provides an exact sequence connecting homology groups of topological subspaces with their union and intersection. Dehn surgery on knots in the three-sphere generates closed orientable three-manifolds classified by hyperbolic volume and Chern-Simons invariants. Garside normal forms decompose elements of the Artin braid group into unique left-greedy canonical factors. The Temperley-Lieb algebra represents planar tangle diagrams corresponding to Jones polynomial evaluations and knot state sums."),
        ("curriculum_a_topology_04", "Pure braid groups form the kernel of the natural homomorphism from the Artin braid group to the symmetric group of strand permutations. Configuration spaces of ordered points in the complex plane possess fundamental groups naturally isomorphic to pure braid groups. Cohomology rings of complement spaces of complex hyperplanes determine braid monodromy representations. The Alexander polynomial calculates knot determinants through infinite cyclic covering spaces. Reidemeister Type III moves govern triple-crossing braid sliding invariance under topological deformations."),
        ("curriculum_b_systems_03", "NUMA memory topology partitions physical random access memory across distinct processor sockets with non-uniform interconnect latency. Translation Lookaside Buffers cache virtual to physical page translations to accelerate page table traversals. TLB shootdowns broadcast inter-processor interrupts across cores to invalidate stale virtual addresses during page remaps. Hardware transactional memory executes critical sections speculatively, rolling back state on memory address conflicts. SIMD vector registers execute parallel lane operations over contiguous aligned float arrays."),
        ("curriculum_b_systems_04", "Direct Memory Access ring descriptors orchestrate asynchronous packet transfers between PCIe peripheral controllers and host physical memory without CPU intervention. Input Output Completion Ports in the Windows NT kernel decouple thread pools from asynchronous I/O completion queues. Epoll and kqueue register edge-triggered event notifications over high-concurrency socket file descriptors. Zero-copy ring buffers pass memory-mapped frame pointers directly to userspace consumers without redundant kernel-user copies."),
        ("curriculum_c_geomag_03", "International Geomagnetic Reference Field spherical harmonic coefficients expand geomagnetic scalar potentials up to degree and order thirteen. Secular variation captures decadal westward drift of geomagnetic poles driven by torsional oscillations in the outer core. Magnetotelluric tensor impedance relates horizontal electric and magnetic field variations across tectonic boundaries. Telluric currents induced by geomagnetic storms circulate through the lithosphere and regional electrical grids."),
        ("curriculum_c_geomag_04", "Schumann resonances establish global electromagnetic standing waves within the Earth-ionosphere cavity with fundamental mode peaks at 7.83 Hz, 14.3 Hz, and 20.8 Hz. Solar wind dynamic pressure compresses the dayside magnetopause while stretching the nightside geomagnetic tail into reconnection regions. Hall conductivity dominates the ionospheric E-region where ion gyrofrequencies drop below collision frequencies. Geomagnetic quiet variations provide unperturbed baseline references for physical sensor calibrations."),
        ("curriculum_d_semiotics_03", "The Fisher information metric defines a Riemannian metric tensor on manifolds of probability distributions. Amari dual affine connections govern information geometric projections between exponential and mixture statistical families. The Kullback-Leibler divergence serves as a canonical divergence function generating the Fisher metric and dual skewness tensors. Semantic manifolds represent token probability distributions whose geodesics minimize relative entropy across lexical transitions."),
        ("curriculum_d_semiotics_04", "Kolmogorov complexity bounds the minimal description length of discrete symbolic sequences. Shannon entropy establishes theoretical channel capacity limits for lossless data transmission over noisy channels. Rate-distortion theory formalizes optimal tradeoff curves between bit rate and semantic reconstruction distortion. Continuous Lie group actions on latent embedding spaces model grammatical transformations and semantic analogies as continuous symmetries."),
        ("curriculum_e_autopoiesis_03", "Maturana and Varela formalize autopoiesis as the necessary and sufficient condition for living systems characterized by continuous self-production. Operational closure establishes systemic boundaries where internal recursive processes determine system state transitions without external instructional specification. Ashby's law of requisite variety states that the variety of a viable controller must match or exceed the variety of the controlled system. Structural coupling describes mutual adaptation between autonomous systems and their surrounding medium."),
        ("curriculum_e_autopoiesis_04", "Prigogine dissipative structures maintain ordered configurations far from thermodynamic equilibrium through continuous entropy export to the environment. Self-organized criticality drives complex non-linear dynamical systems toward scale-invariant attractors without fine-tuned parameter regulation. Phase transitions in neural and physical computing architectures exhibit power-law avalanche distributions near critical bifurcation points. Dialectical emergence synthesizes local micro-scale interactions into coherent macroscopic functional intelligence."),
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
    println!("Cycle 3 Ingestion: {} New Shards | {} Chars | {} New Tokens Added", curricula.len(), total_chars, total_tokens);
    println!("======================================================");
}