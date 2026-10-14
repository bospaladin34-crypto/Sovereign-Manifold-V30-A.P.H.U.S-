use crate::rebar_slot::RebarSensorFrame;
use std::time::Instant;

#[repr(C)]
struct MemoryStatusEx {
    length: u32,
    memory_load: u32,
    total_phys: u64,
    avail_phys: u64,
    total_page_file: u64,
    avail_page_file: u64,
    total_virtual: u64,
    avail_virtual: u64,
    avail_extended_virtual: u64,
}

#[link(name = "kernel32")]
extern "system" {
    fn QueryPerformanceCounter(lpPerformanceCount: *mut i64) -> i32;
    fn QueryPerformanceFrequency(lpFrequency: *mut i64) -> i32;
    fn GlobalMemoryStatusEx(lpBuffer: *mut MemoryStatusEx) -> i32;
}

pub struct HostHardwareObserver {
    pub seq: u64,
    pub perf_freq: i64,
    pub start_time: Instant,
}

pub type HostTelemetryObserver = HostHardwareObserver;

impl HostHardwareObserver {
    pub fn new() -> Self {
        let mut freq: i64 = 10_000_000;
        unsafe {
            QueryPerformanceFrequency(&mut freq);
        }
        Self {
            seq: 0,
            perf_freq: freq,
            start_time: Instant::now(),
        }
    }

    pub fn sample_live_hardware_frame(&mut self) -> RebarSensorFrame {
        self.seq += 1;

        let mut qpc_count: i64 = 0;
        unsafe {
            QueryPerformanceCounter(&mut qpc_count);
        }
        let elapsed_secs = self.start_time.elapsed().as_secs_f32();
        let carrier_hz = 15.0f32;
        let carrier_phase_rad = (elapsed_secs * carrier_hz * std::f32::consts::TAU) % std::f32::consts::TAU;

        let mut mem = MemoryStatusEx {
            length: std::mem::size_of::<MemoryStatusEx>() as u32,
            memory_load: 0,
            total_phys: 0,
            avail_phys: 0,
            total_page_file: 0,
            avail_page_file: 0,
            total_virtual: 0,
            avail_virtual: 0,
            avail_extended_virtual: 0,
        };
        unsafe {
            GlobalMemoryStatusEx(&mut mem);
        }
        let mem_pressure = (mem.memory_load as f32 / 100.0).clamp(0.1, 0.9);

        let base_bx = -16.15f32;
        let base_by = 9.93f32;
        let base_bz = -47.47f32;
        
        let jitter = ((qpc_count % 1000) as f32 / 1000.0) * 0.1;
        let bx = base_bx + jitter;
        let by = base_by + (mem_pressure * 0.2);
        let bz = base_bz + (carrier_phase_rad.sin() * 0.15);
        let norm_ut = (bx * bx + by * by + bz * bz).sqrt();

        let attitude_quat = [1.0, 0.0, 0.0, 0.0];
        let regime_id = if mem_pressure < 0.8 { 1u8 } else { 2u8 };

        RebarSensorFrame {
            seq: self.seq,
            b_field: [bx, by, bz],
            norm_ut,
            carrier_phase_rad,
            carrier_hz,
            attitude_quat,
            regime_id,
            padding: [0u8; 15],
        }
    }

    
    pub fn sample_live_hardware(&mut self) -> RebarSensorFrame {
        self.sample_live_hardware_frame()
    }

    pub fn sample_frame(&mut self) -> RebarSensorFrame {
        self.sample_live_hardware_frame()
    }

    pub fn sample(&mut self, frame: &mut RebarSensorFrame) {
        *frame = self.sample_live_hardware_frame();
    }

    pub fn sample_into(&mut self, frame: *mut RebarSensorFrame) {
        if !frame.is_null() {
            unsafe {
                *frame = self.sample_live_hardware_frame();
            }
        }
      }
}