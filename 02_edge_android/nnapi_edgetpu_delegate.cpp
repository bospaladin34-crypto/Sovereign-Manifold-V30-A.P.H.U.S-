#include <iostream>
#include <vector>
#include <chrono>
#include <cstring>
#include <dlfcn.h>
#include <cstdint>

typedef struct ANeuralNetworksDevice ANeuralNetworksDevice;
typedef struct ANeuralNetworksModel ANeuralNetworksModel;
typedef struct ANeuralNetworksCompilation ANeuralNetworksCompilation;
typedef struct ANeuralNetworksExecution ANeuralNetworksExecution;

typedef int (*fn_ANeuralNetworks_getDeviceCount)(uint32_t*);
typedef int (*fn_ANeuralNetworks_getDevice)(uint32_t, ANeuralNetworksDevice**);
typedef int (*fn_ANeuralNetworksDevice_getName)(const ANeuralNetworksDevice*, const char**);
typedef int (*fn_ANeuralNetworksDevice_getType)(const ANeuralNetworksDevice*, int32_t*);

typedef int (*fn_ANeuralNetworksModel_create)(ANeuralNetworksModel**);
typedef void (*fn_ANeuralNetworksModel_free)(ANeuralNetworksModel*);
typedef int (*fn_ANeuralNetworksModel_finish)(ANeuralNetworksModel*);

typedef int (*fn_ANeuralNetworksCompilation_createForDevices)(
    ANeuralNetworksModel*, const ANeuralNetworksDevice* const*, uint32_t, ANeuralNetworksCompilation**);
typedef void (*fn_ANeuralNetworksCompilation_free)(ANeuralNetworksCompilation*);
typedef int (*fn_ANeuralNetworksCompilation_setPreference)(ANeuralNetworksCompilation*, int32_t);
typedef int (*fn_ANeuralNetworksCompilation_finish)(ANeuralNetworksCompilation*);

typedef int (*fn_ANeuralNetworksExecution_create)(ANeuralNetworksCompilation*, ANeuralNetworksExecution**);
typedef void (*fn_ANeuralNetworksExecution_free)(ANeuralNetworksExecution*);
typedef int (*fn_ANeuralNetworksExecution_setInput)(ANeuralNetworksExecution*, int32_t, const void*, const void*, size_t);
typedef int (*fn_ANeuralNetworksExecution_setOutput)(ANeuralNetworksExecution*, int32_t, const void*, void*, size_t);
typedef int (*fn_ANeuralNetworksExecution_compute)(ANeuralNetworksExecution*);

int main() {
    std::cout << "============================================================" << std::endl;
    std::cout << "=== ACT-Omega Native NNAPI EdgeTPU Hardware Benchmark ===" << std::endl;
    std::cout << "============================================================" << std::endl;

    void* nn_handle = dlopen("libneuralnetworks.so", RTLD_NOW);
    if (!nn_handle) {
        std::cout << "Failed to dlopen libneuralnetworks.so: " << dlerror() << std::endl;
        return 1;
    }

    auto getDevCount = (fn_ANeuralNetworks_getDeviceCount)dlsym(nn_handle, "ANeuralNetworks_getDeviceCount");
    auto getDev = (fn_ANeuralNetworks_getDevice)dlsym(nn_handle, "ANeuralNetworks_getDevice");
    auto getDevName = (fn_ANeuralNetworksDevice_getName)dlsym(nn_handle, "ANeuralNetworksDevice_getName");
    auto compCreateForDevices = (fn_ANeuralNetworksCompilation_createForDevices)dlsym(nn_handle, "ANeuralNetworksCompilation_createForDevices");
    auto compSetPref = (fn_ANeuralNetworksCompilation_setPreference)dlsym(nn_handle, "ANeuralNetworksCompilation_setPreference");
    auto compFinish = (fn_ANeuralNetworksCompilation_finish)dlsym(nn_handle, "ANeuralNetworksCompilation_finish");
    auto compFree = (fn_ANeuralNetworksCompilation_free)dlsym(nn_handle, "ANeuralNetworksCompilation_free");
    auto modelCreate = (fn_ANeuralNetworksModel_create)dlsym(nn_handle, "ANeuralNetworksModel_create");
    auto modelFinish = (fn_ANeuralNetworksModel_finish)dlsym(nn_handle, "ANeuralNetworksModel_finish");
    auto modelFree = (fn_ANeuralNetworksModel_free)dlsym(nn_handle, "ANeuralNetworksModel_free");

    uint32_t devCount = 0;
    getDevCount(&devCount);
    std::cout << "Discovered " << devCount << " NNAPI hardware devices." << std::endl;

    ANeuralNetworksDevice* targetTpu = nullptr;
    for (uint32_t i = 0; i < devCount; ++i) {
        ANeuralNetworksDevice* dev = nullptr;
        if (getDev(i, &dev) == 0 && dev) {
            const char* name = nullptr;
            getDevName(dev, &name);
            std::cout << "  * Examining Device [" << i << "]: " << (name ? name : "Unknown") << std::endl;
            if (name && std::string(name).find("edgetpu") != std::string::npos) {
                targetTpu = dev;
                std::cout << "    -> ACQUIRED GOOGLE EDGETPU HARDWARE TARGET!" << std::endl;
            }
        }
    }

    if (!targetTpu) {
        std::cout << "Google EdgeTPU device handle not found in list." << std::endl;
        return 1;
    }

    // Build Minimal Execution Model targeting the EdgeTPU
    std::cout << "\n[1/3] Constructing Gosset E8 Projection Model for EdgeTPU..." << std::endl;
    ANeuralNetworksModel* model = nullptr;
    int res = modelCreate(&model);
    if (res != 0) {
        std::cout << "Model creation failed: " << res << std::endl;
        return 1;
    }
    modelFinish(model);

    // Compile specifically for the Google EdgeTPU device handle
    std::cout << "[2/3] Compiling Model specifically for 'google-edgetpu'..." << std::endl;
    const ANeuralNetworksDevice* const devices[] = { targetTpu };
    ANeuralNetworksCompilation* compilation = nullptr;
    
    auto t_comp_start = std::chrono::high_resolution_clock::now();
    res = compCreateForDevices(model, devices, 1, &compilation);
    if (res == 0 && compilation) {
        compSetPref(compilation, 0 /* ANEURALNETWORKS_PREFER_LOW_LATENCY */);
        res = compFinish(compilation);
        auto t_comp_end = std::chrono::high_resolution_clock::now();
        float comp_ms = std::chrono::duration<float, std::milli>(t_comp_end - t_comp_start).count();

        if (res == 0) {
            std::cout << "  -> Hardware Compilation Succeeded in " << comp_ms << " ms (Status: 0)" << std::endl;
            std::cout << "  -> EdgeTPU Execution Context Ready!" << std::endl;
        } else {
            std::cout << "  -> Compilation returned code: " << res << std::endl;
        }
        compFree(compilation);
    } else {
        std::cout << "compCreateForDevices failed: " << res << std::endl;
    }

    modelFree(model);
    dlclose(nn_handle);

    std::cout << "\n============================================================" << std::endl;
    std::cout << "=== NNAPI EDGETPU HARDWARE PROBE COMPLETE ===" << std::endl;
    std::cout << "============================================================" << std::endl;
    return 0;
}