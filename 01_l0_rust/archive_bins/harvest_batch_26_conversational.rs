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
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 26 (Conversational)");
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

    // Curriculum Batch 26 Dialogue Groups
    let dialogue_groups: Vec<Vec<(&str, &str)>> = vec![
        // Shard Group 0: Dialogue Framing & Special Token Mechanics
        vec![
            (
                "How do special tokens frame conversational turns in the manifold?",
                "Special tokens structure the sequence into discrete causal phases. The prompt token sets the conditioning context, the response token activates supervised prediction, and the end token marks conversational turn completion."
            ),
            (
                "Why is loss backpropagation masked during the prompt phase?",
                "Masking the prompt preserves the user prompt representation across the 32 stalks without penalizing prior conversational tokens, focusing gradient updates strictly on the emitted response."
            ),
            (
                "What triggers generation termination in conversational dialogue?",
                "The manifold emits the end-of-sequence token at index 239 when the topological state completes its trajectory and returns to the stable vacuum ground state."
            ),
            (
                "How does the tokenizer handle alphanumeric and punctuation strings?",
                "The BPE tokenizer maps whitespace-separated words into root-aligned subwords and falls back to character-level ASCII tokens within the 240-element vocabulary."
            ),
            (
                "Explain how conversational conditioning stabilizes autoregressive generation.",
                "Prompt tokens prime the 30-layer sheaf state with initial boundary conditions, preventing unguided drift into stationary root attractors."
            ),
        ],
        // Shard Group 1: Multi-Turn Consistency & Sheaf Restriction Maps
        vec![
            (
                "How do sheaf restriction maps enforce multi-turn consistency?",
                "Restriction maps verify that representations in overlapping stalk neighborhoods agree. Conflicting statements produce non-zero cohomology cocycles that are penalized by the loss function."
            ),
            (
                "What is a global section in conversational memory?",
                "A global section is a continuous assignment of states across all 32 stalks that satisfies all restriction maps, ensuring factual claims remain coherent across dialogue turns."
            ),
            (
                "How does Dirichlet energy descent eliminate conversational hallucinations?",
                "Dirichlet energy measures high-frequency variance between adjacent stalks. Diffusion smooths local inconsistencies, dampening spurious activations before token projection."
            ),
            (
                "What role does the second cohomology group play in discourse?",
                "The second cohomology group measures obstruction to extending local dialogue segments into globally consistent narratives across extended interaction histories."
            ),
            (
                "Describe how stalk state persistence supports context memory.",
                "Stalk states from preceding turns act as persistent topological memory, allowing subsequent turns to modulate existing sections without recalculating earlier context from scratch."
            ),
        ],
        // Shard Group 2: Dual-Silicon Distributed Inference & P2P Swarm
        vec![
            (
                "How do the Lenovo LOQ host and Pixel 10 edge node split inference?",
                "The Lenovo LOQ 15 handles heavy multi-core QAT training and global section optimization, while the Pixel 10 Tensor G5 executes quantized 81 microsecond reflex responses."
            ),
            (
                "What protocol synchronizes model checkpoints between dual silicon?",
                "Checkpoints are synchronized over HTTP port 8099 and direct ADB reverse sockets, transitioning to peer-to-peer Iroh relays inside the AVF Debian container."
            ),
            (
                "Describe the role of mDNS auto-discovery on local networks.",
                "mDNS broadcasts sovereign node availability on port 8098, enabling zero-config peer pairing between the workstation and mobile device without manual IP configuration."
            ),
            (
                "How does the C++23 reflex engine run on Android without Python?",
                "The native C++23 engine compiles directly via the Android NDK into an arm64-v8a shared library, mapped directly to hardware vector registers and the Tensor TPU."
            ),
            (
                "What ensures fault tolerance if mobile communication drops?",
                "Both nodes maintain autonomous local quantized manifolds. If network synchronization drops, each node continues executing local inference independently until reconnection."
            ),
        ],
        // Shard Group 3: Geodesic Carrier Transduction & 15 Hz Clock
        vec![
            (
                "Why is the carrier clock tuned to 15.0 Hertz?",
                "The 15 Hz carrier clock aligns with biological low-beta neural oscillation, matching the perceptual integration window for human-machine telemetry."
            ),
            (
                "How are real-time geomagnetic fields transduced into tokens?",
                "Tri-axial magnetometer vectors Bx, By, and Bz modulate the phase offset of the carrier clock, grounding token generation in physical ambient field dynamics."
            ),
            (
                "What is the geodesic anchor coordinate for the sovereign manifold?",
                "The geodesic anchor is fixed in Missoula, Montana at latitude 46.8721 North, longitude 113.9940 West, and elevation 907.4 meters above sea level."
            ),
            (
                "Explain the phase coupling between carrier oscillation and token emission.",
                "Tokens are emitted synchronously with the zero-crossing phase transitions of the 15 Hz carrier wave, preventing packet jitter and stabilizing network pacing."
            ),
            (
                "How does sensory modulation prevent deterministic model freezing?",
                "Ambient field fluctuations inject micro-scale phase noise into the input stalk coordinates, continuously nudging the manifold out of potential stiction states."
            ),
        ],
        // Shard Group 4: Autopoietic Criticality & Self-Stabilization
        vec![
            (
                "What are the target balance metrics for autopoietic criticality?",
                "The manifold targets an integration-segregation index of B = 0.45 and an avalanche criticality exponent of alpha = 1.5, maintaining the edge of chaos."
            ),
            (
                "How does the closed-loop governor regulate stiction?",
                "When sliding-window token entropy drops below 1.2 nats, the governor detects stiction and injects non-Hermitian kinetic kicks to restore aperiodic flow."
            ),
            (
                "Describe the balance between integration and segregation in the stalks.",
                "Segregation allows individual stalks to represent specialized features, while integration via cross-attention binds them into unified conceptual representations."
            ),
            (
                "What occurs when criticality alpha deviates from 1.5?",
                "If alpha exceeds 1.5, dynamics collapse into rigid subcritical stiction. If alpha falls below 1.5, the system enters supercritical divergence and loses semantic coherence."
            ),
            (
                "Define autopoiesis in the context of the sovereign manifold.",
                "Autopoiesis is the manifold capacity to continuously regenerate its own operational state, weights, and communication channels through recursive closed-loop feedback."
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
    println!("  -> Total Tokens Ingested in Batch 26: {}", total_batch_tokens);
    println!("  -> New Vault Scale: {} Shards | ~{} Tokens", 
        start_shard + 5, 109866 + total_batch_tokens);
    println!("============================================================");
    println!("CURRICULUM BATCH 26 HARVEST COMPLETE: PASS");
    println!("============================================================");

    Ok(())
}