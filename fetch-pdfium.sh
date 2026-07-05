#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
TOOLS="$ROOT/third_party/depot_tools"
WORK="$ROOT/third_party/pdfium-work"

if [[ ! -d "$TOOLS/.git" ]]; then
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git "$TOOLS"
fi
mkdir -p "$WORK"
cd "$WORK"
export DEPOT_TOOLS_UPDATE=0
export PATH="$TOOLS:$PATH"

if [[ ! -f .gclient ]]; then
  gclient config --unmanaged https://pdfium.googlesource.com/pdfium.git \
    --custom-var checkout_configuration=minimal
  printf '\ntarget_os = [ "android" ]\n' >> .gclient
fi
gclient sync -r "${PDFIUM_REVISION:-origin/chromium/6927}" --no-history --shallow
