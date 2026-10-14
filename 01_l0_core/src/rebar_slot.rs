#[repr(C, align(64))]
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct RebarSensorFrame {
    pub seq: u64,
    pub b_field: [f32; 3],          // Mapped host silicon jitter [Bx, By, Bz]
    pub norm_ut: f32,               // Total instantaneous normalized power
    pub carrier_phase_rad: f32,      // 15.0 Hz carrier phase theta(t)
    pub carrier_hz: f32,             // 15.0 Hz fundamental heartbeat
    pub attitude_quat: [f32; 4],     // Thread scheduler jitter quaternion
    pub regime_id: u8,              // 1 = Nominal laminar, 2 = AFE Stiction transition
    pub padding: [u8; 15],          // Enforces strict 64-byte C-ABI alignment
}

impl Default for RebarSensorFrame {
    fn default() -> Self {
        Self {
            seq: 0,
            b_field: [-13.335, 13.640, -41.841], // Missoula, MT geodetic baseline
            norm_ut: 46.00,
            carrier_phase_rad: 0.0,
            carrier_hz: 15.0,
            attitude_quat: [1.0, 0.0, 0.0, 0.0],
            regime_id: 1,
            padding: [0u8; 15],
        }
    }
}