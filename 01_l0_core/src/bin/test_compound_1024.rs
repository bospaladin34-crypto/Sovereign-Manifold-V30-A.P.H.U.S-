use act_omega_l0_core::e8_roots::{generate_e8_roots, E8_ROOT_COUNT};
use std::time::Instant;

pub const VOCAB_SIZE_1024: usize = 1024;

pub struct CompoundPairLattice1024 {
    pub pairs: Vec<([f32; 8], [f32; 8])>,
}

impl CompoundPairLattice1024 {
    pub fn new(roots: &[[f32; 8]; E8_ROOT_COUNT]) -> Self {
        let mut pairs = Vec::with_capacity(VOCAB_SIZE_1024);
        
        // 1. Fundamental 240 Diagonal Self-Pairs (e_i, e_i)
        for &r in roots.iter() {
            pairs.push((r, r));
        }

        // 2. Primary 240 Orthogonal Successor Pairs (e_i, e_{i+1})
        for i in 0..E8_ROOT_COUNT {
            let next_idx = (i + 1) % E8_ROOT_COUNT;
            if let (Some(&r1), Some(&r2)) = (roots.get(i), roots.get(next_idx)) {
                pairs.push((r1, r2));
            }
        }

        // 3. Harmonic Inversion Pairs (e_i, -e_{i+1})
        for i in 0..E8_ROOT_COUNT {
            let next_idx = (i + 2) % E8_ROOT_COUNT;
            if let (Some(&r1), Some(&r2)) = (roots.get(i), roots.get(next_idx)) {
                let mut neg_r2 = [0.0f32; 8];
                for (j, slot) in neg_r2.iter_mut().enumerate() {
                    if let Some(&v) = r2.get(j) { *slot = -v; }
                }
                pairs.push((r1, neg_r2));
            }
        }

        // 4. Parity Cross-Pairs (e_i, e_{i+120})
        for i in 0..E8_ROOT_COUNT {
            let cross_idx = (i + 120) % E8_ROOT_COUNT;
            if let (Some(&r1), Some(&r2)) = (roots.get(i), roots.get(cross_idx)) {
                pairs.push((r1, r2));
            }
        }

        // 5. 64 Boundary Coset Pairs (e_i, e_{i*3 % 240})
        for i in 0..64 {
            let coset_idx = (i * 3) % E8_ROOT_COUNT;
            if let (Some(&r1), Some(&r2)) = (roots.get(i), roots.get(coset_idx)) {
                pairs.push((r1, r2));
            }
        }

        Self { pairs }
    }

    pub fn snap_bi_stalk(&self, stalk_a: &[f32; 8], stalk_b: &[f32; 8]) -> (usize, f32) {
        let mut best_idx = 0usize;
        let mut max_affinity = f32::NEG_INFINITY;

        for (idx, (p_a, p_b)) in self.pairs.iter().enumerate() {
            let mut dot_a = 0.0f32;
            let mut dot_b = 0.0f32;
            for k in 0..8 {
                if let (Some(&sa), Some(&pa)) = (stalk_a.get(k), p_a.get(k)) { dot_a += sa * pa; }
                if let (Some(&sb), Some(&pb)) = (stalk_b.get(k), p_b.get(k)) { dot_b += sb * pb; }
            }
            let total_affinity = dot_a + dot_b;
            if total_affinity > max_affinity {
                max_affinity = total_affinity;
                best_idx = idx;
            }
        }

        (best_idx, max_affinity)
    }
}

fn main() {
    println!("======================================================");
    println!("ACT-Omega v30.0: High-Order Compound-Pair Lattice (1024)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let t0 = Instant::now();
    let roots = generate_e8_roots();
    println!("[1/3] Loaded 240 Gosset E8 Root Basis in {} us", t0.elapsed().as_micros());

    let t_lattice = Instant::now();
    let lattice = CompoundPairLattice1024::new(&roots);
    println!("[2/3] Generated 1024 Compound-Pair Lattice in {} us", t_lattice.elapsed().as_micros());
    println!("  -> Total Bi-Stalk Pairs: {}", lattice.pairs.len());
    assert_eq!(lattice.pairs.len(), VOCAB_SIZE_1024, "Lattice must contain exactly 1024 compound pairs");

    // Benchmark Bi-Stalk Snapping
    let test_stalk_a = [0.5f32, -0.5, 0.5, -0.5, 0.5, -0.5, 0.5, -0.5];
    let test_stalk_b = [1.0f32, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    let t_snap = Instant::now();
    let (snapped_token, affinity) = lattice.snap_bi_stalk(&test_stalk_a, &test_stalk_b);
    let snap_us = t_snap.elapsed().as_micros();

    println!("[3/3] Bi-Stalk Projection Benchmarked:");
    println!("  -> Snapped Compound-Pair Token: {} / 1024", snapped_token);
    println!("  -> Geometric Affinity: {:.4}", affinity);
    println!("  -> Projection Latency: {} us ({:.1} k-proj/sec)", snap_us, 1_000_000.0 / (snap_us.max(1) as f64));

    println!("======================================================");
    println!("CYCLE 3 MILESTONE 30.40: 1024-LATTICE GENERATOR: PASS");
    println!("======================================================");
}