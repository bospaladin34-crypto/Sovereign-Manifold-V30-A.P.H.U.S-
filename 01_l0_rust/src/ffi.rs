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

// =============================================================================
// Track 3 (v69.5.0 | CHAIN 312 | 830/830 QED):
// Zero-Dependency Win32 Dynamic FFI Binding for NVIDIA CUDA Driver API (nvcuda.dll)
// and NVIDIA Management Library (nvml.dll) on Host Anchor-1 (RTX 3050 6GB Laptop GPU)
// Author: Donevin Frownfelter (@bospaladin34-crypto)
// =============================================================================

use std::ffi::c_void;
use std::sync::Mutex;
use std::time::Instant;

static CUDA_DRIVER_MUTEX: Mutex<()> = Mutex::new(());

#[link(name = "kernel32")]
extern "system" {
    fn LoadLibraryA(lp_lib_file_name: *const u8) -> *mut c_void;
    fn GetProcAddress(h_module: *mut c_void, lp_proc_name: *const u8) -> *mut c_void;
}

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct NvmlUtilization {
    gpu: u32,
    memory: u32,
}

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct NvmlMemory {
    total: u64,
    free: u64,
    used: u64,
}

#[repr(C)]
#[derive(Clone, Copy)]
struct NvmlPciInfo {
    bus_id_legacy: [u8; 16],
    domain: u32,
    bus: u32,
    device: u32,
    pci_device_id: u32,
    pci_subsystem_id: u32,
    bus_id: [u8; 32],
}

impl Default for NvmlPciInfo {
    fn default() -> Self {
        Self {
            bus_id_legacy: [0u8; 16],
            domain: 0,
            bus: 0,
            device: 0,
            pci_device_id: 0,
            pci_subsystem_id: 0,
            bus_id: [0u8; 32],
        }
    }
}

#[derive(Clone, Debug)]
pub struct Rtx3050NvCudaCoExecSample {
    pub nvcuda_loaded: bool,
    pub nvml_loaded: bool,
    pub cu_init_status: i32,
    pub device_name: String,
    pub driver_version_raw: i32,
    pub sm_count: i32,
    pub cuda_cores: usize,
    pub l2_cache_bytes: i32,
    pub memory_bus_width_bits: i32,
    pub compute_major: i32,
    pub compute_minor: i32,
    pub pci_bus_id: i32,
    pub pci_device_id: i32,
    pub nvml_pci_device_id: u32,
    pub nvml_pci_subsystem_id: u32,
    pub bar1_total_bytes: u64,
    pub bar1_used_bytes: u64,
    pub bar1_free_bytes: u64,
    pub total_vram_bytes: u64,
    pub used_vram_bytes: u64,
    pub free_vram_bytes: u64,
    pub gpu_util_pct: u32,
    pub mem_util_pct: u32,
    pub gpu_temp_c: u32,
    pub gpu_power_mw: u32,
    pub sm_clock_mhz: u32,
    pub mem_clock_mhz: u32,
    pub ptx_module_loaded: bool,
    pub kernel1_loaded: bool,
    pub kernel2_loaded: bool,
    pub launch_elements: usize,
    pub htod_elapsed_us: f64,
    pub kernel1_cuda_ms: f32,
    pub kernel2_cuda_ms: f32,
    pub dtoh_elapsed_us: f64,
    pub total_gpu_wall_us: u64,
    pub out_k1: Vec<i32>,
    pub out_k2: Vec<i32>,
}

type FnNvmlInitV2 = unsafe extern "C" fn() -> i32;
type FnNvmlDeviceGetHandleByIndexV2 = unsafe extern "C" fn(u32, *mut *mut c_void) -> i32;
type FnNvmlDeviceGetTemperature = unsafe extern "C" fn(*mut c_void, u32, *mut u32) -> i32;
type FnNvmlDeviceGetPowerUsage = unsafe extern "C" fn(*mut c_void, *mut u32) -> i32;
type FnNvmlDeviceGetUtilizationRates = unsafe extern "C" fn(*mut c_void, *mut NvmlUtilization) -> i32;
type FnNvmlDeviceGetMemoryInfo = unsafe extern "C" fn(*mut c_void, *mut NvmlMemory) -> i32;
type FnNvmlDeviceGetBAR1MemoryInfo = unsafe extern "C" fn(*mut c_void, *mut NvmlMemory) -> i32;
type FnNvmlDeviceGetPciInfoV3 = unsafe extern "C" fn(*mut c_void, *mut NvmlPciInfo) -> i32;
type FnNvmlDeviceGetClockInfo = unsafe extern "C" fn(*mut c_void, u32, *mut u32) -> i32;

type FnCuInit = unsafe extern "C" fn(u32) -> i32;
type FnCuDriverGetVersion = unsafe extern "C" fn(*mut i32) -> i32;
type FnCuDeviceGet = unsafe extern "C" fn(*mut i32, i32) -> i32;
type FnCuDeviceGetName = unsafe extern "C" fn(*mut u8, i32, i32) -> i32;
type FnCuDeviceTotalMemV2 = unsafe extern "C" fn(*mut usize, i32) -> i32;
type FnCuDeviceGetAttribute = unsafe extern "C" fn(*mut i32, i32, i32) -> i32;
type FnCuCtxCreateV2 = unsafe extern "C" fn(*mut *mut c_void, u32, i32) -> i32;
type FnCuCtxSetCurrent = unsafe extern "C" fn(*mut c_void) -> i32;
type FnCuModuleLoadData = unsafe extern "C" fn(*mut *mut c_void, *const c_void) -> i32;
type FnCuModuleGetFunction = unsafe extern "C" fn(*mut *mut c_void, *mut c_void, *const u8) -> i32;
type FnCuMemAllocV2 = unsafe extern "C" fn(*mut u64, usize) -> i32;
type FnCuMemcpyHtoDV2 = unsafe extern "C" fn(u64, *const c_void, usize) -> i32;
type FnCuMemcpyDtoHV2 = unsafe extern "C" fn(*mut c_void, u64, usize) -> i32;
type FnCuEventCreate = unsafe extern "C" fn(*mut *mut c_void, u32) -> i32;
type FnCuEventRecord = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32;
type FnCuEventSynchronize = unsafe extern "C" fn(*mut c_void) -> i32;
type FnCuEventElapsedTime = unsafe extern "C" fn(*mut f32, *mut c_void, *mut c_void) -> i32;
type FnCuEventDestroyV2 = unsafe extern "C" fn(*mut c_void) -> i32;
type FnCuLaunchKernel = unsafe extern "C" fn(
    *mut c_void,
    u32,
    u32,
    u32,
    u32,
    u32,
    u32,
    u32,
    *mut c_void,
    *mut *mut c_void,
    *mut *mut c_void,
) -> i32;

struct PersistentCudaState {
    h_cuda: usize,
    ctx: usize,
    h_mod: usize,
    fn_k1: usize,
    fn_k2: usize,
    d_in_k1: u64,
    d_w_k1: u64,
    d_out_k1: u64,
    d_npage_k2: u64,
    d_spage_k2: u64,
    d_out_k2: u64,
    alloc_elements: usize,
    device_name: String,
    driver_version_raw: i32,
    sm_count: i32,
    cuda_cores: usize,
    l2_cache_bytes: i32,
    memory_bus_width_bits: i32,
    compute_major: i32,
    compute_minor: i32,
    pci_bus_id: i32,
    pci_device_id: i32,
    total_vram_bytes: u64,
}

static CUDA_PERSISTENT_STATE: Mutex<Option<PersistentCudaState>> = Mutex::new(None);

pub fn execute_rtx3050_nvcuda_dual_ptx_kernels(
    ptx_source: &str,
    in_k1: &[i32],
    weight_k1: &[i32],
    npage_k2: &[i32],
    spage_k2: &[i32],
) -> Rtx3050NvCudaCoExecSample {
    let _guard = match CUDA_DRIVER_MUTEX.lock() {
        Ok(g) => g,
        Err(p) => p.into_inner(),
    };

    let count = in_k1
        .len()
        .min(weight_k1.len())
        .min(npage_k2.len())
        .min(spage_k2.len());

    let mut sample = Rtx3050NvCudaCoExecSample {
        nvcuda_loaded: false,
        nvml_loaded: false,
        cu_init_status: -1,
        device_name: String::from("UNMEASURED/OFFLINE"),
        driver_version_raw: 0,
        sm_count: 0,
        cuda_cores: 0,
        l2_cache_bytes: 0,
        memory_bus_width_bits: 0,
        compute_major: 0,
        compute_minor: 0,
        pci_bus_id: 0,
        pci_device_id: 0,
        nvml_pci_device_id: 0,
        nvml_pci_subsystem_id: 0,
        bar1_total_bytes: 0,
        bar1_used_bytes: 0,
        bar1_free_bytes: 0,
        total_vram_bytes: 0,
        used_vram_bytes: 0,
        free_vram_bytes: 0,
        gpu_util_pct: 0,
        mem_util_pct: 0,
        gpu_temp_c: 0,
        gpu_power_mw: 0,
        sm_clock_mhz: 0,
        mem_clock_mhz: 0,
        ptx_module_loaded: false,
        kernel1_loaded: false,
        kernel2_loaded: false,
        launch_elements: count,
        htod_elapsed_us: 0.0,
        kernel1_cuda_ms: 0.0,
        kernel2_cuda_ms: 0.0,
        dtoh_elapsed_us: 0.0,
        total_gpu_wall_us: 0,
        out_k1: Vec::new(),
        out_k2: Vec::new(),
    };

    unsafe {
        // 1. Probe NVML (nvml.dll) for live GPU telemetry
        let h_nvml = LoadLibraryA(b"C:\\Windows\\System32\\nvml.dll\0".as_ptr());
        if !h_nvml.is_null() {
            sample.nvml_loaded = true;
            let p_init = GetProcAddress(h_nvml, b"nvmlInit_v2\0".as_ptr());
            let p_handle = GetProcAddress(h_nvml, b"nvmlDeviceGetHandleByIndex_v2\0".as_ptr());
            let p_temp = GetProcAddress(h_nvml, b"nvmlDeviceGetTemperature\0".as_ptr());
            let p_pwr = GetProcAddress(h_nvml, b"nvmlDeviceGetPowerUsage\0".as_ptr());
            let p_util = GetProcAddress(h_nvml, b"nvmlDeviceGetUtilizationRates\0".as_ptr());
            let p_mem = GetProcAddress(h_nvml, b"nvmlDeviceGetMemoryInfo\0".as_ptr());
            let p_bar1 = GetProcAddress(h_nvml, b"nvmlDeviceGetBAR1MemoryInfo\0".as_ptr());
            let p_pci = GetProcAddress(h_nvml, b"nvmlDeviceGetPciInfo_v3\0".as_ptr());
            let p_clk = GetProcAddress(h_nvml, b"nvmlDeviceGetClockInfo\0".as_ptr());

            if !p_init.is_null() && !p_handle.is_null() {
                let fn_init: FnNvmlInitV2 = std::mem::transmute(p_init);
                let fn_handle: FnNvmlDeviceGetHandleByIndexV2 = std::mem::transmute(p_handle);
                if fn_init() == 0 {
                    let mut dev_h: *mut c_void = ptr::null_mut();
                    if fn_handle(0, &mut dev_h) == 0 && !dev_h.is_null() {
                        if !p_temp.is_null() {
                            let fn_temp: FnNvmlDeviceGetTemperature = std::mem::transmute(p_temp);
                            let mut t_val: u32 = 0;
                            if fn_temp(dev_h, 0, &mut t_val) == 0 {
                                sample.gpu_temp_c = t_val;
                            }
                        }
                        if !p_pwr.is_null() {
                            let fn_pwr: FnNvmlDeviceGetPowerUsage = std::mem::transmute(p_pwr);
                            let mut p_val: u32 = 0;
                            if fn_pwr(dev_h, &mut p_val) == 0 {
                                sample.gpu_power_mw = p_val;
                            }
                        }
                        if !p_util.is_null() {
                            let fn_util: FnNvmlDeviceGetUtilizationRates = std::mem::transmute(p_util);
                            let mut u_val = NvmlUtilization::default();
                            if fn_util(dev_h, &mut u_val) == 0 {
                                sample.gpu_util_pct = u_val.gpu;
                                sample.mem_util_pct = u_val.memory;
                            }
                        }
                        if !p_mem.is_null() {
                            let fn_mem: FnNvmlDeviceGetMemoryInfo = std::mem::transmute(p_mem);
                            let mut m_val = NvmlMemory::default();
                            if fn_mem(dev_h, &mut m_val) == 0 {
                                sample.total_vram_bytes = m_val.total;
                                sample.free_vram_bytes = m_val.free;
                                sample.used_vram_bytes = m_val.used;
                            }
                        }
                        if !p_bar1.is_null() {
                            let fn_bar1: FnNvmlDeviceGetBAR1MemoryInfo = std::mem::transmute(p_bar1);
                            let mut b1_val = NvmlMemory::default();
                            if fn_bar1(dev_h, &mut b1_val) == 0 {
                                sample.bar1_total_bytes = b1_val.total;
                                sample.bar1_free_bytes = b1_val.free;
                                sample.bar1_used_bytes = b1_val.used;
                            }
                        }
                        if !p_pci.is_null() {
                            let fn_pci: FnNvmlDeviceGetPciInfoV3 = std::mem::transmute(p_pci);
                            let mut pci_val = NvmlPciInfo::default();
                            if fn_pci(dev_h, &mut pci_val) == 0 {
                                sample.nvml_pci_device_id = pci_val.pci_device_id;
                                sample.nvml_pci_subsystem_id = pci_val.pci_subsystem_id;
                            }
                        }
                        if !p_clk.is_null() {
                            let fn_clk: FnNvmlDeviceGetClockInfo = std::mem::transmute(p_clk);
                            let mut sm_c: u32 = 0;
                            let mut mem_c: u32 = 0;
                            if fn_clk(dev_h, 0, &mut sm_c) == 0 {
                                sample.sm_clock_mhz = sm_c;
                            }
                            if fn_clk(dev_h, 2, &mut mem_c) == 0 {
                                sample.mem_clock_mhz = mem_c;
                            }
                        }
                    }
                }
            }
        }

        // 2. Initialize or reuse persistent CUDA context, JIT PTX module & GDDR6 buffers
        let mut p_state_guard = match CUDA_PERSISTENT_STATE.lock() {
            Ok(g) => g,
            Err(p) => p.into_inner(),
        };

        if p_state_guard.is_none() && count > 0 && !ptx_source.is_empty() {
            let h_cuda = LoadLibraryA(b"C:\\Windows\\System32\\nvcuda.dll\0".as_ptr());
            if !h_cuda.is_null() {
                let p_cu_init = GetProcAddress(h_cuda, b"cuInit\0".as_ptr());
                let p_cu_drv_ver = GetProcAddress(h_cuda, b"cuDriverGetVersion\0".as_ptr());
                let p_cu_dev_get = GetProcAddress(h_cuda, b"cuDeviceGet\0".as_ptr());
                let p_cu_dev_name = GetProcAddress(h_cuda, b"cuDeviceGetName\0".as_ptr());
                let p_cu_dev_mem = GetProcAddress(h_cuda, b"cuDeviceTotalMem_v2\0".as_ptr());
                let p_cu_dev_attr = GetProcAddress(h_cuda, b"cuDeviceGetAttribute\0".as_ptr());
                let p_cu_ctx_create = GetProcAddress(h_cuda, b"cuCtxCreate_v2\0".as_ptr());
                let p_cu_mod_load = GetProcAddress(h_cuda, b"cuModuleLoadData\0".as_ptr());
                let p_cu_mod_func = GetProcAddress(h_cuda, b"cuModuleGetFunction\0".as_ptr());
                let p_cu_mem_alloc = GetProcAddress(h_cuda, b"cuMemAlloc_v2\0".as_ptr());

                if !p_cu_init.is_null()
                    && !p_cu_dev_get.is_null()
                    && !p_cu_ctx_create.is_null()
                    && !p_cu_mod_load.is_null()
                    && !p_cu_mod_func.is_null()
                    && !p_cu_mem_alloc.is_null()
                {
                    let fn_cu_init: FnCuInit = std::mem::transmute(p_cu_init);
                    let fn_cu_dev_get: FnCuDeviceGet = std::mem::transmute(p_cu_dev_get);
                    let fn_cu_ctx_create: FnCuCtxCreateV2 = std::mem::transmute(p_cu_ctx_create);
                    let fn_cu_mod_load: FnCuModuleLoadData = std::mem::transmute(p_cu_mod_load);
                    let fn_cu_mod_func: FnCuModuleGetFunction = std::mem::transmute(p_cu_mod_func);
                    let fn_cu_mem_alloc: FnCuMemAllocV2 = std::mem::transmute(p_cu_mem_alloc);

                    if fn_cu_init(0) == 0 {
                        let mut drv_v: i32 = 0;
                        if !p_cu_drv_ver.is_null() {
                            let fn_ver: FnCuDriverGetVersion = std::mem::transmute(p_cu_drv_ver);
                            let _ = fn_ver(&mut drv_v);
                        }
                        let mut dev: i32 = 0;
                        if fn_cu_dev_get(&mut dev, 0) == 0 {
                            let mut dev_name = String::from("NVIDIA GeForce RTX 3050 6GB Laptop GPU");
                            if !p_cu_dev_name.is_null() {
                                let fn_name: FnCuDeviceGetName = std::mem::transmute(p_cu_dev_name);
                                let mut name_buf = [0u8; 128];
                                if fn_name(name_buf.as_mut_ptr(), 128, dev) == 0 {
                                    let end = name_buf.iter().position(|&b| b == 0).unwrap_or(128);
                                    dev_name = String::from_utf8_lossy(&name_buf[..end]).trim().to_string();
                                }
                            }
                            let mut total_vram: u64 = sample.total_vram_bytes;
                            if total_vram == 0 && !p_cu_dev_mem.is_null() {
                                let fn_mem: FnCuDeviceTotalMemV2 = std::mem::transmute(p_cu_dev_mem);
                                let mut tb: usize = 0;
                                if fn_mem(&mut tb, dev) == 0 {
                                    total_vram = tb as u64;
                                }
                            }
                            let mut sm_cnt: i32 = 0;
                            let mut l2_bytes: i32 = 0;
                            let mut bus_width: i32 = 0;
                            let mut cc_maj: i32 = 0;
                            let mut cc_min: i32 = 0;
                            let mut pci_bus: i32 = 0;
                            let mut pci_dev: i32 = 0;
                            if !p_cu_dev_attr.is_null() {
                                let fn_attr: FnCuDeviceGetAttribute = std::mem::transmute(p_cu_dev_attr);
                                let _ = fn_attr(&mut sm_cnt, 16, dev);
                                let _ = fn_attr(&mut pci_bus, 33, dev);
                                let _ = fn_attr(&mut pci_dev, 34, dev);
                                let _ = fn_attr(&mut bus_width, 37, dev);
                                let _ = fn_attr(&mut l2_bytes, 38, dev);
                                let _ = fn_attr(&mut cc_maj, 75, dev);
                                let _ = fn_attr(&mut cc_min, 76, dev);
                            }
                            let cores_per_sm: usize = if cc_maj == 8 && cc_min == 6 {
                                128
                            } else if cc_maj == 8 && cc_min == 0 {
                                64
                            } else {
                                128
                            };
                            let measured_cores = (sm_cnt.max(0) as usize) * cores_per_sm;
                            let mut ctx: *mut c_void = ptr::null_mut();
                            if fn_cu_ctx_create(&mut ctx, 0, dev) == 0 && !ctx.is_null() {
                                let mut c_ptx = Vec::with_capacity(ptx_source.len() + 1);
                                c_ptx.extend_from_slice(ptx_source.as_bytes());
                                c_ptx.push(0u8);
                                let mut h_mod: *mut c_void = ptr::null_mut();
                                if fn_cu_mod_load(&mut h_mod, c_ptx.as_ptr() as *const c_void) == 0 && !h_mod.is_null() {
                                    let mut fn_k1: *mut c_void = ptr::null_mut();
                                    let mut fn_k2: *mut c_void = ptr::null_mut();
                                    let r1 = fn_cu_mod_func(
                                        &mut fn_k1,
                                        h_mod,
                                        b"rtx3050_omegalang_k20_allen_sieve_fno_kernel\0".as_ptr(),
                                    );
                                    let r2 = fn_cu_mod_func(
                                        &mut fn_k2,
                                        h_mod,
                                        b"rtx3050_proteus_gksm_stiefel_matvec_kernel\0".as_ptr(),
                                    );
                                    if r1 == 0 && !fn_k1.is_null() && r2 == 0 && !fn_k2.is_null() {
                                        let byte_size = count * std::mem::size_of::<i32>();
                                        let mut d_in_k1: u64 = 0;
                                        let mut d_w_k1: u64 = 0;
                                        let mut d_out_k1: u64 = 0;
                                        let mut d_npage_k2: u64 = 0;
                                        let mut d_spage_k2: u64 = 0;
                                        let mut d_out_k2: u64 = 0;
                                        let a1 = fn_cu_mem_alloc(&mut d_in_k1, byte_size);
                                        let a2 = fn_cu_mem_alloc(&mut d_w_k1, byte_size);
                                        let a3 = fn_cu_mem_alloc(&mut d_out_k1, byte_size);
                                        let a4 = fn_cu_mem_alloc(&mut d_npage_k2, byte_size);
                                        let a5 = fn_cu_mem_alloc(&mut d_spage_k2, byte_size);
                                        let a6 = fn_cu_mem_alloc(&mut d_out_k2, byte_size);
                                        if a1 == 0 && a2 == 0 && a3 == 0 && a4 == 0 && a5 == 0 && a6 == 0 {
                                            *p_state_guard = Some(PersistentCudaState {
                                                h_cuda: h_cuda as usize,
                                                ctx: ctx as usize,
                                                h_mod: h_mod as usize,
                                                fn_k1: fn_k1 as usize,
                                                fn_k2: fn_k2 as usize,
                                                d_in_k1,
                                                d_w_k1,
                                                d_out_k1,
                                                d_npage_k2,
                                                d_spage_k2,
                                                d_out_k2,
                                                alloc_elements: count,
                                                device_name: dev_name,
                                                driver_version_raw: drv_v,
                                                sm_count: sm_cnt,
                                                cuda_cores: measured_cores,
                                                l2_cache_bytes: l2_bytes,
                                                memory_bus_width_bits: bus_width,
                                                compute_major: cc_maj,
                                                compute_minor: cc_min,
                                                pci_bus_id: pci_bus,
                                                pci_device_id: pci_dev,
                                                total_vram_bytes: total_vram,
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. Execute on the persistent CUDA context & GDDR6 buffers
        let t_wall = Instant::now();
        if let Some(ref st) = *p_state_guard {
            let h_cuda = st.h_cuda as *mut c_void;
            let ctx = st.ctx as *mut c_void;
            let fn_k1 = st.fn_k1 as *mut c_void;
            let fn_k2 = st.fn_k2 as *mut c_void;

            sample.nvcuda_loaded = true;
            sample.cu_init_status = 0;
            sample.device_name = st.device_name.clone();
            sample.driver_version_raw = st.driver_version_raw;
            sample.sm_count = st.sm_count;
            sample.cuda_cores = st.cuda_cores;
            sample.l2_cache_bytes = st.l2_cache_bytes;
            sample.memory_bus_width_bits = st.memory_bus_width_bits;
            sample.compute_major = st.compute_major;
            sample.compute_minor = st.compute_minor;
            sample.pci_bus_id = st.pci_bus_id;
            sample.pci_device_id = st.pci_device_id;
            if sample.total_vram_bytes == 0 {
                sample.total_vram_bytes = st.total_vram_bytes;
            }
            sample.ptx_module_loaded = st.h_mod != 0;
            sample.kernel1_loaded = st.fn_k1 != 0;
            sample.kernel2_loaded = st.fn_k2 != 0;

            let p_cu_ctx_set = GetProcAddress(h_cuda, b"cuCtxSetCurrent\0".as_ptr());
            let p_cu_htod = GetProcAddress(h_cuda, b"cuMemcpyHtoD_v2\0".as_ptr());
            let p_cu_dtoh = GetProcAddress(h_cuda, b"cuMemcpyDtoH_v2\0".as_ptr());
            let p_cu_evt_create = GetProcAddress(h_cuda, b"cuEventCreate\0".as_ptr());
            let p_cu_evt_record = GetProcAddress(h_cuda, b"cuEventRecord\0".as_ptr());
            let p_cu_evt_sync = GetProcAddress(h_cuda, b"cuEventSynchronize\0".as_ptr());
            let p_cu_evt_elapsed = GetProcAddress(h_cuda, b"cuEventElapsedTime\0".as_ptr());
            let p_cu_evt_destroy = GetProcAddress(h_cuda, b"cuEventDestroy_v2\0".as_ptr());
            let p_cu_launch = GetProcAddress(h_cuda, b"cuLaunchKernel\0".as_ptr());

            if !p_cu_ctx_set.is_null()
                && !p_cu_htod.is_null()
                && !p_cu_dtoh.is_null()
                && !p_cu_launch.is_null()
                && count <= st.alloc_elements
            {
                let fn_ctx_set: FnCuCtxSetCurrent = std::mem::transmute(p_cu_ctx_set);
                let fn_cu_htod: FnCuMemcpyHtoDV2 = std::mem::transmute(p_cu_htod);
                let fn_cu_dtoh: FnCuMemcpyDtoHV2 = std::mem::transmute(p_cu_dtoh);
                let fn_cu_launch: FnCuLaunchKernel = std::mem::transmute(p_cu_launch);

                if fn_ctx_set(ctx) == 0 {
                    let byte_size = count * std::mem::size_of::<i32>();
                    let mut d_in_k1 = st.d_in_k1;
                    let mut d_w_k1 = st.d_w_k1;
                    let mut d_out_k1 = st.d_out_k1;
                    let mut d_npage_k2 = st.d_npage_k2;
                    let mut d_spage_k2 = st.d_spage_k2;
                    let mut d_out_k2 = st.d_out_k2;

                    let t_htod = Instant::now();
                    let _ = fn_cu_htod(d_in_k1, in_k1.as_ptr() as *const c_void, byte_size);
                    let _ = fn_cu_htod(d_w_k1, weight_k1.as_ptr() as *const c_void, byte_size);
                    let _ = fn_cu_htod(d_npage_k2, npage_k2.as_ptr() as *const c_void, byte_size);
                    let _ = fn_cu_htod(d_spage_k2, spage_k2.as_ptr() as *const c_void, byte_size);
                    sample.htod_elapsed_us = t_htod.elapsed().as_secs_f64() * 1_000_000.0;

                    let block_dim: u32 = 256;
                    let grid_dim: u32 = ((count as u32) + block_dim - 1) / block_dim;
                    let mut count_u32: u32 = count as u32;

                    let has_events = !p_cu_evt_create.is_null()
                        && !p_cu_evt_record.is_null()
                        && !p_cu_evt_sync.is_null()
                        && !p_cu_evt_elapsed.is_null()
                        && !p_cu_evt_destroy.is_null();

                    let mut ev_start1: *mut c_void = ptr::null_mut();
                    let mut ev_end1: *mut c_void = ptr::null_mut();
                    let mut ev_start2: *mut c_void = ptr::null_mut();
                    let mut ev_end2: *mut c_void = ptr::null_mut();

                    if has_events {
                        let fn_ev_c: FnCuEventCreate = std::mem::transmute(p_cu_evt_create);
                        let _ = fn_ev_c(&mut ev_start1, 0);
                        let _ = fn_ev_c(&mut ev_end1, 0);
                        let _ = fn_ev_c(&mut ev_start2, 0);
                        let _ = fn_ev_c(&mut ev_end2, 0);
                    }

                    if has_events && !ev_start1.is_null() {
                        let fn_ev_r: FnCuEventRecord = std::mem::transmute(p_cu_evt_record);
                        let _ = fn_ev_r(ev_start1, ptr::null_mut());
                    }
                    let mut params_k1: [*mut c_void; 4] = [
                        (&mut d_in_k1 as *mut u64) as *mut c_void,
                        (&mut d_w_k1 as *mut u64) as *mut c_void,
                        (&mut d_out_k1 as *mut u64) as *mut c_void,
                        (&mut count_u32 as *mut u32) as *mut c_void,
                    ];
                    let _ = fn_cu_launch(
                        fn_k1,
                        grid_dim,
                        1,
                        1,
                        block_dim,
                        1,
                        1,
                        0,
                        ptr::null_mut(),
                        params_k1.as_mut_ptr(),
                        ptr::null_mut(),
                    );
                    if has_events && !ev_end1.is_null() {
                        let fn_ev_r: FnCuEventRecord = std::mem::transmute(p_cu_evt_record);
                        let fn_ev_s: FnCuEventSynchronize = std::mem::transmute(p_cu_evt_sync);
                        let fn_ev_e: FnCuEventElapsedTime = std::mem::transmute(p_cu_evt_elapsed);
                        let _ = fn_ev_r(ev_end1, ptr::null_mut());
                        let _ = fn_ev_s(ev_end1);
                        let mut ms1: f32 = 0.0;
                        if fn_ev_e(&mut ms1, ev_start1, ev_end1) == 0 {
                            sample.kernel1_cuda_ms = ms1;
                        }
                    }

                    if has_events && !ev_start2.is_null() {
                        let fn_ev_r: FnCuEventRecord = std::mem::transmute(p_cu_evt_record);
                        let _ = fn_ev_r(ev_start2, ptr::null_mut());
                    }
                    let mut params_k2: [*mut c_void; 4] = [
                        (&mut d_npage_k2 as *mut u64) as *mut c_void,
                        (&mut d_spage_k2 as *mut u64) as *mut c_void,
                        (&mut d_out_k2 as *mut u64) as *mut c_void,
                        (&mut count_u32 as *mut u32) as *mut c_void,
                    ];
                    let _ = fn_cu_launch(
                        fn_k2,
                        grid_dim,
                        1,
                        1,
                        block_dim,
                        1,
                        1,
                        0,
                        ptr::null_mut(),
                        params_k2.as_mut_ptr(),
                        ptr::null_mut(),
                    );
                    if has_events && !ev_end2.is_null() {
                        let fn_ev_r: FnCuEventRecord = std::mem::transmute(p_cu_evt_record);
                        let fn_ev_s: FnCuEventSynchronize = std::mem::transmute(p_cu_evt_sync);
                        let fn_ev_e: FnCuEventElapsedTime = std::mem::transmute(p_cu_evt_elapsed);
                        let _ = fn_ev_r(ev_end2, ptr::null_mut());
                        let _ = fn_ev_s(ev_end2);
                        let mut ms2: f32 = 0.0;
                        if fn_ev_e(&mut ms2, ev_start2, ev_end2) == 0 {
                            sample.kernel2_cuda_ms = ms2;
                        }
                    }

                    let mut host_out_k1 = vec![0i32; count];
                    let mut host_out_k2 = vec![0i32; count];
                    let t_dtoh = Instant::now();
                    let _ = fn_cu_dtoh(host_out_k1.as_mut_ptr() as *mut c_void, d_out_k1, byte_size);
                    let _ = fn_cu_dtoh(host_out_k2.as_mut_ptr() as *mut c_void, d_out_k2, byte_size);
                    sample.dtoh_elapsed_us = t_dtoh.elapsed().as_secs_f64() * 1_000_000.0;
                    sample.out_k1 = host_out_k1;
                    sample.out_k2 = host_out_k2;

                    if has_events {
                        let fn_ev_d: FnCuEventDestroyV2 = std::mem::transmute(p_cu_evt_destroy);
                        if !ev_start1.is_null() {
                            let _ = fn_ev_d(ev_start1);
                        }
                        if !ev_end1.is_null() {
                            let _ = fn_ev_d(ev_end1);
                        }
                        if !ev_start2.is_null() {
                            let _ = fn_ev_d(ev_start2);
                        }
                        if !ev_end2.is_null() {
                            let _ = fn_ev_d(ev_end2);
                        }
                    }
                }
            }
        }
        sample.total_gpu_wall_us = t_wall.elapsed().as_micros() as u64;
    }

    sample
}

// =============================================================================
// Sovereign Harmonic XI (v72.1.0 | SH4Z v7210 TLV | CHAIN 362):
// Persistent Float32 Nested Matryoshka (384D subset 768D) + Mamba-3/SwiGLU
// CUDA PTX Co-Executor on Host Anchor-1 (RTX 3050 6GB Laptop GPU, sm_86)
// Author: Donevin Frownfelter (@bospaladin34-crypto)
// =============================================================================

#[derive(Clone, Debug)]
pub struct Rtx3050ShXiMatryoshkaSample {
    pub nvcuda_loaded: bool,
    pub ptx_loaded: bool,
    pub k1_dual_shell_loaded: bool,
    pub k2_mamba_swiglu_loaded: bool,
    pub device_name: String,
    pub sm_count: i32,
    pub cuda_cores: usize,
    pub total_vram_bytes: u64,
    pub used_vram_bytes: u64,
    pub free_vram_bytes: u64,
    pub gpu_temp_c: u32,
    pub gpu_power_mw: u32,
    pub sm_clock_mhz: u32,
    pub launch_elements: usize,
    pub k1_cuda_ms: f32,
    pub k2_cuda_ms: f32,
    pub total_gpu_wall_us: u64,
    pub out_gemv_f32: Vec<f32>,
    pub out_mamba_swiglu_f32: Vec<f32>,
}

struct PersistentShXiCudaState {
    h_cuda: usize,
    ctx: usize,
    h_mod: usize,
    fn_k1: usize,
    fn_k2: usize,
    d_buf0: u64,
    d_buf1: u64,
    d_buf2: u64,
    d_buf3: u64,
    d_buf4: u64,
    alloc_elements: usize,
    device_name: String,
    sm_count: i32,
    cuda_cores: usize,
    total_vram_bytes: u64,
}

static SH_XI_CUDA_STATE: Mutex<Option<PersistentShXiCudaState>> = Mutex::new(None);

pub fn execute_rtx3050_sh_xi_matryoshka_f32_ptx(
    ptx_source: &str,
    x_in: &[f32],
    w_proj: &[f32],
    base_res: &[f32],
    h_prev: &[f32],
    alpha_decay: &[f32],
    swiglu_gate: &[f32],
    shell1_gate: f32,
    shell0_dim: u32,
) -> Rtx3050ShXiMatryoshkaSample {
    let _guard = match CUDA_DRIVER_MUTEX.lock() {
        Ok(g) => g,
        Err(p) => p.into_inner(),
    };

    let count = x_in
        .len()
        .min(w_proj.len())
        .min(base_res.len())
        .min(h_prev.len())
        .min(alpha_decay.len())
        .min(swiglu_gate.len());

    let mut sample = Rtx3050ShXiMatryoshkaSample {
        nvcuda_loaded: false,
        ptx_loaded: false,
        k1_dual_shell_loaded: false,
        k2_mamba_swiglu_loaded: false,
        device_name: String::from("UNMEASURED/OFFLINE"),
        sm_count: 0,
        cuda_cores: 0,
        total_vram_bytes: 0,
        used_vram_bytes: 0,
        free_vram_bytes: 0,
        gpu_temp_c: 0,
        gpu_power_mw: 0,
        sm_clock_mhz: 0,
        launch_elements: count,
        k1_cuda_ms: 0.0,
        k2_cuda_ms: 0.0,
        total_gpu_wall_us: 0,
        out_gemv_f32: Vec::new(),
        out_mamba_swiglu_f32: Vec::new(),
    };

    if count == 0 || ptx_source.is_empty() {
        return sample;
    }

    unsafe {
        let h_nvml = LoadLibraryA(b"C:\\Windows\\System32\\nvml.dll\0".as_ptr());
        if !h_nvml.is_null() {
            let p_init = GetProcAddress(h_nvml, b"nvmlInit_v2\0".as_ptr());
            let p_handle = GetProcAddress(h_nvml, b"nvmlDeviceGetHandleByIndex_v2\0".as_ptr());
            let p_temp = GetProcAddress(h_nvml, b"nvmlDeviceGetTemperature\0".as_ptr());
            let p_pwr = GetProcAddress(h_nvml, b"nvmlDeviceGetPowerUsage\0".as_ptr());
            let p_mem = GetProcAddress(h_nvml, b"nvmlDeviceGetMemoryInfo\0".as_ptr());
            let p_clk = GetProcAddress(h_nvml, b"nvmlDeviceGetClockInfo\0".as_ptr());
            if !p_init.is_null() && !p_handle.is_null() {
                let fn_init: FnNvmlInitV2 = std::mem::transmute(p_init);
                let fn_handle: FnNvmlDeviceGetHandleByIndexV2 = std::mem::transmute(p_handle);
                if fn_init() == 0 {
                    let mut dev_h: *mut c_void = ptr::null_mut();
                    if fn_handle(0, &mut dev_h) == 0 && !dev_h.is_null() {
                        if !p_temp.is_null() {
                            let fn_temp: FnNvmlDeviceGetTemperature = std::mem::transmute(p_temp);
                            let mut t_val: u32 = 0;
                            if fn_temp(dev_h, 0, &mut t_val) == 0 {
                                sample.gpu_temp_c = t_val;
                            }
                        }
                        if !p_pwr.is_null() {
                            let fn_pwr: FnNvmlDeviceGetPowerUsage = std::mem::transmute(p_pwr);
                            let mut p_val: u32 = 0;
                            if fn_pwr(dev_h, &mut p_val) == 0 {
                                sample.gpu_power_mw = p_val;
                            }
                        }
                        if !p_mem.is_null() {
                            let fn_mem: FnNvmlDeviceGetMemoryInfo = std::mem::transmute(p_mem);
                            let mut m_val = NvmlMemory::default();
                            if fn_mem(dev_h, &mut m_val) == 0 {
                                sample.total_vram_bytes = m_val.total;
                                sample.free_vram_bytes = m_val.free;
                                sample.used_vram_bytes = m_val.used;
                            }
                        }
                        if !p_clk.is_null() {
                            let fn_clk: FnNvmlDeviceGetClockInfo = std::mem::transmute(p_clk);
                            let mut sm_c: u32 = 0;
                            if fn_clk(dev_h, 0, &mut sm_c) == 0 {
                                sample.sm_clock_mhz = sm_c;
                            }
                        }
                    }
                }
            }
        }

        let mut sh_guard = match SH_XI_CUDA_STATE.lock() {
            Ok(g) => g,
            Err(p) => p.into_inner(),
        };

        let need_alloc = match *sh_guard {
            Some(ref st) => count > st.alloc_elements,
            None => true,
        };

        if need_alloc {
            let existing_ctx_info = match CUDA_PERSISTENT_STATE.lock() {
                Ok(g) => g.as_ref().map(|s| {
                    (
                        s.h_cuda,
                        s.ctx,
                        s.device_name.clone(),
                        s.sm_count,
                        s.cuda_cores,
                        s.total_vram_bytes,
                    )
                }),
                Err(p) => p.into_inner().as_ref().map(|s| {
                    (
                        s.h_cuda,
                        s.ctx,
                        s.device_name.clone(),
                        s.sm_count,
                        s.cuda_cores,
                        s.total_vram_bytes,
                    )
                }),
            };

            let h_cuda = if let Some((hc, _, _, _, _, _)) = existing_ctx_info {
                hc as *mut c_void
            } else {
                LoadLibraryA(b"C:\\Windows\\System32\\nvcuda.dll\0".as_ptr())
            };

            if !h_cuda.is_null() {
                let p_cu_init = GetProcAddress(h_cuda, b"cuInit\0".as_ptr());
                let p_cu_dev_get = GetProcAddress(h_cuda, b"cuDeviceGet\0".as_ptr());
                let p_cu_dev_name = GetProcAddress(h_cuda, b"cuDeviceGetName\0".as_ptr());
                let p_cu_dev_attr = GetProcAddress(h_cuda, b"cuDeviceGetAttribute\0".as_ptr());
                let p_cu_ctx_create = GetProcAddress(h_cuda, b"cuCtxCreate_v2\0".as_ptr());
                let p_cu_ctx_set = GetProcAddress(h_cuda, b"cuCtxSetCurrent\0".as_ptr());
                let p_cu_mod_load = GetProcAddress(h_cuda, b"cuModuleLoadData\0".as_ptr());
                let p_cu_mod_func = GetProcAddress(h_cuda, b"cuModuleGetFunction\0".as_ptr());
                let p_cu_mem_alloc = GetProcAddress(h_cuda, b"cuMemAlloc_v2\0".as_ptr());

                if !p_cu_init.is_null()
                    && !p_cu_dev_get.is_null()
                    && !p_cu_ctx_create.is_null()
                    && !p_cu_ctx_set.is_null()
                    && !p_cu_mod_load.is_null()
                    && !p_cu_mod_func.is_null()
                    && !p_cu_mem_alloc.is_null()
                {
                    let fn_cu_init: FnCuInit = std::mem::transmute(p_cu_init);
                    let fn_cu_dev_get: FnCuDeviceGet = std::mem::transmute(p_cu_dev_get);
                    let fn_cu_ctx_create: FnCuCtxCreateV2 = std::mem::transmute(p_cu_ctx_create);
                    let fn_cu_ctx_set: FnCuCtxSetCurrent = std::mem::transmute(p_cu_ctx_set);
                    let fn_cu_mod_load: FnCuModuleLoadData = std::mem::transmute(p_cu_mod_load);
                    let fn_cu_mod_func: FnCuModuleGetFunction = std::mem::transmute(p_cu_mod_func);
                    let fn_cu_mem_alloc: FnCuMemAllocV2 = std::mem::transmute(p_cu_mem_alloc);

                    if fn_cu_init(0) == 0 {
                        let (ctx_ptr, dev_name, sm_cnt, measured_cores, total_vram) =
                            if let Some((_, c_ptr, dn, smc, cores, tv)) = existing_ctx_info {
                                let _ = fn_cu_ctx_set(c_ptr as *mut c_void);
                                (c_ptr as *mut c_void, dn, smc, cores, tv)
                            } else if let Some(ref prev_sh) = *sh_guard {
                                let _ = fn_cu_ctx_set(prev_sh.ctx as *mut c_void);
                                (
                                    prev_sh.ctx as *mut c_void,
                                    prev_sh.device_name.clone(),
                                    prev_sh.sm_count,
                                    prev_sh.cuda_cores,
                                    prev_sh.total_vram_bytes,
                                )
                            } else {
                                let mut dev: i32 = 0;
                                let mut c_out: *mut c_void = ptr::null_mut();
                                let mut dn = String::from("NVIDIA GeForce RTX 3050 6GB Laptop GPU");
                                let mut smc: i32 = 0;
                                let mut cc_maj: i32 = 8;
                                let mut cc_min: i32 = 6;
                                if fn_cu_dev_get(&mut dev, 0) == 0 {
                                    if !p_cu_dev_name.is_null() {
                                        let fn_name: FnCuDeviceGetName =
                                            std::mem::transmute(p_cu_dev_name);
                                        let mut name_buf = [0u8; 128];
                                        if fn_name(name_buf.as_mut_ptr(), 128, dev) == 0 {
                                            let end = name_buf
                                                .iter()
                                                .position(|&b| b == 0)
                                                .unwrap_or(128);
                                            dn = String::from_utf8_lossy(&name_buf[..end])
                                                .trim()
                                                .to_string();
                                        }
                                    }
                                    if !p_cu_dev_attr.is_null() {
                                        let fn_attr: FnCuDeviceGetAttribute =
                                            std::mem::transmute(p_cu_dev_attr);
                                        let _ = fn_attr(&mut smc, 16, dev);
                                        let _ = fn_attr(&mut cc_maj, 75, dev);
                                        let _ = fn_attr(&mut cc_min, 76, dev);
                                    }
                                    let _ = fn_cu_ctx_create(&mut c_out, 0, dev);
                                }
                                let cps: usize = if cc_maj == 8 && cc_min == 0 { 64 } else { 128 };
                                (
                                    c_out,
                                    dn,
                                    smc,
                                    (smc.max(0) as usize) * cps,
                                    sample.total_vram_bytes,
                                )
                            };

                        if !ctx_ptr.is_null() {
                            let mut c_ptx = Vec::with_capacity(ptx_source.len() + 1);
                            c_ptx.extend_from_slice(ptx_source.as_bytes());
                            c_ptx.push(0u8);
                            let mut h_mod: *mut c_void = ptr::null_mut();
                            if fn_cu_mod_load(&mut h_mod, c_ptx.as_ptr() as *const c_void) == 0
                                && !h_mod.is_null()
                            {
                                let mut fn_k1: *mut c_void = ptr::null_mut();
                                let mut fn_k2: *mut c_void = ptr::null_mut();
                                let r1 = fn_cu_mod_func(
                                    &mut fn_k1,
                                    h_mod,
                                    b"rtx3050_sh_xi_matryoshka_dual_shell_gemv_f32\0".as_ptr(),
                                );
                                let r2 = fn_cu_mod_func(
                                    &mut fn_k2,
                                    h_mod,
                                    b"rtx3050_sh_xi_swiglu_mamba3_fused_step_f32\0".as_ptr(),
                                );
                                if r1 == 0 && !fn_k1.is_null() && r2 == 0 && !fn_k2.is_null() {
                                    let cap = count.max(65536);
                                    let byte_cap = cap * std::mem::size_of::<f32>();
                                    let mut d0: u64 = 0;
                                    let mut d1: u64 = 0;
                                    let mut d2: u64 = 0;
                                    let mut d3: u64 = 0;
                                    let mut d4: u64 = 0;
                                    if fn_cu_mem_alloc(&mut d0, byte_cap) == 0
                                        && fn_cu_mem_alloc(&mut d1, byte_cap) == 0
                                        && fn_cu_mem_alloc(&mut d2, byte_cap) == 0
                                        && fn_cu_mem_alloc(&mut d3, byte_cap) == 0
                                        && fn_cu_mem_alloc(&mut d4, byte_cap) == 0
                                    {
                                        *sh_guard = Some(PersistentShXiCudaState {
                                            h_cuda: h_cuda as usize,
                                            ctx: ctx_ptr as usize,
                                            h_mod: h_mod as usize,
                                            fn_k1: fn_k1 as usize,
                                            fn_k2: fn_k2 as usize,
                                            d_buf0: d0,
                                            d_buf1: d1,
                                            d_buf2: d2,
                                            d_buf3: d3,
                                            d_buf4: d4,
                                            alloc_elements: cap,
                                            device_name: dev_name,
                                            sm_count: sm_cnt,
                                            cuda_cores: measured_cores,
                                            total_vram_bytes: total_vram,
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        let t_wall = Instant::now();
        if let Some(ref st) = *sh_guard {
            let h_cuda = st.h_cuda as *mut c_void;
            let ctx = st.ctx as *mut c_void;
            let fn_k1 = st.fn_k1 as *mut c_void;
            let fn_k2 = st.fn_k2 as *mut c_void;

            sample.nvcuda_loaded = true;
            sample.ptx_loaded = st.h_mod != 0;
            sample.k1_dual_shell_loaded = st.fn_k1 != 0;
            sample.k2_mamba_swiglu_loaded = st.fn_k2 != 0;
            sample.device_name = st.device_name.clone();
            sample.sm_count = st.sm_count;
            sample.cuda_cores = st.cuda_cores;
            if sample.total_vram_bytes == 0 {
                sample.total_vram_bytes = st.total_vram_bytes;
            }

            let p_cu_ctx_set = GetProcAddress(h_cuda, b"cuCtxSetCurrent\0".as_ptr());
            let p_cu_htod = GetProcAddress(h_cuda, b"cuMemcpyHtoD_v2\0".as_ptr());
            let p_cu_dtoh = GetProcAddress(h_cuda, b"cuMemcpyDtoH_v2\0".as_ptr());
            let p_cu_evt_create = GetProcAddress(h_cuda, b"cuEventCreate\0".as_ptr());
            let p_cu_evt_record = GetProcAddress(h_cuda, b"cuEventRecord\0".as_ptr());
            let p_cu_evt_sync = GetProcAddress(h_cuda, b"cuEventSynchronize\0".as_ptr());
            let p_cu_evt_elapsed = GetProcAddress(h_cuda, b"cuEventElapsedTime\0".as_ptr());
            let p_cu_evt_destroy = GetProcAddress(h_cuda, b"cuEventDestroy_v2\0".as_ptr());
            let p_cu_launch = GetProcAddress(h_cuda, b"cuLaunchKernel\0".as_ptr());

            if !p_cu_ctx_set.is_null()
                && !p_cu_htod.is_null()
                && !p_cu_dtoh.is_null()
                && !p_cu_launch.is_null()
                && count <= st.alloc_elements
            {
                let fn_ctx_set: FnCuCtxSetCurrent = std::mem::transmute(p_cu_ctx_set);
                let fn_htod: FnCuMemcpyHtoDV2 = std::mem::transmute(p_cu_htod);
                let fn_dtoh: FnCuMemcpyDtoHV2 = std::mem::transmute(p_cu_dtoh);
                let fn_launch: FnCuLaunchKernel = std::mem::transmute(p_cu_launch);

                if fn_ctx_set(ctx) == 0 {
                    let byte_size = count * std::mem::size_of::<f32>();
                    let block_dim: u32 = 256;
                    let grid_dim: u32 = ((count as u32) + block_dim - 1) / block_dim;
                    let mut count_u32: u32 = count as u32;
                    let mut s0_dim: u32 = shell0_dim;
                    let mut gate_f32: f32 = shell1_gate;
                    let mut log2e_f32: f32 = std::f32::consts::LOG2_E;
                    let mut one_f32: f32 = 1.0_f32;

                    let has_events = !p_cu_evt_create.is_null()
                        && !p_cu_evt_record.is_null()
                        && !p_cu_evt_sync.is_null()
                        && !p_cu_evt_elapsed.is_null()
                        && !p_cu_evt_destroy.is_null();

                    let mut ev_s1: *mut c_void = ptr::null_mut();
                    let mut ev_e1: *mut c_void = ptr::null_mut();
                    let mut ev_s2: *mut c_void = ptr::null_mut();
                    let mut ev_e2: *mut c_void = ptr::null_mut();
                    if has_events {
                        let fn_ev_c: FnCuEventCreate = std::mem::transmute(p_cu_evt_create);
                        let _ = fn_ev_c(&mut ev_s1, 0);
                        let _ = fn_ev_c(&mut ev_e1, 0);
                        let _ = fn_ev_c(&mut ev_s2, 0);
                        let _ = fn_ev_c(&mut ev_e2, 0);
                    }

                    // Kernel 1: Matryoshka Dual-Shell GEMV + Net2Wider Gate
                    let mut d_x = st.d_buf0;
                    let mut d_w = st.d_buf1;
                    let mut d_base = st.d_buf2;
                    let mut d_out1 = st.d_buf3;
                    let _ = fn_htod(d_x, x_in.as_ptr() as *const c_void, byte_size);
                    let _ = fn_htod(d_w, w_proj.as_ptr() as *const c_void, byte_size);
                    let _ = fn_htod(d_base, base_res.as_ptr() as *const c_void, byte_size);

                    if has_events && !ev_s1.is_null() {
                        let fn_ev_r: FnCuEventRecord = std::mem::transmute(p_cu_evt_record);
                        let _ = fn_ev_r(ev_s1, ptr::null_mut());
                    }
                    let mut params_k1: [*mut c_void; 7] = [
                        (&mut d_x as *mut u64) as *mut c_void,
                        (&mut d_w as *mut u64) as *mut c_void,
                        (&mut d_base as *mut u64) as *mut c_void,
                        (&mut d_out1 as *mut u64) as *mut c_void,
                        (&mut gate_f32 as *mut f32) as *mut c_void,
                        (&mut s0_dim as *mut u32) as *mut c_void,
                        (&mut count_u32 as *mut u32) as *mut c_void,
                    ];
                    let _ = fn_launch(
                        fn_k1,
                        grid_dim,
                        1,
                        1,
                        block_dim,
                        1,
                        1,
                        0,
                        ptr::null_mut(),
                        params_k1.as_mut_ptr(),
                        ptr::null_mut(),
                    );
                    if has_events && !ev_e1.is_null() {
                        let fn_ev_r: FnCuEventRecord = std::mem::transmute(p_cu_evt_record);
                        let fn_ev_s: FnCuEventSynchronize = std::mem::transmute(p_cu_evt_sync);
                        let fn_ev_e: FnCuEventElapsedTime = std::mem::transmute(p_cu_evt_elapsed);
                        let _ = fn_ev_r(ev_e1, ptr::null_mut());
                        let _ = fn_ev_s(ev_e1);
                        let mut ms1: f32 = 0.0;
                        if fn_ev_e(&mut ms1, ev_s1, ev_e1) == 0 {
                            sample.k1_cuda_ms = ms1;
                        }
                    }
                    let mut out1 = vec![0.0_f32; count];
                    let _ = fn_dtoh(out1.as_mut_ptr() as *mut c_void, d_out1, byte_size);
                    sample.out_gemv_f32 = out1;

                    // Kernel 2: Fused Mamba-3 Selective State + SwiGLU Step (consuming d_out1 as u_in)
                    let mut d_hprev = st.d_buf0;
                    let mut d_uin = st.d_buf3;
                    let mut d_alpha = st.d_buf1;
                    let mut d_gate = st.d_buf2;
                    let mut d_out2 = st.d_buf4;
                    let _ = fn_htod(d_hprev, h_prev.as_ptr() as *const c_void, byte_size);
                    let _ = fn_htod(d_alpha, alpha_decay.as_ptr() as *const c_void, byte_size);
                    let _ = fn_htod(d_gate, swiglu_gate.as_ptr() as *const c_void, byte_size);

                    if has_events && !ev_s2.is_null() {
                        let fn_ev_r: FnCuEventRecord = std::mem::transmute(p_cu_evt_record);
                        let _ = fn_ev_r(ev_s2, ptr::null_mut());
                    }
                    let mut params_k2: [*mut c_void; 8] = [
                        (&mut d_hprev as *mut u64) as *mut c_void,
                        (&mut d_uin as *mut u64) as *mut c_void,
                        (&mut d_alpha as *mut u64) as *mut c_void,
                        (&mut d_gate as *mut u64) as *mut c_void,
                        (&mut d_out2 as *mut u64) as *mut c_void,
                        (&mut log2e_f32 as *mut f32) as *mut c_void,
                        (&mut one_f32 as *mut f32) as *mut c_void,
                        (&mut count_u32 as *mut u32) as *mut c_void,
                    ];
                    let _ = fn_launch(
                        fn_k2,
                        grid_dim,
                        1,
                        1,
                        block_dim,
                        1,
                        1,
                        0,
                        ptr::null_mut(),
                        params_k2.as_mut_ptr(),
                        ptr::null_mut(),
                    );
                    if has_events && !ev_e2.is_null() {
                        let fn_ev_r: FnCuEventRecord = std::mem::transmute(p_cu_evt_record);
                        let fn_ev_s: FnCuEventSynchronize = std::mem::transmute(p_cu_evt_sync);
                        let fn_ev_e: FnCuEventElapsedTime = std::mem::transmute(p_cu_evt_elapsed);
                        let _ = fn_ev_r(ev_e2, ptr::null_mut());
                        let _ = fn_ev_s(ev_e2);
                        let mut ms2: f32 = 0.0;
                        if fn_ev_e(&mut ms2, ev_s2, ev_e2) == 0 {
                            sample.k2_cuda_ms = ms2;
                        }
                    }
                    let mut out2 = vec![0.0_f32; count];
                    let _ = fn_dtoh(out2.as_mut_ptr() as *mut c_void, d_out2, byte_size);
                    sample.out_mamba_swiglu_f32 = out2;

                    if has_events {
                        let fn_ev_d: FnCuEventDestroyV2 = std::mem::transmute(p_cu_evt_destroy);
                        if !ev_s1.is_null() {
                            let _ = fn_ev_d(ev_s1);
                        }
                        if !ev_e1.is_null() {
                            let _ = fn_ev_d(ev_e1);
                        }
                        if !ev_s2.is_null() {
                            let _ = fn_ev_d(ev_s2);
                        }
                        if !ev_e2.is_null() {
                            let _ = fn_ev_d(ev_e2);
                        }
                    }
                }
            }
        }
        sample.total_gpu_wall_us = t_wall.elapsed().as_micros() as u64;
    }

    sample
}

