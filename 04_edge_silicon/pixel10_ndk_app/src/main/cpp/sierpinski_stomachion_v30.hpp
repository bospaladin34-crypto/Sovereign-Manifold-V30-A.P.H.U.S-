// 02_edge_android/app/src/main/cpp/sierpinski_stomachion_v30.hpp
// Pixel 10 (Tensor G5 Laguna 3nm) Embedded C++23 1.58-Bit Ternary & Stomachion Reflex Kernel
#pragma once
#include <cstdint>
#include <cmath>

namespace act_omega_v30 {

constexpr uint32_t PACKED_STALK_BYTES = 1536;
constexpr uint32_t PACKED_CTX_BYTES = 11520;
constexpr float PIXEL10_CARRIER_PHASE_RAD = 0.17259f;

inline float evaluate_zero_mul_radix243(const uint8_t* packed_1536, const float* activations, float scale_gamma) noexcept {
    float acc = 0.0f;
    for (uint32_t b = 0; b < PACKED_STALK_BYTES; ++b) {
        uint8_t rem = *(packed_1536 + b);
        const uint32_t base = b * 5u;
        for (uint32_t k = 0; k < 5u; ++k) {
            const int8_t trit = static_cast<int8_t>(rem % 3u) - 1;
            rem /= 3u;
            const float act = *(activations + base + k);
            if (trit == 1) { acc += act; } else if (trit == -1) { acc -= act; }
        }
    }
    return acc * scale_gamma;
}

inline uint32_t select_cutler_stomachion_config(uint64_t sequence_window_id, float b_norm_ut) noexcept {
    const uint32_t mag_seed = static_cast<uint32_t>(std::fabs(b_norm_ut) * 13.7f);
    return static_cast<uint32_t>((sequence_window_id * 31ULL + mag_seed + 144ULL) % 536ULL);
}

} // namespace act_omega_v30