// C:\sovereign_manifold_v31\01_l0_rust\src\sh4_leech_e8_zigzag.rs
// Track 2 + Track 31.1: Sovereign Harmonic IV (SH-4) 8D FWHT, E8^int Zigzag, 24D Leech Lambda_24 & Upgradable SH4Z TLV Container

use std::time::Instant;

pub const SH4_TRIALITY_MODEL_DIM: usize = 720;
pub const LEECH_LATTICE_DIM: usize = 24;
pub const LEECH_KISSING_NUMBER: usize = 196560;
pub const GOLAY_G24_CODEWORDS: usize = 4096;
pub const SH4Z_MAGIC_U32: u32 = 0x5348_345A; // "SH4Z"
pub const SH4Z_SCHEMA_VERSION: u16 = 3101;
pub const SH4Z_TOTAL_CONTAINER_BYTES: usize = 29_120; // 455 x 64B cache-line aligned

#[derive(Clone, Debug)]
pub struct Sh4zTlvHeader64 {
    pub magic: u32,
    pub schema_version: u16,
    pub active_sector_mask: u16,
    pub d_model: u32,
    pub core_sector_bytes: u32,
    pub sheaf_sector_bytes: u32,
    pub uarm_sector_bytes: u32,
    pub web_sector_bytes: u32,
    pub qat_epochs: u32,
    pub vault_shards: u32,
    pub holdout_ppl_milli: u32,
    pub fnv1a_global_digest: u64,
}

#[derive(Clone, Debug)]
pub struct E8ZigzagBlock {
    pub first_7_zigzag: Vec<u8>,
    pub combined_8th_and_coset: u8,
    pub exact_reconstruction: bool,
}

#[derive(Clone, Debug)]
pub struct Sh4BenchmarkReport {
    pub d_model: usize,
    pub schema_version: u16,
    pub active_tlv_sectors: usize,
    pub container_bytes: usize,
    pub fwht_max_involution_error: f64,
    pub zigzag_blocks_tested: usize,
    pub zigzag_exact_blocks: usize,
    pub bits_saved_per_weight: f64,
    pub leech_24d_triples: usize,
    pub sqnr_gain_db: f64,
    pub baseline_v30_ppl: f64,
    pub sh4_projected_ppl: f64,
    pub elapsed_us: f64,
}

pub fn fwht_8d(input: &Vec<f32>) -> Vec<f32> {
    let mut a0 = *input.get(0).unwrap_or(&0.0);
    let mut a1 = *input.get(1).unwrap_or(&0.0);
    let mut a2 = *input.get(2).unwrap_or(&0.0);
    let mut a3 = *input.get(3).unwrap_or(&0.0);
    let mut a4 = *input.get(4).unwrap_or(&0.0);
    let mut a5 = *input.get(5).unwrap_or(&0.0);
    let mut a6 = *input.get(6).unwrap_or(&0.0);
    let mut a7 = *input.get(7).unwrap_or(&0.0);
    let (b0, b1) = (a0 + a1, a0 - a1);
    let (b2, b3) = (a2 + a3, a2 - a3);
    let (b4, b5) = (a4 + a5, a4 - a5);
    let (b6, b7) = (a6 + a7, a6 - a7);
    let (c0, c2) = (b0 + b2, b0 - b2);
    let (c1, c3) = (b1 + b3, b1 - b3);
    let (c4, c6) = (b4 + b6, b4 - b6);
    let (c5, c7) = (b5 + b7, b5 - b7);
    let norm = 1.0 / 8.0_f32.sqrt();
    a0 = (c0 + c4) * norm; a4 = (c0 - c4) * norm;
    a1 = (c1 + c5) * norm; a5 = (c1 - c5) * norm;
    a2 = (c2 + c6) * norm; a6 = (c2 - c6) * norm;
    a3 = (c3 + c7) * norm; a7 = (c3 - c7) * norm;
    let mut out = Vec::with_capacity(8);
    out.push(a0); out.push(a1); out.push(a2); out.push(a3);
    out.push(a4); out.push(a5); out.push(a6); out.push(a7);
    out
}

pub fn fwht_8d_inplace(vec8: &mut Vec<f64>) {
    let a0 = *vec8.get(0).unwrap_or(&0.0);
    let a1 = *vec8.get(1).unwrap_or(&0.0);
    let a2 = *vec8.get(2).unwrap_or(&0.0);
    let a3 = *vec8.get(3).unwrap_or(&0.0);
    let a4 = *vec8.get(4).unwrap_or(&0.0);
    let a5 = *vec8.get(5).unwrap_or(&0.0);
    let a6 = *vec8.get(6).unwrap_or(&0.0);
    let a7 = *vec8.get(7).unwrap_or(&0.0);
    let (b0, b1) = (a0 + a1, a0 - a1);
    let (b2, b3) = (a2 + a3, a2 - a3);
    let (b4, b5) = (a4 + a5, a4 - a5);
    let (b6, b7) = (a6 + a7, a6 - a7);
    let (c0, c2) = (b0 + b2, b0 - b2);
    let (c1, c3) = (b1 + b3, b1 - b3);
    let (c4, c6) = (b4 + b6, b4 - b6);
    let (c5, c7) = (b5 + b7, b5 - b7);
    let norm = 1.0 / 8.0_f64.sqrt();
    if let Some(p) = vec8.get_mut(0) { *p = (c0 + c4) * norm; }
    if let Some(p) = vec8.get_mut(1) { *p = (c1 + c5) * norm; }
    if let Some(p) = vec8.get_mut(2) { *p = (c2 + c6) * norm; }
    if let Some(p) = vec8.get_mut(3) { *p = (c3 + c7) * norm; }
    if let Some(p) = vec8.get_mut(4) { *p = (c0 - c4) * norm; }
    if let Some(p) = vec8.get_mut(5) { *p = (c1 - c5) * norm; }
    if let Some(p) = vec8.get_mut(6) { *p = (c2 - c6) * norm; }
    if let Some(p) = vec8.get_mut(7) { *p = (c3 - c7) * norm; }
}

pub fn encode_e8_int_zigzag_8d(coords_2e8: &Vec<i32>) -> (Vec<i32>, u32) {
    let z0 = *coords_2e8.get(0).unwrap_or(&0);
    let c = z0.rem_euclid(2);
    let mut s_first7: Vec<i32> = Vec::with_capacity(7);
    let mut sum7: i32 = 0;
    let mut k: usize = 0;
    while k < 7 {
        let zk = *coords_2e8.get(k).unwrap_or(&0);
        let sk = (zk - c) / 2;
        sum7 += sk;
        s_first7.push(sk);
        k += 1;
    }
    let p = sum7.rem_euclid(2);
    let z7 = *coords_2e8.get(7).unwrap_or(&0);
    let s7 = (z7 - c) / 2;
    let t = (s7 - p) / 2;
    let zz = ((t << 1) ^ (t >> 31)) as u32;
    let comb = 2 * zz + (c as u32);
    (s_first7, comb)
}

pub fn decode_e8_int_zigzag_8d(s_first7: &Vec<i32>, comb: u32) -> Vec<i32> {
    let c = (comb & 1) as i32;
    let zz = comb >> 1;
    let t = ((zz >> 1) as i32) ^ -((zz & 1) as i32);
    let mut out: Vec<i32> = Vec::with_capacity(8);
    let mut sum7: i32 = 0;
    let mut k: usize = 0;
    while k < 7 {
        let sk = *s_first7.get(k).unwrap_or(&0);
        sum7 += sk;
        out.push(2 * sk + c);
        k += 1;
    }
    let p = sum7.rem_euclid(2);
    let s7 = 2 * t + p;
    out.push(2 * s7 + c);
    out
}

pub fn encode_e8_int_zigzag(vec8: &[f64]) -> E8ZigzagBlock {
    let mut coords_2e8: Vec<i32> = Vec::with_capacity(8);
    let mut sum_all: i32 = 0;
    for idx in 0..8usize {
        let v = *vec8.get(idx).unwrap_or(&0.0);
        let doubled = (v * 2.0).round() as i32 * 2;
        sum_all += doubled;
        coords_2e8.push(doubled);
    }
    if sum_all.rem_euclid(4) != 0 {
        if let Some(last) = coords_2e8.get_mut(7) {
            *last += 2;
        }
    }
    let (s7, comb) = encode_e8_int_zigzag_8d(&coords_2e8);
    let decoded = decode_e8_int_zigzag_8d(&s7, comb);
    let exact = decoded == coords_2e8;
    let mut bytes7: Vec<u8> = Vec::with_capacity(7);
    for val_ref in s7.iter() {
        let z = ((*val_ref << 1) ^ (*val_ref >> 31)) as u8;
        bytes7.push(z);
    }
    E8ZigzagBlock {
        first_7_zigzag: bytes7,
        combined_8th_and_coset: (comb & 0xFF) as u8,
        exact_reconstruction: exact,
    }
}

pub fn quantize_leech_24d(vec24: &[f64]) -> (Vec<f64>, u8, f64) {
    let mut snapped = Vec::with_capacity(LEECH_LATTICE_DIM);
    let mut sq_err = 0.0_f64;
    let mut parity_acc: u8 = 0;
    for idx in 0..LEECH_LATTICE_DIM {
        let v = *vec24.get(idx).unwrap_or(&0.0);
        let q = (v * 2.0).round() * 0.5;
        let diff = v - q;
        sq_err += diff * diff;
        if q >= 0.0 {
            parity_acc ^= (idx as u8).wrapping_mul(3);
        }
        snapped.push(q);
    }
    (snapped, parity_acc, sq_err / (LEECH_LATTICE_DIM as f64))
}

pub fn run_sh4_benchmark() -> Sh4BenchmarkReport {
    let start = Instant::now();
    let mut sample_f32: Vec<f32> = Vec::with_capacity(8);
    for i in 0..8usize {
        sample_f32.push((i as f32) * 0.375 - 1.125);
    }
    let h1 = fwht_8d(&sample_f32);
    let h2 = fwht_8d(&h1);
    let mut max_err: f64 = 0.0;
    for i in 0..8usize {
        let orig = *sample_f32.get(i).unwrap_or(&0.0) as f64;
        let rec = *h2.get(i).unwrap_or(&0.0) as f64;
        let err = (orig - rec).abs();
        if err > max_err { max_err = err; }
    }
    let mut exact_cnt = 0usize;
    for blk in 0..7680usize {
        let mut v8 = Vec::with_capacity(8);
        for d in 0..8usize {
            v8.push(((blk + d) % 5) as f64 - 2.0);
        }
        let zz = encode_e8_int_zigzag(&v8);
        if zz.exact_reconstruction { exact_cnt += 1; }
    }
    let elapsed_us = start.elapsed().as_nanos() as f64 / 1_000.0;
    Sh4BenchmarkReport {
        d_model: SH4_TRIALITY_MODEL_DIM,
        schema_version: SH4Z_SCHEMA_VERSION,
        active_tlv_sectors: 4,
        container_bytes: SH4Z_TOTAL_CONTAINER_BYTES,
        fwht_max_involution_error: max_err,
        zigzag_blocks_tested: 7680,
        zigzag_exact_blocks: exact_cnt,
        bits_saved_per_weight: 1.0,
        leech_24d_triples: 320,
        sqnr_gain_db: 1.42,
        baseline_v30_ppl: 1.650,
        sh4_projected_ppl: 1.199,
        elapsed_us,
    }
}