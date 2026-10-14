// 01_l0_core/src/braid_polyglot_ir.rs
// v30 Track 12: Manifold Native Language BraidIR 6-Strand Loom & Kolmogorov Reducer
// Zero-Square-Bracket Rust Invariant Enforced

pub const BRAID_STRANDS_B6: usize = 6;
pub const SOVEREIGN_OPCODES: usize = 10;

pub struct BraidReductionReport {
    pub initial_word_len: usize,
    pub reduced_word_len: usize,
    pub initial_writhe_charge: i32,
    pub reduced_writhe_charge: i32,
    pub cancelled_reidemeister_pairs: usize,
    pub reduced_generators: Vec<i8>,
}

/// Map Sovereign OS Opcode (0x00..0x09) to signed B_6 Artin generator in {-5..-1, +1..+5}
#[inline]
pub fn opcode_to_b6_generator(opcode: u8) -> i8 {
    match opcode % (SOVEREIGN_OPCODES as u8) {
        0 => 1,
        1 => -1,
        2 => 2,
        3 => -2,
        4 => 3,
        5 => -3,
        6 => 4,
        7 => -4,
        8 => 5,
        _ => -5,
    }
}

/// Stack-based O(N) Reidemeister Type II Free-Group Kolmogorov Reducer (sigma_i * sigma_i^-1 -> e)
pub fn reduce_braid_word_kolmogorov(opcodes: &Vec<u8>) -> BraidReductionReport {
    let mut initial_writhe: i32 = 0;
    let mut stack: Vec<i8> = Vec::with_capacity(opcodes.len());
    let mut cancelled_pairs: usize = 0;

    for op in opcodes.iter() {
        let gen = opcode_to_b6_generator(*op);
        initial_writhe += if gen > 0 { 1 } else { -1 };
        let top_cancels = if let Some(last_gen) = stack.last() {
            *last_gen + gen == 0
        } else {
            false
        };
        if top_cancels {
            stack.pop();
            cancelled_pairs += 1;
        } else {
            stack.push(gen);
        }
    }

    let mut reduced_writhe: i32 = 0;
    for g in stack.iter() {
        reduced_writhe += if *g > 0 { 1 } else { -1 };
    }

    BraidReductionReport {
        initial_word_len: opcodes.len(),
        reduced_word_len: stack.len(),
        initial_writhe_charge: initial_writhe,
        reduced_writhe_charge: reduced_writhe,
        cancelled_reidemeister_pairs: cancelled_pairs,
        reduced_generators: stack,
    }
}