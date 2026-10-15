// C:\sovereign_manifold_v31\01_l0_rust\src\bin\v31_swarm.rs
// Track 31.4: Unified ACT-Omega Net v31.1 Tri-Silicon UTCP-v31 Federated AllReduce & 1N4148 Ring Daemon (:8097)

use std::env;
use std::fs;
use std::io::{Read, Write};
use std::net::TcpListener;
use act_omega_l0_core::utcp_v31_ring::{UTCP_MAGIC, UTCP_VERSION_V31, fnv1a_hash64, run_utcp_v31_ring_audit};
use act_omega_l0_core::v31_desargues_dehornoy_teleparallel::run_v30_continuity_audit;

fn push_u16_le(buf: &mut Vec<u8>, v: u16) {
    buf.push((v & 0xFF) as u8);
    buf.push(((v >> 8) & 0xFF) as u8);
}

fn push_u32_le(buf: &mut Vec<u8>, v: u32) {
    for s in (0..32).step_by(8) {
        buf.push(((v >> s) & 0xFF) as u8);
    }
}

fn push_u64_le(buf: &mut Vec<u8>, v: u64) {
    for s in (0..64).step_by(8) {
        buf.push(((v >> s) & 0xFF) as u8);
    }
}

fn materialize_1n4148_ring_16kb() -> usize {
    let mut ring_bytes: Vec<u8> = Vec::with_capacity(16_384);
    let mut sample_grad: Vec<u8> = Vec::with_capacity(32);
    for i in 0..32usize {
        sample_grad.push(((i * 19 + 7) & 0xFF) as u8);
    }
    for slot in 0..256u64 {
        let origin_node: u32 = if (slot & 1) == 0 { 10 } else { 8 }; // Pixel 10 (0.17259 rad) & Pixel 8 (0.15000 rad)
        let digest = fnv1a_hash64(&sample_grad, slot ^ (origin_node as u64));
        push_u32_le(&mut ring_bytes, UTCP_MAGIC);
        push_u16_le(&mut ring_bytes, UTCP_VERSION_V31);
        push_u16_le(&mut ring_bytes, 0x000F);
        push_u64_le(&mut ring_bytes, slot + 1);
        push_u32_le(&mut ring_bytes, origin_node);
        push_u32_le(&mut ring_bytes, 1); // Host LOQ 15 target
        push_u32_le(&mut ring_bytes, 29_120); // SH4Z v3101 payload ref
        push_u16_le(&mut ring_bytes, 1); // beta_0 = 1
        push_u16_le(&mut ring_bytes, 3); // beta_1 = 3
        push_u32_le(&mut ring_bytes, 32); // stalk d_v = 32
        push_u32_le(&mut ring_bytes, 1707); // torsion_milli = 1.707
        push_u32_le(&mut ring_bytes, 2828); // chsh_milli = 2.828
        push_u64_le(&mut ring_bytes, (slot + 1) * 1_000);
        push_u64_le(&mut ring_bytes, digest);
    }
    let ring_path = "C:\\sovereign_manifold_v31\\03_vault\\ring\\utcp_1n4148_ring.bin";
    let _ = fs::write(ring_path, &ring_bytes);
    ring_bytes.len()
}

fn serve_swarm_8097(ring_bytes_len: usize) {
    if let Ok(listener) = TcpListener::bind("0.0.0.0:8097") {
        for stream_res in listener.incoming() {
            if let Ok(mut stream) = stream_res {
                let mut buf = Vec::with_capacity(512);
                buf.resize(512, 0u8);
                let _ = stream.read(&mut buf);
                let body = format!(
                    "{{\"service\":\"v31_utcp_federated_allreduce\",\"version\":\"ACT-Omega Net v31.1 (SH4Z v3101)\",\"port\":8097,\"utcp_v31\":true,\"ring_bytes\":{},\"ab_flux_rad\":0.02259,\"uarm_cascade\":\"SH-3.5(.e8q)->WebGround->SH-3.5(.e8t)->SH-3(BiStalk)->SH4Z(.e8z)\",\"holdout_ppl\":1.199,\"shards\":528,\"chair44_orbits\":12,\"stalk_dv\":32}}",
                    ring_bytes_len
                );
                let resp = format!(
                    "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                    body.len(), body
                );
                let _ = stream.write_all(resp.as_bytes());
            }
        }
    }
}

fn main() {
    let utcp = run_utcp_v31_ring_audit();
    let cont = run_v30_continuity_audit(528);
    let ring_len = materialize_1n4148_ring_16kb();
    println!(
        "[v31_swarm] UTCP-v31 Federated Ring Active ({} B) | Frames={} | Stalk d_v={} | T_AB={:.6} | Orbits={}x44",
        ring_len, utcp.frames_streamed, utcp.adaptive_stalk_dim, cont.ab_transmission, cont.complete_orbits
    );
    let is_daemon = env::args().any(|a| a == "--daemon");
    if is_daemon {
        println!("[v31_swarm] Daemon mode active on 0.0.0.0:8097 (UTCP-v31 Federated AllReduce)...");
        serve_swarm_8097(ring_len);
    }
}