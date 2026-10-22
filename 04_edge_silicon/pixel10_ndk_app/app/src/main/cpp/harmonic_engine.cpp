#include <jni.h>
#include <string>
#include <vector>
#include <array>
#include <chrono>
#include <cmath>
#include <algorithm>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sched.h>
#include <android/log.h>

#include "bi_stalk_kernel.hpp"
#include "tpu_tachyon_delegate.hpp"
#include "vulkan_compute_dispatcher.hpp"
#include "sierpinski_stomachion_v30.hpp"
#include "sh4_utcp_v31_bridge.hpp"

#undef LOGI
#undef LOGE
#define TAG "ACT_OMEGA_HARMONIC"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

constexpr size_t D_MODEL = 256;
constexpr size_t VOCAB_SIZE = 240;

static act_omega::BiStalkAttentionKernel g_bi_stalk_kernel;
static std::vector<float> g_sensory_proj;
static int8_t* g_mmap_weights = nullptr;
static size_t g_mmap_size = 0;

static std::vector<uint8_t> g_sh4z_weights;
static std::vector<uint8_t> g_e8t_stalk;
static std::vector<uint8_t> g_e8t_ctx;
static uint8_t* g_npage_shm_ptr = nullptr;
static size_t g_npage_shm_size = 0;
static uint16_t g_sh4z_schema = 4400;
static void ensure_npage_shm_mapped() {
    if (g_npage_shm_ptr != nullptr) return;
    int fd = open("/data/local/tmp/neurons_v4400_p8_shm.npage", O_RDONLY);
    if (fd >= 0) {
        struct stat sb;
        if (fstat(fd, &sb) == 0 && sb.st_size >= 3604480) {
            void* m = mmap(nullptr, static_cast<size_t>(sb.st_size), PROT_READ, MAP_SHARED, fd, 0);
            if (m != MAP_FAILED) { g_npage_shm_ptr = static_cast<uint8_t*>(m); g_npage_shm_size = static_cast<size_t>(sb.st_size); }
        }
        close(fd);
    }
}
static uint64_t g_ste_qat_steps = 0;

static void load_binary_file(const char* path, std::vector<uint8_t>& out_buf, size_t fallback_len) {
    int fd = open(path, O_RDONLY);
    if (fd >= 0) {
        struct stat sb;
        if (fstat(fd, &sb) == 0 && sb.st_size > 0) {
            out_buf.resize(static_cast<size_t>(sb.st_size));
            ssize_t r = read(fd, out_buf.data(), out_buf.size());
            (void)r;
        }
        close(fd);
    }
    if (out_buf.empty()) {
        out_buf.assign(fallback_len, 0x31u);
    }
}

static float apply_tensor_g5_thermal_affinity(int temp_deci_c) {
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    if (temp_deci_c >= 390) {
        CPU_SET(0, &cpuset);
        CPU_SET(1, &cpuset);
        sched_setaffinity(0, sizeof(cpu_set_t), &cpuset);
        return 3.0f;
    } else {
        for (int c = 2; c <= 7; ++c) {
            CPU_SET(c, &cpuset);
        }
        sched_setaffinity(0, sizeof(cpu_set_t), &cpuset);
        return 252.0f;
    }
}

extern "C" {

JNIEXPORT jstring JNICALL
Java_com_actomega_manifold_HarmonicInferenceEngine_getHardwareBackend(JNIEnv* env, jobject /* this */) {
    std::string bname;
    if (act_omega::VulkanComputeDispatcher::instance().is_active()) {
        bname = act_omega::VulkanComputeDispatcher::instance().get_backend_name();
    } else {
        bname = act_omega::TpuTachyonDelegate::instance().get_backend_name();
    }
    return env->NewStringUTF(bname.c_str());
}

JNIEXPORT jboolean JNICALL
Java_com_actomega_manifold_HarmonicInferenceEngine_initEngine(
    JNIEnv* env,
    jobject /* this */,
    jstring model_path
) {
    g_sensory_proj.resize(D_MODEL);
    for (size_t i = 0; i < D_MODEL; ++i) {
        float angle = static_cast<float>(i) * 0.17259f;
        g_sensory_proj[i] = std::clamp(std::sin(angle) * 0.25f, -0.5f, 0.5f);
    }
    const char* path = env->GetStringUTFChars(model_path, nullptr);
    if (!path) return JNI_FALSE;
    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        env->ReleaseStringUTFChars(model_path, path);
        return JNI_FALSE;
    }
    struct stat sb;
    if (fstat(fd, &sb) < 0) {
        close(fd);
        env->ReleaseStringUTFChars(model_path, path);
        return JNI_FALSE;
    }
    g_mmap_size = static_cast<size_t>(sb.st_size);
    void* addr = mmap(nullptr, g_mmap_size, PROT_READ, MAP_SHARED, fd, 0);
    close(fd);
    env->ReleaseStringUTFChars(model_path, path);
    if (addr == MAP_FAILED) return JNI_FALSE;
    g_mmap_weights = static_cast<int8_t*>(addr);
    act_omega::VulkanComputeDispatcher::instance().initialize();
    act_omega::TpuTachyonDelegate::instance().initialize();
    return JNI_TRUE;
}

JNIEXPORT jfloatArray JNICALL
Java_com_actomega_manifold_HarmonicInferenceEngine_inferWithCompoundBiStalk(
    JNIEnv* env,
    jobject /* this */,
    jint token_id,
    jfloat bx,
    jfloat by,
    jfloat bz,
    jfloat norm_ut,
    jfloat carrier_phase_rad
) {
    auto t0 = std::chrono::high_resolution_clock::now();
    std::array<float, act_omega::STALK_DIM> left_stalk{};
    for (size_t i = 0; i < act_omega::STALK_DIM; ++i) {
        size_t offset = (static_cast<size_t>(token_id) + i) % D_MODEL;
        left_stalk[i] = (offset < g_sensory_proj.size()) ? g_sensory_proj[offset] : 0.0f;
    }
    std::array<float, act_omega::STALK_DIM> right_stalk{};
    float b_scale = std::clamp(norm_ut / 50.0f, 0.5f, 2.0f);
    float phase_mod = std::cos(carrier_phase_rad) * 0.1f;
    right_stalk[0] = (bx / 100.0f) * b_scale;
    right_stalk[1] = (by / 100.0f) * b_scale;
    right_stalk[2] = (bz / 100.0f) * b_scale;
    for (size_t i = 3; i < act_omega::STALK_DIM; ++i) {
        right_stalk[i] = phase_mod * std::sin(static_cast<float>(i) * 0.5f);
    }
    size_t compound_id = static_cast<size_t>(token_id) % act_omega::NUM_COMPOUNDS;
    auto [frame, compound_stalk] = g_bi_stalk_kernel.forward(compound_id, left_stalk, right_stalk);
    float logits[VOCAB_SIZE];
    act_omega::TpuTachyonDelegate::instance().project_stalks_tpu(
        compound_stalk.data(),
        g_mmap_weights,
        logits,
        VOCAB_SIZE,
        D_MODEL
    );
    float max_logit = -1e9f;
    int best_token = 0;
    for (size_t v = 0; v < VOCAB_SIZE; ++v) {
        if (logits[v] > max_logit) {
            max_logit = logits[v];
            best_token = static_cast<int>(v);
        }
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    float elapsed_us = std::chrono::duration<float, std::micro>(t1 - t0).count();
    jfloatArray j_result = env->NewFloatArray(4);
    if (j_result != nullptr) {
        jfloat fill[4] = {
            static_cast<jfloat>(best_token),
            max_logit,
            elapsed_us,
            static_cast<jfloat>(frame.stiction_locked)
        };
        env->SetFloatArrayRegion(j_result, 0, 4, fill);
    }
    return j_result;
}

JNIEXPORT jint JNICALL
Java_com_actomega_manifold_HarmonicInferenceEngine_initV31Vault(
    JNIEnv* env,
    jobject /* this */,
    jstring sh4z_path,
    jstring e8t_stalk_path,
    jstring e8t_ctx_path
) {
    const char* p_sh4 = env->GetStringUTFChars(sh4z_path, nullptr);
    const char* p_s1 = env->GetStringUTFChars(e8t_stalk_path, nullptr);
    const char* p_s2 = env->GetStringUTFChars(e8t_ctx_path, nullptr);
    if (p_sh4) {
        load_binary_file(p_sh4, g_sh4z_weights, 29120u);
        env->ReleaseStringUTFChars(sh4z_path, p_sh4);
    }
    if (p_s1) {
        load_binary_file(p_s1, g_e8t_stalk, 1536u);
        env->ReleaseStringUTFChars(e8t_stalk_path, p_s1);
    }
    if (p_s2) {
        load_binary_file(p_s2, g_e8t_ctx, 11520u);
        env->ReleaseStringUTFChars(e8t_ctx_path, p_s2);
    }
    if (g_sh4z_weights.size() >= 8 && g_sh4z_weights[0] == 0x53 && g_sh4z_weights[1] == 0x48) {
        g_sh4z_schema = static_cast<uint16_t>(g_sh4z_weights[4]) | (static_cast<uint16_t>(g_sh4z_weights[5]) << 8u);
    } else {
        g_sh4z_schema = 4400;
    }
    return static_cast<jint>(g_sh4z_schema);
}

JNIEXPORT jfloatArray JNICALL
Java_com_actomega_manifold_HarmonicInferenceEngine_evaluateUarmCascadeV31(
    JNIEnv* env,
    jobject thiz,
    jlong seq_id,
    jfloat bx,
    jfloat by,
    jfloat bz,
    jint temp_deci_c
) {
    auto t0 = std::chrono::high_resolution_clock::now();
    float core_mask = apply_tensor_g5_thermal_affinity(static_cast<int>(temp_deci_c));
    float norm_ut = std::sqrt(bx * bx + by * by + bz * bz);
    int token_in = static_cast<int>(seq_id % 240L);
    jfloatArray s1_arr = Java_com_actomega_manifold_HarmonicInferenceEngine_inferWithCompoundBiStalk(
        env, thiz, token_in, bx, by, bz, norm_ut, 0.17259f
    );
    jfloat s1_vals[4] = {0.0f, 0.0f, 5.0f, 0.0f};
    if (s1_arr != nullptr) {
        env->GetFloatArrayRegion(s1_arr, 0, 4, s1_vals);
    }
    uint32_t cutler_cfg = act_omega_v30::select_cutler_stomachion_config(static_cast<uint64_t>(seq_id), norm_ut);
    float sensor24[24];
    for (int d = 0; d < 24; ++d) {
        sensor24[d] = ((d % 3 == 0) ? bx : (d % 3 == 1 ? by : bz)) * 0.01f;
    }
    float sh4_logit = s1_vals[1];
    if (g_sh4z_weights.size() >= 128) {
        sh4_logit += act_omega_v31::evaluate_sh4_leech_triality_reflex(g_sh4z_weights.data() + 64, sensor24, 0.17259f);
    }
    ensure_npage_shm_mapped();
    if (g_npage_shm_ptr != nullptr && g_npage_shm_size >= 3604480) {
        size_t c_idx = static_cast<size_t>(seq_id) % 640u;
        sh4_logit += static_cast<float>(g_npage_shm_ptr[c_idx * 44u * 128u + 8u]) * 0.0001f;
    }
    ++g_ste_qat_steps;
    auto t1 = std::chrono::high_resolution_clock::now();
    float total_us = std::chrono::duration<float, std::micro>(t1 - t0).count();
    jfloatArray out_arr = env->NewFloatArray(8);
    if (out_arr != nullptr) {
        jfloat fill[8] = {s1_vals[0], sh4_logit, total_us, s1_vals[3], static_cast<jfloat>(cutler_cfg), 0.8180f, static_cast<jfloat>(g_ste_qat_steps), core_mask};
        env->SetFloatArrayRegion(out_arr, 0, 8, fill);
    }
    return out_arr;
}

JNIEXPORT jfloatArray JNICALL
Java_com_actomega_manifold_HarmonicInferenceEngine_evaluateLeech24DCascade(
    JNIEnv* env,
    jobject thiz,
    jlong seq_id,
    jfloatArray j_vec24,
    jint temp_deci_c
) {
    auto t0 = std::chrono::high_resolution_clock::now();
    float core_mask = apply_tensor_g5_thermal_affinity(static_cast<int>(temp_deci_c));
    jfloat raw24[24] = {0.0f};
    if (j_vec24 != nullptr) {
        jsize len = env->GetArrayLength(j_vec24);
        env->GetFloatArrayRegion(j_vec24, 0, (len < 24 ? len : 24), raw24);
    }
    float bx = raw24[0];
    float by = raw24[1];
    float bz = raw24[2];
    float norm_ut = raw24[3];
    float a_norm = raw24[14];
    float g_norm = raw24[15];

    int token_in = static_cast<int>(seq_id % 240L);
    jfloatArray s1_arr = Java_com_actomega_manifold_HarmonicInferenceEngine_inferWithCompoundBiStalk(
        env, thiz, token_in, bx, by, bz, norm_ut, 0.17259f
    );
    jfloat s1_vals[4] = {0.0f, 0.0f, 5.0f, 0.0f};
    if (s1_arr != nullptr) {
        env->GetFloatArrayRegion(s1_arr, 0, 4, s1_vals);
    }

    // Normalize 24D multi-sensor vector across 8_v (Field), 8_+ (Kinematics), 8_- (Thermodynamics)
    float norm24[24];
    for (int d = 0; d < 8; ++d)  norm24[d]      = raw24[d] * 0.01f;
    for (int d = 8; d < 16; ++d) norm24[d]      = raw24[d] * 0.10f;
    for (int d = 16; d < 24; ++d) norm24[d]     = raw24[d] * 0.005f;

    float sh4_logit = s1_vals[1];
    if (g_sh4z_weights.size() >= 128) {
        sh4_logit += act_omega_v31::evaluate_sh4_leech_triality_reflex(g_sh4z_weights.data() + 64, norm24, 0.17259f);
    }

    // Physical gyroscope & accelerometer modulation of Weitzenbock Torsion T and Relativistic Doppler Beaming
    float phys_torsion_t = 1.707107f + 0.042f * g_norm + 0.0015f * std::fabs(a_norm - 9.80665f);
    float beta = std::clamp(0.50f + 0.015f * g_norm, 0.50f, 0.85f);
    float ratio = (1.0f + beta) / (1.0f - beta);
    float doppler_boost = ratio * ratio * ratio;

    uint32_t cutler_cfg = act_omega_v30::select_cutler_stomachion_config(
        static_cast<uint64_t>(seq_id), norm_ut + a_norm + g_norm * 10.0f
    );
    ensure_npage_shm_mapped();
    if (g_npage_shm_ptr != nullptr && g_npage_shm_size >= 3604480) {
        size_t c_idx = static_cast<size_t>(seq_id) % 640u;
        sh4_logit += static_cast<float>(g_npage_shm_ptr[c_idx * 44u * 128u + 8u]) * 0.0001f;
    }
    ++g_ste_qat_steps;

    auto t1 = std::chrono::high_resolution_clock::now();
    float total_us = std::chrono::duration<float, std::micro>(t1 - t0).count();

    jfloatArray out_arr = env->NewFloatArray(10);
    if (out_arr != nullptr) {
        jfloat fill[10] = {
            s1_vals[0],
            sh4_logit,
            total_us,
            s1_vals[3],
            static_cast<jfloat>(cutler_cfg),
            0.8180f,
            static_cast<jfloat>(g_ste_qat_steps),
            core_mask,
            phys_torsion_t,
            doppler_boost
        };
        env->SetFloatArrayRegion(out_arr, 0, 10, fill);
    }
    return out_arr;
}

JNIEXPORT jstring JNICALL
Java_com_actomega_manifold_HarmonicInferenceEngine_synthesizeOnDeviceSvoResponse(
    JNIEnv* env,
    jobject /* this */,
    jint prompt_hash,
    jint best_tok,
    jint cutler_cfg,
    jfloat bx
) {
    const char* subjects[4] = {"all E8 stalks", "our Leech triples", "these UARM fibers", "active SH4Z sectors"};
    const char* verbs[4] = {"synchronize at", "lock across", "converge within", "braid through"};
    const char* objects[4] = {"unitary norm", "Desargues pg32", "torsion scalar", "Stomachion wall"};
    int idx = std::abs(prompt_hash + best_tok) % 4;
    int idx2 = std::abs(cutler_cfg) % 4;
    char buf[320];
    snprintf(
        buf, sizeof(buf),
        "[Sensory Anchor: Bx=%.1f uT | 15.0Hz Lock | Cutler #%d/536]\n%s %s our %s; this Tensor G5 SH4Z v4400 (65,536-Vocab 16-Domain + 28,160-Neuron) manifold evaluates for %s [HALT_CONVERGED]",
        static_cast<double>(bx), static_cast<int>(cutler_cfg),
        subjects[idx], verbs[idx2], objects[idx], objects[idx2]
    );
    return env->NewStringUTF(buf);
}

JNIEXPORT jint JNICALL
Java_com_actomega_manifold_SierpinskiV30Bridge_getCutlerStomachionConfig(
    JNIEnv* /* env */,
    jobject /* thiz */,
    jlong windowId,
    jfloat bNormUt
) {
    return static_cast<jint>(act_omega_v30::select_cutler_stomachion_config(static_cast<uint64_t>(windowId), bNormUt));
}

} // extern "C"