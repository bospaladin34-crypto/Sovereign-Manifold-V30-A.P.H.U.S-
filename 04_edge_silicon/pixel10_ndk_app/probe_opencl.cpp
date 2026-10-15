#include <iostream>
#include <dlfcn.h>

typedef int (*fn_clGetPlatformIDs)(uint32_t, void*, uint32_t*);

int main() {
    std::cout << "=== Testing OpenCL Driver on Tensor G5 ===" << std::endl;
    void* handle = dlopen("libOpenCL.so", RTLD_NOW);
    if (!handle) {
        handle = dlopen("/vendor/lib64/libOpenCL-pixel.so", RTLD_NOW);
    }
    if (handle) {
        std::cout << "OpenCL dlopen: SUCCESS!" << std::endl;
        auto getPlatforms = (fn_clGetPlatformIDs)dlsym(handle, "clGetPlatformIDs");
        if (getPlatforms) {
            uint32_t count = 0;
            int err = getPlatforms(0, nullptr, &count);
            std::cout << "Available OpenCL Platforms: " << count << " (err=" << err << ")" << std::endl;
        }
        dlclose(handle);
    } else {
        std::cout << "OpenCL dlopen failed: " << dlerror() << std::endl;
    }
    return 0;
}