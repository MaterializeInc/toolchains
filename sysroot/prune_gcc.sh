#!/usr/bin/env bash

set -eux

LIBSTDCXX_VERSION=$1
LIBSTDCXX_MAJOR=$2

rm -rf /var/buildlibs/gcc/bin
rm -rf /var/buildlibs/gcc/usr/bin
rm -rf /var/buildlibs/gcc/libexec
rm -rf /var/buildlibs/gcc/share

if [ "$ARCH" == 'x86_64' ]; then
  mv /var/buildlibs/gcc/lib/gcc/${ARCH}-linux /var/buildlibs/gcc/lib/gcc/${ARCH}-linux-gnu
  mv /var/buildlibs/gcc/lib/gcc/${ARCH}-linux-gnu/${LIBSTDCXX_VERSION} /var/buildlibs/gcc/lib/gcc/${ARCH}-linux-gnu/${LIBSTDCXX_MAJOR}
  mv /var/buildlibs/gcc/include/c++/${LIBSTDCXX_VERSION} /var/buildlibs/gcc/include/c++/${LIBSTDCXX_MAJOR}
  mv /var/buildlibs/gcc/include/c++/${LIBSTDCXX_MAJOR}/${ARCH}-linux /var/buildlibs/gcc/include/c++/${LIBSTDCXX_MAJOR}/${ARCH}-linux-gnu
elif [ "$ARCH" == 'aarch64' ]; then
  mv /var/buildlibs/gcc/lib/gcc/${ARCH}-linux /var/buildlibs/gcc/lib/gcc/${ARCH}-linux-gnu
  mv /var/buildlibs/gcc/lib/gcc/${ARCH}-linux-gnu/${LIBSTDCXX_VERSION} /var/buildlibs/gcc/lib/gcc/${ARCH}-linux-gnu/${LIBSTDCXX_MAJOR}
  mv /var/buildlibs/gcc/${ARCH}-linux/include/c++/${LIBSTDCXX_VERSION} /var/buildlibs/gcc/${ARCH}-linux/include/c++/${LIBSTDCXX_MAJOR}
  mv /var/buildlibs/gcc/${ARCH}-linux/include/c++/${LIBSTDCXX_MAJOR}/${ARCH}-linux /var/buildlibs/gcc/${ARCH}-linux/include/c++/${LIBSTDCXX_MAJOR}/${ARCH}-linux-gnu
  mv /var/buildlibs/gcc/${ARCH}-linux/include/c++ /var/buildlibs/gcc/include/c++
  mv /var/buildlibs/gcc/${ARCH}-linux/lib64/* /var/buildlibs/gcc/lib64/
  rm -r /var/buildlibs/gcc/${ARCH}-linux
else
  exit 1
fi
