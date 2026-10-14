#include <iostream>
#include <vector>
#include <cstdint>
#include <dlfcn.h>

// -------------------------------------------------------------
// OpenCL C-API Minimal Signatures
// -------------------------------------------------------------
typedef struct _cl_platform_id * cl_platform_id;
typedef struct _cl_device_id *   cl_device_id;
typedef int cl_int;
typedef uint32_t cl_uint;
typedef uint64_t cl_ulong;

typedef cl_int (*fn_clGetPlatformIDs)(cl_uint, cl_platform_id*, cl_uint*);
typedef cl_int (*fn_clGetDeviceIDs)(cl_platform_id, cl_ulong, cl_uint, cl_device_id*, cl_uint*);
typedef cl_int (*fn_clGetDeviceInfo)(cl_device_id, cl_uint, size_t, void*, size_t*);

// -------------------------------------------------------------
// Vulkan C-API Minimal Signatures
// -------------------------------------------------------------
typedef uint32_t VkResult;
typedef void* VkInstance;
typedef void* VkPhysicalDevice;

struct VkPhysicalDeviceProperties_min {
    uint32_t apiVersion;
    uint32_t driverVersion;
    uint32_t vendorID;
    uint32_t deviceID;
    uint32_t deviceType;
    char deviceName[256];
    uint8_t pipelineCacheUUID[16];
    // Remaining limits omitted
};

typedef VkResult (*fn_vkEnumerateInstanceVersion)(uint32_t*);
typedef VkResult (*fn_vkCreateInstance)(const void*, const void*, VkInstance*);
typedef void (*fn_vkDestroyInstance)(VkInstance, const void*);
typedef VkResult (*fn_vkEnumeratePhysicalDevices)(VkInstance, uint32_t*, VkPhysicalDevice*);
typedef void (*fn_vkGetPhysicalDeviceProperties)(VkPhysicalDevice, void*);

// -------------------------------------------------------------
// Android NNAPI Minimal Signatures
// -------------------------------------------------------------
typedef struct ANeuralNetworksDevice ANeuralNetworksDevice;
typedef int (*fn_ANeuralNetworks_getDeviceCount)(uint32_t*);
typedef int (*fn_ANeuralNetworks_getDevice)(uint32_t, ANeuralNetworksDevice**);
typedef int (*fn_ANeuralNetworksDevice_getName)(const ANeuralNetworksDevice*, const char**);
typedef int (*fn_ANeuralNetworksDevice_getType)(const ANeuralNetworksDevice*, int32_t*);
typedef int (*fn_ANeuralNetworksDevice_getFeatureLevel)(const ANeuralNetworksDevice*, int64_t*);

int main() {
    std::cout << "============================================================" << std::endl;
    std::cout << "=== ACT-Omega Tri-Backend Accelerator Hardware Probe ===" << std::endl;
    std::cout << "============================================================" << std::endl;

    // ---------------------------------------------------------
    // 1. OPENCL GPGPU PROBE
    // ---------------------------------------------------------
    std::cout << "\n[1/3] Probing OpenCL GPU Compute (PowerVR D-Series)..." << std::endl;
    void* cl_handle = dlopen("libOpenCL.so", RTLD_NOW);
    if (!cl_handle) cl_handle = dlopen("/vendor/lib64/libOpenCL-pixel.so", RTLD_NOW);

    if (cl_handle) {
        auto getPlatforms = (fn_clGetPlatformIDs)dlsym(cl_handle, "clGetPlatformIDs");
        auto getDevices = (fn_clGetDeviceIDs)dlsym(cl_handle, "clGetDeviceIDs");
        auto getDeviceInfo = (fn_clGetDeviceInfo)dlsym(cl_handle, "clGetDeviceInfo");

        if (getPlatforms && getDevices && getDeviceInfo) {
            cl_uint num_platforms = 0;
            getPlatforms(0, nullptr, &num_platforms);
            std::cout << "  -> OpenCL Platforms: " << num_platforms << std::endl;

            if (num_platforms > 0) {
                std::vector<cl_platform_id> platforms(num_platforms);
                getPlatforms(num_platforms, platforms.data(), nullptr);

                for (cl_uint p = 0; p < num_platforms; ++p) {
                    cl_uint num_devices = 0;
                    getDevices(platforms[p], 0xFFFFFFFF, 0, nullptr, &num_devices);
                    std::cout << "  -> Platform [" << p << "] Devices: " << num_devices << std::endl;

                    if (num_devices > 0) {
                        std::vector<cl_device_id> devices(num_devices);
                        getDevices(platforms[p], 0xFFFFFFFF, num_devices, devices.data(), nullptr);

                        for (cl_uint d = 0; d < num_devices; ++d) {
                            char name[256] = {0};
                            cl_uint compute_units = 0;
                            size_t max_work_group = 0;
                            char cl_version[256] = {0};

                            getDeviceInfo(devices[d], 0x102B /* CL_DEVICE_NAME */, sizeof(name), name, nullptr);
                            getDeviceInfo(devices[d], 0x1002 /* CL_DEVICE_MAX_COMPUTE_UNITS */, sizeof(compute_units), &compute_units, nullptr);
                            getDeviceInfo(devices[d], 0x1004 /* CL_DEVICE_MAX_WORK_GROUP_SIZE */, sizeof(max_work_group), &max_work_group, nullptr);
                            getDeviceInfo(devices[d], 0x102F /* CL_DEVICE_OPENCL_C_VERSION */, sizeof(cl_version), cl_version, nullptr);

                            std::cout << "     * GPU Device [" << d << "]: " << name << std::endl;
                            std::cout << "       Compute Units: " << compute_units << std::endl;
                            std::cout << "       Max Workgroup Size: " << max_work_group << std::endl;
                            std::cout << "       OpenCL C Version: " << cl_version << std::endl;
                        }
                    }
                }
            }
        }
        dlclose(cl_handle);
    } else {
        std::cout << "  -> OpenCL dlopen FAILED (" << dlerror() << ")" << std::endl;
    }

    // ---------------------------------------------------------
    // 2. VULKAN 1.4 COMPUTE PROBE
    // ---------------------------------------------------------
    std::cout << "\n[2/3] Probing Vulkan 1.4 Compute Capabilities..." << std::endl;
    void* vk_handle = dlopen("libvulkan.so", RTLD_NOW);
    if (vk_handle) {
        auto vkEnumVer = (fn_vkEnumerateInstanceVersion)dlsym(vk_handle, "vkEnumerateInstanceVersion");
        auto vkCreateInst = (fn_vkCreateInstance)dlsym(vk_handle, "vkCreateInstance");
        auto vkDestroyInst = (fn_vkDestroyInstance)dlsym(vk_handle, "vkDestroyInstance");
        auto vkEnumPhys = (fn_vkEnumeratePhysicalDevices)dlsym(vk_handle, "vkEnumeratePhysicalDevices");
        auto vkGetProps = (fn_vkGetPhysicalDeviceProperties)dlsym(vk_handle, "vkGetPhysicalDeviceProperties");

        if (vkEnumVer) {
            uint32_t ver = 0;
            vkEnumVer(&ver);
            std::cout << "  -> Vulkan Instance API: " 
                      << (ver >> 22) << "." << ((ver >> 12) & 0x3ff) << "." << (ver & 0xfff) << std::endl;
        }

        // Minimal instance create info
        struct {
            uint32_t sType = 1; // VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
            const void* pNext = nullptr;
            uint32_t flags = 0;
            const void* pAppInfo = nullptr;
            uint32_t enabledLayerCount = 0;
            const char* const* ppEnabledLayerNames = nullptr;
            uint32_t enabledExtensionCount = 0;
            const char* const* ppEnabledExtensionNames = nullptr;
        } instInfo;

        VkInstance inst = nullptr;
        if (vkCreateInst && vkCreateInst(&instInfo, nullptr, &inst) == 0 && inst) {
            uint32_t devCount = 0;
            vkEnumPhys(inst, &devCount, nullptr);
            std::cout << "  -> Vulkan Physical Devices: " << devCount << std::endl;

            if (devCount > 0) {
                std::vector<VkPhysicalDevice> pDevs(devCount);
                vkEnumPhys(inst, &devCount, pDevs.data());
                for (uint32_t i = 0; i < devCount; ++i) {
                    VkPhysicalDeviceProperties_min props{};
                    vkGetProps(pDevs[i], &props);
                    std::cout << "     * Vulkan Device [" << i << "]: " << props.deviceName << std::endl;
                    std::cout << "       API Version: " 
                              << (props.apiVersion >> 22) << "." << ((props.apiVersion >> 12) & 0x3ff) << "." << (props.apiVersion & 0xfff) << std::endl;
                    std::cout << "       Driver Version: " << props.driverVersion << std::endl;
                }
            }
            if (vkDestroyInst) vkDestroyInst(inst, nullptr);
        }
        dlclose(vk_handle);
    } else {
        std::cout << "  -> Vulkan dlopen FAILED (" << dlerror() << ")" << std::endl;
    }

    // ---------------------------------------------------------
    // 3. ANDROID NNAPI / EDGETPU PROBE
    // ---------------------------------------------------------
    std::cout << "\n[3/3] Probing Android NNAPI & EdgeTPU Hardware Accelerators..." << std::endl;
    void* nn_handle = dlopen("libneuralnetworks.so", RTLD_NOW);
    if (nn_handle) {
        auto getDevCount = (fn_ANeuralNetworks_getDeviceCount)dlsym(nn_handle, "ANeuralNetworks_getDeviceCount");
        auto getDev = (fn_ANeuralNetworks_getDevice)dlsym(nn_handle, "ANeuralNetworks_getDevice");
        auto getDevName = (fn_ANeuralNetworksDevice_getName)dlsym(nn_handle, "ANeuralNetworksDevice_getName");
        auto getDevType = (fn_ANeuralNetworksDevice_getType)dlsym(nn_handle, "ANeuralNetworksDevice_getType");
        auto getDevFeature = (fn_ANeuralNetworksDevice_getFeatureLevel)dlsym(nn_handle, "ANeuralNetworksDevice_getFeatureLevel");

        if (getDevCount) {
            uint32_t devCount = 0;
            int res = getDevCount(&devCount);
            std::cout << "  -> NNAPI Device Count: " << devCount << " (result=" << res << ")" << std::endl;

            for (uint32_t i = 0; i < devCount; ++i) {
                ANeuralNetworksDevice* dev = nullptr;
                if (getDev && getDev(i, &dev) == 0 && dev) {
                    const char* name = nullptr;
                    int32_t type = 0;
                    int64_t feat = 0;
                    if (getDevName) getDevName(dev, &name);
                    if (getDevType) getDevType(dev, &type);
                    if (getDevFeature) getDevFeature(dev, &feat);

                    const char* typeDesc = "UNKNOWN";
                    if (type == 1) typeDesc = "CPU";
                    else if (type == 2) typeDesc = "GPU";
                    else if (type == 3) typeDesc = "ACCELERATOR (NPU/TPU)";

                    std::cout << "     * Device [" << i << "]: " << (name ? name : "Unnamed") << std::endl;
                    std::cout << "       Type: " << typeDesc << " (" << type << ")" << std::endl;
                    std::cout << "       Feature Level: " << feat << std::endl;
                }
            }
        }
        dlclose(nn_handle);
    } else {
        std::cout << "  -> NNAPI dlopen FAILED (" << dlerror() << ")" << std::endl;
    }

    std::cout << "\n============================================================" << std::endl;
    std::cout << "=== PROBE SUITE COMPLETE ===" << std::endl;
    std::cout << "============================================================" << std::endl;
    return 0;
}