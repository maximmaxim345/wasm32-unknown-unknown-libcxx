cmake_minimum_required(VERSION 3.21)

# Set the CMake toolchain file for cross-compilation
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/clang_toolchain.cmake" CACHE PATH "Path to the CMake's toolchain file")

project(Wasm32UnknownUnknownLibCXX VERSION 0.1.1 LANGUAGES C CXX ASM)

set(LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "" FORCE)
set(LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "" FORCE)

# Set C++ and C standards
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Fetch OpenBSD source
include(FetchContent)
FetchContent_Declare(
    OpenBSDSrc
    GIT_REPOSITORY https://github.com/openbsd/src.git
    GIT_TAG 86f778b976d08af3c1842d7f9984f0ca71a98f54 # From 31.08.2024
)
FetchContent_MakeAvailable(OpenBSDSrc)
set(OPENBSD_SRC ${openbsdsrc_SOURCE_DIR})

# Prepare include directories
set(BUILD_INCLUDE_DIR "${CMAKE_BINARY_DIR}/modified_includes")
file(MAKE_DIRECTORY ${BUILD_INCLUDE_DIR})
file(COPY
    "${OPENBSD_SRC}/include/" "${OPENBSD_SRC}/sys/" "${CMAKE_CURRENT_LIST_DIR}/include/"
    DESTINATION "${BUILD_INCLUDE_DIR}"
    FILES_MATCHING PATTERN "*.h"
)
file(COPY
    "${OPENBSD_SRC}/sys/arch/sh/include/_float.h"
    DESTINATION "${BUILD_INCLUDE_DIR}/machine"
)
file(COPY
    "${OPENBSD_SRC}/sys/sys/cdefs.h"
    DESTINATION "${BUILD_INCLUDE_DIR}/sys"
)
file(COPY
    "${OPENBSD_SRC}/sys/sys/endian.h"
    DESTINATION "${BUILD_INCLUDE_DIR}/sys"
)
file(REMOVE "${BUILD_INCLUDE_DIR}/sys/syscall.h")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -isystem ${BUILD_INCLUDE_DIR}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -isystem ${BUILD_INCLUDE_DIR}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I ${BUILD_INCLUDE_DIR}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D__OpenBSD__")

# Compile subset of OpenBSD libc
set(OPENBSD_LIBC_SOURCES
    stdlib/heapsort.c
    stdlib/qsort.c
    string/bcmp.c
    string/bcopy.c
    string/bzero.c
    string/explicit_bzero.c
    string/ffs.c
    string/memccpy.c
    string/memchr.c
    string/memcmp.c
    string/memmem.c
    string/memrchr.c
    string/stpcpy.c
    string/stpncpy.c
    string/strcasecmp.c
    string/strcasecmp_l.c
    string/strcasestr.c
    string/strcat.c
    string/strchr.c
    string/strcmp.c
    string/strcoll.c
    string/strcpy.c
    string/strcspn.c
    string/strdup.c
    string/strerror.c
    string/strlcat.c
    string/strlcpy.c
    string/strlen.c
    string/strmode.c
    string/strncat.c
    string/strncmp.c
    string/strncpy.c
    string/strndup.c
    string/strnlen.c
    string/strpbrk.c
    string/strrchr.c
    string/strsep.c
    string/strspn.c
    string/strstr.c
    string/strtok.c
    string/strxfrm.c
    string/strxfrm_l.c
    string/swab.c
    string/timingsafe_bcmp.c
    string/timingsafe_memcmp.c
)
list(TRANSFORM OPENBSD_LIBC_SOURCES PREPEND "${OPENBSD_SRC}/lib/libc/")

add_library(openbsd-libc STATIC ${OPENBSD_LIBC_SOURCES})
target_include_directories(openbsd-libc PUBLIC "${BUILD_INCLUDE_DIR}")

install(TARGETS openbsd-libc
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)

# Install OpenBSD libc headers
install(DIRECTORY "${BUILD_INCLUDE_DIR}/"
    DESTINATION include-libc
    FILES_MATCHING PATTERN "*.h"
)

# Fetch LLVM project
FetchContent_Declare(
    LLVMProject
    URL https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.0/llvm-project-14.0.0.src.tar.xz
    URL_HASH SHA256=35ce9edbc8f774fe07c8f4acdf89ec8ac695c8016c165dd86b8d10e7cba07e23
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(LLVMProject)
set(LLVM_PROJECT_SOURCE_DIR ${llvmproject_SOURCE_DIR})

# Build and install compiler-rt
set(COMPILER_RT_BAREMETAL_BUILD ON CACHE BOOL "" FORCE)
set(COMPILER_RT_DEFAULT_TARGET_ONLY ON CACHE BOOL "" FORCE)
set(COMPILER_RT_BUILD_BUILTINS ON CACHE BOOL "" FORCE)
set(COMPILER_RT_BUILD_SANITIZERS OFF CACHE BOOL "" FORCE)
set(COMPILER_RT_BUILD_XRAY OFF CACHE BOOL "" FORCE)
set(COMPILER_RT_BUILD_LIBFUZZER OFF CACHE BOOL "" FORCE)
set(COMPILER_RT_BUILD_PROFILE OFF CACHE BOOL "" FORCE)
set(COMPILER_RT_INSTALL_PATH "${CMAKE_INSTALL_PREFIX}" CACHE PATH "Installation directory")

add_subdirectory(${LLVM_PROJECT_SOURCE_DIR}/compiler-rt compiler-rt)
install(FILES ${LLVM_PROJECT_SOURCE_DIR}/compiler-rt/LICENSE.TXT
    DESTINATION licenses/compiler-rt
)

# Build and install libc++
set(LIBCXX_ENABLE_STATIC_ABI_LIBRARY OFF CACHE BOOL "" FORCE)
set(LIBCXX_ENABLE_SHARED OFF CACHE BOOL "" FORCE)
set(LIBCXX_ENABLE_FILESYSTEM OFF CACHE BOOL "" FORCE)
set(LIBCXX_INCLUDE_TESTS OFF CACHE BOOL "" FORCE)
set(LIBCXX_INCLUDE_BENCHMARKS OFF CACHE BOOL "" FORCE)
set(LIBCXX_INCLUDE_DOCS OFF CACHE BOOL "" FORCE)
set(LIBCXX_ENABLE_THREADS OFF CACHE BOOL "" FORCE)
set(LIBCXX_USE_COMPILER_RT ON CACHE BOOL "" FORCE)
set(LIBCXX_CXX_ABI "libcxxabi" CACHE STRING "" FORCE)

add_subdirectory(${LLVM_PROJECT_SOURCE_DIR}/libcxx libcxx)
install(FILES ${LLVM_PROJECT_SOURCE_DIR}/libcxx/LICENSE.TXT
    DESTINATION licenses/libcxx
)

# Build and install libc++abi
set(LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "" FORCE)
set(LIBCXXABI_ENABLE_THREADS OFF CACHE BOOL "" FORCE)
set(LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "" FORCE)
set(LIBCXXABI_INCLUDE_TESTS OFF CACHE BOOL "" FORCE)
set(LIBCXXABI_BAREMETAL ON CACHE BOOL "" FORCE)
set(LIBCXXABI_SILENT_TERMINATE ON CACHE BOOL "" FORCE)
set(LIBCXXABI_NON_DEMANGLING_TERMINATE ON CACHE BOOL "" FORCE)

add_subdirectory(${LLVM_PROJECT_SOURCE_DIR}/libcxxabi libcxxabi)
install(FILES ${LLVM_PROJECT_SOURCE_DIR}/libcxxabi/LICENSE.TXT
    DESTINATION licenses/libcxxabi
)

# Patch the cmath header
install(CODE "
    file(READ \"${CMAKE_BINARY_DIR}/include/c++/v1/cmath\" CMATH_CONTENT)
    string(REGEX REPLACE \"(^|\\n)[ \\t]*(using ::abs _LIBCPP_USING_IF_EXISTS;)\" \"\\\\1// \\\\2\" CMATH_CONTENT_PATCHED \"\${CMATH_CONTENT}\")
    file(WRITE \"${CMAKE_INSTALL_PREFIX}/include/c++/v1/cmath\" \"\${CMATH_CONTENT_PATCHED}\")
")

# Install the environment script
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/env.sh" DESTINATION .)

# Copy libc++.a to libstdc++.a
install(CODE "
    file(COPY \"\${CMAKE_INSTALL_PREFIX}/lib/libc++.a\" DESTINATION \"\${CMAKE_INSTALL_PREFIX}/lib\")
    file(RENAME \"\${CMAKE_INSTALL_PREFIX}/lib/libc++.a\" \"\${CMAKE_INSTALL_PREFIX}/lib/libstdc++.a\")
")

# Copy libopenbsd-libc.a to libc.a
install(CODE "
    file(COPY \"\${CMAKE_INSTALL_PREFIX}/lib/libopenbsd-libc.a\" DESTINATION \"\${CMAKE_INSTALL_PREFIX}/lib\")
    file(RENAME \"\${CMAKE_INSTALL_PREFIX}/lib/libopenbsd-libc.a\" \"\${CMAKE_INSTALL_PREFIX}/lib/libc.a\")
")

# Configure CPack
include(InstallRequiredSystemLibraries)
set(CPACK_PACKAGE_NAME "Wasm32UnknownUnknownLibCXX")
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Wasm32 unknown-unknown libc++ cross-compilation environment")
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Wasm32UnknownUnknownLibCXX")
set(CPACK_PACKAGE_FILE_NAME "wasm32-unknown-unknown-libcxx-${PROJECT_VERSION}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "wasm32-unknown-unknown-libcxx-${PROJECT_VERSION}-source")
set(CPACK_GENERATOR "TGZ;ZIP")
include(CPack)
