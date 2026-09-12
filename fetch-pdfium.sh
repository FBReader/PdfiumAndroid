#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
TOOLS="$ROOT/third_party/depot_tools"
WORK="$ROOT/third_party/pdfium-work"
TOOLS_REVISION=1b1b01fa912786b88a79f3504176a275183839b5

if [[ ! -d "$TOOLS/.git" ]]; then
  git init "$TOOLS"
  git -C "$TOOLS" remote add origin https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi
if [[ $(git -C "$TOOLS" rev-parse HEAD 2>/dev/null || true) != "$TOOLS_REVISION" ]]; then
  git -C "$TOOLS" fetch --depth 1 origin "$TOOLS_REVISION"
  git -C "$TOOLS" checkout --detach "$TOOLS_REVISION"
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
gclient sync -r "${PDFIUM_REVISION:-a4cbdc9ed1d06a16bae780f8e25ab6b385bc0468}" --no-history --shallow
