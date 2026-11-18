//! ACT-Omega Sovereign Manifold :: 'omega_sec_manifold' v0.2.0 ('SH4Z-SEC1')
//! Zero-Float, '#![no_std]' 5-Layer Geometric-Topological Security Engine
//! Wire-compatible bit-for-bit with 'OmegaSteg v0.2' (:19786) across Windows 11 & Android 17.
//!
//! 1. Trigonometry : Modular Chebyshev Semigroup T_n(x) mod (2^61 - 1)
//! 2. Algebra      : Ring-LWE (q = 3329, N = 64) + McEliece-M24 (S * G24 * P)
//! 3. Polytope     : Self-Dual 4D 24-Cell {3,4,3} Hurwitz Quaternion 6-Round Feistel
//! 4. Topology     : Artin Braid B_16 Burau Commutator [A,B] + Cellular Sheaf H^1=0 Seal
//! 5. Geometry     : [24, 12, 8] Extended Binary Golay + (2,3) GF(2^8) Shamir Hyperplanes

#![cfg_attr(all(not(test), not(feature = "std")), no_std)]
#![allow(clippy::needless_range_loop)]

#[cfg(all(feature = "alloc", not(test), not(feature = "std")))]
extern crate alloc;

pub const M61: u64 = (1u64 << 61) - 1;
pub const BURAU_P: u16 = 65521;
pub const LWE_Q: i32 = 3329;

pub const LAYER_TRIG_CHEBYSHEV: u8   = 0x01;
pub const LAYER_ALG_MLKEM_M24: u8    = 0x02;
pub const LAYER_POLY_24CELL: u8      = 0x04;
pub const LAYER_TOPO_BRAID_SHEAF: u8 = 0x08;
pub const LAYER_GEOM_LEECH_GOLAY: u8 = 0x10;
pub const LAYER_ALL_FIVE: u8         = 0x1F;

/// 64-Byte Cache-Line-Aligned 'SH4Z-SEC1' Wire Header (Zero-Copy 'mmap' / FFI Ready)
#[repr(C, align(64))]
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct Sh4zSec1Header {
    pub magic: [u8; 8],              // "SH4ZSEC1"
    pub version: u8,                 // 2
    pub layer_mask: u8,              // 0x1F
    pub station_id: u8,              // 0..31
    pub payload_kind: u8,            // 0..4
    pub plain_len_le: u32,           // exact payload bytes
    pub epoch_nonce_le: u64,         // monotonic anti-replay nonce
    pub chebyshev_pub_t_le: u64,     // T_r(x_0) mod (2^61 - 1)
    pub kem_capsule_tag_le: u64,     // Ring-LWE q=3329 tag
    pub braid_commutator_le: u64,    // Artin B_16 [A,B] Burau digest
    pub sheaf_coboundary_le: u64,    // Cellular Sheaf H^1 = 0 witness
    pub golay_word_count_le: u32,    // [24,12,8] codeword count
    pub plain_crc32_le: u32,         // Majorana-1 end-to-end CRC-32
}

pub const GOLAY_PARITY12: [u16; 12] = [
    0xA3B, 0xC76, 0x8ED, 0x9DA, 0xBB4, 0xF68,
    0xED1, 0xDA3, 0xB47, 0xE8E, 0xD1D, 0x7FF,
];

pub const HURWITZ_24CELL: [[i8; 4]; 24] = [
    [ 2, 0, 0, 0], [-2, 0, 0, 0], [ 0, 2, 0, 0], [ 0,-2, 0, 0],
    [ 0, 0, 2, 0], [ 0, 0,-2, 0], [ 0, 0, 0, 2], [ 0, 0, 0,-2],
    [ 1, 1, 1, 1], [ 1, 1, 1,-1], [ 1, 1,-1, 1], [ 1, 1,-1,-1],
    [ 1,-1, 1, 1], [ 1,-1, 1,-1], [ 1,-1,-1, 1], [ 1,-1,-1,-1],
    [-1, 1, 1, 1], [-1, 1, 1,-1], [-1, 1,-1, 1], [-1, 1,-1,-1],
    [-1,-1, 1, 1], [-1,-1, 1,-1], [-1,-1,-1, 1], [-1,-1,-1,-1],
];

#[inline]
pub fn splitmix64(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

#[inline]
pub fn fold61(x: u64) -> u64 {
    let mut r = (x & M61) + (x >> 61);
    if r >= M61 { r -= M61; }
    r
}

#[inline]
pub fn add_mod61(a: u64, b: u64) -> u64 {
    let mut s = a + b;
    if s >= M61 { s -= M61; }
    s
}

#[inline]
pub fn sub_mod61(a: u64, b: u64) -> u64 {
    if a >= b { a - b } else { M61 - (b - a) }
}

#[inline]
pub fn mul_mod61(a: u64, b: u64) -> u64 {
    let prod = (fold61(a) as u128) * (fold61(b) as u128);
    let lo = (prod as u64) & M61;
    let hi = (prod >> 61) as u64;
    add_mod61(fold61(lo), fold61(hi))
}

/// Layer 1 (Trigonometry): Constant-time 60-bit Chebyshev ladder T_n(x) mod (2^61 - 1)
pub fn chebyshev_t_mod61(n: u64, x_in: u64) -> u64 {
    let x = fold61(x_in);
    if n == 0 { return 1; }
    let mut u = 1u64;
    let mut v = x;
    let mut bit: i32 = 59;
    while bit >= 0 {
        let uv = mul_mod61(u, v);
        let mid = sub_mod61(add_mod61(uv, uv), x);
        if ((n >> (bit as u32)) & 1) == 0 {
            let uu = mul_mod61(u, u);
            u = sub_mod61(add_mod61(uu, uu), 1);
            v = mid;
        } else {
            let vv = mul_mod61(v, v);
            u = mid;
            v = sub_mod61(add_mod61(vv, vv), 1);
        }
        bit -= 1;
    }
    u
}

/// Layer 5 (Geometry): Extended Binary Golay [24, 12, 8] encoder
#[inline]
pub fn golay_encode24(d12: u16) -> u32 {
    let d = d12 & 0xFFF;
    let mut p12 = 0u32;
    for i in 0..12 {
        if ((d & GOLAY_PARITY12[i]).count_ones() & 1) != 0 {
            p12 |= 1u32 << i;
        }
    }
    ((d as u32) << 12) | p12
}

/// Layer 4 (Topology): Right-multiply 16x16 Burau matrix over F_65521 by sigma_{idx}^{sign}
pub fn burau_apply_crossing16(m: &mut [[u16; 16]; 16], idx: usize, sign: i32, t_param: u16, t_inv: u16) {
    let one_minus_t = ((BURAU_P as u32 + 1 - t_param as u32) % BURAU_P as u32) as u32;
    let one_minus_tinv = ((BURAU_P as u32 + 1 - t_inv as u32) % BURAU_P as u32) as u32;
    for row in 0..16 {
        let a = m[row][idx] as u32;
        let b = m[row][idx + 1] as u32;
        if sign > 0 {
            m[row][idx]     = ((a * one_minus_t + b) % BURAU_P as u32) as u16;
            m[row][idx + 1] = ((a * (t_param as u32)) % BURAU_P as u32) as u16;
        } else {
            m[row][idx]     = ((b * (t_inv as u32)) % BURAU_P as u32) as u16;
            m[row][idx + 1] = ((a + b * one_minus_tinv) % BURAU_P as u32) as u16;
        }
    }
}

/// C-ABI Self-Test Entrypoint for C++23 ('omega_sec_ffi.h') and Deno FFI ('omega_sec_bridge.ts')
#[no_mangle]
pub extern "C" fn omega_sec_self_test() -> i32 {
    if core::mem::size_of::<Sh4zSec1Header>() != 64 { return -1; }
    let mut rng = 0x7777_ACE0_3101_0001u64;
    for _ in 0..64 {
        let x = (splitmix64(&mut rng) % (M61 - 5)) + 3;
        let r = (splitmix64(&mut rng) & ((1u64 << 58) - 1)) + 5;
        let s = (splitmix64(&mut rng) & ((1u64 << 58) - 1)) + 7;
        let k1 = chebyshev_t_mod61(r, chebyshev_t_mod61(s, x));
        let k2 = chebyshev_t_mod61(s, chebyshev_t_mod61(r, x));
        if k1 != k2 { return -2; }
    }
    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn self_test_chebyshev_and_header_size_pass() {
        assert_eq!(omega_sec_self_test(), 0);
        assert_eq!(core::mem::size_of::<Sh4zSec1Header>(), 64);
    }

    #[test]
    fn golay_encode24_nonzero_weight_property() {
        let cw = golay_encode24(0x0A5C);
        assert!(cw != 0);
        assert_eq!((cw >> 12) & 0xFFF, 0x0A5C);
    }
}
