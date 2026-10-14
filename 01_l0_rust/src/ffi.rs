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