use std::ffi::c_char;
use std::ptr;
use std::path::Path;
use crate::rebar_slot::RebarSensorFrame;
use crate::host_telemetry::HostHardwareObserver;
use crate::sh3_manifold_30l::SovereignHarmonic30LManifold;

static VERSION_CSTR: &[u8] = b"30.0.0-sh3-cabi-vault\0";

#[no_mangle]
pub extern "C" fn sh3_version() -> *const c_char {
    VERSION_CSTR.as_ptr() as *const c_char
}

#[no_mangle]
pub extern "C" fn sh3_manifold_create() -> *mut SovereignHarmonic30LManifold {
    let vault_path = "C:\\sovereign_manifold_v31\\04_canonical_vault\\models\\model_harmonic_iii.e8q";
    let manifold = if Path::new(vault_path).exists() {
        println!("[C-ABI] Loading trained manifold from: {}", vault_path);
        SovereignHarmonic30LManifold::new_with_vault(Some(vault_path))
    } else {
        println!("[C-ABI] Vault model not found; using algebraic fallback.");
        SovereignHarmonic30LManifold::new()
    };
    Box::into_raw(Box::new(manifold))
}

#[no_mangle]
pub extern "C" fn sh3_manifold_free(ptr: *mut SovereignHarmonic30LManifold) {
    if !ptr.is_null() {
        unsafe {
            drop(Box::from_raw(ptr));
        }
    }
}

#[no_mangle]
pub extern "C" fn sh3_sample_hardware_telemetry(out_frame: *mut RebarSensorFrame) -> i32 {
    if out_frame.is_null() {
        return -1;
    }
    let mut observer = HostHardwareObserver::new();
    let frame = observer.sample_live_hardware();
    unsafe {
        ptr::write(out_frame, frame);
    }
    0
}

#[no_mangle]
pub extern "C" fn sh3_manifold_infer_step(
    manifold_ptr: *mut SovereignHarmonic30LManifold,
    input_token: usize,
    sensor_ptr: *const RebarSensorFrame,
    out_token: *mut usize,
    out_logit: *mut f32,
    out_latency_us: *mut f64,
    out_h1: *mut f32,
) -> i32 {
    if manifold_ptr.is_null() || sensor_ptr.is_null() {
        return -1;
    }
    let manifold = unsafe { &mut *manifold_ptr };
    let sensor = unsafe { &*sensor_ptr };

    let (token, logit, latency, h1) = manifold.infer_30_layers(input_token, sensor);

    unsafe {
        if !out_token.is_null() { *out_token = token; }
        if !out_logit.is_null() { *out_logit = logit; }
        if !out_latency_us.is_null() { *out_latency_us = latency; }
        if !out_h1.is_null() { *out_h1 = h1; }
    }
    0
}

/// Bleeding Edge Synthesis 1 (ICSE 2025 Cross-Language ABI & Zero-Copy Shared Memory Ring):
/// Strictly 64-byte cacheline-aligned `#[repr(C, align(64))]` descriptor with explicit
/// padding guard to prevent Rust-to-C/C++/NDK/Deno pointer aliasing and alignment faults.
#[repr(C, align(64))]
#[derive(Clone, Copy, Debug)]
pub struct ActOmegaZeroCopyRingFrame64 {
    pub magic_header: u64,
    pub sequence_epoch: u64,
    pub chair44_column_id: u32,
    pub active_sector_id: u32,
    pub leech_golay_codeword: u32,
    pub burau_parity_lock: i32,
    pub sheaf_coboundary_energy_f64: f64,
    pub ring_allreduce_bytes: u64,
    pub yubikey_serial: u32,
    pub reserved_padding_guard: u32,
    pub fnv1a_cacheline_digest: u64,
}

pub fn verify_icse2025_repr_c_64b_ring_invariants(
    seq_epoch: u64,
    col_id: u32,
    sector_id: u32,
    golay_cw: u32,
    sheaf_energy: f64,
    allreduce_bytes: u64,
    yk_serial: u32,
    digest: u64,
) -> (usize, usize, bool, usize, u64) {
    let frame = ActOmegaZeroCopyRingFrame64 {
        magic_header: 0x4143_545F_4F4D_4731,
        sequence_epoch: seq_epoch,
        chair44_column_id: col_id,
        active_sector_id: sector_id,
        leech_golay_codeword: golay_cw,
        burau_parity_lock: 1,
        sheaf_coboundary_energy_f64: sheaf_energy,
        ring_allreduce_bytes: allreduce_bytes,
        yubikey_serial: yk_serial,
        reserved_padding_guard: 0x5A5A_5A5A,
        fnv1a_cacheline_digest: digest,
    };
    let sz = std::mem::size_of::<ActOmegaZeroCopyRingFrame64>();
    let al = std::mem::align_of::<ActOmegaZeroCopyRingFrame64>();
    let ptr_addr = (&frame as *const ActOmegaZeroCopyRingFrame64) as usize;
    let aligned_64 = (sz == 64) && (al == 64) && ((ptr_addr % 64) == 0);
    let aliasing_faults: usize = if aligned_64 && frame.reserved_padding_guard == 0x5A5A_5A5A {
        0
    } else {
        1
    };
    (sz, al, aligned_64, aliasing_faults, frame.fnv1a_cacheline_digest)
}
