# Build Qt 5.15.2 on macOS

Qt5 can be built on macOS **only** if your macOS SDK is 10.15 or lower. It will not build with the default SDK that's bundled with Xcode on Big Sur.

There are 2 ways to get older SDK on Big Sur:

1. "Official". Install an older version of Xcode that comes with the SDK you need.
2. "Hacky". Grab an older SDK from github (for example from [this repo](https://github.com/piiq/MacOSX-SDKs)) and place it beside the latest SDK in `Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/`. After this action running `xcodebuild -showsdks` should show you 10.15 SDK available.

---

The build commands listed bellow are packed into a script that you can launch locally.
Modify the script to meet your system specifics.

```bash
curl -s https://raw.githubusercontent.com/piiq/qt-easy-build/5.15.2-macOS11.1/Build-qt.sh -o Build-qt.sh
```

For other platforms or Qt versions please refer to [this repository](https://github.com/jcfr/qt-easy-build).


## Prerequisites

This build process requires llvm that can be obtained from homebrew.

```bash
brew install llvm
```


### Setup build environment

Copy the following line into the terminal substituting paths to the ones you have in your system.

```bash
CMAKE=/usr/local/bin/cmake
DEPLOYMENT_TARGET=10.15
SYSROOT=macosx10.15

INSTALL_DIR=~/Qt
QT_VERSION=5.15.2

CWD=$(pwd)
NUMCORES=`sysctl -n hw.ncpu`
```

### Build Qt

```bash
rm -f qt-everywhere-src-5.15.2.tar.gz
rm -rf qt-everywhere-src-5.15.2
rm -rf qt-everywhere-build-5.15.2
mkdir qt-everywhere-build-5.15.2

curl -OL https://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz
MD5=`md5 ./qt-everywhere-src-5.15.2.tar.xz`
[ $MD5 == "e1447db4f06c841d8947f0a6ce83a7b5" ] || ( echo "MD5 mismatch. Problem downloading Qt" )
tar -xzvf qt-everywhere-src-5.15.2.tar.xz
cd qt-everywhere-src-5.15.2
./configure -prefix ${INSTALL_DIR} \
  -release -opensource -confirm-license \
  -c++std c++14 \
  -nomake examples \
  -nomake tests \
  -no-rpath \
  -silent \
  -sdk ${SYSROOT} \
  -no-openssl -securetransport \
  -v
make -j${NUMCORES} -k; make 2>&1 | tee /tmp/qtbuild.log
make install
```


## Alternative build with optional prerequisites

Zlib and OpenSSL are required for building Qt on Linux. This is an optional step on macOS because `zlib` is bundled with Xcode and you can use native `securetransport` instead of OpenSSL. The build instructions are provided for the edge case when you'd like to follow the same build process as on linux.

### Build zlib

```bash
rm -rf zlib*
mkdir zlib-install
mkdir zlib-build
git clone git://github.com/commontk/zlib.git
cd zlib-build
"${CMAKE}" -DCMAKE_BUILD_TYPE:STRING=Release \
       -DZLIB_MANGLE_PREFIX:STRING=slicer_zlib_ \
       -DCMAKE_INSTALL_PREFIX:PATH=${CWD}/zlib-install \
       -DCMAKE_OSX_ARCHITECTURES=x86_64 \
       -DCMAKE_OSX_SYSROOT=${SYSROOT} \
       -DCMAKE_OSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET} \
       ../zlib
make -j${NUMCORES}
make install
cd ..
cp zlib-install/lib/libzlib.a zlib-install/lib/libz.a
```

### Build OpenSSL

```bash
rm -f openssl-1.0.1h.tar.gz
rm -rf openssl-1.0.1h/
curl -OL https://packages.kitware.com/download/item/6173/openssl-1.0.1h.tar.gz
MD5=`md5 ./openssl-1.0.1h.tar.gz`
[ ${MD5} == "8d6d684a9430d5cc98a62a5d8fbda8cf" ] || ( echo "MD5 mismatch. Problem downloading OpenSSL" )
tar -xzvf openssl-1.0.1h.tar.gz
cd openssl-1.0.1h/
export KERNEL_BITS=64
./config zlib -I${CWD}/zlib-install/include -L${CWD}/zlib-install/lib shared
make -j1 build_libs  # Note that OpenSSL only builds with a single thread
install_name_tool -id ${CWD}/openssl-1.0.1h/libcrypto.dylib ${CWD}/openssl-1.0.1h/libcrypto.dylib
install_name_tool \
          -change /usr/local/ssl/lib/libcrypto.1.0.0.dylib ${CWD}/openssl-1.0.1h/libcrypto.dylib \
          -id ${CWD}/openssl-1.0.1h/libssl.dylib ${CWD}/openssl-1.0.1h/libssl.dylib
cd ..
```

### Build Qt with optional prerequisites

The build process in this case is the same with the only difference in the configuration command

```bash
./configure -prefix ${INSTALL_DIR} \
  -release -opensource -confirm-license \
  -c++std c++14 \
  -nomake examples \
  -nomake tests \
  -no-rpath \
  -silent \
  -sdk ${SYSROOT} \
  -openssl -I ${CWD}/openssl-1.0.1h/include/openssl -L ${CWD}/openssl-1.0.1h
```

---
