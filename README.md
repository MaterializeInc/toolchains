<div align="center">
  <h1><code>toolchains</code></h1>
</div>

### About

This repository contains Github Actions to build and package Rust and C toolchains for consumption with Bazel.

#### Rust

Currently we just re-compress the Rust toolchains from `static.rust-lang.org` with [`zstd`](https://github.com/facebook/zstd)
which has much faster decompression times than the default `LZMA2` algorithm typically used with `.tar.xz` package.

#### C (Clang)

We build a Clang toolchain from the upstream source [`llvm-project`](https://github.com/llvm/llvm-project) with CMake and
Ninja. Generally following the instructions from:

* [Clang - Getting Started](https://clang.llvm.org/get_started.html)
* [Building LLVM with CMake](https://llvm.org/docs/CMake.html)
* [Assembling a Complete Toolchain](https://clang.llvm.org/docs/Toolchain.html)

The resulting toolchain is designed for consumption with [`toolchains_llvm`](https://github.com/bazel-contrib/toolchains_llvm)
and to be a drop-in replacement for the toolchains provided by the upstream `llvm-project`. Similar to Rust, we also compress
the package with `zstd`.
