#!/usr/bin/env bash

# Get script directory in a shell-agnostic way
if [ -n "${BASH_SOURCE[0]}" ]; then
    # bash
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "$ZSH_VERSION" ]; then
    # zsh
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    # fallback for sh
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

export WASM32_UNKNOWN_UNKNOWN_STDLIB=$SCRIPT_DIR
export CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS="-C link-arg=-L$WASM32_UNKNOWN_UNKNOWN_STDLIB/lib/ -L $WASM32_UNKNOWN_UNKNOWN_STDLIB/lib/ -lstatic=c -lstatic=c++abi --Z wasm_c_abi=spec"
export CFLAGS_wasm32_unknown_unknown="--sysroot=$WASM32_UNKNOWN_UNKNOWN_STDLIB -D__OpenBSD__ -D__WASM32_UNKNOWN_UNKNOWN__"
export CXXFLAGS_wasm32_unknown_unknown="$CFLAGS_wasm32_unknown_unknown -fexceptions"
export BINDGEN_EXTRA_CLANG_ARGS_wasm32_unknown_unknown="-fvisibility=default"
