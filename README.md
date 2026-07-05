# Introduction

## Fully static dependency build

Run `./fetch-pdfium.sh` and then `./build-static.sh`. The checkout remains in
`third_party/pdfium-work/pdfium`; complete archives and their `args.gn` files
remain in `src/main/jni/static/<abi>`. The only library retained under each
`src/main/jni/lib/<abi>` directory is the final `libjniPdfium.so`.

This repository is a fork of [barteksc/PdfiumAndroid](https://github.com/meganz/PdfiumAndroid). 

On top of the original project, this fork adds the 16KB page size support for Android15. The changes include:
- Upgrade to [PDFium 133.0.6927.0](https://github.com/bblanchon/pdfium-binaries/releases/tag/chromium%2F6927)
- Add a `CMakeLists.txt` for building PdfiumAndroid `.so` file.
- Update [libpng v1.6.44](https://github.com/pnggroup/libpng/releases/tag/v1.6.44) and [libfreetype2 v2.10.0](https://download.savannah.gnu.org/releases/freetype/) binaries for building PdfiumAndroid library. 


- available at: implementation("io.github.oothp:pdfium-android:1.9.5-beta01")
