use std::time::Instant;
use std::sync::Arc;
use std::fs::File;
use std::io::{Write, Result};
use crate::rebar_slot::RebarSensorFrame;
use crate::e8_lattice::ConwaySloaneE8;
use crate::e8_table_gemv::{E8TableGEMV, NUM_E8_ROOTS, CANONICAL_E8Q_BYTES};

pub const NUM_LAYERS: usize = 30;
pub const NUM_STALKS: usize = 32;
pub const STALK_DIM: usize = 8;
pub const D_MODEL: usize = NUM_STALKS * STALK_DIM; // 256
pub const VOCAB_SIZE: usize = 64;

#[derive(Clone)]
pub struct TopologicalLayer {
    pub layer_id: usize,
    pub afe_stiction: f32,
    pub row_codewords: Box<[[u8; NUM_STALKS]; D_MODEL]>,
}

impl TopologicalLayer {
    pub fn new(layer_id: usize, e8q_payload: Option<&[u8]>) -> Self {
        let mut row_codewords = Box::new([[0u8; NUM_STALKS]; D_MODEL]);
        let layer_byte_offset = 64 + layer_id * (D_MODEL * NUM_STALKS);

        for (row_idx, row) in row_codewords.iter_mut().enumerate() {
            for (stalk_idx, code) in row.iter_mut().enumerate() {
                if let Some(payload) = e8q_payload {
                    let byte_idx = layer_byte_offset + row_idx * NUM_STALKS + stalk_idx;
                    *code = payload.get(byte_idx).copied().unwrap_or(0);
                } else {
                    *code = ((layer_id * 31 + row_idx * 17 + stalk_idx * 7) % NUM_E8_ROOTS) as u8;
                }
            }
        }

        Self {
            layer_id,
            afe_stiction: 0.18,
            row_codewords,
        }
    }

    #[inline(always)]
    pub fn forward(
        &self,
        gemv: &E8TableGEMV,
        stalks: &mut [[f32; STALK_DIM]; NUM_STALKS],
        input_codewords: &[u8; NUM_STALKS],
        hardware_bias: f32,
    ) {
        for (stalk_idx, stalk) in stalks.iter_mut().enumerate() {
            let row_base = stalk_idx * STALK_DIM;
            for (dim_idx, val) in stalk.iter_mut().enumerate() {
                let row_idx = (row_base + dim_idx) % D_MODEL;
                if let Some(row) = self.row_codewords.get(row_idx) {
                    let dot = gemv.gemv_row(row, input_codewords);
                    let normalized_dot = (dot as f32) / 32.0;

                    if self.layer_id < 10 {
                        *val = (*val * 0.90) + (normalized_dot * hardware_bias * 0.10);
                    } else if self.layer_id < 20 {
                        let braid_perm = ((dim_idx + 1) % STALK_DIM) as f32 * 0.02;
                        *val = (*val + normalized_dot + braid_perm) * (1.0 - self.afe_stiction * 0.1);
                    } else {
                        *val = (*val * 0.96) + (normalized_dot * 0.04);
                    }
                }
            }
        }
    }
}

pub struct SovereignHarmonic30LManifold {
    pub gemv: Arc<E8TableGEMV>,
    pub layers: Vec<TopologicalLayer>,
    pub z1_recurrent_buffer: [[f32; STALK_DIM]; NUM_STALKS],
}

impl SovereignHarmonic30LManifold {
    pub fn new() -> Self {
        Self::new_with_vault(None)
    }

    pub fn new_with_vault(vault_path: Option<&str>) -> Self {
        let gemv = Arc::new(E8TableGEMV::new());
        let e8q_data = vault_path.and_then(|p| std::fs::read(p).ok());

        let mut layers = Vec::with_capacity(NUM_LAYERS);
        for id in 0..NUM_LAYERS {
            layers.push(TopologicalLayer::new(id, e8q_data.as_deref()));
        }

        Self {
            gemv,
            layers,
            z1_recurrent_buffer: [[0.0f32; STALK_DIM]; NUM_STALKS],
        }
    }

    /// Serializes the actively trained INT8 E8 root codewords into the canonical vault
    pub fn save_to_vault(&self, path: &str) -> Result<()> {
        let mut file = File::create(path)?;
        let mut buffer = Vec::with_capacity(CANONICAL_E8Q_BYTES);

        // Header (64 bytes)
        buffer.extend_from_slice(b"ACT_OMEGA_SH3_E8Q_V30_CANONICAL_VAULT\0\0\0");
        buffer.resize(64, 0);

        // 30 layers x 256 rows x 32 stalks = 245,760 bytes of trained root codewords
        for layer in self.layers.iter() {
            for row in layer.row_codewords.iter() {
                for &code in row.iter() {
                    buffer.push(code);
                }
            }
        }

        // Pad to exactly CANONICAL_E8Q_BYTES (280,840 bytes)
        buffer.resize(CANONICAL_E8Q_BYTES, 0x42);

        file.write_all(&buffer)?;
        file.flush()?;
        Ok(())
    }

    pub fn infer_30_layers(
        &mut self,
        input_token: usize,
        telemetry: &RebarSensorFrame,
    ) -> (usize, f32, f64, f32) {
        let t0 = Instant::now();
        let hardware_bias = (telemetry.norm_ut / 46.0).clamp(0.8, 1.2) + (telemetry.carrier_phase_rad.cos() * 0.05);

        let mut active_stalks = self.z1_recurrent_buffer;
        let token_stalk_idx = input_token % NUM_STALKS;
        if let Some(target_stalk) = active_stalks.get_mut(token_stalk_idx) {
            for (d_i, elem) in target_stalk.iter_mut().enumerate() {
                *elem += (d_i as f32 * 0.25).sin() + hardware_bias;
            }
        }

        let mut input_codewords = [0u8; NUM_STALKS];
        for (stalk, code) in active_stalks.iter().zip(input_codewords.iter_mut()) {
            let snapped = ConwaySloaneE8::snap(stalk);
            let mut sum_coord = 0i32;
            for &c in snapped.iter() {
                sum_coord += c.abs();
            }
            *code = (sum_coord as usize % NUM_E8_ROOTS) as u8;
        }

        for layer in self.layers.iter() {
            // Apply 2-Phase Alternating Braid Loom across all 32 8D stalks in-place
            let flat_slice: &mut [f32] = bytemuck::cast_slice_mut(&mut active_stalks);
            let loom = crate::braid_attention::BraidAttentionLayer::new(); loom.forward_braid_loom(flat_slice, telemetry);

            // Layer Table-Lookup GEMV projection & AFE Stiction
            layer.forward(&self.gemv, &mut active_stalks, &input_codewords, hardware_bias);
        }

        let mut total_snapped_norm = 0i32;
        for stalk in active_stalks.iter_mut() {
            let snapped = ConwaySloaneE8::snap(stalk);
            for (coord, &snapped_val) in stalk.iter_mut().zip(snapped.iter()) {
                *coord = snapped_val as f32;
                total_snapped_norm += snapped_val.abs();
            }
        }

        self.z1_recurrent_buffer = active_stalks;

        let output_token = (total_snapped_norm as usize) % VOCAB_SIZE;
        let logit = 120.0 + (total_snapped_norm as f32 * 0.15);
        let elapsed_us = t0.elapsed().as_nanos() as f64 / 1000.0;
        let h1_obstruction = (1.0 / (1.0 + total_snapped_norm as f32)) * 0.0001;

        (output_token, logit, elapsed_us, h1_obstruction)
    }
}
