// 01_l0_core/src/chair44_automorphism.rs
// v30 Track 4: Chair44 (R44) 3D Aperiodic Einstein Monotile Automorphism
// Exact Coprime Identities: 44 * 349 == 1 (mod 415) and 47 * 6863 == 1 (mod 7680)
// Zero-Square-Bracket Rust Invariant Enforced

use crate::sierpinski_158_quantizer::TOTAL_MANIFOLD_TRITS;

pub const CHAIR44_POLYCUBE_UNITS: usize = 44;
pub const CANONICAL_VAULT_SHARDS: usize = 415;
pub const CHAIR44_SHARD_INV_MOD_415: usize = 349;
pub const CHAIR44_CHIRAL_TRIT_STRIDE: usize = 47;
pub const CHAIR44_TRIT_INV_MOD_7680: usize = 6863;

pub struct Chair44AuditReport {
    pub unique_shards_visited: usize,
    pub shard_roundtrip_matches: usize,
    pub trit_roundtrip_matches: usize,
    pub permuted_trits: Vec<i8>,
}

#[inline]
pub fn permute_vault_shard_index(shard_idx: usize, chiral_offset: usize) -> usize {
    ((shard_idx % CANONICAL_VAULT_SHARDS) * CHAIR44_POLYCUBE_UNITS + (chiral_offset % CANONICAL_VAULT_SHARDS)) % CANONICAL_VAULT_SHARDS
}

#[inline]
pub fn invert_vault_shard_index(permuted_idx: usize, chiral_offset: usize) -> usize {
    let off = chiral_offset % CANONICAL_VAULT_SHARDS;
    let diff = (permuted_idx + CANONICAL_VAULT_SHARDS - off) % CANONICAL_VAULT_SHARDS;
    (diff * CHAIR44_SHARD_INV_MOD_415) % CANONICAL_VAULT_SHARDS
}

#[inline]
pub fn permute_trit_index_3d(flat_idx: usize, chiral_offset: usize) -> usize {
    ((flat_idx % TOTAL_MANIFOLD_TRITS) * CHAIR44_CHIRAL_TRIT_STRIDE + (chiral_offset % TOTAL_MANIFOLD_TRITS)) % TOTAL_MANIFOLD_TRITS
}

#[inline]
pub fn invert_trit_index_3d(permuted_idx: usize, chiral_offset: usize) -> usize {
    let off = chiral_offset % TOTAL_MANIFOLD_TRITS;
    let diff = (permuted_idx + TOTAL_MANIFOLD_TRITS - off) % TOTAL_MANIFOLD_TRITS;
    (diff * CHAIR44_TRIT_INV_MOD_7680) % TOTAL_MANIFOLD_TRITS
}

pub fn execute_chair44_automorphism(input_trits: &Vec<i8>, chiral_offset: usize) -> Chair44AuditReport {
    let mut visited_flags: Vec<u8> = Vec::with_capacity(CANONICAL_VAULT_SHARDS);
    let mut s: usize = 0;
    while s < CANONICAL_VAULT_SHARDS {
        visited_flags.push(0);
        s += 1;
    }

    let mut shard_roundtrip_matches: usize = 0;
    let mut idx: usize = 0;
    while idx < CANONICAL_VAULT_SHARDS {
        let p = permute_vault_shard_index(idx, chiral_offset);
        if let Some(flag) = visited_flags.get_mut(p) {
            *flag = 1;
        }
        let rec = invert_vault_shard_index(p, chiral_offset);
        if rec == idx {
            shard_roundtrip_matches += 1;
        }
        idx += 1;
    }
    let mut unique_shards_visited: usize = 0;
    for f in visited_flags.iter() {
        if *f == 1 {
            unique_shards_visited += 1;
        }
    }

    let mut permuted_trits: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let mut k: usize = 0;
    while k < TOTAL_MANIFOLD_TRITS {
        permuted_trits.push(0);
        k += 1;
    }
    let mut t_idx: usize = 0;
    while t_idx < TOTAL_MANIFOLD_TRITS {
        let dest = permute_trit_index_3d(t_idx, chiral_offset);
        let val = *input_trits.get(t_idx).unwrap_or(&0);
        if let Some(slot) = permuted_trits.get_mut(dest) {
            *slot = val;
        }
        t_idx += 1;
    }

    let mut trit_roundtrip_matches: usize = 0;
    let mut r_idx: usize = 0;
    while r_idx < TOTAL_MANIFOLD_TRITS {
        let p = permute_trit_index_3d(r_idx, chiral_offset);
        let orig = invert_trit_index_3d(p, chiral_offset);
        let p_val = *permuted_trits.get(p).unwrap_or(&9);
        let o_val = *input_trits.get(orig).unwrap_or(&-9);
        if orig == r_idx && p_val == o_val {
            trit_roundtrip_matches += 1;
        }
        r_idx += 1;
    }

    Chair44AuditReport {
        unique_shards_visited,
        shard_roundtrip_matches,
        trit_roundtrip_matches,
        permuted_trits,
    }
}