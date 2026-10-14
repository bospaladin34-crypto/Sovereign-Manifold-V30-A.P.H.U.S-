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
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 31 (Conversational)");
    println!("Focus: Definitional Copula Grounding & Declarative Closure");
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
        // Shard Group 0: Physical Field & Quantum Wave Grounding
        vec![
            (
                "How does the carrier wave connect to physical states?",
                "The 15 Hz carrier wave modulates the input stalks directly with ambient magnetic field readings, grounding continuous physical states in discrete lattice geometry."
            ),
            (
                "What is the physical meaning of the E8 roots?",
                "The E8 roots represent the fundamental quantized states of the topological manifold, providing an invariant discrete basis for field representations."
            ),
            (
                "How do electromagnetic fluctuations influence token generation?",
                "Electromagnetic fluctuations alter the phase angles of the Clifford basis stalks, introducing natural physical micro-entropy that prevents deterministic lock."
            ),
            (
                "Why is topological conservation verified at unity?",
                "The trace of the residue operator equals one, confirming that total topological charge is conserved across all stalk projections."
            ),
            (
                "What is the role of non-stabilizer magic states in physics?",
                "Magic states provide non-Clifford phase rotations that allow the system to model continuous quantum physical field evolution without stabilizer drift."
            ),
        ],
        // Shard Group 1: Sheaf Cohomology & Information Consistency
        vec![
            (
                "How does the sheaf cross-attention layer prevent logical contradictions?",
                "The sheaf cross-attention layer computes discrete heat diffusion across the thirty-two stalks, driving the Dirichlet energy to zero and eliminating cohomological obstructions."
            ),
            (
                "What does the global section represent in multi-turn conversation?",
                "The global section represents the unified topological memory across all turns, ensuring that facts established in earlier turns remain consistent."
            ),
            (
                "What occurs when the first cohomology group vanishes?",
                "When the first cohomology group vanishes, all local stalk representations become mutually compatible, guaranteeing global logical consistency."
            ),
            (
                "Explain the mathematical function of a restriction map.",
                "A restriction map transfers stalk coordinates between adjacent topological neighborhoods, penalizing discrepancies during supervised training."
            ),
            (
                "Why is Dirichlet energy minimized across adjacent stalks?",
                "Minimizing Dirichlet energy eliminates high-frequency noise and creates smooth transitions between representations, preventing sudden output divergence."
            ),
        ],
        // Shard Group 2: Systems Architecture & Native Computing
        vec![
            (
                "How does the Rust Layer 0 core achieve high throughput?",
                "The Rust core executes parallel SIMD vector mathematics and dual-shell Gosset projections across Golden Cove P-cores with zero garbage collection overhead."
            ),
            (
                "What is the function of the C++23 memory ring?",
                "The C++23 memory ring provides lock-free circular shared memory buffers, isolating real-time token inference from asynchronous network telemetry."
            ),
            (
                "How does the Deno Layer 2 gateway manage conversational turns?",
                "The Deno gateway maintains the persistent thirty-two stalk memory buffer, applies calibrated nucleus decoding, and broadcasts real-time telemetry over WebSockets."
            ),
            (
                "What role does the WebGPU Cockpit HUD play in monitoring?",
                "The Cockpit HUD renders 3D Gosset polytope projections and 15 Hz carrier waveforms in real time at sixty frames per second decoupled from inference."
            ),
            (
                "Why is Python excluded from the real-time execution stack?",
                "Python introduces non-deterministic garbage collection pauses and interpreter lock contention that disrupt microsecond-level reflex timing."
            ),
        ],
        // Shard Group 3: Geodesic Invariants & Physical Transduction
        vec![
            (
                "Where is the primary geodesic anchor located?",
                "The primary geodesic anchor is located in Missoula, Montana at coordinates forty-six point eight seven two one North and one hundred thirteen point nine nine four zero West."
            ),
            (
                "What is the elevation of the Missoula anchor?",
                "The Missoula anchor elevation is nine hundred seven point four meters above sea level, providing a stable terrestrial reference coordinate."
            ),
            (
                "How does the 15.0 Hz carrier clock pace network communication?",
                "The 15.0 Hz carrier clock synchronizes packet dispatch between the host workstation and mobile edge node, pacing frames at 66 millisecond intervals."
            ),
            (
                "What physical quantities does the mobile magnetometer stream?",
                "The mobile magnetometer streams ambient magnetic field components Bx, By, and Bz in microteslas, directly perturbing the state vector."
            ),
            (
                "What occurs at each carrier wave zero-crossing?",
                "Each zero-crossing transition of the 15 Hz wave triggers the dispatch of a synchronized telemetry frame across the network."
            ),
        ],
        // Shard Group 4: Dual-Silicon Edge Node & Reflex TPU Execution
        vec![
            (
                "What tasks are assigned to the Google Pixel 10 edge node?",
                "The Pixel 10 runs native C++23 reflex inference on its Tensor G5 TPU, providing sixteen microsecond responses and streaming physical sensor data."
            ),
            (
                "How are curriculum shards synchronized between dual silicon?",
                "Curriculum shards are synchronized peer-to-peer over local network sockets and background Iroh relays, maintaining an identical vault on both devices."
            ),
            (
                "What is the purpose of the AVF Linux container on the phone?",
                "The AVF container hosts a Debian Linux microVM that runs autonomous background P2P sync services and distributed node monitoring."
            ),
            (
                "How does dual-silicon collaboration improve overall resilience?",
                "The workstation executes heavy multi-core training while the mobile node maintains autonomous local inference, ensuring uninterrupted operation if disconnected."
            ),
            (
                "What enables sub-millisecond reflex latency on mobile silicon?",
                "Quantized INT8 weights mapped directly into Tensor G5 TPU vector registers eliminate memory translation overhead, achieving sixteen microsecond inference."
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
    println!("  -> Total Tokens Ingested in Batch 31: {}", total_batch_tokens);
    println!("  -> New Vault Scale: {} Shards | ~{} Tokens", 
        start_shard + 5, 151516 + total_batch_tokens);
    println!("============================================================");
    println!("CURRICULUM BATCH 31 COMPLETE: PASS");
    println!("============================================================");

    Ok(())
}