// 01_l0_core/src/ab_plaquette_coincidence.rs
// v30 Track 2 & Track 8: Closed-Loop Aharonov-Bohm Plaquette Integrator
// & Wheeler Participatory Coincidence Ledger (garlock00 <-> Pixel 10 <-> Pixel 8)
// Zero-Square-Bracket Rust Invariant Enforced

use crate::sierpinski_158_quantizer::{
    E8_STALK_DIM, MANIFOLD_LAYERS, MANIFOLD_STALKS,
    Sierpinski158Tensor, is_sierpinski_boundary, quantize_heat_then_compress,
};

pub const PIXEL_10_CARRIER_RAD: f32 = 0.17259;
pub const PIXEL_8_CARRIER_RAD: f32 = 0.15000;
pub const EXPECTED_AB_FLUX_RAD: f32 = 0.02259;

#[derive(PartialEq, Eq)]
pub enum CoincidenceState {
    EmptyWindow,
    UncollapsedSuperposition,
    CollapsedCoincidence,
}

pub struct EdgeStePacket {
    pub sequence_window_id: u64,
    pub node_serial_tag: u32,
    pub carrier_phase_rad: f32,
    pub ste_deltas: Vec<i8>,
}

pub struct PlaquetteCollapseReport {
    pub sequence_window_id: u64,
    pub state: CoincidenceState,
    pub ab_flux_rad: f32,
    pub wilson_loop_trace: f32,
    pub eraser_d0_cos2_weight: f32,
    pub eraser_d1_sin2_weight: f32,
    pub updated_boundary_stalks: usize,
    pub updated_tensor: Sierpinski158Tensor,
}

pub struct WheelerCoincidenceLedger {
    pub active_window_id: u64,
    pub pixel10_slot: Option<EdgeStePacket>,
    pub pixel8_slot: Option<EdgeStePacket>,
    pub total_coincidences_collapsed: u64,
}

impl WheelerCoincidenceLedger {
    pub fn new(initial_window_id: u64) -> Self {
        WheelerCoincidenceLedger {
            active_window_id: initial_window_id,
            pixel10_slot: None,
            pixel8_slot: None,
            total_coincidences_collapsed: 0,
        }
    }

    pub fn ingest_edge_packet(&mut self, packet: EdgeStePacket) -> CoincidenceState {
        if packet.sequence_window_id != self.active_window_id {
            self.active_window_id = packet.sequence_window_id;
            self.pixel10_slot = None;
            self.pixel8_slot = None;
        }
        if packet.node_serial_tag == 10 {
            self.pixel10_slot = Some(packet);
        } else if packet.node_serial_tag == 8 {
            self.pixel8_slot = Some(packet);
        }
        if self.pixel10_slot.is_some() && self.pixel8_slot.is_some() {
            CoincidenceState::CollapsedCoincidence
        } else if self.pixel10_slot.is_some() || self.pixel8_slot.is_some() {
            CoincidenceState::UncollapsedSuperposition
        } else {
            CoincidenceState::EmptyWindow
        }
    }

    pub fn try_collapse_plaquette(&mut self, host_manifold: &mut Vec<i8>) -> Option<PlaquetteCollapseReport> {
        if self.pixel10_slot.is_none() || self.pixel8_slot.is_none() {
            return None;
        }
        let p10 = self.pixel10_slot.take().unwrap();
        let p8 = self.pixel8_slot.take().unwrap();

        let ab_flux_rad = p10.carrier_phase_rad - p8.carrier_phase_rad;
        let half_flux = 0.5 * ab_flux_rad;
        let cos_half = half_flux.cos();
        let sin_half = half_flux.sin();
        let wilson_loop_trace = cos_half;
        let eraser_d0_cos2_weight = cos_half * cos_half;
        let eraser_d1_sin2_weight = sin_half * sin_half;

        let cos_ab = ab_flux_rad.cos();
        let sin_ab = ab_flux_rad.sin();
        let mut updated_boundary_stalks: usize = 0;

        let mut layer: usize = 0;
        while layer < MANIFOLD_LAYERS {
            let mut stalk: usize = 0;
            while stalk < MANIFOLD_STALKS {
                let on_gasket = is_sierpinski_boundary(layer, stalk);
                if on_gasket {
                    updated_boundary_stalks += 1;
                }
                let mut dim: usize = 0;
                while dim < E8_STALK_DIM {
                    let idx = (layer * MANIFOLD_STALKS + stalk) * E8_STALK_DIM + dim;
                    let h_val = *host_manifold.get(idx).unwrap_or(&0) as f32;
                    let d10 = *p10.ste_deltas.get(idx).unwrap_or(&0) as f32;
                    let d8 = *p8.ste_deltas.get(idx).unwrap_or(&0) as f32;

                    let merged = if on_gasket {
                        let sym_d0 = 0.5 * (d10 + d8) * eraser_d0_cos2_weight;
                        let anti_d1 = 0.5 * (d10 - d8) * eraser_d1_sin2_weight;
                        let gauge_transport = d10 * cos_ab - d8 * sin_ab;
                        h_val + 0.5 * (sym_d0 + anti_d1 + 0.25 * gauge_transport)
                    } else {
                        h_val * 0.5
                    };
                    if let Some(slot) = host_manifold.get_mut(idx) {
                        *slot = merged.round().clamp(-127.0, 127.0) as i8;
                    }
                    dim += 1;
                }
                stalk += 1;
            }
            layer += 1;
        }

        self.total_coincidences_collapsed += 1;
        let updated_tensor = quantize_heat_then_compress(host_manifold, ab_flux_rad);

        Some(PlaquetteCollapseReport {
            sequence_window_id: p10.sequence_window_id,
            state: CoincidenceState::CollapsedCoincidence,
            ab_flux_rad,
            wilson_loop_trace,
            eraser_d0_cos2_weight,
            eraser_d1_sin2_weight,
            updated_boundary_stalks,
            updated_tensor,
        })
    }
}