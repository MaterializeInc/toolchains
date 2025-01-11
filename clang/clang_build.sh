#!/bin/bash

# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License in the LICENSE file at the
# root of this repository, or online at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -exo pipefail

bootstrap_clang_version="$1"
clang_version="$2"

# Platform we're currently building on.
build_arch="$3"

# CPU target that we want to optimize for.
target_cpu="$4"
target_arch="$5"

# Assemble all of our variables.
libs_dir="$build_arch-linux-gnu"
c_binary="clang-$bootstrap_clang_version"
cxx_binary="clang++-$bootstrap_clang_version"
lld_binary="lld-$bootstrap_clang_version"

target_cpu_arg=""
if [ -n "$target_cpu" ]; then
    target_cpu_arg="-mcpu=$target_cpu"
fi

target_arch=""
target_arch_arg=""
if [ -n "$target_arch" ]; then
    target_arch_arg="-march=$target_arch"
fi

case $build_arch in
    "amd64")
        clang_arch=x86_64
    ;;
    "arm64")
        clang_arch=aarch64
    ;;
    *)
        echo "Programming error, unknown platform"
        exit 1
    ;;
esac

clang_target="$clang_arch-unknown-linux-gnu"
libs_dir="$clang_arch-linux-gnu"
clang_major_minor=$(echo "$clang_version" | cut -d. -f1-2)

# Configure the build.

cmake -G Ninja -S llvm -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-flto=thin -pthread -fPIC -O3 -DNDEBUG $target_cpu_arg $target_arch_arg" \
    -DCMAKE_CXX_FLAGS="-flto=thin -pthread -fPIC -O3 -DNDEBUG $target_cpu_arg $target_arch_arg" \
    -DCMAKE_SHARED_LINKER_FLAGS="-fPIC" \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION="on" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
    -DLLVM_DISTRIBUTION_COMPONENTS="clang-resource-headers" \
    -DCMAKE_C_COMPILER="$c_binary" \
    -DCMAKE_CXX_COMPILER="$cxx_binary" \
    -DCMAKE_CXX_STANDARD=17 \
    -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
    -DLLVM_USE_LINKER="$lld_binary" \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_ENABLE_LIBCXXABI=ON \
    -DLIBCXX_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DLLVM_ENABLE_LTO=Thin \
    -DLLVM_ENABLE_PIC=ON \
    -DLLVM_ENABLE_THREADS=ON \
    -DLLVM_ENABLE_ZLIB=FORCE_ON \
    -DLLVM_ENABLE_ZSTD=FORCE_ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLIBUNWIND_INSTALL_HEADERS=ON \
    -DTerminfo_LIBRARIES=/usr/lib/$libs_dir/libtinfo.a \
    -DZLIB_LIBRARY=/usr/lib/$libs_dir/libz.a \
    -Dzstd_LIBRARY=/usr/lib/$libs_dir/libzstd.a

# Actually build Clang and friends.

cmake --build build --target \
    clang \
    lld \
    llvm-ar \
    llvm-as \
    llvm-cov \
    llvm-dwp \
    llvm-dwarfdump \
    llvm-libtool-darwin \
    llvm-nm \
    llvm-objcopy \
    llvm-objdump \
    llvm-profdata \
    llvm-strip \
    llvm-ranlib \
    cxx \
    cxxabi \
    unwind \
    builtins \
    runtimes \
    sancov

# Configure the build for libclang.

cmake -G Ninja -S llvm -B build_libclang \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-flto=thin -pthread -fPIC -O3 -DNDEBUG $target_cpu_arg $target_arch_arg" \
    -DCMAKE_CXX_FLAGS="-flto=thin -pthread -fPIC -O3 -DNDEBUG $target_cpu_arg $target_arch_arg" \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION="on" \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DCMAKE_C_COMPILER="$c_binary" \
    -DCMAKE_CXX_COMPILER="$cxx_binary" \
    -DCMAKE_CXX_STANDARD=17 \
    -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
    -DLLVM_USE_LINKER="$lld_binary" \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_ENABLE_LTO=Thin \
    -DLLVM_ENABLE_PIC=ON \
    -DLLVM_ENABLE_THREADS=ON \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_ZLIB=FORCE_ON \
    -DLLVM_ENABLE_ZSTD=FORCE_ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DZLIB_LIBRARY=/usr/lib/$libs_dir/libz.a \
    -Dzstd_LIBRARY=/usr/lib/$libs_dir/libzstd.a

# Actually build libclang.

cmake --build build_libclang --target libclang
