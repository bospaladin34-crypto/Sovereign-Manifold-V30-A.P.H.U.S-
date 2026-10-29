// ACT-Omega Net v50.0.0 (SH4Z v5000 TLV | CHAIN 145)
// Native Zig 0.17.0 @Vector(32, i8) & @Vector(8, f32) AVX2 SIMD Cacheline Kernel
// Target: x86_64-windows-msvc (-mcpu=alderlake) & aarch64-linux-android (Tensor G5/G3)

pub const Vec32i8 = @Vector(32, i8);
pub const Vec32i16 = @Vector(32, i16);
pub const Vec8f32 = @Vector(8, f32);

/// Computes the exact 64-byte .e8z cacheline inner product using two 256-bit @Vector(32, i8) lanes
/// expanded into @Vector(32, i16) to prevent signed 8-bit overflow on Alder Lake AVX2.
pub export fn sovereign_zig_e8_cacheline_dot64(
    line_a: [*]const i8,
    line_b: [*]const i8,
) callconv(.c) i32 {
    const a_lo: Vec32i8 = line_a[0..32].*;
    const a_hi: Vec32i8 = line_a[32..64].*;
    const b_lo: Vec32i8 = line_b[0..32].*;
    const b_hi: Vec32i8 = line_b[32..64].*;

    const a_lo16: Vec32i16 = a_lo;
    const a_hi16: Vec32i16 = a_hi;
    const b_lo16: Vec32i16 = b_lo;
    const b_hi16: Vec32i16 = b_hi;

    const prod_lo: Vec32i16 = a_lo16 * b_lo16;
    const prod_hi: Vec32i16 = a_hi16 * b_hi16;

    const sum_lo: i32 = @intCast(@reduce(.Add, prod_lo));
    const sum_hi: i32 = @intCast(@reduce(.Add, prod_hi));
    return sum_lo + sum_hi;
}

/// Computes the 8D E8 lattice projection norm squared across two @Vector(8, f32) lanes.
pub export fn sovereign_zig_e8_norm_sq8(
    vec_a: [*]const f32,
    vec_b: [*]const f32,
) callconv(.c) f32 {
    const a: Vec8f32 = vec_a[0..8].*;
    const b: Vec8f32 = vec_b[0..8].*;
    const diff: Vec8f32 = a - b;
    const sq: Vec8f32 = @mulAdd(Vec8f32, a, b, diff * diff);
    return @reduce(.Add, sq);
}
