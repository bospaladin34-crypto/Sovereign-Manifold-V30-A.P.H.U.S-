#pragma once
#include <cstdint>
#include <cmath>

namespace act_omega_v31 {

constexpr uint32_t UTCP_MAGIC_V31 = 0x55544350u;
constexpr uint16_t UTCP_VERSION_V31 = 31u;
constexpr uint32_t SH4_E8Z_BYTES = 28800u;
constexpr uint32_t TERNARY_VAULT_BYTES = 13056u;

struct alignas(64) UtcpV31BinaryHeader {
    uint32_t magic;
    uint16_t version;
    uint16_t flags;
    uint64_t sequence_id;
    uint32_t node_origin;
    uint32_t node_target;
    uint32_t payload_len;
    uint16_t betti_0;
    uint16_t betti_1;
    uint32_t sheaf_stalk_dim;
    int32_t torsion_milli;
    uint32_t chsh_milli;
    uint64_t timestamp_ns;
    uint64_t fnv1a_checksum;
};

inline uint64_t fnv1a_hash64_edge(const uint8_t* data, uint32_t len, uint64_t seed) noexcept {
    uint64_t hash = 0xcbf29ce484222325ULL ^ seed;
    for (uint32_t i = 0; i < len; ++i) {
        hash ^= static_cast<uint64_t>(*(data + i));
        hash *= 0x0100000001b3ULL;
    }
    return hash;
}

inline float evaluate_sh4_leech_triality_reflex(
    const uint8_t* e8z_weights,
    const float* sensor_vec24,
    float carrier_phase_rad
) noexcept {
    float acc = 0.0f;
    for (uint32_t d = 0; d < 24u; ++d) {
        const uint8_t zz = *(e8z_weights + d);
        const int32_t signed_val = static_cast<int32_t>(zz >> 1u) ^ -static_cast<int32_t>(zz & 1u);
        acc += static_cast<float>(signed_val) * (*(sensor_vec24 + d));
    }
    return acc * std::cos(carrier_phase_rad);
}

} // namespace act_omega_v31