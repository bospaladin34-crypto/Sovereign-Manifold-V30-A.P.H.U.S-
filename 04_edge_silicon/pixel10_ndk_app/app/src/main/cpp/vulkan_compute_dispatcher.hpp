#ifndef ACT_OMEGA_VULKAN_COMPUTE_DISPATCHER_HPP
#define ACT_OMEGA_VULKAN_COMPUTE_DISPATCHER_HPP

#include <vulkan/vulkan.h>
#include <vector>
#include <string>
#include <atomic>
#include <cstring>
#include <cstdint>

namespace act_omega {

// In-Memory Embedded SPIR-V Bytecode (2,208 bytes / 552 uint32 words)
alignas(4) static const uint32_t E8_PROJECTION_SPV[] = {
    
};
constexpr size_t E8_PROJECTION_SPV_SIZE = sizeof(E8_PROJECTION_SPV);

class VulkanComputeDispatcher {
public:
    static VulkanComputeDispatcher& instance() {
        static VulkanComputeDispatcher s_instance;
        return s_instance;
    }

    bool initialize() {
        if (m_initialized.load()) return true;

        VkApplicationInfo appInfo{};
        appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
        appInfo.pApplicationName = "ACT-Omega Manifold";
        appInfo.applicationVersion = VK_MAKE_VERSION(30, 0, 0);
        appInfo.pEngineName = "Gosset Compute";
        appInfo.engineVersion = VK_MAKE_VERSION(30, 0, 0);
        appInfo.apiVersion = VK_API_VERSION_1_2;

        VkInstanceCreateInfo createInfo{};
        createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
        createInfo.pApplicationInfo = &appInfo;

        VkResult res = vkCreateInstance(&createInfo, nullptr, &m_instance);
        if (res != VK_SUCCESS) {
            m_status = "Vulkan Failed: vkCreateInstance (err=" + std::to_string(res) + ")";
            return false;
        }

        uint32_t deviceCount = 0;
        vkEnumeratePhysicalDevices(m_instance, &deviceCount, nullptr);
        if (deviceCount == 0) {
            m_status = "Vulkan Failed: No Physical Device";
            return false;
        }

        std::vector<VkPhysicalDevice> devices(deviceCount);
        vkEnumeratePhysicalDevices(m_instance, &deviceCount, devices.data());
        m_physicalDevice = devices[0];

        VkPhysicalDeviceProperties props;
        vkGetPhysicalDeviceProperties(m_physicalDevice, &props);
        m_gpu_name = props.deviceName;

        // Find Compute Queue Family
        uint32_t queueFamilyCount = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(m_physicalDevice, &queueFamilyCount, nullptr);
        std::vector<VkQueueFamilyProperties> queueFamilies(queueFamilyCount);
        vkGetPhysicalDeviceQueueFamilyProperties(m_physicalDevice, &queueFamilyCount, queueFamilies.data());

        for (uint32_t i = 0; i < queueFamilyCount; ++i) {
            if (queueFamilies[i].queueFlags & VK_QUEUE_COMPUTE_BIT) {
                m_computeQueueFamily = i;
                break;
            }
        }

        if (m_computeQueueFamily == UINT32_MAX) {
            m_status = "Vulkan Failed: No Compute Queue";
            return false;
        }

        float queuePriority = 1.0f;
        VkDeviceQueueCreateInfo queueCreateInfo{};
        queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
        queueCreateInfo.queueFamilyIndex = m_computeQueueFamily;
        queueCreateInfo.queueCount = 1;
        queueCreateInfo.pQueuePriorities = &queuePriority;

        VkDeviceCreateInfo deviceCreateInfo{};
        deviceCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
        deviceCreateInfo.queueCreateInfoCount = 1;
        deviceCreateInfo.pQueueCreateInfos = &queueCreateInfo;

        res = vkCreateDevice(m_physicalDevice, &deviceCreateInfo, nullptr, &m_device);
        if (res != VK_SUCCESS) {
            m_status = "Vulkan Failed: vkCreateDevice (err=" + std::to_string(res) + ")";
            return false;
        }

        vkGetDeviceQueue(m_device, m_computeQueueFamily, 0, &m_computeQueue);

        // Create Shader Module directly from in-memory array (0 file IO)
        VkShaderModuleCreateInfo shaderModuleInfo{};
        shaderModuleInfo.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
        shaderModuleInfo.codeSize = E8_PROJECTION_SPV_SIZE;
        shaderModuleInfo.pCode = E8_PROJECTION_SPV;

        res = vkCreateShaderModule(m_device, &shaderModuleInfo, nullptr, &m_shaderModule);
        if (res != VK_SUCCESS) {
            m_status = "Vulkan Failed: vkCreateShaderModule (err=" + std::to_string(res) + ")";
            return false;
        }

        m_status = "Vulkan 1.4 Compute (" + m_gpu_name + ")";
        m_initialized.store(true);
        return true;
    }

    bool is_active() const {
        return m_initialized.load();
    }

    std::string get_backend_name() const {
        return m_status;
    }

private:
    VulkanComputeDispatcher() : m_status("Vulkan Uninitialized") {}
    ~VulkanComputeDispatcher() {
        if (m_device != VK_NULL_HANDLE) {
            if (m_shaderModule != VK_NULL_HANDLE) vkDestroyShaderModule(m_device, m_shaderModule, nullptr);
            vkDestroyDevice(m_device, nullptr);
        }
        if (m_instance != VK_NULL_HANDLE) vkDestroyInstance(m_instance, nullptr);
    }

    VkInstance m_instance = VK_NULL_HANDLE;
    VkPhysicalDevice m_physicalDevice = VK_NULL_HANDLE;
    VkDevice m_device = VK_NULL_HANDLE;
    VkQueue m_computeQueue = VK_NULL_HANDLE;
    uint32_t m_computeQueueFamily = UINT32_MAX;
    VkShaderModule m_shaderModule = VK_NULL_HANDLE;

    std::string m_gpu_name = "PowerVR D-Series";
    std::string m_status;
    std::atomic<bool> m_initialized{false};
};

} // namespace act_omega

#endif // ACT_OMEGA_VULKAN_COMPUTE_DISPATCHER_HPP