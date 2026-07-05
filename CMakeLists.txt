# Set the minimum required version of CMake
cmake_minimum_required(VERSION 3.22)

# Set the project name and language
project(jniPdfium LANGUAGES CXX)

message(STATUS "ANDROID_NDK: ${ANDROID_NDK}")
message(STATUS "CMAKE_ANDROID_NDK: ${CMAKE_ANDROID_NDK}")
message(STATUS "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")
message(STATUS "CMAKE_ANDROID_ARCH_ABI: ${CMAKE_ANDROID_ARCH_ABI}")
message(STATUS "ANDROID_ABI: ${ANDROID_ABI}")
message(STATUS "ANDROID_PLATFORM: ${ANDROID_PLATFORM}")


# Add the source files for the library
set(SOURCES
        src/main/jni/src/mainJNILib.cpp
        src/main/jni/src/util.hpp
)

# Create the shared library target
add_library(jniPdfium SHARED ${SOURCES})

# Specify include directories if necessary
target_include_directories(jniPdfium
        PRIVATE ${CMAKE_SOURCE_DIR}/src/main/jni/include
)

# This complete archive includes PDFium's bundled third-party libraries.
# build-static.sh also selects the NDK's static libc++ runtime.
target_link_libraries(jniPdfium
        PRIVATE ${CMAKE_SOURCE_DIR}/src/main/jni/static/${ANDROID_ABI}/libpdfium.a
        PRIVATE ${CMAKE_SOURCE_DIR}/src/main/jni/static/${ANDROID_ABI}/libchromium_cxx.a
        PRIVATE log android jnigraphics dl m
)

# Specify additional compile options if required
target_compile_options(jniPdfium PRIVATE
        -Wall -Wextra -DHAVE_PTHREADS
)

# Specify additional linker flags if necessary
target_link_options(jniPdfium PRIVATE -Wl,--no-undefined -Wl,-z,max-page-size=16384)
