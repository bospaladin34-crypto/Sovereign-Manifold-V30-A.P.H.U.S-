use std::collections::BTreeSet;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream, UdpSocket};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

const P2P_TCP_PORT: u16 = 8097;
const BEACON_UDP_PORT: u16 = 8098;
const MODEL_SIZE: usize = 7680;

fn get_shard_directories() -> Vec<PathBuf> {
    let candidates = [
        PathBuf::from("shards"),
        PathBuf::from("C:/sovereign_manifold_v30/01_l0_core/shards"),
        PathBuf::from("C:/sovereign_manifold_v30/04_canonical_vault/shards"),
        PathBuf::from("shards_240"),
        PathBuf::from("C:/sovereign_manifold_v30/01_l0_core/shards_240"),
        PathBuf::from("C:/sovereign_manifold_v30/04_canonical_vault/shards_240"),
    ];
    let mut dirs = Vec::new();
    for c in &candidates {
        if c.exists() && !dirs.contains(c) {
            dirs.push(c.clone());
        }
    }
    if dirs.is_empty() {
        dirs.push(PathBuf::from("shards"));
    }
    dirs
}

fn handle_client(
    mut stream: TcpStream,
    shard_dirs: &[PathBuf],
    model_path: &Path,
    edge_grads: &Arc<Mutex<Option<Vec<i8>>>>
) {
    let mut buf = [0u8; 256];
    if let Ok(n) = stream.read(&mut buf) {
        let req = String::from_utf8_lossy(&buf[..n]).trim().to_string();

        if req == "PING" {
            let _ = stream.write_all(b"PONG\n");
        } else if req == "LIST_SHARDS" {
            let mut shard_ids = BTreeSet::new();
            for s_dir in shard_dirs {
                if let Ok(entries) = fs::read_dir(s_dir) {
                    for e in entries.flatten() {
                        let name = e.file_name().to_string_lossy().to_string();
                        if name.starts_with("shard_") {
                            let id_str = name.trim_start_matches("shard_")
                                .trim_end_matches(".bin")
                                .trim_end_matches(".binshard");
                            if let Ok(id) = id_str.parse::<usize>() {
                                shard_ids.insert(id);
                            }
                        }
                    }
                }
            }
            let resp = shard_ids.iter().map(|id| id.to_string()).collect::<Vec<_>>().join(",");
            let _ = stream.write_all(format!("SHARDS:{}\n", resp).as_bytes());
        } else if req.starts_with("GET_SHARD:") {
            let id = req.trim_start_matches("GET_SHARD:");
            let mut found = false;
            for s_dir in shard_dirs {
                let target_bin = s_dir.join(format!("shard_{}.bin", id));
                let target_binshard = s_dir.join(format!("shard_{}.binshard", id));
                let p = if target_bin.exists() {
                    target_bin
                } else if target_binshard.exists() {
                    target_binshard
                } else {
                    continue;
                };

                if let Ok(mut f) = File::open(&p) {
                    let mut content = Vec::new();
                    if f.read_to_end(&mut content).is_ok() {
                        let header = format!("OK:{}\n", content.len());
                        let _ = stream.write_all(header.as_bytes());
                        let _ = stream.write_all(&content);
                        found = true;
                        break;
                    }
                }
            }
            if !found {
                let _ = stream.write_all(b"ERR:NOT_FOUND\n");
            }
        } else if req == "GET_MODEL" {
            if let Ok(mut f) = File::open(model_path) {
                let mut content = Vec::new();
                if f.read_to_end(&mut content).is_ok() {
                    let header = format!("OK:{}\n", content.len());
                    let _ = stream.write_all(header.as_bytes());
                    let _ = stream.write_all(&content);
                }
            } else {
                let _ = stream.write_all(b"ERR:NOT_FOUND\n");
            }
        } else if req.starts_with("PUSH_GRADIENTS:") {
            let mut grad_payload = vec![0u8; MODEL_SIZE];
            if stream.read_exact(&mut grad_payload).is_ok() {
                let grad_i8: Vec<i8> = grad_payload.iter().map(|&b| b as i8).collect();
                if let Ok(mut lock) = edge_grads.lock() {
                    *lock = Some(grad_i8);
                }

                // AllReduce: Persist and blend incoming delta into canonical weights
                let delta_path = Path::new("C:/sovereign_manifold_v30/04_canonical_vault/weights/edge_gradient_delta.bin");
                let mut final_delta = grad_payload.clone();
                if let Ok(existing) = fs::read(delta_path) {
                    if existing.len() == final_delta.len() {
                        for (dst, &src) in final_delta.iter_mut().zip(existing.iter()) {
                            let blended = ((*dst as i16 + src as i16) / 2) as u8;
                            *dst = blended;
                        }
                    }
                }
                let _ = fs::write(delta_path, &final_delta);

                static INGEST_SEQ: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(1);
                let seq_num = INGEST_SEQ.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                let node_raw = req.trim_start_matches("PUSH_GRADIENTS:").trim();
                let node_name = if node_raw.is_empty() { "Edge Device" } else { node_raw };
                println!(
                    "[P2P Swarm] [LIVE #{:04}] Ingested 7,680-byte Edge Gradient Delta from {}! (Timestamp: {:?})",
                    seq_num, node_name, std::time::SystemTime::now()
                );
                let _ = stream.write_all(b"ACK_GRADIENTS\n");
            }
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("====================================================");
    println!("ACT-Omega v30.0: Distributed In-Flight P2P Training Swarm");
    println!("Host: Lenovo LOQ 15IAX9 (garlock00)");
    println!("Protocols: Multi-Directory Shard Catalog + Dynamic AllReduce");
    println!("====================================================");

    let shard_dirs = Arc::new(get_shard_directories());
    let model_path = PathBuf::from("C:/sovereign_manifold_v30/04_canonical_vault/models/model_harmonic_iii_240.e8q");
    let edge_gradients: Arc<Mutex<Option<Vec<i8>>>> = Arc::new(Mutex::new(None));

    println!("Active Shard Serving Roots: {:?}", shard_dirs.as_ref());

    // UDP Beacon Thread (15.0 Hz Geodesic Pacing)
    let shard_dirs_clone = Arc::clone(&shard_dirs);
    thread::spawn(move || {
        let socket = UdpSocket::bind("0.0.0.0:0").expect("Failed to bind UDP sender");
        let _ = socket.set_broadcast(true);
        let broadcast_addr = format!("255.255.255.255:{}", BEACON_UDP_PORT);

        loop {
            let mut total_shards = 0usize;
            for d in shard_dirs_clone.as_ref() {
                if let Ok(entries) = fs::read_dir(d) {
                    total_shards += entries.flatten().count();
                }
            }
            let beacon_msg = format!("SWARM_BEACON:HOST=garlock00,SHARDS={},TCP={}\n", total_shards, P2P_TCP_PORT);
            let _ = socket.send_to(beacon_msg.as_bytes(), &broadcast_addr);
            thread::sleep(Duration::from_millis(66)); // 15.0 Hz
        }
    });

    let listener = TcpListener::bind(format!("0.0.0.0:{}", P2P_TCP_PORT))?;
    println!("Distributed Swarm Node Active on port {}", P2P_TCP_PORT);

    for stream in listener.incoming() {
        if let Ok(stream) = stream {
            let dirs = Arc::clone(&shard_dirs);
            let model = model_path.clone();
            let grads = Arc::clone(&edge_gradients);
            thread::spawn(move || {
                handle_client(stream, &dirs, &model, &grads);
            });
        }
    }
    Ok(())
}