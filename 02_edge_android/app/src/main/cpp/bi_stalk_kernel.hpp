#pragma once

#include <vector>
#include <array>
#include <cmath>
#include <algorithm>
#include <cstdint>

namespace act_omega {

constexpr size_t NUM_COMPOUNDS = 1024;
constexpr size_t STALK_DIM = 8;
constexpr size_t COMPOUND_DIM = 16;
constexpr float AFE_STICTION_THRESHOLD = 0.18f;

struct alignas(64) BiStalkFrame {
    uint16_t compound_id;
    uint8_t base_root_id;
    uint8_t mod_root_id;
    uint8_t stiction_locked;
    float coboundary_norm;
    uint8_t padding[6];
    std::array<float, STALK_DIM> left_stalk;
    std::array<float, STALK_DIM> right_stalk;
};

class BiStalkAttentionKernel {
private:
    std::vector<float> braid_matrices; // 1024 * 8 * 8
    std::array<float, STALK_DIM> sensory_bias;

public:
    BiStalkAttentionKernel() {
        braid_matrices.resize(NUM_COMPOUNDS * STALK_DIM * STALK_DIM);
        for (size_t c = 0; c < NUM_COMPOUNDS; ++c) {
            float theta = std::sin(static_cast<float>(c) * 0.0061359f) * 0.5f;
            for (size_t i = 0; i < STALK_DIM; ++i) {
                for (size_t j = 0; j < STALK_DIM; ++j) {
                    float val = 0.0f;
                    if (i == j) val = std::cos(theta);
                    else if ((i + 1) % STALK_DIM == j) val = std::sin(theta);
                    else if (i == (j + 1) % STALK_DIM) val = -std::sin(theta);
                    braid_matrices[c * STALK_DIM * STALK_DIM + i * STALK_DIM + j] = val;
                }
            }
        }

        for (size_t i = 0; i < STALK_DIM; ++i) {
            sensory_bias[i] = std::clamp(std::cos(static_cast<float>(i) * 0.7854f) * 0.05f, -0.1f, 0.1f);
        }
    }

    std::pair<BiStalkFrame, std::array<float, COMPOUND_DIM>> forward(
        size_t compound_id,
        const std::array<float, STALK_DIM>& left,
        const std::array<float, STALK_DIM>& right
    ) const {
        size_t cid = compound_id % NUM_COMPOUNDS;
        BiStalkFrame frame{};
        frame.compound_id = static_cast<uint16_t>(cid);
        frame.base_root_id = static_cast<uint8_t>(cid % 64);
        frame.mod_root_id = static_cast<uint8_t>((cid / 64) % 240);

        // Calculate Sheaf Coboundary: delta = right - left
        float diff_sq = 0.0f;
        for (size_t i = 0; i < STALK_DIM; ++i) {
            float d = right[i] - left[i];
            diff_sq += d * d;
        }
        float coboundary_norm = std::sqrt(diff_sq);
        frame.coboundary_norm = coboundary_norm;

        std::array<float, STALK_DIM> attended_left = left;
        std::array<float, STALK_DIM> attended_right = right;

        if (coboundary_norm < AFE_STICTION_THRESHOLD) {
            frame.stiction_locked = 1;
        } else {
            frame.stiction_locked = 0;
            size_t mat_offset = cid * STALK_DIM * STALK_DIM;
            for (size_t i = 0; i < STALK_DIM; ++i) {
                float acc = 0.0f;
                for (size_t j = 0; j < STALK_DIM; ++j) {
                    acc += braid_matrices[mat_offset + i * STALK_DIM + j] * right[j];
                }
                attended_right[i] = acc + sensory_bias[i];
            }
        }

        frame.left_stalk = attended_left;
        frame.right_stalk = attended_right;

        std::array<float, COMPOUND_DIM> compound_stalk{};
        std::copy(attended_left.begin(), attended_left.end(), compound_stalk.begin());
        std::copy(attended_right.begin(), attended_right.end(), compound_stalk.begin() + STALK_DIM);

        return {frame, compound_stalk};
    }
};

} // namespace act_omega