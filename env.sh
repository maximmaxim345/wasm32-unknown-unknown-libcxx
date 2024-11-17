#!/usr/bin/env bash

# Get script directory in a shell-agnostic way
if [ -n "${BASH_SOURCE}" ]; then
    # bash
    WASM32_UNKNOWN_UNKNOWN_STDLIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "$ZSH_VERSION" ]; then
    # zsh
    WASM32_UNKNOWN_UNKNOWN_STDLIB="$(cd "$(dirname "$0")" && pwd)"
else
    # fallback for sh, we can't determine this scripts directory, so we assume the current directory
    # if it's not, you can set WASM32_UNKNOWN_UNKNOWN_STDLIB_DIR to the correct directory
    if [ -n "$WASM32_UNKNOWN_UNKNOWN_STDLIB_DIR" ]; then
        WASM32_UNKNOWN_UNKNOWN_STDLIB="$WASM32_UNKNOWN_UNKNOWN_STDLIB_DIR"
    else
        WASM32_UNKNOWN_UNKNOWN_STDLIB="$(pwd)"
    fi
fi

export CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS="-C link-arg=-L$WASM32_UNKNOWN_UNKNOWN_STDLIB/lib/ -L $WASM32_UNKNOWN_UNKNOWN_STDLIB/lib/ -lstatic=c -lstatic=c++abi --Z wasm_c_abi=spec"
export CFLAGS_wasm32_unknown_unknown="--sysroot=$WASM32_UNKNOWN_UNKNOWN_STDLIB -D__OpenBSD__ -D__WASM32_UNKNOWN_UNKNOWN__"
export CXXFLAGS_wasm32_unknown_unknown="$CFLAGS_wasm32_unknown_unknown -fexceptions"
export BINDGEN_EXTRA_CLANG_ARGS_wasm32_unknown_unknown="-fvisibility=default"
