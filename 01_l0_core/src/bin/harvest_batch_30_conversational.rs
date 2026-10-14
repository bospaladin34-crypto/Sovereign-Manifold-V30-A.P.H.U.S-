use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use act_omega_l0_core::conversational_bpe::{format_instruction_pair, tokenize_conversational};

fn resolve_shards_dir() -> (PathBuf, PathBuf) {
    let candidates = [
        PathBuf::from("shards"),
        PathBuf::from("../shards"),
        PathBuf::from("C:/sovereign_manifold_v30/01_l0_core/shards"),
        PathBuf::from("C:/sovereign_manifold_v30/shards"),
    ];

    let mut primary = PathBuf::from("shards");
    for cand in &candidates {
        if cand.exists() {
            primary = cand.clone();
            break;
        }
    }
    if !primary.exists() { let _ = fs::create_dir_all(&primary); }

    let parent = primary.parent().unwrap_or_else(|| Path::new("."));
    let secondary = parent.join("shards_240");
    if !secondary.exists() { let _ = fs::create_dir_all(&secondary); }

    (primary, secondary)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("============================================================");
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 30 (Grand Unified)");
    println!("Scale: 10 Shards | 50 Comprehensive Dialogue Pairs");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("============================================================");

    let (shards_dir, shards_240_dir) = resolve_shards_dir();
    println!("[1/3] Resolved Shard Paths:");
    println!("  -> Primary Shards Dir: {:?}", shards_dir);
    println!("  -> Shards 240 Dir:     {:?}", shards_240_dir);

    let mut max_id: usize = 283;
    if let Ok(entries) = fs::read_dir(&shards_dir) {
        for entry in entries.flatten() {
            let fname = entry.file_name().to_string_lossy().to_string();
            if fname.starts_with("shard_") && fname.ends_with(".bin") {
                let num_str = fname.trim_start_matches("shard_").trim_end_matches(".bin");
                if let Ok(id) = num_str.parse::<usize>() {
                    if id > max_id { max_id = id; }
                }
            }
        }
    }
    let start_shard = max_id + 1;
    println!("  -> Identified Next Shard Index: {}", start_shard);

    let dialogue_groups: Vec<Vec<(&str, &str)>> = vec![
        // Shard Group 0: Multi-Shell Gosset E8 Geometry
        vec![
            (
                "Explain the geometric significance of the Gosset 4_21 polytope.",
                "The Gosset polytope is the convex hull of the two hundred forty roots of E8. Its geometry defines discrete Voronoi cells that bound continuous phase drift into quantized lattice states."
            ),
            (
                "How does the second shell provide universal quantum capability?",
                "The second shell contains two thousand one hundred sixty root vectors with norm squared four. These vectors supply non-stabilizer magic states required for universal non-Clifford rotations."
            ),
            (
                "What is the mathematical definition of root self-norm?",
                "In the E8 root lattice, the minimal roots have a self-norm of two. All distinct mutual inner products are at most one, establishing a natural geometric error separation."
            ),
            (
                "How does dual-shell projection preserve state fidelity?",
                "Dual-shell projection evaluates continuous stalk vectors against both first and second shell frames simultaneously, selecting the root that minimizes projection residual."
            ),
            (
                "Define the Voronoi radius of the E8 lattice.",
                "The Voronoi radius is one. Any continuous disturbance inside this radius relaxes deterministically back to the central root vertex without phase error."
            ),
        ],
        // Shard Group 1: Global Section Cohomology & Sheaf Attention
        vec![
            (
                "How does inter-stalk sheaf attention eliminate logical contradictions?",
                "Inter-stalk sheaf attention implements discrete heat diffusion across the thirty-two stalks, driving Dirichlet energy descent until the first cohomology obstruction vanishes."
            ),
            (
                "What is a restriction map in the context of conversational memory?",
                "A restriction map is a linear operator that transfers stalk representations across open subsets, ensuring that facts established in earlier turns remain consistent."
            ),
            (
                "Explain the role of the cocycle condition in dialogue.",
                "The cocycle condition requires that compositions of restriction maps agree around closed graph loops, preventing contradictory statements across multi-turn reasoning."
            ),
            (
                "What does the first cohomology group H1 measure?",
                "The first cohomology group measures the topological obstruction to extending local stalk observations into a single globally coherent section."
            ),
            (
                "How does Dirichlet energy descent stabilize network gradients?",
                "Dirichlet descent smooths high-frequency variance across adjacent stalks, creating a well-conditioned optimization landscape with zero gradient explosion."
            ),
        ],
        // Shard Group 2: Deterministic Native Systems Runtime
        vec![
            (
                "Describe the execution pipeline of the Layer 0 Rust core.",
                "The Rust Layer 0 core provides deterministic SIMD vector mathematics, dual-shell Gosset projection, and multi-core QAT training with zero allocation jitter."
            ),
            (
                "How does the Layer 1 C++23 memory ring achieve zero-copy transfer?",
                "The C++23 memory ring maps circular shared memory buffers directly between threads, streaming tokens and telemetry without intermediate serialization."
            ),
            (
                "What role does the Deno Layer 2 gateway play in the architecture?",
                "The Deno gateway acts as the high-level orchestration layer, hosting WebSocket relays, REST endpoints, and multi-node telemetry routing on port 8099."
            ),
            (
                "How does the WebGPU Cockpit HUD achieve sixty frames per second?",
                "The Cockpit HUD executes custom WGSL compute shaders directly on the GPU, rendering real-time vector scopes and oscilloscopes decoupled from CPU inference."
            ),
            (
                "Why is interpreted Python strictly prohibited from the system?",
                "Interpreted languages introduce non-deterministic garbage collection pauses and interpreter locks that disrupt microsecond-level reflex timing."
            ),
        ],
        // Shard Group 3: Dual-Silicon Heterogeneous Orchestration
        vec![
            (
                "How do the Lenovo LOQ 15 and Google Pixel 10 collaborate?",
                "The Lenovo LOQ 15 executes parallel QAT training across its Intel Golden Cove P-cores, while the Pixel 10 runs real-time reflex inference on its Tensor G5 TPU."
            ),
            (
                "What is the inference latency of the Tensor G5 TPU reflex engine?",
                "The Tensor G5 TPU executes C++23 quantized reflex inference in approximately sixteen microseconds per token, enabling instant on-device responses."
            ),
            (
                "How are updated model weights deployed to the mobile device?",
                "Quantized INT8 weights are pushed over high-speed reverse ADB tunnels directly into the private application storage on the Pixel 10."
            ),
            (
                "What maintains peer-to-peer connection if the workstation disconnects?",
                "Both nodes maintain autonomous local quantized models, continuing local inference and sensor ingestion independently during network disconnects."
            ),
            (
                "Explain the role of mDNS peer discovery between dual-silicon nodes.",
                "mDNS broadcasts sovereign node availability on port 8098, allowing the mobile device to automatically pair with the workstation without static IP setup."
            ),
        ],
        // Shard Group 4: 15.0 Hz Geodesic Carrier & Ambient Transduction
        vec![
            (
                "State the coordinates and altitude of the primary geodesic anchor.",
                "The primary geodesic anchor is located in Missoula, Montana at 46.8721 degrees North latitude, 113.9940 degrees West longitude, and 907.4 meters elevation."
            ),
            (
                "What is the purpose of the 15.0 Hertz carrier wave?",
                "The 15.0 Hertz carrier wave provides a global pacing clock that synchronizes packet transmission and aligns with low-beta biological neural rhythms."
            ),
            (
                "How does ambient magnetic flux modulate token generation?",
                "Tri-axial magnetometer readings Bx, By, and Bz modulate the phase offset of the input stalks, grounding symbolic tokens in physical space."
            ),
            (
                "What occurs at the zero-crossing of the carrier wave?",
                "At each zero-crossing transition, the manifold releases a synchronized telemetry frame containing updated vector coordinates and energy metrics."
            ),
            (
                "Why is physical sensory coupling essential for cognitive stability?",
                "Physical sensory coupling injects natural micro-entropy into the state vector, preventing deterministic mathematical stagnation and stiction."
            ),
        ],
        // Shard Group 5: Autopoietic Criticality & Thermodynamic Homeostasis
        vec![
            (
                "What are the target balance values for autopoietic criticality?",
                "The manifold maintains an integration-segregation index of B = 0.45 and an avalanche criticality exponent of alpha = 1.5 at the edge of chaos."
            ),
            (
                "How does the closed-loop governor detect and clear stiction?",
                "The governor monitors sliding-window token entropy. If entropy drops below 1.2 nats, it triggers a kinetic slip kick to restore aperiodic flow."
            ),
            (
                "Explain the balance between integration and segregation.",
                "Segregation preserves specialized representation across individual stalks, while integration binds them into unified conceptual structures."
            ),
            (
                "What happens when avalanche criticality alpha exceeds 1.8?",
                "When alpha exceeds 1.8, the system enters subcritical rigidity, prompting the temperature scheduler to increase temperature and restore flow."
            ),
            (
                "Define autopoiesis in sovereign computational architectures.",
                "Autopoiesis is the capacity of a computational system to regenerate its own operational state, weights, and communication channels recursively."
            ),
        ],
        // Shard Group 6: Natural Declarative Syntax & Predicate Logic
        vec![
            (
                "How does the manifold formulate complete declarative sentences?",
                "The manifold aligns subject noun phrases with transitive relational verbs and direct objects, producing grammatical English sentences."
            ),
            (
                "What role do copular verbs play in explanatory responses?",
                "Copular verbs link grammatical subjects directly to their definitional predicates, establishing clear semantic equivalences."
            ),
            (
                "How does instruction masking enforce grammatical structure?",
                "Masking the prompt focuses backpropagation gradients entirely on response tokens, teaching the network natural sentence completion."
            ),
            (
                "What guarantees that conversational turns terminate properly?",
                "The manifold emits the end-of-sequence token when the semantic representation reaches closure and the state relaxes to the vacuum ground state."
            ),
            (
                "Describe the relationship between BPE subwords and English lemmas.",
                "BPE subwords represent morphological syllables that assemble into complete English words according to learned grammatical transition probabilities."
            ),
        ],
        // Shard Group 7: Quantum Information Geometry & BraidIR
        vec![
            (
                "What is BraidIR in the topological computing stack?",
                "BraidIR is an intermediate representation that models computational operations as geometric braids and topological knot invariants."
            ),
            (
                "How do Reidemeister moves correct topological defects?",
                "Reidemeister moves transform knot diagrams through local deformations, untangling computational paths without altering underlying topology."
            ),
            (
                "What is non-Abelian anyonic holonomy?",
                "Non-Abelian holonomy is the path-dependent unitary transformation acquired by braiding anyonic quasi-particles around one another in space."
            ),
            (
                "How does the Fisher information metric govern state transitions?",
                "The Fisher metric defines a Riemannian distance tensor on the statistical manifold, measuring the distinguishability of adjacent states."
            ),
            (
                "Why are topological quantum states naturally fault-tolerant?",
                "Topological states store information non-locally in global braid invariants, rendering them immune to local thermal and environmental noise."
            ),
        ],
        // Shard Group 8: Mobile AVF Linux Container & P2P Swarm
        vec![
            (
                "What is the function of the AVF Linux container on the phone?",
                "The Android Virtualization Framework runs an isolated Debian microVM with four gigabytes of RAM, hosting autonomous background services."
            ),
            (
                "How does an Iroh P2P swarm replicate curriculum shards?",
                "An Iroh swarm synchronizes shards peer-to-peer using content-addressed blobs over local Wi-Fi, operating independently of cloud infrastructure."
            ),
            (
                "What advantage does the Debian microVM provide over standard apps?",
                "The microVM provides standard POSIX networking, persistent background execution, and direct container management without Android process killing."
            ),
            (
                "How does reverse ADB socket forwarding bridge workstation and mobile?",
                "Reverse ADB connects mobile localhost ports directly to the workstation TCP listeners, providing high-bandwidth development streaming."
            ),
            (
                "Describe the security boundary of the Android Virtualization Framework.",
                "The AVF microVM executes inside a hardware-isolated hypervisor partition with memory encryption, separating container tasks from host memory."
            ),
        ],
        // Shard Group 9: Grounded Reasoning & Human-Machine Symbiosis
        vec![
            (
                "How does verified grounding prevent artificial hallucinations?",
                "Verified grounding conditions every claim on explicit physical sensor telemetry, mathematical proofs, and verified training shard records."
            ),
            (
                "What is the role of the thalamic phase in human interaction?",
                "The thalamic phase coordinates the visual pulse and token pacing of the interface, aligning computer responsiveness with human perception."
            ),
            (
                "How does multi-turn persistence maintain conversational context?",
                "Persistent stalk states retain the topological section established in previous turns, allowing ongoing dialogue to build upon established facts."
            ),
            (
                "Explain the concept of sovereign computation in ACT-Omega.",
                "Sovereign computation guarantees that all training, inference, and telemetry remain entirely on local hardware without third-party cloud dependence."
            ),
            (
                "What is the ultimate objective of the sovereign manifold?",
                "The objective is to establish an autonomous, physically grounded, fault-tolerant cognitive architecture operating harmoniously across dual silicon."
            ),
        ],
    ];

    println!("[2/3] Tokenizing and Writing 10 Shards...");
    let mut total_batch_tokens = 0usize;

    for (group_idx, pairs) in dialogue_groups.iter().enumerate() {
        let shard_id = start_shard + group_idx;
        let mut shard_tokens: Vec<u8> = Vec::new();

        for (prompt, response) in pairs {
            let formatted = format_instruction_pair(prompt, response);
            let tokens: Vec<usize> = tokenize_conversational(&formatted);
            let u8_tokens: Vec<u8> = tokens.iter().map(|&t| (t % 240) as u8).collect();
            shard_tokens.extend_from_slice(&u8_tokens);
        }

        total_batch_tokens += shard_tokens.len();

        let path_primary = shards_dir.join(format!("shard_{}.bin", shard_id));
        let mut file_primary = File::create(&path_primary)?;
        file_primary.write_all(&shard_tokens)?;

        let path_240 = shards_240_dir.join(format!("shard_{}.bin", shard_id));
        let mut file_240 = File::create(&path_240)?;
        file_240.write_all(&shard_tokens)?;

        println!("  -> Wrote Shard {}: {} tokens", shard_id, shard_tokens.len());
    }

    println!("[3/3] Harvest Summary:");
    println!("  -> Total New Shards Written: 10");
    println!("  -> Total Tokens Ingested in Batch 30: {}", total_batch_tokens);
    println!("  -> New Vault Scale: {} Shards | ~{} Tokens", 
        start_shard + 10, 137704 + total_batch_tokens);
    println!("============================================================");
    println!("CURRICULUM BATCH 30 (GRAND UNIFIED) COMPLETE: PASS");
    println!("============================================================");

    Ok(())
}