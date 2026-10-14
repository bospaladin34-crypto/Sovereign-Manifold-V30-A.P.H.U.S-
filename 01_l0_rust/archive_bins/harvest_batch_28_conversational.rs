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
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 28 (Conversational)");
    println!("Focus: Declarative Predicates & Transitive Relational Verbs");
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

    // Curriculum Batch 28 Structured Dialogue Groups
    let dialogue_groups: Vec<Vec<(&str, &str)>> = vec![
        // Shard Group 0: Transitive Relational Geometry (Gosset E8 Projection)
        vec![
            (
                "How does the manifold project continuous fields into discrete states?",
                "The projection head maps continuous stalk coordinates directly onto the nearest E8 lattice root, which quantizes phase drift and stabilizes the state vector."
            ),
            (
                "What does the second shell provide to the computational architecture?",
                "The second shell provides two thousand one hundred sixty non-stabilizer magic states that enable arbitrary continuous rotations across high dimensional boundaries."
            ),
            (
                "How does the residue trace operator preserve topological invariants?",
                "The residue trace operator measures global section boundary flux and ensures that total topological charge remains conserved at unity."
            ),
            (
                "Why does the projection layer align stalks with lattice vertices?",
                "Aligning stalks with lattice vertices prevents chaotic trajectory divergence and bounds numerical representation errors within discrete Voronoi cells."
            ),
            (
                "What connects the first shell roots to physical quantum states?",
                "The two hundred forty minimal roots form the root system of Lie algebra E8, connecting discrete physical gauge symmetries to topological field configurations."
            ),
        ],
        // Shard Group 1: Relational Sheaf Diffusion & Cohomological Vanishing
        vec![
            (
                "How does inter-stalk diffusion eliminate informational contradiction?",
                "Inter-stalk diffusion smooths local discrepancies across adjacent stalks and vanishes the first cohomology obstruction group."
            ),
            (
                "What does a restriction map enforce across stalk boundaries?",
                "A restriction map enforces strict compatibility between overlapping local sections, penalizing mismatched information with coboundary loss."
            ),
            (
                "Why does the network minimize Dirichlet energy during training?",
                "Minimizing Dirichlet energy dampens high frequency noise, producing smooth semantic transitions and preventing catastrophic representation collapse."
            ),
            (
                "How do persistent stalks maintain multi-turn dialogue memory?",
                "Persistent stalks preserve topological section state across turns, allowing new prompts to modulate existing knowledge without recomputing past context."
            ),
            (
                "What confirms that global section convergence has occurred?",
                "Convergence is confirmed when the coboundary difference between all adjacent stalks drops below numerical tolerance, indicating zero obstruction."
            ),
        ],
        // Shard Group 2: Systems Runtime & Lock-Free Ring Buffers
        vec![
            (
                "How does the C++23 memory ring decouple inference from streaming?",
                "The C++23 memory ring uses lock-free circular buffers to isolate high frequency token generation from asynchronous telemetry broadcasting."
            ),
            (
                "What role does the Deno L2 gateway perform in the sovereign stack?",
                "The Deno gateway orchestrates high level state graphs, handles WebSocket client connections, and serves live HTTP telemetry to the Cockpit HUD."
            ),
            (
                "Why does zero-copy memory architecture improve throughput?",
                "Zero-copy architecture eliminates redundant memory copies and cache thrashing, sustaining over eighty-five thousand tokens per second on four P-cores."
            ),
            (
                "How does the WebGPU HUD render complex 3D polytope vectors?",
                "The WebGPU HUD utilizes custom WGSL compute and fragment shaders to project multidimensional vector scopes at sixty frames per second."
            ),
            (
                "What guarantees sub-millisecond reflex latency on the host?",
                "Sub-millisecond latency is guaranteed by deterministic thread affinity on Intel Golden Cove P-cores, avoiding operating system scheduler preemption."
            ),
        ],
        // Shard Group 3: Geodesic Carrier Synchronization & Sensory Anchoring
        vec![
            (
                "How does the ambient magnetic field modulate the compute manifold?",
                "The tri-axial magnetometer streams Bx, By, and Bz readings to perturb input stalks, grounding symbolic tokens in real physical space."
            ),
            (
                "What is the purpose of the 15.0 Hertz carrier clock?",
                "The 15.0 Hertz carrier clock synchronizes the internal timing of dual silicon nodes, aligning packet pacing with biological neural rhythms."
            ),
            (
                "Where is the primary geodesic anchor located?",
                "The primary geodesic anchor is anchored in Missoula, Montana at coordinates forty-six point eight seven two one North and one hundred thirteen point nine nine four zero West."
            ),
            (
                "How does sensory grounding prevent deterministic stiction?",
                "Sensory grounding injects physical micro-entropy into the system, keeping the manifold dynamically active and preventing stationary root lock."
            ),
            (
                "What happens when the carrier wave reaches a phase zero-crossing?",
                "Each zero-crossing transition of the carrier wave triggers the dispatch of a synchronized telemetry frame across the network."
            ),
        ],
        // Shard Group 4: Dual-Silicon Edge Swarm & Tensor G5 TPU Reflex
        vec![
            (
                "What computational tasks does the Pixel 10 edge node execute?",
                "The Pixel 10 edge node executes on-device C++23 reflex inference on the Tensor G5 TPU, providing sixteen microsecond local token generation."
            ),
            (
                "How do the LOQ 15 host and Pixel 10 edge node collaborate?",
                "The LOQ 15 workstation runs intensive multi-threaded QAT training and weight fusion, while the Pixel 10 captures physical telemetry and tests mobile inference."
            ),
            (
                "How are updated model weights transferred to the edge node?",
                "Updated weights are pushed over reverse ADB sockets or local Wi-Fi relays directly into the mobile application file system."
            ),
            (
                "What is the function of the AVF Linux container on Android?",
                "The Android Virtualization Framework hosts a headless Debian container that runs autonomous P2P swarm nodes and distributed sync tasks."
            ),
            (
                "Why is pure native code used instead of Python on edge devices?",
                "Pure native C++23 and Rust eliminate runtime interpreter overhead, garbage collection pauses, and multi-megabyte dependency footprints on mobile silicon."
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
    println!("  -> Total Tokens Ingested in Batch 28: {}", total_batch_tokens);
    println!("  -> New Vault Scale: {} Shards | ~{} Tokens", 
        start_shard + 5, 124862 + total_batch_tokens);
    println!("============================================================");
    println!("CURRICULUM BATCH 28 HARVEST COMPLETE: PASS");
    println!("============================================================");

    Ok(())
}