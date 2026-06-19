cmake_minimum_required(VERSION 3.21)

# Set the CMake toolchain file for cross-compilation
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/clang_toolchain.cmake" CACHE PATH "Path to the CMake's toolchain file")

project(Wasm32UnknownUnknownLibCXX VERSION 0.1.3 LANGUAGES C CXX ASM)

set(LIBCXX_ENABLE_EXCEPTIONS ON CACHE BOOL "" FORCE)
set(LIBCXXABI_ENABLE_EXCEPTIONS ON CACHE BOOL "" FORCE)

# Compile libcxx/libcxxabi/libunwind with native wasm exception handling so
# the runtime support symbols (__cxa_*, __wasm_lpad_context,
# _Unwind_CallPersonality) are emitted for the wasm EH ABI rather than the
# Itanium/__cxa_throw shim.
#
# Also define __USING_WASM_EXCEPTIONS__ explicitly: in clang 22 the predefined
# macro was renamed to __WASM_EXCEPTIONS__, but the libcxxabi 18 / libunwind 18
# source still uses the older name to gate the wasm EH paths (e.g. it's what
# spells out __gxx_personality_wasm0 instead of __gxx_personality_v0). Without
# the define, libcxxabi compiles to an Itanium-only build and the wasm
# personality stays absent.
# `-mllvm -wasm-use-legacy-eh=false` opts into the standardized try_table /
# exnref opcodes. Without it clang defaults to the legacy try / catch ops and
# the wasm engine refuses to load modules that mix the two encodings.
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fwasm-exceptions -D__USING_WASM_EXCEPTIONS__=1 -mllvm -wasm-use-legacy-eh=false")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fwasm-exceptions -D__USING_WASM_EXCEPTIONS__=1 -mllvm -wasm-use-legacy-eh=false")

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
file(COPY
    "${OPENBSD_SRC}/sys/sys/fcntl.h"
    DESTINATION "${BUILD_INCLUDE_DIR}"
)
file(COPY
    "${OPENBSD_SRC}/sys/sys/malloc.h"
    DESTINATION "${BUILD_INCLUDE_DIR}"
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
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)

# Fetch LLVM project
# 19.1.7 is the minimum that builds cleanly along the wasm EH path. Its libc++
# has complete C++20 ranges and its libc++abi/libunwind use consistent function
# signatures. LLVM 18 mismatches the __cxa_init_primary_exception and
# __cxa_throw destructor signatures when __USING_WASM_EXCEPTIONS__ is set.
FetchContent_Declare(
    LLVMProject
    URL https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/llvm-project-19.1.7.src.tar.xz
    URL_HASH SHA256=82401fea7b79d0078043f7598b835284d6650a75b93e64b6f761ea7b63097501
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(LLVMProject)
set(LLVM_PROJECT_SOURCE_DIR ${llvmproject_SOURCE_DIR})

# Make LLVM's cmake helper modules (AddLLVM and friends) available to the
# compiler-rt / libcxx / libcxxabi / libunwind subprojects when we build them
# via add_subdirectory instead of the full LLVM_ENABLE_RUNTIMES dance.
list(APPEND CMAKE_MODULE_PATH "${LLVM_PROJECT_SOURCE_DIR}/llvm/cmake/modules")

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
# Keep filesystem enabled. In libcxx 18+, disabling LIBCXX_ENABLE_FILESYSTEM
# also strips std::basic_filebuf, which downstream code using <fstream> needs.
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

# Build only Unwind-wasm.c from libunwind, which provides the runtime symbols
# (__wasm_lpad_context, _Unwind_CallPersonality, __gxx_personality_wasm0)
# emitted by -fwasm-exceptions. The rest of libunwind is the arch-generic
# stack walker, whose __libunwind_config.h has no wasm32 case, so the full
# add_subdirectory path fails to compile. Unwind-wasm.c needs none of it.
add_library(unwind STATIC
    ${LLVM_PROJECT_SOURCE_DIR}/libunwind/src/Unwind-wasm.c
)
target_compile_definitions(unwind PRIVATE
    # Define away the _LIBUNWIND_TRACE_API logging macros so the build does not
    # reference the unprovided logAPIs/logUnwinding/logDWARF debug symbols.
    NDEBUG
    _LIBUNWIND_IS_BAREMETAL=1
    # -fwasm-exceptions sets __USING_WASM_EXCEPTIONS__ only on C++ TUs; for
    # the C source we define it manually so the wasm EH personality code
    # inside Unwind-wasm.c is included.
    __USING_WASM_EXCEPTIONS__=1
    # libunwind's config.h falls back to __declspec(dllexport) on non-ELF /
    # non-MACH / non-AIX. wasm isn't any of those; hiding symbols turns the
    # export macro into a no-op, which is what we want for static linking.
    _LIBUNWIND_HIDE_SYMBOLS=1
)
target_compile_options(unwind PRIVATE -fwasm-exceptions)
target_include_directories(unwind PRIVATE
    ${LLVM_PROJECT_SOURCE_DIR}/libunwind/include
    ${LLVM_PROJECT_SOURCE_DIR}/libunwind/src
)

install(TARGETS unwind
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)
install(FILES ${LLVM_PROJECT_SOURCE_DIR}/libunwind/include/unwind.h
    DESTINATION include
)
install(FILES ${LLVM_PROJECT_SOURCE_DIR}/libunwind/LICENSE.TXT
    DESTINATION licenses/libunwind
)

# Build and install libc++abi
set(LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "" FORCE)
set(LIBCXXABI_ENABLE_THREADS OFF CACHE BOOL "" FORCE)
set(LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "" FORCE)
# Defaults to ON in libcxxabi 18; we build libunwind separately via
# add_subdirectory above and rely on downstream to link it explicitly, so the
# LLVM_ENABLE_RUNTIMES-aware integration is unnecessary.
set(LIBCXXABI_USE_LLVM_UNWINDER OFF CACHE BOOL "" FORCE)
set(LIBCXXABI_LIBUNWIND_INCLUDES "${LLVM_PROJECT_SOURCE_DIR}/libunwind/include" CACHE PATH "" FORCE)
set(LIBCXXABI_INCLUDE_TESTS OFF CACHE BOOL "" FORCE)
set(LIBCXXABI_BAREMETAL ON CACHE BOOL "" FORCE)
set(LIBCXXABI_SILENT_TERMINATE ON CACHE BOOL "" FORCE)

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

# Define the __cpp_exception tag that -fwasm-exceptions imports from `env`.
# wasm-ld merges this module-local definition with those imports, so links need
# no post-processing to drop the `env` import. Installed as libcppexception.a so
# env.sh can pull it with -lstatic=cppexception.
add_library(cppexception STATIC "${CMAKE_CURRENT_SOURCE_DIR}/cpp_exception_tag.s")
set_target_properties(cppexception PROPERTIES LINKER_LANGUAGE C)
install(TARGETS cppexception
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)

# Install the environment script
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/env.sh" DESTINATION .)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/env.bat" DESTINATION .)

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
