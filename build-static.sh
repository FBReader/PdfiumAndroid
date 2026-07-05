#!/usr/bin/env bash
set -euo pipefail

# Build complete PDFium archives and a self-contained JNI library for each ABI.
ROOT=$(cd "$(dirname "$0")" && pwd)
WORK="$ROOT/third_party/pdfium-work"
PDFIUM="$WORK/pdfium"
DEPOT_TOOLS="$ROOT/third_party/depot_tools"
STATIC_ROOT="$ROOT/src/main/jni/static"
JNI_ROOT="$ROOT/src/main/jni/lib"
JOBS=${JOBS:-$(sysctl -n hw.logicalcpu 2>/dev/null || echo 8)}

if [[ $(uname -s) == Darwin && ${PDFIUM_LINUX_CONTAINER:-0} != 1 ]]; then
  HOST_NDK=${ANDROID_NDK_ROOT:-${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk/29.0.13113456}}
  HOST_UNWIND="$HOST_NDK/toolchains/llvm/prebuilt/darwin-x86_64/lib/clang/20/lib/linux"
  for pair in "armeabi-v7a:arm" "arm64-v8a:aarch64" "x86:i386" "x86_64:x86_64"; do
    abi=${pair%%:*}; arch=${pair##*:}
    mkdir -p "$STATIC_ROOT/$abi"
    cp -f "$HOST_UNWIND/$arch/libunwind.a" "$STATIC_ROOT/$abi/libunwind.a"
  done
  docker build --platform linux/amd64 -f "$ROOT/Dockerfile.pdfium" -t pdfium-android-builder "$ROOT"
  if [[ ! -x "$PDFIUM/buildtools/linux64/gn" ]]; then
    docker run --rm --platform linux/amd64 \
      -e PDFIUM_LINUX_CONTAINER=1 -e JOBS="$JOBS" \
      -e HOME=/tmp/build-home \
      -v "$ROOT:/workspace" -w /workspace/third_party/pdfium-work \
      pdfium-android-builder gclient sync -r origin/chromium/6927 --no-history --shallow
  fi
  exec docker run --rm --platform linux/amd64 \
    -e PDFIUM_LINUX_CONTAINER=1 -e JOBS="$JOBS" \
    -e HOME=/tmp/build-home \
    -v "$ROOT:/workspace" -w /workspace \
    pdfium-android-builder ./build-static.sh
fi

NDK_ROOT=${ANDROID_NDK_ROOT:-${ANDROID_NDK_HOME:-$PDFIUM/third_party/android_toolchain/ndk}}

if [[ $(uname -s) == Darwin ]]; then
  GN="$PDFIUM/buildtools/mac/gn"
else
  GN="$PDFIUM/buildtools/linux64/gn"
fi
if [[ ! -x "$GN" || ! -d "$PDFIUM/third_party" ]]; then
  echo "PDFium source or host tools are missing. Run ./fetch-pdfium.sh first." >&2
  exit 1
fi
NDK_TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64"
CLANG="$PDFIUM/third_party/llvm-build/Release+Asserts/bin/clang++"
if [[ ! -d "$NDK_TOOLCHAIN/sysroot" || ! -x "$CLANG" ]]; then
  echo "PDFium's pinned Android NDK or Clang toolchain is missing." >&2
  exit 1
fi
NINJA=$(command -v ninja)
export DEPOT_TOOLS_UPDATE=0
export PATH="$DEPOT_TOOLS:$PATH"

build_pdfium() {
  local abi=$1 cpu=$2 out="$PDFIUM/out/android-$1-static"
  mkdir -p "$out" "$STATIC_ROOT/$abi"
  cat >"$out/args.gn" <<EOF
clang_use_chrome_plugins = false
default_min_sdk_version = 21
is_component_build = false
is_debug = false
pdf_enable_v8 = false
pdf_enable_xfa = false
pdf_is_complete_lib = true
pdf_is_standalone = true
pdf_use_partition_alloc = false
target_cpu = "$cpu"
target_os = "android"
treat_warnings_as_errors = false
EOF
  "$GN" gen "$out" --root="$PDFIUM"
  "$NINJA" -C "$out" -j "$JOBS" pdfium
  "$NINJA" -C "$out" -j "$JOBS" phony/buildtools/third_party/libc++/libc++
  local runtime="$out/obj/buildtools/third_party"
  "$PDFIUM/third_party/llvm-build/Release+Asserts/bin/llvm-ar" rcs \
    "$STATIC_ROOT/$abi/libchromium_cxx.a" \
    "$runtime"/libc++/libc++/*.o \
    "$runtime"/libc++abi/libc++abi/*.o \
    "$runtime"/libunwind/libunwind/*.o
  cp -f "$out/obj/libpdfium.a" "$STATIC_ROOT/$abi/libpdfium.a"
  cp -f "$out/args.gn" "$STATIC_ROOT/$abi/args.gn"
}

build_jni() {
  local abi=$1 target=$2 out="$ROOT/build-static/jni/$1"
  mkdir -p "$out"
  "$CLANG" --target="$target" --sysroot="$NDK_TOOLCHAIN/sysroot" \
    -fPIC -O2 -std=c++17 -fexceptions -frtti -DHAVE_PTHREADS \
    -I"$ROOT/src/main/jni/include" \
    -shared "$ROOT/src/main/jni/src/mainJNILib.cpp" \
    "$STATIC_ROOT/$abi/libpdfium.a" \
    "$STATIC_ROOT/$abi/libchromium_cxx.a" \
    -L"$STATIC_ROOT/$abi" \
    -static-libstdc++ -Wl,--no-undefined -Wl,-z,max-page-size=16384 \
    -Wl,--exclude-libs,ALL -llog -landroid -ljnigraphics -ldl -lm \
    -o "$out/libjniPdfium.so"
  "$PDFIUM/third_party/llvm-build/Release+Asserts/bin/llvm-strip" \
    --strip-unneeded "$out/libjniPdfium.so"
  mkdir -p "$JNI_ROOT/$abi"
  find "$JNI_ROOT/$abi" -maxdepth 1 -type f -name '*.so' -delete
  cp -f "$out/libjniPdfium.so" "$JNI_ROOT/$abi/libjniPdfium.so"
}

build_pdfium armeabi-v7a arm
build_pdfium arm64-v8a arm64
build_pdfium x86 x86
build_pdfium x86_64 x64
build_jni armeabi-v7a armv7a-linux-androideabi21
build_jni arm64-v8a aarch64-linux-android21
build_jni x86 i686-linux-android21
build_jni x86_64 x86_64-linux-android21

echo "Static PDFium archives: $STATIC_ROOT"
echo "Self-contained JNI libraries: $JNI_ROOT"
