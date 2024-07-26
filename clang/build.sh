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

# Script for building clang/LLVM from source, and packaging it into a tarball
# that can be consumed by downstream systems, e.g. Bazel.

if [ $# -ne 3 ]; then
    echo "Need to provide the semver version of clang, the major version to bootstrap with, and a directory to build in."
    echo "Usage ./build.sh <version> <bootstrap_version> <directory>"
    exit 1
fi
clang_version="$1"
clang_bootstrap_version="$2"
build_directory="$3"

if [ -z "$CLANG_ARCH" ]; then
    echo "Need to specify the CLANG_ARCH you're building for."
    exit 1
fi

# 0. Install common dependencies that we need.

apt-get install -y zstd cmake

# 1. Install the version of clang we'll use to bootstrap

script_dir=$(dirname "$(realpath "$0")")
"$script_dir"/llvm.sh $clang_bootstrap_version

# 2. Move into our build directory and clone the llvm-project repo.

cd $build_directory
git clone https://github.com/llvm/llvm-project
cd "llvm-project"
git checkout llvmorg-$clang_version

# 3. Run cmake to configure the build

libs_dir="$CLANG_ARCH-linux-gnu"

target_cpu_arg=""
if [ -n "$TARGET_CPU" ]; then target_cpu_arg="-mcpu=$TARGET_CPU"
fi

cmake -S llvm -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="$target_cpu_arg -flto=thin -pthread" \
    -DCMAKE_CXX_FLAGS="$target_cpu_arg -flto=thin -pthread" \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION="on" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
    -DLLVM_DISTRIBUTION_COMPONENTS="clang-resource-headers" \
    -DCMAKE_C_COMPILER=clang-17 \
    -DCMAKE_CXX_COMPILER=clang++-17 \
    -DLLVM_USE_LINKER=lld-17 \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
    -DLLVM_ENABLE_LTO=Thin \
    -DLLVM_ENABLE_PIC=ON \
    -DLLVM_ENABLE_THREADS=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DTerminfo_LIBRARIES=/usr/lib/$libs_dir/libtinfo.a \
    -DZLIB_LIBRARY=/usr/lib/$libs_dir/libz.a

CC="clang-$clang_bootstrap_version" CXX="clang++-$clang_bootstrap_version" cmake --build build --target \
    clang \
    lld \
    llvm-ar \
    llvm-as \
    llvm-cov \
    llvm-dwp \
    llvm-libtool-darwin \
    llvm-nm \
    llvm-objcopy \
    llvm-objdump \
    llvm-profdata \
    cxx \
    cxxabi \
    unwind \
    builtins \
    -j $(nproc)
