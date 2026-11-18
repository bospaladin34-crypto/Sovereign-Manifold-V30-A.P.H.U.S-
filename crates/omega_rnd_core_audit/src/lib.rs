#![no_std]
//! Omega R&D Digital Lab (`E:\OMEGA_RND_LAB`) — Complete 5-Track `#![no_std]` Zero-Crate Primitives
//! - Track #01: Zero-allocation UTF-8/UTF-16 BOM stripping
//! - Track #03: IEEE 802.3 CRC-32, Extended Binary Golay `[24,12,8]`, Dual-Slot Seqlock WAL, HLC CRDT
//! - Track #04: 64-Chip Golay Complementary Ultrasonic Sequences (`R_A + R_B = 2N*delta[0]`) & Integer Hopf `S^3 -> S^2`
//! - Track #05: Cellular Sheaf `#[repr(C)]` FFI Verifier (`H^1 = 0`), Quest DAG Cycle Guard, & Unique AOB Hook Scanner

pub const OMEGA_RND_MAGIC: u32 = 0x4F52_4E44;   // "ORND"
pub const OMEGA_VAULT_MAGIC: u32 = 0x4F56_4C54; // "OVLT"

/// Canonical self-orthogonal 12x12 parity submatrix B (B * B^T == I_12 mod 2, d_min = 8)
pub const GOLAY24_B: [u16; 12] = [
    0xDC5, 0x6E3, 0xB71, 0x5B9, 0x2DD, 0x16F,
    0x8B7, 0xC5B, 0xE2D, 0x717, 0xB8B, 0xFFE,
];

/// Exact transpose B^T of GOLAY24_B for O(1) Kasami dual-syndrome algebraic decoding
pub const GOLAY24_BT: [u16; 12] = [
    0x0A3B, 0x0D1D, 0x068F, 0x0B47, 0x0DA3, 0x0ED1,
    0x0769, 0x03B5, 0x01DB, 0x08ED, 0x0477, 0x0FFE,
];

/// Strips a leading UTF-8 (`EF BB BF`) or UTF-16 (`FE FF` / `FF FE`) BOM without heap allocation.
pub fn strip_bom_slice(input: &[u8]) -> &[u8] {
    if input.len() >= 3 && input[0] == 0xEF && input[1] == 0xBB && input[2] == 0xBF {
        &input[3..]
    } else if input.len() >= 2
        && ((input[0] == 0xFE && input[1] == 0xFF) || (input[0] == 0xFF && input[1] == 0xFE))
    {
        &input[2..]
    } else {
        input
    }
}

/// Zero-table, constant-space IEEE 802.3 CRC-32 (`0xEDB8_8320`) for torn-write WAL verification.
pub fn crc32_ieee_nostd(bytes: &[u8]) -> u32 {
    let mut crc: u32 = 0xFFFF_FFFF;
    let mut i = 0;
    while i < bytes.len() {
        crc ^= bytes[i] as u32;
        let mut bit = 0;
        while bit < 8 {
            let mask = (crc & 1).wrapping_neg();
            crc = (crc >> 1) ^ (0xEDB8_8320 & mask);
            bit += 1;
        }
        i += 1;
    }
    !crc
}

#[inline]
fn mul_mat12(v12: u16, mat: &[u16; 12]) -> u16 {
    let mut out: u16 = 0;
    let mut r = 0;
    while r < 12 {
        if ((v12 & mat[r]).count_ones() & 1) != 0 {
            out |= 1u16 << (11 - r);
        }
        r += 1;
    }
    out
}

/// Encodes a 12-bit word into a 24-bit Extended Binary Golay `[24, 12, 8]` codeword.
pub fn golay24_encode(data12: u16) -> u32 {
    let d = data12 & 0x0FFF;
    let p = mul_mat12(d, &GOLAY24_BT) & 0x0FFF;
    ((d as u32) << 12) | (p as u32)
}

/// Algebraic Kasami IMLD decoder for Extended Golay `[24, 12, 8]`.
pub fn golay24_decode_3bit(cw24: u32) -> (u16, u8, bool) {
    let d_rx = ((cw24 >> 12) & 0x0FFF) as u16;
    let p_rx = (cw24 & 0x0FFF) as u16;
    let s = p_rx ^ mul_mat12(d_rx, &GOLAY24_BT);
    let ws = s.count_ones() as u8;
    if ws <= 3 {
        return (d_rx, ws, true);
    }
    let mut i = 0;
    while i < 12 {
        let w = (s ^ GOLAY24_B[i]).count_ones() as u8;
        if w <= 2 {
            let e_d = 1u16 << (11 - i);
            return ((d_rx ^ e_d) & 0x0FFF, 1 + w, true);
        }
        i += 1;
    }
    let sb = mul_mat12(s, &GOLAY24_B);
    let wsb = sb.count_ones() as u8;
    if wsb <= 3 {
        return ((d_rx ^ sb) & 0x0FFF, wsb, true);
    }
    let mut j = 0;
    while j < 12 {
        let w = (sb ^ GOLAY24_BT[j]).count_ones() as u8;
        if w <= 2 {
            let e_d = sb ^ GOLAY24_BT[j];
            return ((d_rx ^ e_d) & 0x0FFF, 1 + w, true);
        }
        j += 1;
    }
    (d_rx, 4, false)
}

/// Dual-slot Seqlock WAL slot descriptor (`even seqlock_gen > 0` + valid magic + matching CRC-32).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct WalSlotHeader {
    pub magic: u32,
    pub seqlock_gen: u64,
    pub payload_crc32: u32,
}

/// Selects the highest valid committed slot (`Some(0)` for A, `Some(1)` for B, `None` if both torn).
pub fn select_intact_seqlock_slot(
    hdr_a: WalSlotHeader,
    bytes_a: &[u8],
    hdr_b: WalSlotHeader,
    bytes_b: &[u8],
) -> Option<usize> {
    let ok_a = hdr_a.magic == OMEGA_VAULT_MAGIC
        && hdr_a.seqlock_gen > 0
        && (hdr_a.seqlock_gen & 1) == 0
        && crc32_ieee_nostd(bytes_a) == hdr_a.payload_crc32;
    let ok_b = hdr_b.magic == OMEGA_VAULT_MAGIC
        && hdr_b.seqlock_gen > 0
        && (hdr_b.seqlock_gen & 1) == 0
        && crc32_ieee_nostd(bytes_b) == hdr_b.payload_crc32;
    match (ok_a, ok_b) {
        (true, true) => {
            if hdr_b.seqlock_gen >= hdr_a.seqlock_gen {
                Some(1)
            } else {
                Some(0)
            }
        }
        (true, false) => Some(0),
        (false, true) => Some(1),
        (false, false) => None,
    }
}

/// Hybrid Logical Clock (HLC) stamp for commutative, associative, idempotent offline CRDT merges.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct HlcStamp {
    pub wall_ms: u64,
    pub logical_seq: u32,
    pub node_id: u32,
    pub value_hash: u64,
}

/// Total order tie-breaker guaranteeing `merge(a, b) == merge(b, a)` across offline devices.
pub fn crdt_hlc_choose_winner(a: HlcStamp, b: HlcStamp) -> HlcStamp {
    let key_a = (a.wall_ms, a.logical_seq, a.node_id, a.value_hash);
    let key_b = (b.wall_ms, b.logical_seq, b.node_id, b.value_hash);
    if key_b > key_a { b } else { a }
}

/// Track #04: Generates 64-chip Rudin-Shapiro / Golay complementary sequences `(A_64, B_64)` in `{-1, +1}^64`
/// satisfying `R_AA[tau] + R_BB[tau] == 128` at `tau == 0` and exact `0` for all `tau in 1..64`.
pub fn golay_complementary_pair_64() -> ([i8; 64], [i8; 64]) {
    let mut a = [1i8; 64];
    let mut b = [1i8; 64];
    let mut len = 1usize;
    while len < 64 {
        let mut prev_a = [0i8; 64];
        let mut prev_b = [0i8; 64];
        let mut k = 0;
        while k < len {
            prev_a[k] = a[k];
            prev_b[k] = b[k];
            k += 1;
        }
        let mut i = 0;
        while i < len {
            a[i] = prev_a[i];
            a[len + i] = prev_b[i];
            b[i] = prev_a[i];
            b[len + i] = -prev_b[i];
            i += 1;
        }
        len *= 2;
    }
    (a, b)
}

/// Computes the summed aperiodic autocorrelation `R_AA[tau] + R_BB[tau]` for lag `tau in 0..64`.
pub fn golay64_autocorr_sum(a: &[i8; 64], b: &[i8; 64], tau: usize) -> i32 {
    if tau >= 64 {
        return 0;
    }
    let mut sum: i32 = 0;
    let mut i = 0;
    while i + tau < 64 {
        sum += (a[i] as i32) * (a[i + tau] as i32) + (b[i] as i32) * (b[i + tau] as i32);
        i += 1;
    }
    sum
}

/// Track #04: Zero-float Q14 fixed-point (`1.0 == 16384`) Hopf fibration `S^3 -> S^2`:
/// `pi(w, x, y, z) = (2*(x*z + w*y), 2*(y*z - w*x), w^2 + z^2 - x^2 - y^2) >> 14`.
pub fn hopf_project_q14(w: i32, x: i32, y: i32, z: i32) -> (i32, i32, i32) {
    let w64 = w as i64;
    let x64 = x as i64;
    let y64 = y as i64;
    let z64 = z as i64;
    let rx = (2 * (x64 * z64 + w64 * y64)) >> 14;
    let ry = (2 * (y64 * z64 - w64 * x64)) >> 14;
    let rz = (w64 * w64 + z64 * z64 - x64 * x64 - y64 * y64) >> 14;
    (rx as i32, ry as i32, rz as i32)
}

/// Track #05: Cellular Sheaf FFI layout descriptor `(offset, size, align)` across two language stalks.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct FfiFieldSpec {
    pub offset: u32,
    pub size: u32,
    pub align: u32,
}

/// Returns `0` (`H^1 = 0` exact ABI agreement) iff every field's offset, size, and alignment match.
pub fn sheaf_ffi_coboundary_defect(stalk_a: &[FfiFieldSpec], stalk_b: &[FfiFieldSpec]) -> u32 {
    if stalk_a.len() != stalk_b.len() {
        return 0xFFFF_FFFF;
    }
    let mut defect: u32 = 0;
    let mut i = 0;
    while i < stalk_a.len() {
        defect = defect
            .saturating_add(stalk_a[i].offset.abs_diff(stalk_b[i].offset))
            .saturating_add(stalk_a[i].size.abs_diff(stalk_b[i].size))
            .saturating_add(stalk_a[i].align.abs_diff(stalk_b[i].align));
        i += 1;
    }
    defect
}

/// Track #05: Static Creation Engine Quest-Stage DAG Cycle Detector over up to 16 quest stages.
/// `prereq_masks[s]` has bit `p` set if stage `s` requires stage `p` first.
/// Returns `0` (`H^1 = 0` acyclic) if all stages have a valid topological order, else bitmask of cyclic stages.
pub fn sheaf_quest_stage_cycle_mask(prereq_masks: &[u16], stage_count: usize) -> u16 {
    let n = if stage_count > 16 { 16 } else { stage_count };
    if n == 0 {
        return 0;
    }
    let full_mask: u16 = if n == 16 { 0xFFFF } else { (1u16 << n) - 1 };
    let mut resolved: u16 = 0;
    let mut pass = 0;
    while pass < n {
        let mut progress = false;
        let mut s = 0;
        while s < n {
            let bit = 1u16 << s;
            if (resolved & bit) == 0 {
                let req = prereq_masks[s] & full_mask;
                if (req & !resolved) == 0 {
                    resolved |= bit;
                    progress = true;
                }
            }
            s += 1;
        }
        if !progress {
            break;
        }
        pass += 1;
    }
    full_mask & !resolved
}

/// Track #05: Fail-closed SKSE64 / F4SE AOB binary signature scanner (`0xFFFF` = wildcard `?` byte).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AobHookScanResult {
    UniqueMatch(usize),
    ZeroMatches,
    AmbiguousMatches(usize),
}

pub fn scan_unique_aob_signature(haystack: &[u8], pattern: &[u16]) -> AobHookScanResult {
    if pattern.is_empty() || haystack.len() < pattern.len() {
        return AobHookScanResult::ZeroMatches;
    }
    let limit = haystack.len() - pattern.len();
    let mut count = 0usize;
    let mut first_idx = 0usize;
    let mut pos = 0usize;
    while pos <= limit {
        let mut ok = true;
        let mut k = 0usize;
        while k < pattern.len() {
            let p = pattern[k];
            if p <= 0x00FF && haystack[pos + k] != (p as u8) {
                ok = false;
                break;
            }
            k += 1;
        }
        if ok {
            if count == 0 {
                first_idx = pos;
            }
            count += 1;
        }
        pos += 1;
    }
    match count {
        0 => AobHookScanResult::ZeroMatches,
        1 => AobHookScanResult::UniqueMatch(first_idx),
        n => AobHookScanResult::AmbiguousMatches(n),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn utf8_bom_stripped_cleanly() {
        let raw = [0xEF, 0xBB, 0xBF, b'f', b'n'];
        assert_eq!(strip_bom_slice(&raw), b"fn");
    }

    #[test]
    fn crc32_standard_check_vector() {
        assert_eq!(crc32_ieee_nostd(b"123456789"), 0xCBF4_3926);
    }

    #[test]
    fn golay24_heals_all_3bit_and_flags_4bit() {
        let msg: u16 = 0x0A5C;
        let cw = golay24_encode(msg);
        let noisy3 = cw ^ ((1u32 << 21) | (1u32 << 13) | (1u32 << 2));
        let (dec3, corr3, ok3) = golay24_decode_3bit(noisy3);
        assert!(ok3 && dec3 == msg && corr3 == 3);
        let noisy4 = noisy3 ^ (1u32 << 7);
        let (_, _, ok4) = golay24_decode_3bit(noisy4);
        assert!(!ok4);
    }

    #[test]
    fn seqlock_wal_survives_torn_newer_slot() {
        let snap_v1 = b"vault_gen_2_committed";
        let snap_v2_torn = b"vault_gen_3_half_flus";
        let ha = WalSlotHeader {
            magic: OMEGA_VAULT_MAGIC,
            seqlock_gen: 2,
            payload_crc32: crc32_ieee_nostd(snap_v1),
        };
        let hb_odd_torn = WalSlotHeader {
            magic: OMEGA_VAULT_MAGIC,
            seqlock_gen: 3,
            payload_crc32: crc32_ieee_nostd(snap_v2_torn),
        };
        assert_eq!(select_intact_seqlock_slot(ha, snap_v1, hb_odd_torn, snap_v2_torn), Some(0));
    }

    #[test]
    fn crdt_hlc_winner_is_commutative_and_idempotent() {
        let loq = HlcStamp { wall_ms: 1700000100, logical_seq: 2, node_id: 1, value_hash: 0x11 };
        let p8  = HlcStamp { wall_ms: 1700000100, logical_seq: 2, node_id: 8, value_hash: 0x88 };
        assert_eq!(crdt_hlc_choose_winner(loq, p8), crdt_hlc_choose_winner(p8, loq));
        assert_eq!(crdt_hlc_choose_winner(p8, p8), p8);
    }

    #[test]
    fn sheaf_ffi_catches_padding_drift() {
        let rust_repr = [
            FfiFieldSpec { offset: 0, size: 4, align: 4 },
            FfiFieldSpec { offset: 8, size: 8, align: 8 },
        ];
        let broken_pack1 = [
            FfiFieldSpec { offset: 0, size: 4, align: 1 },
            FfiFieldSpec { offset: 4, size: 8, align: 1 },
        ];
        assert_eq!(sheaf_ffi_coboundary_defect(&rust_repr, &rust_repr), 0);
        assert!(sheaf_ffi_coboundary_defect(&rust_repr, &broken_pack1) > 0);
    }

    #[test]
    fn golay64_ultrasonic_pair_has_exact_zero_sidelobes() {
        let (a, b) = golay_complementary_pair_64();
        assert_eq!(golay64_autocorr_sum(&a, &b, 0), 128);
        let mut tau = 1usize;
        while tau < 64 {
            assert_eq!(golay64_autocorr_sum(&a, &b, tau), 0);
            tau += 1;
        }
    }

    #[test]
    fn hopf_q14_preserves_fiber_phase_rotation() {
        // q0 = (1/2, 1/2, 1/2, 1/2) in Q14 -> each component = 8192
        let p0 = hopf_project_q14(8192, 8192, 8192, 8192);
        // Right-multiply q0 by k = exp(k * pi/2) = (0, 0, 0, 1):
        // (w,x,y,z)*(0,0,0,1) = (-z, y, -x, w) -> (-8192, 8192, -8192, 8192)
        let p_fiber90 = hopf_project_q14(-8192, 8192, -8192, 8192);
        assert_eq!(p0, p_fiber90);
        assert_eq!(p0, (16384, 0, 0));
    }

    #[test]
    fn quest_sheaf_detects_override_deadlock_cycle() {
        // Valid 4-stage Fallout 4 / Skyrim quest: 0 -> 1 -> 2 -> 3
        let valid_dag = [0b0000u16, 0b0001, 0b0010, 0b0100];
        assert_eq!(sheaf_quest_stage_cycle_mask(&valid_dag, 4), 0);
        // Conflicting mod override makes stage 1 require stage 2 while stage 2 requires stage 1!
        let cyclic_dag = [0b0000u16, 0b0101, 0b0010, 0b0100];
        assert_eq!(sheaf_quest_stage_cycle_mask(&cyclic_dag, 4), 0b1110);
    }

    #[test]
    fn aob_hook_scanner_enforces_unique_match() {
        let pe_text: [u8; 16] = [
            0x90, 0x48, 0x89, 0x5C, 0x24, 0x08, 0x57, 0x48,
            0x83, 0xEC, 0x20, 0xC3, 0x90, 0x90, 0x90, 0x90,
        ];
        let sig_unique: [u16; 6] = [0x48, 0x89, 0x5C, 0x24, 0xFFFF, 0x57];
        let sig_ambig: [u16; 1] = [0x90];
        let sig_miss: [u16; 3] = [0x0F, 0x1F, 0x44];
        assert_eq!(scan_unique_aob_signature(&pe_text, &sig_unique), AobHookScanResult::UniqueMatch(1));
        assert_eq!(scan_unique_aob_signature(&pe_text, &sig_ambig), AobHookScanResult::AmbiguousMatches(5));
        assert_eq!(scan_unique_aob_signature(&pe_text, &sig_miss), AobHookScanResult::ZeroMatches);
    }
}
