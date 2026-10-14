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
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 32 (Conversational)");
    println!("Focus: Full Declarative SVO Sentence Mastery");
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
        // Shard Group 0: Declarative Polytope & Projection Physics
        vec![
            (
                "What does the Gosset projection accomplish?",
                "The Gosset projection maps continuous stalk coordinates directly onto discrete E8 lattice vertices."
            ),
            (
                "What does the second shell provide?",
                "The second shell provides non-stabilizer magic states for universal fault-tolerant computation."
            ),
            (
                "How does the manifold preserve topological charge?",
                "The residue trace operator measures the global section boundary flux and conserves total topological charge at unity."
            ),
            (
                "What bounds numerical trajectory drift?",
                "The discrete Voronoi cells of the E8 lattice bound all trajectory drift within a radius of one."
            ),
            (
                "How do the 240 minimal roots function?",
                "The two hundred forty minimal roots establish the fundamental geometric frame for all discrete token states."
            ),
        ],
        // Shard Group 1: Sheaf Cohomology & Global Section Consistency
        vec![
            (
                "How does the sheaf cross-attention layer operate?",
                "The sheaf cross-attention layer diffuses local representations across adjacent stalks to smooth informational discrepancies."
            ),
            (
                "What eliminates logical contradictions across turns?",
                "Dirichlet energy minimization smooths high-frequency variance across stalks until the first cohomology obstruction vanishes."
            ),
            (
                "What does a restriction map enforce?",
                "A restriction map enforces strict mathematical agreement between overlapping local section neighborhoods."
            ),
            (
                "How does the manifold maintain conversational memory?",
                "The thirty-two persistent stalks preserve the topological section state across consecutive dialogue turns."
            ),
            (
                "What confirms global section convergence?",
                "Zero coboundary norm between adjacent stalks confirms that the global section has achieved full convergence."
            ),
        ],
        // Shard Group 2: High-Performance Systems & Native Execution
        vec![
            (
                "How does the Layer 0 core execute vector math?",
                "The Layer 0 Rust core executes parallel SIMD vector operations across four Golden Cove P-cores without garbage collection."
            ),
            (
                "What does the C++23 memory ring accomplish?",
                "The C++23 memory ring isolates real-time token inference from network telemetry using lock-free circular buffers."
            ),
            (
                "How does the Deno gateway manage network traffic?",
                "The Deno gateway routes WebSocket streams and HTTP requests between the compute engine and the Cockpit HUD."
            ),
            (
                "How does the WebGPU HUD render the vector scope?",
                "The WebGPU HUD executes custom WGSL compute shaders directly on the GPU at sixty frames per second."
            ),
            (
                "Why does zero-copy architecture improve latency?",
                "Zero-copy architecture eliminates memory copies and cache thrashing, sustaining over eighty-five thousand tokens per second."
            ),
        ],
        // Shard Group 3: Physical Transduction & Geodesic Invariants
        vec![
            (
                "How does ambient magnetic flux modulate the manifold?",
                "The tri-axial magnetometer streams Bx, By, and Bz flux readings to perturb the input stalks in real time."
            ),
            (
                "What role does the carrier wave perform?",
                "The 15.0 Hertz carrier wave synchronizes packet transmission between dual-silicon nodes at sixty-six millisecond intervals."
            ),
            (
                "State the coordinates of the Missoula anchor.",
                "The primary geodesic anchor is located in Missoula, Montana at coordinates 46.8721 North, 113.9940 West, and 907.4 meters elevation."
            ),
            (
                "What happens at each carrier wave zero-crossing?",
                "Each zero-crossing transition of the 15 Hz wave triggers the release of a synchronized telemetry frame across the network."
            ),
            (
                "Why is sensory grounding essential for stability?",
                "Sensory grounding injects physical micro-entropy into the state vector to prevent deterministic mathematical stiction."
            ),
        ],
        // Shard Group 4: Dual-Silicon Edge Hardware & Vulkan Acceleration
        vec![
            (
                "How does the Pixel 10 accelerate reflex inference?",
                "The Pixel 10 executes native Vulkan 1.4 compute shaders on the PowerVR DXT GPU in four microseconds per token."
            ),
            (
                "What is the function of the ARMv9.2-A NEON kernel?",
                "The ARMv9.2-A NEON kernel provides an in-process CPU vector fallback that evaluates projections in eight microseconds."
            ),
            (
                "How does the autonomous P2P daemon synchronize shards?",
                "The autonomous P2P daemon polls the host on port 8097 every five seconds and replicates new curriculum shards automatically."
            ),
            (
                "What role does the AVF Debian container fulfill?",
                "The AVF Debian container hosts autonomous background network services and distributed peer-to-peer relays on mobile silicon."
            ),
            (
                "How do the host and edge nodes collaborate during training?",
                "The host workstation executes heavy multi-threaded QAT training while the mobile node runs real-time reflex inference and sensor transduction."
            ),
        ],
    ];

    println!("[2/3] Tokenizing and Writing 5 Shards...");
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
    println!("  -> Total Tokens Ingested in Batch 32: {}", total_batch_tokens);
    println!("  -> New Vault Scale: {} Shards | ~{} Tokens", 
        start_shard + 5, 158522 + total_batch_tokens);
    println!("============================================================");
    println!("CURRICULUM BATCH 32 COMPLETE: PASS");
    println!("============================================================");

    Ok(())
}