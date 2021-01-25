# MacOSX

## Prerequisites

```bash
CMAKE=/usr/local/bin/cmake
DEPLOYMENT_TARGET=11.1
SYSROOT=/Applications/DevelopmentTools/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX11.1.sdk
INSTALL_DIR=/User/p2p/Qt

````

## Build zlib

```bash
CWD=$(pwd)

rm -rf zlib*
mkdir zlib-install 
mkdir zlib-build 
git clone git://github.com/commontk/zlib.git 
cd zlib-build 
"$CMAKE" -DCMAKE_BUILD_TYPE:STRING=Release \
       -DZLIB_MANGLE_PREFIX:STRING=slicer_zlib_ \
       -DCMAKE_INSTALL_PREFIX:PATH=$CWD/zlib-install \
       -DCMAKE_OSX_ARCHITECTURES=x86_64 \
       -DCMAKE_OSX_SYSROOT=$SYSROOT \
       -DCMAKE_OSX_DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET \
       ../zlib
make -j8
make install
cd ..
cp zlib-install/lib/libzlib.a zlib-install/lib/libz.a
```

## Build OpenSSL

```bash
CWD=$(pwd)

rm -f openssl-1.0.1h.tar.gz
rm -rf openssl-1.0.1h/
curl -OL https://packages.kitware.com/download/item/6173/openssl-1.0.1h.tar.gz
MD5=`md5 ./openssl-1.0.1h.tar.gz | awk '{ print $4 }'`
[ $MD5 == "8d6d684a9430d5cc98a62a5d8fbda8cf" ] || ( echo "MD5 mismatch. Problem downloading OpenSSL" ; exit 1; )
tar -xzvf openssl-1.0.1h.tar.gz
cd openssl-1.0.1h/ 
export KERNEL_BITS=64
./config zlib -I$CWD/zlib-install/include -L$CWD/zlib-install/lib shared
make -j1 build_libs
install_name_tool -id $CWD/openssl-1.0.1h/libcrypto.dylib $CWD/openssl-1.0.1h/libcrypto.dylib
install_name_tool \
          -change /usr/local/ssl/lib/libcrypto.1.0.0.dylib $CWD/openssl-1.0.1h/libcrypto.dylib \
          -id $CWD/openssl-1.0.1h/libssl.dylib $CWD/openssl-1.0.1h/libssl.dylib
cd ..
```

## Build Qt


```bash
CWD=$(pwd)

rm -f qt-everywhere-opensource-src-5.15.2.tar.gz
rm -rf qt-everywhere-opensource-src-5.15.2
rm -rf qt-everywhere-opensource-build-5.15.2
mkdir qt-everywhere-opensource-build-5.15.2

mkdir -p $install_dir
qt_install_dir_options="-prefix $INSTALL_DIR"

curl -OL https://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz
MD5=`md5 ./qt-everywhere-opensource-src-5.15.2.tar.gz | awk '{ print $4 }'`
[ $MD5 == "e1447db4f06c841d8947f0a6ce83a7b5" ] || ( echo "MD5 mismatch. Problem downloading Qt" ; exit 1; )
tar -xzvf qt-everywhere-src-5.15.2.tar.xz
cd qt-everywhere-src-5.15.2
# ./configure -prefix ../qt-everywhere-src-5.15.2/  \
#   -release -opensource -confirm-license \
#   -webkit -arch x86_64  -nomake examples -nomake demos \
#   -sdk $SYSROOT                         \
#   -openssl -I $CWD/openssl-1.0.1h/include \
#   -L $CWD/openssl-1.0.1h
./configure $qt_install_dir_options                           \
  -release -opensource -confirm-license \
  -c++std c++14 \
  -nomake examples \
  -nomake tests \
  -no-rpath \
  -silent \
  -openssl -I $deps_dir/openssl-$OPENSSL_VERSION/include           \
  ${qt_macos_options}                                         \
  -L $deps_dir/openssl-$OPENSSL_VERSION
make -j7
make install
```