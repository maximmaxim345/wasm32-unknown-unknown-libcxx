@echo off

REM Get script directory
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

set WASM32_UNKNOWN_UNKNOWN_STDLIB=%SCRIPT_DIR%
set CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS=-C link-arg=-L%WASM32_UNKNOWN_UNKNOWN_STDLIB%\lib -L %WASM32_UNKNOWN_UNKNOWN_STDLIB%\lib -lstatic=c -lstatic=c++abi --Z wasm_c_abi=spec
set CFLAGS_wasm32_unknown_unknown=--sysroot=%WASM32_UNKNOWN_UNKNOWN_STDLIB% -D__OpenBSD__ -D__WASM32_UNKNOWN_UNKNOWN__
set CXXFLAGS_wasm32_unknown_unknown=%CFLAGS_wasm32_unknown_unknown% -fexceptions
set BINDGEN_EXTRA_CLANG_ARGS_wasm32_unknown_unknown=-fvisibility=default
