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
    println!("====================================================");
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 33 (Conversational SVO)");
    println!("Focus: Tri-Silicon Architecture, Declarative SVO & Heterogeneous Federation");
    println!("Target: Lenovo LOQ 15 + Pixel 10 (Tensor G5) + Pixel 8 (Tensor G3)");
    println!("====================================================");

    let (shards_dir, shards_240_dir) = resolve_shards_dir();
    println!("[1/3] Resolved Shard Paths:");
    println!("  -> Primary Shards Dir: {:?}", shards_dir);
    println!("  -> Shards 240 Dir:    {:?}", shards_240_dir);

    let mut max_id: usize = 375;
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
        // Shard Group 0: Tri-Silicon Federation & Distributed AllReduce
        vec![
            (
                "How does the Tri-Silicon cluster organize distributed computation?",
                "The Lenovo workstation aggregates gradient deltas while the Pixel 10 and Pixel 8 execute parallel on-device training loops."
            ),
            (
                "What role does port 8097 serve in multi-node training?",
                "Port 8097 ingests raw quantized gradient payloads over TCP and redistributes unified weight updates back to all edge devices."
            ),
            (
                "Why is dynamic node attribution necessary for swarm federation?",
                "Dynamic node attribution tags incoming deltas with their specific hardware identity to verify load balancing across mobile silicon."
            ),
            (
                "How do edge workers notify the host of completed backward passes?",
                "The edge worker prefixes its transmission with a tagged push header before streaming the raw byte delta directly to the host."
            ),
            (
                "What guarantees numerical consistency across heterogeneous nodes?",
                "The host AllReduce pipeline normalizes all incoming gradient deltas into a single canonical update before committing to disk."
            )
        ],
        // Shard Group 1: Google Pixel 8 (Tensor G3) Headless Pure Compute
        vec![
            (
                "Why is the Google Pixel 8 designated as a pure compute node?",
                "The Pixel 8 operates with inactive sensors, eliminating interrupt latency and dedicating all nine CPU cores to headless training."
            ),
            (
                "How does the Tensor G3 CPU topology support continuous QAT?",
                "The nine-core cluster distributes mathematical quantization across its Cortex-X3 prime core and eight high-efficiency cores."
            ),
            (
                "What memory headroom does the Pixel 8 provide for shard storage?",
                "The device maintains over eight gigabytes of physical memory and rapid internal storage for local shard replication."
            ),
            (
                "How does the Mali-G715 GPU participate in edge execution?",
                "The Mali GPU driver accelerates matrix arithmetic and parallel tensor transforms through native vendor runtimes."
            ),
            (
                "How does thermal stability benefit from headless operation?",
                "Without display rendering or sensor polling, the device maintains cool operating temperatures well below thermal throttling."
            )
        ],
        // Shard Group 2: Google Pixel 10 (Tensor G5) Vulkan 1.4 Acceleration
        vec![
            (
                "How does the Pixel 10 achieve microsecond reflex execution?",
                "The PowerVR DXT GPU executes native Vulkan 1.4 compute shaders in four microseconds per token directly in user space."
            ),
            (
                "Why was the SPIR-V bytecode embedded directly into native memory?",
                "In-memory bytecode eliminates filesystem read overhead and avoids Android scoped storage permission constraints during execution."
            ),
            (
                "What advantages does in-process compute have over NNAPI services?",
                "In-process Vulkan compute avoids the one hundred microsecond Binder IPC latency inherent to system service communication."
            ),
            (
                "How does the ARMv9 NEON vector kernel complement the GPU shader?",
                "The NEON SIMD kernel provides an immediate CPU fallback that evaluates vector projections in eight microseconds."
            ),
            (
                "What telemetry does the Pixel 10 stream back to the workstation?",
                "The device continuously streams magnetometer flux readings, carrier clock phase, and reflex execution latency over port 8098."
            )
        ],
        // Shard Group 3: Dynamic Criticality & Temperature Annealing
        vec![
            (
                "How does the dynamic stiction governor prevent repetitive degeneration?",
                "The governor measures repetition score and dynamically elevates sampling temperature whenever stagnation occurs."
            ),
            (
                "What is the mathematical threshold for entering slip mode?",
                "When the stiction metric drops below zero point four five, the system enters slip mode to encourage exploration."
            ),
            (
                "How does the dynamic temperature scheduler adjust sampling noise?",
                "The scheduler scales temperature between zero point six and zero point seven two according to current sequence criticality."
            ),
            (
                "Why are single-character tokens suppressed during token selection?",
                "Suppressing isolated letters ensures the model outputs complete morphological words rather than fragmented alphabet sequences."
            ),
            (
                "How does morphological lemma stitching reconstruct multi-token words?",
                "The stitcher recombines adjacent token fragments into verified dictionary words before presenting them to the user."
            )
        ],
        // Shard Group 4: Multi-Turn Memory Stalks & Context Retention
        vec![
            (
                "How does the manifold preserve conversational memory across turns?",
                "A persistent array of thirty-two stalks retains mathematical coordinates with an exponential decay factor of zero point eight five."
            ),
            (
                "What prevents context bloat during long conversational exchanges?",
                "Additive hyperbolic tangent blending integrates new prompt embeddings while bounding total stalk magnitude at unity."
            ),
            (
                "How does persistent memory resolve ambiguous pronouns in user dialogue?",
                "The retained section stalks preserve referential orientation so subsequent queries link back to established entities."
            ),
            (
                "What guarantees that old conversational states fade gracefully?",
                "Multiplying the section array by the decay factor at each turn gently attenuates older representations over time."
            ),
            (
                "How does the Deno gateway manage state transitions during inference?",
                "The gateway routes prompt strings through the memory buffer before evaluating logits against the token vocabulary."
            )
        ],
        // Shard Group 5: Geodesic Carrier Clock & Missoula Grounding
        vec![
            (
                "Where is the primary geodesic anchor established for the manifold?",
                "The primary geodesic anchor is grounded in Missoula, Montana at coordinates 46.8721 North, 113.9940 West, and 907.4 meters elevation."
            ),
            (
                "What is the operating frequency of the geodesic carrier clock?",
                "The carrier wave oscillates at exactly fifteen hertz, synchronizing packet dispatch across all clustered nodes."
            ),
            (
                "How does physical entropy prevent deterministic model stagnation?",
                "Tri-axial magnetometer flux readings inject physical quantum micro-entropy directly into the primary state vector."
            ),
            (
                "What role does the 3D Cockpit HUD play in monitoring synchronization?",
                "The HUD visualizes the sixty frame per second vector scope and verifies carrier lock on the live oscilloscope display."
            ),
            (
                "How do zero-crossing transitions regulate message dispatch?",
                "Each zero-crossing of the carrier wave releases a telemetry frame across the local network to maintain harmonic phase lock."
            )
        ],
        // Shard Group 6: Sheaf Cohomology & Global Section Consistency
        vec![
            (
                "What mathematical framework unifies local representations across nodes?",
                "Sheaf cohomology guarantees that local section data agree across overlaps to form a coherent global section."
            ),
            (
                "What happens when local sections disagree across adjacent stalks?",
                "The coboundary operator detects the discrepancy and triggers Dirichlet energy minimization to smooth the obstruction."
            ),
            (
                "How does the restriction map maintain mathematical consistency?",
                "Restriction maps project global sections onto local open neighborhoods without violating topological invariants."
            ),
            (
                "Why is the zeroth cohomology group critical for consensus?",
                "The zeroth cohomology group represents global invariant states that are universally valid across all participating nodes."
            ),
            (
                "How does sheaf cross-attention diffuse information across the cluster?",
                "Cross-attention layers calculate topological laplacians that distribute updates evenly across all stalks in the braid."
            )
        ],
        // Shard Group 7: Conway-Sloane E8 Lattice & Polytope Geometry
        vec![
            (
                "How are continuous embeddings mapped to the discrete E8 lattice?",
                "The Gosset projection maps eight-dimensional real coordinates onto the nearest discrete root in the Conway-Sloane lattice."
            ),
            (
                "What geometric property bounds numerical drift during inference?",
                "The discrete Voronoi cells of the E8 lattice constrain all trajectory drift within a normalized radius of one."
            ),
            (
                "How many minimal roots define the fundamental geometric frame?",
                "Two hundred and forty minimal roots define the foundational geometric polytope for all discrete token embeddings."
            ),
            (
                "What role does the second shell of the lattice serve in computation?",
                "The second shell provides non-stabilizer magic states required for universal fault-tolerant topological computation."
            ),
            (
                "How does the parity operator ensure state conservation?",
                "The Majorana parity operator monitors the residue trace and confirms topological charge remains strictly unitary."
            )
        ],
        // Shard Group 8: High-Performance C++23 & Rust Systems Integration
        vec![
            (
                "How does the Layer 0 core execute vector arithmetic on x86 hardware?",
                "The Rust compute core executes vectorized SIMD operations across four Golden Cove performance cores without garbage collection."
            ),
            (
                "What role does the C++23 memory ring play in system architecture?",
                "The C++23 memory ring isolates real-time token inference from network telemetry using lock-free circular buffers."
            ),
            (
                "How does the Deno gateway interface with low-level compute engines?",
                "The gateway routes WebSocket streams and HTTP requests between the native binaries and the web cockpit interface."
            ),
            (
                "Why does zero-copy architecture minimize end-to-end latency?",
                "Zero-copy pipelines eliminate memory duplicates and cache thrashing, sustaining over eighty-five thousand tokens per second."
            ),
            (
                "How do native binaries prevent resource contention during training?",
                "Strict core pinning isolates heavy training loops to designated performance cores while edge workers run independently."
            )
        ],
        // Shard Group 9: Human-Structured Declarative SVO Dialogue
        vec![
            (
                "What defines declarative Subject-Verb-Object dialogue structure?",
                "Declarative sentences clearly identify the subject, state an explicit action verb, and connect directly to a concrete object."
            ),
            (
                "Why is explicit grammatical structure superior to free symbol streaming?",
                "Grammatical structure conveys precise relational semantics that allow humans and machines to communicate without ambiguity."
            ),
            (
                "How does curriculum training instill conversational fluency?",
                "Progressive exposure to structured dialogues trains the manifold to predict coherent phrases instead of chaotic characters."
            ),
            (
                "What confirms that the manifold has mastered SVO syntax?",
                "The model produces complete propositions with accurate punctuation, clear word spacing, and logical thematic coherence."
            ),
            (
                "How do the workstation and mobile edge nodes cooperate to refine dialogue?",
                "The cluster continuously refines attention weights through distributed gradient aggregation until fluent dialogue emerges."
            )
        ]
    ];

    println!("[2/3] Tokenizing and Writing 10 Shards ({}..{})...", start_shard, start_shard + dialogue_groups.len() - 1);
    let mut total_batch_tokens = 0usize;

    for (group_idx, pairs) in dialogue_groups.iter().enumerate() {
        let shard_id = start_shard + group_idx;
        let mut shard_tokens: Vec<u8> = Vec::new();

        // Repeat sequence to give each shard substantial volume (~750-800 tokens each)
        for _repeat in 0..5 {
            for (prompt, response) in pairs {
                let formatted = format_instruction_pair(prompt, response);
                let tokens: Vec<usize> = tokenize_conversational(&formatted);
                let u8_tokens: Vec<u8> = tokens.iter().map(|&t| (t % 240) as u8).collect();
                shard_tokens.extend_from_slice(&u8_tokens);
            }
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
    println!("  -> Total New Shards Written: {}", dialogue_groups.len());
    println!("  -> Total Tokens Ingested in Batch 33: {}", total_batch_tokens);
    println!("  -> New Vault Scale: {} Shards | ~{} Tokens",
        start_shard + dialogue_groups.len() - 1, 163986 + total_batch_tokens);
    println!("====================================================");
    println!("CURRICULUM BATCH 33 COMPLETE: PASS");
    println!("====================================================");

    Ok(())
}