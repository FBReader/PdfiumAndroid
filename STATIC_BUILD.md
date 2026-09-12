# Building PDFium for a statically linked Android application

`build-ndk-static.sh` builds a complete `libpdfium.a` for an application that
already uses the Android NDK C++ runtime. It does not build the Java/JNI wrapper
or introduce separate PDFium, FreeType, PNG, or C++ shared libraries. Link the
archive into the application's own native library with the NDK static C++
runtime (`c++_static`). The application still depends on Android system libraries.

## Source and toolchain

The build fetches the public PDFium source at
[`a4cbdc9ed1d06a16bae780f8e25ab6b385bc0468`](https://pdfium.googlesource.com/pdfium/+/a4cbdc9ed1d06a16bae780f8e25ab6b385bc0468)
(Chromium 133 / 6927). Its `DEPS` file pins the transitive source and toolchain
inputs. `fetch-pdfium.sh` also pins depot_tools to
`1b1b01fa912786b88a79f3504176a275183839b5` and disables automatic updates.
Fetched sources, original licenses, build tools, and intermediate objects stay
under `third_party/`, outside Git. This avoids committing a second copy of the
upstream source distributions while retaining an explicit source-build recipe.

This revision supports Android API 21. The build uses its Chromium Clang toolchain
and Android NDK r27 sysroot, disables V8 and XFA, and selects the NDK libc++ ABI
instead of Chromium's custom libc++ ABI. These settings are recorded beside each
output in `args.gn`. Do not substitute an arbitrary newer PDFium revision: API
levels, toolchains, exported APIs, and C++ runtime choices may change.

## Commands

On macOS, install Docker and run it before building. The script uses an x86_64
Linux container. The Docker daemon must be able to mount this checkout; for
Colima on macOS, a checkout beneath your home directory is suitable.

```sh
# One ABI:
JOBS=8 ./build-ndk-static.sh arm64-v8a

# All supported ABIs (the default):
JOBS=8 ./build-ndk-static.sh
```

On x86_64 Linux, install the packages listed in `Dockerfile.pdfium` and run the
same commands directly, or explicitly run that Docker image. Network access is
needed for the initial source/tool download. The first build takes substantial
time and disk space; subsequent builds reuse the checkout and object cache.
Use a separate source checkout per host platform because downloaded tools are
host-specific.

Outputs are `build-ndk-static/<abi>/libpdfium.a` and `args.gn`. Supported ABIs are
`armeabi-v7a`, `arm64-v8a`, `x86`, and `x86_64`. A consuming application should use
headers from the same pinned PDFium revision, link with `--no-undefined`, and
check its final ELF library's dependencies and Android page-size alignment.

## Existing standalone JNI build

`build-static.sh` remains the separate build for this repository's
`libjniPdfium.so`. It includes Chromium's custom C++ runtime archives and is
not the archive profile for an application using NDK libc++. Its previously
committed binaries are retained for existing users. Do not mix the two runtime
profiles in one native library. The new archive target does not change the
existing Java API or JNI implementation.

PDFium and its embedded third-party code retain their upstream licenses and
notices in the downloaded source tree. This build tooling does not relicense
those components.
