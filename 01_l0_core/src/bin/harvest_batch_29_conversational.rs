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
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 29 (Conversational)");
    println!("Focus: Conversational Copula & Definitional Sentences");
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

    // Curriculum Batch 29 Structured Dialogue Groups
    let dialogue_groups: Vec<Vec<(&str, &str)>> = vec![
        // Shard Group 0: Definitional Geometry & Polytope Copula
        vec![
            (
                "What is the second Gosset shell?",
                "The second shell is a geometric boundary that consists of 2160 root vectors with norm squared four, providing non-stabilizer magic states."
            ),
            (
                "What defines the 240 minimal roots of E8?",
                "The 240 minimal roots are the first shell vertices of the Gosset polytope, each possessing norm squared two and defining the roots of the exceptional Lie algebra."
            ),
            (
                "What is a Voronoi cell in the E8 lattice?",
                "A Voronoi cell is the convex polytope surrounding each lattice vertex, defining the nearest-neighbor quantization boundary that bounds phase drift."
            ),
            (
                "What is the residue operator?",
                "The residue operator is a topological flux measurement whose trace equals one, confirming conservation across the global section."
            ),
            (
                "What are non-stabilizer magic states?",
                "Magic states are non-Clifford quantum states that enable universal fault-tolerant computation by providing arbitrary phase rotations."
            ),
        ],
        // Shard Group 1: Sheaf Cohomology & Mathematical Copula
        vec![
            (
                "What is a stalk in the sheaf manifold?",
                "A stalk is a local eight-dimensional vector space assigned to each node of the topological graph, holding local feature representations."
            ),
            (
                "What is a restriction map?",
                "A restriction map is a linear operator that maps stalk representations from an open set to its subsets, enforcing local section agreement."
            ),
            (
                "What is the first cohomology group H1?",
                "The first cohomology group is a mathematical invariant that measures the presence of topological obstructions to forming a global section."
            ),
            (
                "What is Dirichlet energy in sheaf theory?",
                "Dirichlet energy is the sum of squared differences between adjacent stalks, measuring the total spatial irregularity across the manifold."
            ),
            (
                "What defines global section consistency?",
                "Global section consistency is the state where all local stalk representations agree across restriction maps with zero cohomological obstruction."
            ),
        ],
        // Shard Group 2: System Architecture & Hardware Copula
        vec![
            (
                "What is the L0 core?",
                "The L0 core is a deterministic Rust compute engine that executes vector math, Gosset projection, and parallel QAT training without garbage collection."
            ),
            (
                "What is the L1 memory ring?",
                "The L1 memory ring is a lock-free C++23 circular buffer that transfers token arrays and telemetry between compute threads with zero-copy overhead."
            ),
            (
                "What is the L2 gateway?",
                "The L2 gateway is a Deno TypeScript server that manages WebSocket streams, REST endpoints, and multi-node synchronization on port 8099."
            ),
            (
                "What is the WebGPU Cockpit HUD?",
                "The Cockpit HUD is a real-time browser console that renders 3D vector trajectories and oscilloscope telemetry directly on the GPU at sixty frames per second."
            ),
            (
                "What is the Intel Core i5-12450HX?",
                "The i5-12450HX is the workstation host processor, featuring four Golden Cove P-cores with vector extensions that run parallel QAT training at flat sixteen percent utilization."
            ),
        ],
        // Shard Group 3: Geodesic Coordinates & Transduction Copula
        vec![
            (
                "What is the geodesic anchor?",
                "The geodesic anchor is a fixed physical reference in Missoula, Montana located at latitude 46.8721 North and longitude 113.9940 West at elevation 907.4 meters."
            ),
            (
                "What is the 15.0 Hz carrier clock?",
                "The 15.0 Hz carrier clock is a biological resonance wave that paces token emission and coordinates timing between the host and mobile edge node."
            ),
            (
                "What is the tri-axial magnetometer?",
                "The tri-axial magnetometer is an ambient physical sensor that measures local geomagnetic flux in microteslas across the X, Y, and Z axes."
            ),
            (
                "What is sensory modulation?",
                "Sensory modulation is the coupling of real-time physical magnetic readings into input stalks, grounding symbolic tokens in ambient physical space."
            ),
            (
                "What is thalamic phase?",
                "Thalamic phase is a cyclic angular coordinate in radians that tracks the oscillation state of the 15 Hz carrier wave at each telemetry frame."
            ),
        ],
        // Shard Group 4: Mobile Edge & P2P Swarm Copula
        vec![
            (
                "What is the Google Pixel 10 edge node?",
                "The Pixel 10 is an autonomous mobile edge node equipped with a Tensor G5 TPU, executing on-device C++23 reflex inference in sixteen microseconds."
            ),
            (
                "What is the AVF Debian container?",
                "The AVF Debian container is a virtualized Linux microVM running on Android that hosts headless P2P swarm nodes and background data relays."
            ),
            (
                "What is an Iroh P2P swarm?",
                "An Iroh swarm is a peer-to-peer network protocol that replicates curriculum shards and model checkpoints directly over local Wi-Fi without central servers."
            ),
            (
                "What is mDNS auto-discovery?",
                "mDNS auto-discovery is a zero-configuration network protocol that enables nodes to find and pair with each other on port 8098 without manual IP configuration."
            ),
            (
                "What is reflex inference?",
                "Reflex inference is low-latency on-device token prediction executed directly on mobile neural hardware without network round-trips."
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
    println!("  -> Total Tokens Ingested in Batch 29: {}", total_batch_tokens);
    println!("  -> New Vault Scale: {} Shards | ~{} Tokens", 
        start_shard + 5, 131748 + total_batch_tokens);
    println!("============================================================");
    println!("CURRICULUM BATCH 29 HARVEST COMPLETE: PASS");
    println!("============================================================");

    Ok(())
}