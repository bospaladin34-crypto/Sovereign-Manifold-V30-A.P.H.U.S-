#ifndef ACT_OMEGA_TACHYON_API_H
#define ACT_OMEGA_TACHYON_API_H

#include <cstdint>
#include <cstddef>
#include <dlfcn.h>
#include <android/log.h>

#define TACHYON_LOG_TAG "ACT_Omega_TPU"
#ifndef LOGI
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TACHYON_LOG_TAG, __VA_ARGS__)
#endif
#ifndef LOGE
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TACHYON_LOG_TAG, __VA_ARGS__)
#endif

#define EDGE_TPU_CLIENT_LIB_PATH "/vendor/lib64/libedgetpu_client.google.so"
#define EDGE_TPU_TACHYON_LIB_PATH "/vendor/lib64/libedgetpu_tachyon.google.so"

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handles for Tachyon sessions and configurations
typedef struct TachyonComputeSessionConfig_t* TachyonComputeSessionConfig;
typedef struct TachyonComputeSession_t* TachyonComputeSession;
typedef struct TachyonMessage_t* TachyonMessage;

// Function pointer signatures matching libedgetpu_client.google.so export table
typedef const char* (*fn_GetEdgeTpuClientVersion)();
typedef int (*fn_GetEdgeTpuFd)();

typedef TachyonComputeSessionConfig (*fn_TachyonComputeSessionConfig_create)();
typedef void (*fn_TachyonComputeSessionConfig_destroy)(TachyonComputeSessionConfig config);
typedef void (*fn_TachyonComputeSessionConfig_setPrivileged)(TachyonComputeSessionConfig config, bool privileged);
typedef void (*fn_TachyonComputeSessionConfig_setSessionType)(TachyonComputeSessionConfig config, int session_type);
typedef void (*fn_TachyonComputeSessionConfig_setCommandQueueSlotsCount)(TachyonComputeSessionConfig config, uint32_t count);
typedef void (*fn_TachyonComputeSessionConfig_setResponseQueueSlotsCount)(TachyonComputeSessionConfig config, uint32_t count);

typedef int (*fn_TachyonComputeSession_setupCommandQueue)(TachyonComputeSession session);
typedef int (*fn_TachyonComputeSession_setupResponseQueue)(TachyonComputeSession session);
typedef int (*fn_TachyonComputeSession_beginCommandQueueWrite)(TachyonComputeSession session, void** out_slot);
typedef int (*fn_TachyonComputeSession_commitCommandQueueWrite)(TachyonComputeSession session);
typedef int (*fn_TachyonComputeSession_beginResponseQueueRead)(TachyonComputeSession session, const void** in_slot);
typedef int (*fn_TachyonComputeSession_commitResponseQueueRead)(TachyonComputeSession session);

typedef int (*fn_TachyonComputeSession_sendCommand)(TachyonComputeSession session, const void* cmd, size_t size);
typedef int (*fn_TachyonComputeSession_receiveResponse)(TachyonComputeSession session, void* resp, size_t size);
typedef void (*fn_TachyonComputeSession_destroy)(TachyonComputeSession session);

#ifdef __cplusplus
}
#endif

// C++23 Dynamic Loader & Function Table Wrapper
struct TachyonApiTable {
    void* lib_handle = nullptr;

    fn_GetEdgeTpuClientVersion GetVersion = nullptr;
    fn_GetEdgeTpuFd GetFd = nullptr;
    fn_TachyonComputeSessionConfig_create ConfigCreate = nullptr;
    fn_TachyonComputeSessionConfig_destroy ConfigDestroy = nullptr;
    fn_TachyonComputeSessionConfig_setPrivileged SetPrivileged = nullptr;
    fn_TachyonComputeSessionConfig_setSessionType SetSessionType = nullptr;
    fn_TachyonComputeSessionConfig_setCommandQueueSlotsCount SetCommandQueueSlots = nullptr;
    fn_TachyonComputeSessionConfig_setResponseQueueSlotsCount SetResponseQueueSlots = nullptr;
    fn_TachyonComputeSession_setupCommandQueue SetupCommandQueue = nullptr;
    fn_TachyonComputeSession_setupResponseQueue SetupResponseQueue = nullptr;
    fn_TachyonComputeSession_beginCommandQueueWrite BeginCommandQueueWrite = nullptr;
    fn_TachyonComputeSession_commitCommandQueueWrite CommitCommandQueueWrite = nullptr;
    fn_TachyonComputeSession_beginResponseQueueRead BeginResponseQueueRead = nullptr;
    fn_TachyonComputeSession_commitResponseQueueRead CommitResponseQueueRead = nullptr;
    fn_TachyonComputeSession_sendCommand SendCommand = nullptr;
    fn_TachyonComputeSession_receiveResponse ReceiveResponse = nullptr;
    fn_TachyonComputeSession_destroy SessionDestroy = nullptr;

    bool load() {
                // Try public vendor namespace / jniLibs bundled lookup by filename first
        lib_handle = dlopen("libedgetpu_client.google.so", RTLD_NOW | RTLD_LOCAL);
        if (!lib_handle) {
            // Secondary fallback to vendor path
            lib_handle = dlopen("/vendor/lib64/libedgetpu_client.google.so", RTLD_NOW | RTLD_LOCAL);
        }
        if (!lib_handle) {
            LOGE("Failed to dlopen %s: %s", EDGE_TPU_CLIENT_LIB_PATH, dlerror());
            return false;
        }

        GetVersion = (fn_GetEdgeTpuClientVersion)dlsym(lib_handle, "GetEdgeTpuClientVersion");
        GetFd = (fn_GetEdgeTpuFd)dlsym(lib_handle, "GetEdgeTpuFd");
        ConfigCreate = (fn_TachyonComputeSessionConfig_create)dlsym(lib_handle, "TachyonComputeSessionConfig_create");
        ConfigDestroy = (fn_TachyonComputeSessionConfig_destroy)dlsym(lib_handle, "TachyonComputeSessionConfig_destroy");
        SetPrivileged = (fn_TachyonComputeSessionConfig_setPrivileged)dlsym(lib_handle, "TachyonComputeSessionConfig_setPrivileged");
        SetSessionType = (fn_TachyonComputeSessionConfig_setSessionType)dlsym(lib_handle, "TachyonComputeSessionConfig_setSessionType");
        SetCommandQueueSlots = (fn_TachyonComputeSessionConfig_setCommandQueueSlotsCount)dlsym(lib_handle, "TachyonComputeSessionConfig_setCommandQueueSlotsCount");
        SetResponseQueueSlots = (fn_TachyonComputeSessionConfig_setResponseQueueSlotsCount)dlsym(lib_handle, "TachyonComputeSessionConfig_setResponseQueueSlotsCount");
        SetupCommandQueue = (fn_TachyonComputeSession_setupCommandQueue)dlsym(lib_handle, "TachyonComputeSession_setupCommandQueue");
        SetupResponseQueue = (fn_TachyonComputeSession_setupResponseQueue)dlsym(lib_handle, "TachyonComputeSession_setupResponseQueue");
        BeginCommandQueueWrite = (fn_TachyonComputeSession_beginCommandQueueWrite)dlsym(lib_handle, "TachyonComputeSession_beginCommandQueueWrite");
        CommitCommandQueueWrite = (fn_TachyonComputeSession_commitCommandQueueWrite)dlsym(lib_handle, "TachyonComputeSession_commitCommandQueueWrite");
        BeginResponseQueueRead = (fn_TachyonComputeSession_beginResponseQueueRead)dlsym(lib_handle, "TachyonComputeSession_beginResponseQueueRead");
        CommitResponseQueueRead = (fn_TachyonComputeSession_commitResponseQueueRead)dlsym(lib_handle, "TachyonComputeSession_commitResponseQueueRead");
        SendCommand = (fn_TachyonComputeSession_sendCommand)dlsym(lib_handle, "TachyonComputeSession_sendCommand");
        ReceiveResponse = (fn_TachyonComputeSession_receiveResponse)dlsym(lib_handle, "TachyonComputeSession_receiveResponse");
        SessionDestroy = (fn_TachyonComputeSession_destroy)dlsym(lib_handle, "TachyonComputeSession_destroy");

        if (GetVersion) {
            LOGI("Google EdgeTPU Tachyon client loaded successfully: version %s", GetVersion());
        }
        return true;
    }

    void unload() {
        if (lib_handle) {
            dlclose(lib_handle);
            lib_handle = nullptr;
        }
    }
};

#endif // ACT_OMEGA_TACHYON_API_H