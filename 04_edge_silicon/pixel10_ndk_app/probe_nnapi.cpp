#include <iostream>
#include <dlfcn.h>
#include <cstdint>

typedef struct ANeuralNetworksDevice ANeuralNetworksDevice;
typedef int (*fn_ANeuralNetworks_getDeviceCount)(uint32_t*);
typedef int (*fn_ANeuralNetworks_getDevice)(uint32_t, ANeuralNetworksDevice**);
typedef int (*fn_ANeuralNetworksDevice_getName)(const ANeuralNetworksDevice*, const char**);
typedef int (*fn_ANeuralNetworksDevice_getType)(const ANeuralNetworksDevice*, int32_t*);
typedef int (*fn_ANeuralNetworksDevice_getFeatureLevel)(const ANeuralNetworksDevice*, int64_t*);

int main() {
    std::cout << "=== Android NNAPI Accelerator Probe ===" << std::endl;
    void* nn_handle = dlopen("libneuralnetworks.so", RTLD_NOW);
    if (!nn_handle) {
        std::cout << "Failed to dlopen libneuralnetworks.so: " << dlerror() << std::endl;
        return 1;
    }

    auto getDevCount = (fn_ANeuralNetworks_getDeviceCount)dlsym(nn_handle, "ANeuralNetworks_getDeviceCount");
    auto getDev = (fn_ANeuralNetworks_getDevice)dlsym(nn_handle, "ANeuralNetworks_getDevice");
    auto getDevName = (fn_ANeuralNetworksDevice_getName)dlsym(nn_handle, "ANeuralNetworksDevice_getName");
    auto getDevType = (fn_ANeuralNetworksDevice_getType)dlsym(nn_handle, "ANeuralNetworksDevice_getType");
    auto getDevFeature = (fn_ANeuralNetworksDevice_getFeatureLevel)dlsym(nn_handle, "ANeuralNetworksDevice_getFeatureLevel");

    if (getDevCount && getDev) {
        uint32_t devCount = 0;
        int res = getDevCount(&devCount);
        std::cout << "NNAPI Device Count: " << devCount << " (result code=" << res << ")" << std::endl;

        for (uint32_t i = 0; i < devCount; ++i) {
            ANeuralNetworksDevice* dev = nullptr;
            if (getDev(i, &dev) == 0 && dev) {
                const char* name = nullptr;
                int32_t type = 0;
                int64_t feat = 0;
                if (getDevName) getDevName(dev, &name);
                if (getDevType) getDevType(dev, &type);
                if (getDevFeature) getDevFeature(dev, &feat);

                const char* typeDesc = "UNKNOWN";
                if (type == 1) typeDesc = "CPU";
                else if (type == 2) typeDesc = "GPU (PowerVR)";
                else if (type == 3) typeDesc = "ACCELERATOR (NPU/TPU)";

                std::cout << "  * Device [" << i << "]: " << (name ? name : "Unnamed") << std::endl;
                std::cout << "    Type: " << typeDesc << " (id=" << type << ")" << std::endl;
                std::cout << "    Feature Level: " << feat << std::endl;
            }
        }
    } else {
        std::cout << "Failed to resolve NNAPI device symbols." << std::endl;
    }

    return 0;
}