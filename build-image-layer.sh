#!/bin/sh

if [ -z "$TARGETARCH" ]; then
  :
else
  case "${TARGETARCH}" in
    "amd64")
      LINKER_NAME="x86_64-linux-gnu-gcc"
      LINKER_PACKAGE="gcc-x86-64-linux-gnu"
      BUILD_TARGET="x86_64-unknown-linux-gnu" ;;
    "arm64")
      LINKER_NAME="aarch64-linux-gnu-gcc"
      LINKER_PACKAGE="gcc-aarch64-linux-gnu"
      BUILD_TARGET="aarch64-unknown-linux-gnu" ;;
  esac
fi

tools() {
  apt-get install -y "${LINKER_PACKAGE}"
  rustup target add "${BUILD_TARGET}"
}

deps() {
  mkdir -p \
    downloader/src \
    easypwned/src \
    easypwned_bloom/src
  echo 'fn main() { panic!("stub"); }' |
    tee downloader/src/main.rs |
    tee easypwned/src/main.rs
  echo '' |
    tee easypwned_bloom/src/lib.rs
  
  if [ -z "$TARGETARCH" ]; then
    cargo build --locked --release
  else
    cargo build --locked --release --target "${BUILD_TARGET}"
  fi
}

apps() {
  touch -am \
    easypwned/src/main.rs \
    easypwned_bloom/src/lib.rs
  
  if [ -z "$TARGETARCH" ]; then
    cargo build --locked --release
  else
    cargo build --locked --release --target "${BUILD_TARGET}"
    mv target _target && mv _target/"${BUILD_TARGET}" target
  fi
}

if [ -z "$TARGETARCH" ]; then
  :
else
  export RUSTFLAGS="-C linker=${LINKER_NAME}"
  export PKG_CONFIG_ALLOW_CROSS="1"
  export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig"
fi

"$@"