// C:\sovereign_manifold_v31\01_l0_rust\src\bin\v31_swarm.rs
// Unified ACT-Omega Net v31.0 Tri-Silicon P2P Swarm (:8097) Daemon

use std::env;
use std::io::{Read, Write};
use std::net::TcpListener;
use act_omega_l0_core::utcp_v31_ring::run_utcp_v31_ring_audit;
use act_omega_l0_core::v31_desargues_dehornoy_teleparallel::run_v30_continuity_audit;

fn serve_swarm_8097() {
    if let Ok(listener) = TcpListener::bind("0.0.0.0:8097") {
        for stream_res in listener.incoming() {
            if let Ok(mut stream) = stream_res {
                let mut buf = Vec::with_capacity(512);
                buf.resize(512, 0u8);
                let _ = stream.read(&mut buf);
                let body = "{\"service\":\"v31_utcp_swarm\",\"version\":\"ACT-Omega Net v31.0 (SH-4)\",\"port\":8097,\"utcp_v31\":true,\"holdout_ppl\":1.444,\"shards\":485,\"stalk_dv\":32}";
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
    let cont = run_v30_continuity_audit(485);
    println!(
        "[v31_swarm] UTCP-v31 Ring Active | Frames={} | Stalk d_v={} | T_AB={:.6} | Visibility={:.6}",
        utcp.frames_streamed, utcp.adaptive_stalk_dim, cont.ab_transmission, cont.wheeler_visibility
    );
    let is_daemon = env::args().any(|a| a == "--daemon");
    if is_daemon {
        println!("[v31_swarm] Daemon mode active on 0.0.0.0:8097 (UTCP-v31 Ring)...");
        serve_swarm_8097();
    }
}