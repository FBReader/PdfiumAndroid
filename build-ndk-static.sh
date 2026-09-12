#!/usr/bin/env bash
# Complete PDFium archives for applications using the Android NDK C++ runtime.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)
PDFIUM="$ROOT/third_party/pdfium-work/pdfium"
REVISION=a4cbdc9ed1d06a16bae780f8e25ab6b385bc0468
JOBS=${JOBS:-8}
if [[ $# == 0 ]]; then
  set -- armeabi-v7a arm64-v8a x86 x86_64
fi
for abi in "$@"; do
  case "$abi" in armeabi-v7a|arm64-v8a|x86|x86_64) ;; *) echo "Unknown ABI: $abi" >&2; exit 2 ;; esac
done
if [[ $(uname -s) != Linux ]]; then
  docker build --platform linux/amd64 -f "$ROOT/Dockerfile.pdfium" -t pdfium-android-builder "$ROOT"
  exec docker run --rm --platform linux/amd64 \
    -e JOBS="$JOBS" -e HOME=/tmp/build-home \
    -v "$ROOT:/workspace" -w /workspace \
    pdfium-android-builder ./build-ndk-static.sh "$@"
fi
if [[ $(uname -m) != x86_64 ]]; then
  echo 'Use an x86_64 Linux host or the linux/amd64 Docker image.' >&2
  exit 1
fi
if [[ ! -x "$PDFIUM/buildtools/linux64/gn" ]]; then
  PDFIUM_REVISION="$REVISION" "$ROOT/fetch-pdfium.sh"
fi
if [[ $(git -C "$PDFIUM" rev-parse HEAD) != "$REVISION" ]]; then
  echo "Expected PDFium $REVISION. Run PDFIUM_REVISION=$REVISION ./fetch-pdfium.sh" >&2
  exit 1
fi
for abi in "$@"; do
  case "$abi" in
    armeabi-v7a) cpu=arm ;; arm64-v8a) cpu=arm64 ;; x86) cpu=x86 ;; x86_64) cpu=x64 ;;
  esac
  out="$PDFIUM/out/android-$abi-ndk-static"
  destination="$ROOT/build-ndk-static/$abi"
  mkdir -p "$out" "$destination"
  cat > "$out/args.gn" <<ARGS
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
use_custom_libcxx = false
use_custom_libcxx_for_host = true
ARGS
  "$PDFIUM/buildtools/linux64/gn" gen "$out" --root="$PDFIUM"
  ninja -C "$out" -j "$JOBS" pdfium
  cp "$out/obj/libpdfium.a" "$destination/libpdfium.a"
  cp "$out/args.gn" "$destination/args.gn"
  echo "Built $destination/libpdfium.a"
done
