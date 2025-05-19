FROM ubuntu:22.04 as base_image

# Tools needed to install bootsrap clang.
RUN apt-get update && apt-get install -y \
    wget \
    lsb-release \
    software-properties-common \
    gnupg

ARG BOOTSTRAP_CLANG_VERSION
ARG CLANG_VERSION
ENV BOOTSTRAP_CLANG_VERSION=$BOOTSTRAP_CLANG_VERSION \
    CLANG_VERSION=$CLANG_VERSION

COPY llvm.sh /usr/local/bin/llvm.sh
RUN chmod +x /usr/local/bin/llvm.sh
RUN /usr/local/bin/llvm.sh $BOOTSTRAP_CLANG_VERSION


FROM base_image as llvm_image

RUN apt-get update && apt-get install -y \
    git

WORKDIR /downloads

# Shallow clone of the LLVM project since it's quite large.
RUN git clone \
    --depth 1 \
    --branch llvmorg-$CLANG_VERSION \
    https://github.com/llvm/llvm-project.git


FROM llvm_image as build_image

RUN apt-get update && apt-get install -y \
    # Tools needed by the build process.
    zstd \
    cmake \
    gcc \
    ninja-build \
    # Libraries we statically link into clang.
    zlib1g-dev \
    libzstd-dev \
    libncurses-dev \
    libxml2-dev

# Targets we optimize for.
ARG TARGET_CPU
ARG TARGET_CPU_ARCH

# Current arch of the container.
ARG TARGETARCH

ENV TARGET_CPU=$TARGET_CPU \
    TARGET_CPU_ARCH=$TARGET_CPU_ARCH \
    TARGETARCH=$TARGETARCH

WORKDIR /downloads/llvm-project

COPY clang_build.sh clang_build.sh
RUN chmod +x clang_build.sh
RUN ./clang_build.sh \
    $BOOTSTRAP_CLANG_VERSION \
    $CLANG_VERSION \
    $TARGETARCH \
    $TARGET_CPU \
    $TARGET_ARCH


FROM build_image as package_image

WORKDIR /downloads

COPY bin.txt bin.txt
COPY include.txt include.txt
COPY lib.txt lib.txt

COPY bin_libclang.txt bin_libclang.txt
COPY lib_libclang.txt lib_libclang.txt

COPY clang_package.sh clang_package.sh
RUN chmod +x clang_package.sh

RUN ./clang_package.sh $CLANG_VERSION $TARGETARCH
