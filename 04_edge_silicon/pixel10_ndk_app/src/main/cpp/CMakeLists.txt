cmake_minimum_required(VERSION 3.22.1)
project("harmonic_engine")

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(harmonic_engine SHARED
    harmonic_engine.cpp
)

target_link_libraries(harmonic_engine
    log
    vulkan
)

# Enforce 16 KB ELF page alignment for Android 15/16/17 (Tensor G5)
target_link_options(harmonic_engine PRIVATE "-Wl,-z,max-page-size=16384")