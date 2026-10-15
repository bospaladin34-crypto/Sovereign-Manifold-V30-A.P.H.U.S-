#include <iostream>
#include <dlfcn.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    std::cout << "=== ACT-Omega Native EdgeTPU Driver Probe ===" << std::endl;
    
    // 1. Direct device node probe
    int fd_soc = open("/dev/edgetpu-soc", O_RDWR);
    std::cout << "/dev/edgetpu-soc open: " << (fd_soc >= 0 ? "SUCCESS (fd=" + std::to_string(fd_soc) + ")" : "FAILED") << std::endl;
    if (fd_soc >= 0) close(fd_soc);

    // 2. Direct dlopen of vendor client library
    void* handle = dlopen("/vendor/lib64/libedgetpu_client.google.so", RTLD_NOW);
    if (!handle) {
        std::cout << "dlopen failed: " << dlerror() << std::endl;
        // Try filename alone
        handle = dlopen("libedgetpu_client.google.so", RTLD_NOW);
    }

    if (handle) {
        std::cout << "dlopen SUCCESS!" << std::endl;
        typedef const char* (*fn_ver)();
        typedef int (*fn_fd)();
        auto GetVer = (fn_ver)dlsym(handle, "GetEdgeTpuClientVersion");
        auto GetFd = (fn_fd)dlsym(handle, "GetEdgeTpuFd");

        if (GetVer) std::cout << "EdgeTPU Client Version: " << GetVer() << std::endl;
        if (GetFd) std::cout << "EdgeTPU HW File Descriptor: " << GetFd() << std::endl;
        dlclose(handle);
    } else {
        std::cout << "Secondary dlopen also failed: " << dlerror() << std::endl;
    }

    return 0;
}