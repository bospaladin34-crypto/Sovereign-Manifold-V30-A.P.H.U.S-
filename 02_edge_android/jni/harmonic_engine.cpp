#include <jni.h>
#include <string>
#include <vector>
#include <chrono>
#include <cmath>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <android/log.h>

#include "bi_stalk_kernel.hpp"
#include "tpu_tachyon_delegate.hpp"
#include "vulkan_compute_dispatcher.hpp"

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
        g_sensory_proj[i] = std::clamp(std::sin(static_cast<float>(i) * 0.17f) * 0.25f, -0.5f, 0.5f);
    }

    const char* path = env->GetStringUTFChars(model_path, nullptr);
    if (!path) {
        LOGE("Model path string is null");
        return JNI_FALSE;
    }

    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        LOGE("Failed to open model file: %s", path);
        env->ReleaseStringUTFChars(model_path, path);
        return JNI_FALSE;
    }

    struct stat sb;
    if (fstat(fd, &sb) < 0) {
        LOGE("Failed to stat model file");
        close(fd);
        env->ReleaseStringUTFChars(model_path, path);
        return JNI_FALSE;
    }

    g_mmap_size = static_cast<size_t>(sb.st_size);
    void* addr = mmap(nullptr, g_mmap_size, PROT_READ, MAP_SHARED, fd, 0);
    close(fd);
    env->ReleaseStringUTFChars(model_path, path);

    if (addr == MAP_FAILED) {
        LOGE("Failed to mmap model weights");
        return JNI_FALSE;
    }

    g_mmap_weights = static_cast<int8_t*>(addr);
    LOGI("Successfully mmapped %zu bytes of model weights on Tensor G5", g_mmap_size);
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

    static uint64_t s_reflex_counter = 0;
    if (++s_reflex_counter % 60 == 0) {
        LOGI("Tensor G5 TPU Reflex: Tok #%d | Latency: %.1f us | Bx: %.1f | Frame: %llu", 
             best_token, elapsed_us, bx, (unsigned long long)(unsigned long long)s_reflex_counter);
    }

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

} // extern "C"