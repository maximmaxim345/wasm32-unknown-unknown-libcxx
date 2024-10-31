#!/usr/bin/env bash
export WASM32_UNKNOWN_UNKNOWN_STDLIB=$(dirname $(realpath $0))
export CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS="-L $WASM32_UNKNOWN_UNKNOWN_STDLIB/lib/ -lc -lc++abi"
export CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS=$CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS" --Z wasm_c_abi=spec"
export CXXFLAGS_wasm32_unknown_unknown="-isystem ${WASM32_UNKNOWN_UNKNOWN_STDLIB}/include-libc/"
export CXXFLAGS_wasm32_unknown_unknown=$CXXFLAGS_wasm32_unknown_unknown" -D_BYTE_ORDER=_LITTLE_ENDIAN -D__MATH_GENERIC=1 -nostdlib -D_LIBCPP_HAS_NO_LOCALIZATION"
export CXXFLAGS_wasm32_unknown_unknown=$CXXFLAGS_wasm32_unknown_unknown" -isystem ${WASM32_UNKNOWN_UNKNOWN_STDLIB}/include/"
export CXXFLAGS_wasm32_unknown_unknown=$CXXFLAGS_wasm32_unknown_unknown" -DHAVE___CXA_THREAD_ATEXIT_IMPL -DLIBCXXABI_BAREMETAL -DLIBCXXABI_NON_DEMANGLING_TERMINATE -DLIBCXXABI_SILENT_TERMINATE  -D_LIBCPP_DISABLE_EXTERN_TEMPLATE -D_LIBCPP_HAS_NO_LIBRARY_ALIGNED_ALLOCATION -D_LIBCXXABI_HAS_NO_THREADS -D_BYTE_ORDER=_LITTLE_ENDIAN -D__OpenBSD__ -DRUST_CXX_NO_EXCEPTIONS -DENOLINK"
export CXXFLAGS_wasm32_unknown_unknown=$CXXFLAGS_wasm32_unknown_unknown" -fexceptions -D__WASM32_UNKNOWN_UNKNOWN__"
export CFLAGS_wasm32_unknown_unknown=$CXXFLAGS_wasm32_unknown_unknown
export CXXFLAGS_wasm32_unknown_unknown=$CXXFLAGS_wasm32_unknown_unknown" -isystem ${WASM32_UNKNOWN_UNKNOWN_STDLIB}/include/c++/v1/"
export BINDGEN_EXTRA_CLANG_ARGS_wasm32_unknown_unknown="-fvisibility=default"
