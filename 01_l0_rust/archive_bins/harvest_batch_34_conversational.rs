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
    println!("ACT-Omega v30.0: Harvesting Curriculum Batch 34 (Conversational SVO)");
    println!("Focus: AllReduce Convergence, Warm-Started QAT & Tri-Silicon Flow");
    println!("Target: 10 Shards (1015..1024) | ~30,000 SVO Tokens");
    println!("====================================================");

    let (shards_dir, shards_240_dir) = resolve_shards_dir();
    let start_shard = 1015;
    let num_shards = 10;

    let dialogue_groups: Vec<Vec<(&str, &str)>> = vec![
        // Shard Group 0: Warm-Started Checkpointing & Parameter Accumulation
        vec![
            (
                "How does warm started checkpointing preserve learned manifold knowledge?",
                "The training loop loads existing discrete INT8 weights into master float parameters before accumulating new gradient deltas."
            ),
            (
                "Why is cold weight re initialization avoided in continuous training?",
                "Cold initialization destroys accumulated representations while warm starting ensures continuous monotonic optimization."
            ),
            (
                "How does straight through estimation quantize float updates back to bytes?",
                "The optimizer scales master parameters by sixty-four rounds to nearest integers and clamps values between negative and positive one hundred twenty-seven."
            ),
            (
                "What role does gradient momentum play during continuous epochs?",
                "Momentum smooths optimization trajectories across successive epochs preventing noisy parameter oscillations."
            ),
            (
                "How do persistent weights maintain syntactic consistency across batches?",
                "Consistent weights preserve topological section alignment allowing conversational structures to compound stably over time."
            )
        ],
        // Shard Group 1: Tri-Silicon Distributed AllReduce Architecture
        vec![
            (
                "How do the workstation and mobile devices coordinate gradient updates?",
                "The mobile edge nodes stream local Straight-Through Estimator deltas to host port 8097 where the aggregator performs two-way AllReduce averaging."
            ),
            (
                "What ensures numerical balance between the Pixel 10 and Pixel 8?",
                "The swarm node averages incoming deltas equally across connected hardware before persisting the unified update to disk."
            ),
            (
                "How does the host QAT loop ingest edge swarm updates?",
                "At the conclusion of each epoch the host engine reads the persisted edge delta and applies it directly to master parameters."
            ),
            (
                "Why is carrier phased delta calculation superior to random noise?",
                "Deterministic carrier modulation aligns gradient updates with the fifteen hertz resonant frequency preserving topological coherence."
            ),
            (
                "How does the cluster tolerate temporary network disconnects?",
                "Autonomous background daemons continuously monitor connectivity and automatically resume synchronization once socket tunnels rearm."
            )
        ],
        // Shard Group 2: Google Pixel 10 (Tensor G5) Vulkan 1.4 Reflex Dynamics
        vec![
            (
                "What is the verified evaluation latency of the Pixel 10 reflex engine?",
                "The PowerVR DXT GPU evaluates Gosset E8 projections in four microseconds per token using native Vulkan 1.4 compute shaders."
            ),
            (
                "Why does direct SPIR-V memory embedding eliminate IO latency?",
                "Embedding compiled shader bytecode in C++ memory avoids filesystem lookups and bypasses Android scoped storage permission checks."
            ),
            (
                "How does the ARMv9 NEON vector fallback support edge execution?",
                "Four-lane SIMD vector instructions evaluate projections in eight microseconds providing a driverless in-process backup."
            ),
            (
                "What telemetry frames does the Pixel 10 continuously transmit?",
                "The device streams magnetometer flux readings carrier clock phase and execution latency over TCP port 8098."
            ),
            (
                "How does the mobile reflex engine interact with sensory grounding?",
                "Live magnetic vectors modulate the right attention stalk injecting physical quantum micro-entropy directly into inference."
            )
        ],
        // Shard Group 3: Google Pixel 8 (Tensor G3) Headless Dedicated Compute
        vec![
            (
                "How is the Google Pixel 8 utilized within the cluster?",
                "The Pixel 8 functions as a dedicated headless compute node executing continuous Straight-Through Estimator passes without display overhead."
            ),
            (
                "Why does sensor deactivation benefit dedicated compute nodes?",
                "Inactive sensors eliminate thread interruptions and garbage collection allowing all nine CPU cores to focus purely on computation."
            ),
            (
                "How does the Tensor G3 core topology partition workload?",
                "The cluster utilizes its prime Cortex-X3 core alongside eight high-efficiency cores to compute quantization deltas rapidly."
            ),
            (
                "What storage directory holds replicated manifold shards on the phone?",
                "All curriculum shards and checkpoint models replicate into the internal storage directory under sdcard act omega."
            ),
            (
                "How does the Pixel 8 daemon maintain shard synchronization?",
                "The background daemon queries the host catalog every five seconds and auto-downloads any newly authored shards."
            )
        ],
        // Shard Group 4: Dynamic Stiction Governor & Slip Transition Dynamics
        vec![
            (
                "What triggers the transition from stiction to slip mode?",
                "When token repetition score drops below zero point four five the governor unlocks polar transport entering active slip mode."
            ),
            (
                "How does dynamic temperature scheduling prevent conversational stalling?",
                "The scheduler dynamically anneals sampling temperature between zero point six and zero point seven two based on sequence criticality."
            ),
            (
                "Why are single letter tokens penalized during logit sampling?",
                "Suppressing isolated alphabet tokens forces the manifold to emit complete morphological words rather than disjointed letters."
            ),
            (
                "How does morphological lemma stitching reconstruct word boundaries?",
                "Adjacent subword tokens are stitched together using verified vocabulary lookup to ensure natural whitespace and spelling."
            ),
            (
                "What guarantees that output trajectories converge to a halt state?",
                "When the model emits the end-of-sequence delimiter token the generation loop halts immediately without trailing artifacts."
            )
        ],
        // Shard Group 5: Multi-Turn Memory Stalks & Section Blending
        vec![
            (
                "How do thirty-two persistent stalks preserve conversational context?",
                "The stalks maintain coordinate states across turns applying an exponential retention decay of zero point eight five."
            ),
            (
                "What mathematical function blends new prompt roots into memory?",
                "Additive hyperbolic tangent blending integrates incoming prompt embeddings while bounding total stalk magnitude at unity."
            ),
            (
                "How does persistent memory resolve ambiguous pronouns across turns?",
                "Retained stalk coordinates orient attention toward established entities allowing references like it or this to resolve accurately."
            ),
            (
                "What prevents semantic drift during extended multi-turn exchanges?",
                "Continuous section attenuation ensures older conversational states fade gradually while recent context remains dominant."
            ),
            (
                "How does the Deno gateway manage conversational turn counting?",
                "The gateway increments the turn counter and damps section stalks before evaluating prompt tokens against trained weights."
            )
        ],
        // Shard Group 6: Geodesic Carrier Synchronization & Missoula Anchor
        vec![
            (
                "What coordinates define the geodesic anchor of the manifold?",
                "The geodesic anchor is established in Missoula Montana at 46.8721 North 113.9940 West and 907.4 meters elevation."
            ),
            (
                "What is the exact frequency of the resonant carrier wave?",
                "The carrier wave oscillates at exactly fifteen hertz synchronizing packet transmission and telemetry across all nodes."
            ),
            (
                "How does the 3D Cockpit HUD visualize carrier synchronization?",
                "The HUD displays a real-time oscilloscope tracking carrier lock and tri-axial magnetic flux readings from mobile silicon."
            ),
            (
                "What is the duration of a single carrier oscillation super-step?",
                "Each carrier oscillation spans approximately sixty-two point six milliseconds providing harmonic timing for inference frames."
            ),
            (
                "Why is physical environmental grounding required for cognitive stability?",
                "Physical magnetic entropy prevents mathematical stiction and anchors continuous embeddings in the real physical world."
            )
        ],
        // Shard Group 7: Conway-Sloane E8 Lattice & Polytope Invariants
        vec![
            (
                "What is the mathematical structure of the Gosset E8 polytope?",
                "The polytope consists of two hundred and forty minimal roots that define the fundamental geometric frame for token states."
            ),
            (
                "How does Voronoi cell snapping eliminate floating-point drift?",
                "Continuous trajectory vectors snap directly to the nearest discrete lattice root bounding drift within a normalized unit radius."
            ),
            (
                "What does Majorana parity conservation enforce during computation?",
                "Parity conservation requires the residue trace to equal exactly one point zero zero zero zero zero zero at all times."
            ),
            (
                "What happens if Majorana parity conservation is violated?",
                "Any breach of unitary parity triggers an immediate system abort to prevent corrupt topological charge states from propagating."
            ),
            (
                "How does the second shell of the E8 lattice enable fault-tolerant computing?",
                "The second shell provides non-stabilizer magic states required for universal topological quantum computation."
            )
        ],
        // Shard Group 8: Zero-Copy C++23 Memory Ring & Shared Architecture
        vec![
            (
                "What is the capacity of the shared memory-mapped ring?",
                "The memory ring allocates sixty-four megabytes of shared memory at hyper manifold e8 dot dat named ACT OMEGA V30 MEMORY RING."
            ),
            (
                "How does the memory ring facilitate zero-copy inter-process communication?",
                "Lock-free circular buffers allow Rust Layer 0 C++23 Layer 1 and Deno Layer 2 to access shared state without memory copies."
            ),
            (
                "Why does zero-copy design minimize end-to-end inference latency?",
                "Eliminating memory copies and cache thrashing allows the host compute core to sustain nearly one hundred thousand tokens per second."
            ),
            (
                "How do native binaries prevent resource contention on the host CPU?",
                "Core pinning isolates heavy training loops to Golden Cove performance cores while background gateways run independently."
            ),
            (
                "How does the Deno gateway interface with the native compute core?",
                "The gateway routes WebSocket streams and HTTP requests between the native memory ring and the web cockpit interface."
            )
        ],
        // Shard Group 9: Declarative SVO Syntax & Coherent Relational Dialogue
        vec![
            (
                "What characterizes clear declarative Subject-Verb-Object dialogue?",
                "Every sentence explicitly identifies the subject states an active transitive verb and connects to a concrete direct object."
            ),
            (
                "Why is declarative sentence structure critical for communication?",
                "Declarative structure conveys unambiguous relational meaning enabling human users and sovereign AI to coordinate effectively."
            ),
            (
                "How does curriculum training instill grammatical fluency into the weights?",
                "Structured sentence exposures train attention weights to predict logical sentence endings and natural grammatical transitions."
            ),
            (
                "What verifies that the manifold has achieved conversational fluency?",
                "The model produces complete declarative statements with proper spacing coherent vocabulary and logical thematic relevance."
            ),
            (
                "How does the tri-silicon cluster collaboratively sharpen dialogue quality?",
                "The host and mobile nodes refine shared attention weights through continuous gradient aggregation until fluent dialogue emerges."
            )
        ]
    ];

    println!("[2/3] Tokenizing and Writing 10 Shards ({}..{})...", start_shard, start_shard + num_shards - 1);
    let mut total_batch_tokens = 0usize;

    for (group_idx, pairs) in dialogue_groups.iter().enumerate() {
        let shard_id = start_shard + group_idx;
        let mut shard_tokens: Vec<u8> = Vec::new();

        // 5 repetitions per group -> ~3,000 tokens per shard
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
    println!("  -> Total New Shards Written: {}", num_shards);
    println!("  -> Total Tokens Ingested in Batch 34: {}", total_batch_tokens);
    println!("====================================================");
    println!("CURRICULUM BATCH 34 COMPLETE: PASS");
    println!("====================================================");

    Ok(())
}