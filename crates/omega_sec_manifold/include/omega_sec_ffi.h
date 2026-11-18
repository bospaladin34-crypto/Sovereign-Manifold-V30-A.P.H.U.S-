#pragma once
// ============================================================================
// ACT-Omega Sovereign Manifold :: C++23 Zero-Copy FFI Header ('SH4Z-SEC1')
// Compatible with 'omega_sec_manifold' (Rust L0 cdylib) and 'OmegaSteg v0.2'
// ============================================================================
#include <cstdint>
#include <cstddef>

namespace act_omega::sec {

struct alignas(64) Sh4zSec1Header {
    char     magic[8];              // "SH4ZSEC1"
    uint8_t  version;               // 2
    uint8_t  layer_mask;            // 0x1F (Trig|Alg|Poly|Topo|Geom)
    uint8_t  station_id;            // 0=Steg, 6=Sheaf, 9=Forge, 10=Shell, 31=MainlineRust
    uint8_t  payload_kind;          // 0=Text/Key, 1=Omsh, 2=Json, 3=Sheaf, 4=Forge
    uint32_t plain_len_le;
    uint64_t epoch_nonce_le;
    uint64_t chebyshev_pub_t_le;
    uint64_t kem_capsule_tag_le;
    uint64_t braid_commutator_le;
    uint64_t sheaf_coboundary_le;
    uint32_t golay_word_count_le;
    uint32_t plain_crc32_le;
};
static_assert(sizeof(Sh4zSec1Header) == 64, "Sh4zSec1Header must equal exactly one 64B cache line");

extern "C" int32_t omega_sec_self_test();

} // namespace act_omega::sec
