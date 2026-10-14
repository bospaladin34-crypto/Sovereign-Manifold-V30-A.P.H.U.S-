// 01_l0_core/src/bin/test_ab_plaquette_coincidence.rs
// Verification Benchmark for v30 Track 2 & Track 8: Aharonov-Bohm Plaquette & Wheeler Coincidence Ledger

use std::time::Instant;
use act_omega_l0_core::ab_plaquette_coincidence::{
    CoincidenceState, EdgeStePacket, EXPECTED_AB_FLUX_RAD, PIXEL_8_CARRIER_RAD,
    PIXEL_10_CARRIER_RAD, WheelerCoincidenceLedger,
};
use act_omega_l0_core::sierpinski_158_quantizer::{
    PACKED_SIERPINSKI_BYTES, TOTAL_MANIFOLD_TRITS, is_sierpinski_boundary,
};

fn main() {
    println!("=========================================================================");
    println!(" ACT-OMEGA v30.0 | TRACK 2 & 8: AHARONOV-BOHM PLAQUETTE & WHEELER LEDGER ");
    println!("=========================================================================");

    let mut host_manifold: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let mut p10_deltas: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let mut p8_deltas: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);

    let mut idx: usize = 0;
    while idx < TOTAL_MANIFOLD_TRITS {
        let layer = idx / 256;
        let stalk = (idx % 256) / 8;
        let on_gasket = is_sierpinski_boundary(layer, stalk);
        host_manifold.push(if on_gasket { 48 } else { 4 });
        p10_deltas.push(if (idx % 2) == 0 { 16 } else { -12 });
        p8_deltas.push(if (idx % 2) == 0 { 14 } else { -10 });
        idx += 1;
    }

    let mut ledger = WheelerCoincidenceLedger::new(3001);

    let pkt_p10 = EdgeStePacket {
        sequence_window_id: 3001,
        node_serial_tag: 10,
        carrier_phase_rad: PIXEL_10_CARRIER_RAD,
        ste_deltas: p10_deltas,
    };
    let state_after_p10 = ledger.ingest_edge_packet(pkt_p10);
    let premature_collapse = ledger.try_collapse_plaquette(&mut host_manifold);
    assert!(state_after_p10 == CoincidenceState::UncollapsedSuperposition);
    assert!(premature_collapse.is_none());

    let pkt_p8 = EdgeStePacket {
        sequence_window_id: 3001,
        node_serial_tag: 8,
        carrier_phase_rad: PIXEL_8_CARRIER_RAD,
        ste_deltas: p8_deltas,
    };
    let t0 = Instant::now();
    let state_after_p8 = ledger.ingest_edge_packet(pkt_p8);
    let report = ledger.try_collapse_plaquette(&mut host_manifold).expect("Coincidence collapse failed");
    let collapse_us = t0.elapsed().as_secs_f64() * 1.0e6;

    let unitarity_sum = report.eraser_d0_cos2_weight + report.eraser_d1_sin2_weight;

    println!("1. Single-Node Arrival State (P10)  : UncollapsedSuperposition (Premature Collapse Blocked)");
    println!("2. Dual-Node Coincidence Window     : #{} (Pixel 10 + Pixel 8 Synchronized)", report.sequence_window_id);
    println!("3. Aharonov-Bohm Plaquette Flux     : {:.5} rad (Expected: {:.5} rad)", report.ab_flux_rad, EXPECTED_AB_FLUX_RAD);
    println!("4. SU(2) Wilson Loop Trace W(loop)  : {:.7}", report.wilson_loop_trace);
    println!("5. Quantum Eraser D0 cos^2 / D1 sin^2: {:.7} / {:.7} (Sum: {:.7})", report.eraser_d0_cos2_weight, report.eraser_d1_sin2_weight, unitarity_sum);
    println!("6. Active Sierpinski Stalks Gated   : {} / 240 E8 boundary stalks", report.updated_boundary_stalks);
    println!("7. Post-Collapse Packed Ternary Size: {} bytes (Boundary +/-1 Trits: {})", report.updated_tensor.packed_bytes.len(), report.updated_tensor.boundary_active_count);
    println!("8. Coincidence Collapse Latency     : {:.2} us", collapse_us);

    assert!(state_after_p8 == CoincidenceState::CollapsedCoincidence);
    assert!((report.ab_flux_rad - EXPECTED_AB_FLUX_RAD).abs() < 1.0e-6);
    assert!((unitarity_sum - 1.0).abs() < 1.0e-6);
    assert_eq!(report.updated_boundary_stalks, 240);
    assert_eq!(report.updated_tensor.packed_bytes.len(), PACKED_SIERPINSKI_BYTES);
    println!("=== TRACK 2 & TRACK 8 VERIFICATION: ALL ASSERTIONS PASSED ===");
}