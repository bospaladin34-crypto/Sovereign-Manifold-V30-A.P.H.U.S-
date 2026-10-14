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
    
    if !primary.exists() {
        let _ = fs::create_dir_all(&primary);
    }

    let parent = primary.parent().unwrap_or_else(|| Path::new("."));
    let secondary = parent.join("shards_240");
    if !secondary.exists() {
        let _ = fs::create_dir_all(&secondary);
    }

    (primary, secondary)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("============================================================");
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 27 (Conversational)");
    println!("Focus: Syntactic Grammar & Sentence Completion");
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
                    if id > max_id {
                        max_id = id;
                    }
                }
            }
        }
    }
    let start_shard = max_id + 1;
    println!("  -> Identified Next Shard Index: {}", start_shard);

    // Curriculum Batch 27 Structured Dialogue Groups
    let dialogue_groups: Vec<Vec<(&str, &str)>> = vec![
        // Shard Group 0: Natural Syntactic Connectives & Topological Verification
        vec![
            (
                "How does the manifold verify topological conservation?",
                "The manifold computes the trace of the residue operator at every step. When the trace equals one, topological conservation is verified and the section remains globally consistent."
            ),
            (
                "What is the function of the sheaf cohomology layer?",
                "The sheaf cohomology layer computes local obstructions across the stalks. When the first cohomology group vanishes, the local states combine into a single coherent representation."
            ),
            (
                "Explain the role of restriction maps between adjacent stalks.",
                "Restriction maps ensure that data shared between neighboring stalks agrees. If there is a mismatch, the layer introduces an error penalty that drives the network toward agreement."
            ),
            (
                "Why is Dirichlet energy minimized across the stalks?",
                "Minimizing Dirichlet energy eliminates high frequency noise and creates smooth transitions between representations, preventing sudden jumps or contradictory outputs."
            ),
            (
                "What guarantees that token generation will converge?",
                "Convergence is guaranteed by the non-Hermitian damping factor, which dissipates excess kinetic energy and pulls the system into a stable ground state."
            ),
        ],
        // Shard Group 1: Gosset Multi-Shell Geometry & Quantum Magic States
        vec![
            (
                "Describe the geometric structure of the second Gosset shell.",
                "The second shell contains 2160 root vectors with norm squared four. These vectors form a high dimensional boundary that provides non-stabilizer magic states for fault-tolerant computation."
            ),
            (
                "How does dual shell projection operate during inference?",
                "During inference, each output stalk projects simultaneously onto the 240 first shell roots and the 2160 second shell roots, selecting the root that maximizes phase alignment."
            ),
            (
                "What is the physical meaning of the 240 first shell roots?",
                "The 240 first shell roots represent the minimal non-zero roots of the E8 Lie algebra with norm squared two, providing the foundational basis for discrete token states."
            ),
            (
                "How does root projection prevent phase drift over time?",
                "Because root vectors occupy fixed positions in the lattice, continuous phase drift is quantized into the nearest discrete root, preserving state fidelity across long sequences."
            ),
            (
                "Why are magic states necessary in topological computing?",
                "Magic states provide the non-Clifford operations required for universal quantum and topological computing, allowing the system to perform arbitrary continuous rotations."
            ),
        ],
        // Shard Group 2: Systems Runtime & Lock-Free Ring Buffers
        vec![
            (
                "How do the Rust L0 core and C++23 L1 memory ring communicate?",
                "The Rust core and C++23 memory ring communicate through lock-free shared memory circular buffers, transferring token arrays and field states with zero-copy overhead."
            ),
            (
                "What prevents latency spikes during real-time inference?",
                "Latency spikes are prevented by deterministic memory allocation, zero garbage collection pauses, and pre-compiled native vector instructions on the CPU and TPU."
            ),
            (
                "Describe the architecture of the Deno TypeScript gateway.",
                "The Deno gateway serves as the L2 orchestration layer, handling WebSocket streams, HTTP endpoints, and telemetry broadcasts between the compute core and the browser HUD."
            ),
            (
                "How does the WebGPU Cockpit HUD render vector trajectories?",
                "The Cockpit HUD renders 3D vector trajectories using dedicated WGSL compute shaders that draw Gosset polytope projections directly on the GPU at sixty frames per second."
            ),
            (
                "Why is zero-copy memory architecture essential for this manifold?",
                "Zero-copy architecture eliminates buffer cloning and cache invalidation, enabling sub-millisecond round-trip latency between sensory ingestion and token emission."
            ),
        ],
        // Shard Group 3: Geodesic Carrier Synchronization & Sensory Anchoring
        vec![
            (
                "What connects the physical environment to token generation?",
                "Tri-axial magnetometer readings from the mobile device are coupled directly to the input stalks, grounding token generation in real-time ambient magnetic fields."
            ),
            (
                "How does the 15.0 Hz carrier clock coordinate dual-silicon nodes?",
                "The 15.0 Hz carrier clock synchronizes the internal clock of both the laptop host and the mobile edge node, pacing packet transmission and maintaining phase lock."
            ),
            (
                "State the coordinates of the primary geodesic anchor.",
                "The primary geodesic anchor is located in Missoula, Montana at 46.8721 degrees North latitude, 113.9940 degrees West longitude, and 907.4 meters elevation."
            ),
            (
                "What happens when the carrier phase completes a full cycle?",
                "At each zero-crossing transition of the 15 Hz wave, the manifold releases a synchronized telemetry frame containing updated vector coordinates and energy metrics."
            ),
            (
                "Why is ambient sensory coupling important for cognition?",
                "Ambient sensory coupling breaks deterministic mathematical deadlocks, providing a natural physical entropy source that maintains the system at the edge of criticality."
            ),
        ],
        // Shard Group 4: Dual-Silicon Edge Deployment & Mobile TPU Execution
        vec![
            (
                "What role does the Google Pixel 10 play in the sovereign manifold?",
                "The Pixel 10 acts as the sovereign mobile edge node, running C++23 quantized reflex inference on its Tensor G5 TPU and streaming physical telemetry back to the host."
            ),
            (
                "How fast does the Tensor G5 TPU execute reflex inference?",
                "The Tensor G5 TPU executes quantized reflex inference in approximately 16 to 81 microseconds per token, providing immediate local response capability."
            ),
            (
                "How are updated weights transmitted to the Pixel 10?",
                "Updated quantized weights are transferred over reverse ADB sockets or local Wi-Fi relays directly into the mobile application private storage directory."
            ),
            (
                "What is the purpose of the AVF Linux container on the phone?",
                "The Android Virtualization Framework hosts a Debian Linux microVM that runs autonomous peer-to-peer network nodes and background sync tasks without root access."
            ),
            (
                "Explain the dual-silicon collaboration during active training.",
                "The host laptop uses its Intel P-cores to execute parallel QAT training over the full vault, while the phone continuously runs reflex inference and environmental monitoring."
            ),
        ],
    ];

    println!("[2/3] Tokenizing and Writing Shards...");
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
    println!("  -> Total New Shards Written: 5");
    println!("  -> Total Tokens Ingested in Batch 27: {}", total_batch_tokens);
    println!("  -> New Vault Scale: {} Shards | ~{} Tokens", 
        start_shard + 5, 117418 + total_batch_tokens);
    println!("============================================================");
    println!("CURRICULUM BATCH 27 HARVEST COMPLETE: PASS");
    println!("============================================================");

    Ok(())
}