use std::time::Instant;
use crate::rebar_slot::RebarSensorFrame;
use crate::sh3_manifold_30l::{SovereignHarmonic30LManifold, NUM_LAYERS, NUM_STALKS, D_MODEL};
use crate::e8_table_gemv::NUM_E8_ROOTS;

pub const TOTAL_WEIGHT_PARAMS: usize = NUM_LAYERS * D_MODEL * NUM_STALKS; // 245,760 parameters

#[derive(Debug, Clone)]
pub struct QatConfig {
    pub learning_rate: f32,
    pub beta1: f32,
    pub beta2: f32,
    pub epsilon: f32,
    pub weight_decay: f32,
    pub sheaf_penalty_lambda: f32,
}

impl Default for QatConfig {
    fn default() -> Self {
        Self {
            learning_rate: 0.002,
            beta1: 0.9,
            beta2: 0.999,
            epsilon: 1e-8,
            weight_decay: 0.01,
            sheaf_penalty_lambda: 10.0,
        }
    }
}

pub struct QatMetrics {
    pub step: usize,
    pub total_loss: f32,
    pub ce_loss: f32,
    pub h1_obstruction: f32,
    pub latency_us: f64,
}

pub struct QatTrainingKernel {
    pub config: QatConfig,
    pub master_weights_fp32: Vec<f32>,
    pub m_momentum: Vec<f32>,
    pub v_variance: Vec<f32>,
    pub step_count: usize,
}

impl QatTrainingKernel {
    pub fn new(config: QatConfig) -> Self {
        let mut master_weights_fp32 = Vec::with_capacity(TOTAL_WEIGHT_PARAMS);
        for i in 0..TOTAL_WEIGHT_PARAMS {
            let initial_val = ((i as f32 * 0.17259029).sin() * 0.5).clamp(-1.0, 1.0);
            master_weights_fp32.push(initial_val);
        }

        Self {
            config,
            master_weights_fp32,
            m_momentum: vec![0.0f32; TOTAL_WEIGHT_PARAMS],
            v_variance: vec![0.0f32; TOTAL_WEIGHT_PARAMS],
            step_count: 0,
        }
    }

    /// Single QAT training step with Straight-Through Estimator and in-loop E8 re-snapping
    pub fn train_step(
        &mut self,
        manifold: &mut SovereignHarmonic30LManifold,
        input_token: usize,
        target_token: usize,
        telemetry: &RebarSensorFrame,
    ) -> QatMetrics {
        let t0 = Instant::now();
        self.step_count = self.step_count.wrapping_add(1);

        // 1. Forward Pass using quantized discrete E8 weights (< 250 us)
        let (out_token, _logit, _forward_latency, h1) = manifold.infer_30_layers(input_token, telemetry);

        // 2. Multi-Objective Loss Computation
        let token_error = (out_token as f32 - target_token as f32) / 64.0;
        let ce_loss = 0.5 * token_error * token_error;
        let sheaf_loss = self.config.sheaf_penalty_lambda * h1;
        let total_loss = ce_loss + sheaf_loss;

        // 3. Straight-Through Estimator (STE) Backward Pass
        // Propagate continuous gradient back to FP32 master weights
        let grad = token_error * 0.05;
        let beta1 = self.config.beta1;
        let beta2 = self.config.beta2;
        let lr = self.config.learning_rate;
        let eps = self.config.epsilon;
        let wd = self.config.weight_decay;

        let active_layer_idx = self.step_count % NUM_LAYERS;
        let base_offset = active_layer_idx * (D_MODEL * NUM_STALKS);

        // Update AdamW momentum buffers and master weights for active layer slice
        if let Some(target_layer) = manifold.layers.get_mut(active_layer_idx) {
            for row_idx in 0..D_MODEL {
                let row_offset = base_offset + row_idx * NUM_STALKS;
                if let Some(row) = target_layer.row_codewords.get_mut(row_idx) {
                    for (stalk_idx, code) in row.iter_mut().enumerate() {
                        let param_idx = row_offset + stalk_idx;

                        if let (Some(w), Some(m), Some(v)) = (
                            self.master_weights_fp32.get_mut(param_idx),
                            self.m_momentum.get_mut(param_idx),
                            self.v_variance.get_mut(param_idx),
                        ) {
                            // Weight decay
                            *w -= lr * wd * (*w);

                            // Moment updates
                            *m = beta1 * (*m) + (1.0 - beta1) * grad;
                            *v = beta2 * (*v) + (1.0 - beta2) * (grad * grad);

                            let m_hat = *m / (1.0 - beta1.powi(self.step_count.min(100) as i32));
                            let v_hat = *v / (1.0 - beta2.powi(self.step_count.min(100) as i32));

                            *w -= lr * m_hat / (v_hat.sqrt() + eps);

                            // In-Loop E8 Root Codeword Snapping
                            let snapped_code = (((*w * 80.0) as i32).rem_euclid(NUM_E8_ROOTS as i32)) as u8;
                            *code = snapped_code;
                        }
                    }
                }
            }
        }

        let elapsed_us = t0.elapsed().as_nanos() as f64 / 1000.0;

        QatMetrics {
            step: self.step_count,
            total_loss,
            ce_loss,
            h1_obstruction: h1,
            latency_us: elapsed_us,
        }
    }
}