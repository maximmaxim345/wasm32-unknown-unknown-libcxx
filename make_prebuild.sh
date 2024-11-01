#!/usr/bin/env bash
set -e
rm -rf ./prebuild/wasm32-unknown-unknown-libcxx
mkdir -p ./prebuild
cmake -GNinja -S. -Bprebuild/build -DCMAKE_INSTALL_PREFIX=$(pwd)/prebuild/wasm32-unknown-unknown-libcxx --fresh
cmake --build prebuild/build
cmake --install prebuild/build
rm -rf ./prebuild/wasm32-unknown-unknown-libcxx.zip
rm -rf ./prebuild/wasm32-unknown-unknown-libcxx.tar.gz
pushd ./prebuild
zip -r wasm32-unknown-unknown-libcxx.zip wasm32-unknown-unknown-libcxx
tar caf wasm32-unknown-unknown-libcxx.tar.gz wasm32-unknown-unknown-libcxx
popd
