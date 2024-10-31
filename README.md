# wasm32-unknown-unknown-libcxx

This project provides C++ standard library and LibC support for the `wasm32-unknown-unknown` target, enabling C++/Rust interop through bindgen and cxx.

## Building the Libraries

```bash
# Create build directory and compile
cmake -GNinja -S. -Bbuild -DCMAKE_INSTALL_PREFIX=`pwd`/install
cmake --build build
cmake --install build
# Generate prebuild packages with
cmake --build build --target package
```

This will build and install:

- libc++ (C++ standard library)
- compiler-rt
- libc (OpenBSD-based)
- Required headers

## Using the Example Project

The [example project](./example) shows how to use this toolchain with Rust (with iced, bindgen, cxx and autocxx).

### Build Instructions

1. Build the toolchain:

```bash
# Create build directory and compile
cmake -GNinja -S. -Bbuild -DCMAKE_INSTALL_PREFIX=`pwd`/install
cmake --build build
cmake --install build
```

2. Source the environment before building the rust project:

```bash
source install/env.sh
```

3. Build the Wasm project:

```bash
cd example
rustup override set nightly
wasm-pack build --target web
```

4. Start a local server to test:

```bash
python3 -m http.server 8080 --directory .
```

## Important Notes

- Requires nightly Rust compiler for `wasm_c_abi=spec` feature (see [rust-lang/rust#291](https://github.com/rustwasm/team/issues/291))
- C++ exceptions are disabled by default
- Based on OpenBSD libc implementation, but only a subset of the library is actually compiled, so beware of linking errors!
- Manual implementation of some libc functions is required (for example malloc/free)
- I created this project mainly for running [CADara](https://github.com/maximmaxim345/cadara) on webbrowsers. So for a more complex example compiling OpenCASCADE to `wasm32-unknown-unknown`, see that.

## Credits

This project builds upon:

- [wasm32-unknown-unknown-openbsd-libc](https://github.com/trevyn/wasm32-unknown-unknown-openbsd-libc)
- [LlvmCrossCompileArmCortexM](https://github.com/KKoovalsky/LlvmCrossCompileArmCortexM)

