#!/bin/bash
set -eo pipefail

# Setup variables
SYSROOT=macosx10.15
INSTALL_DIR=~/Qt
NUMCORES=$(sysctl -n hw.ncpu)

# Cleanup
rm -f qt-everywhere-src-5.15.2.tar.gz
rm -rf qt-everywhere-src-5.15.2
rm -rf ${INSTALL_DIR}
mkdir ${INSTALL_DIR}

# Download and check Qt 5.15.2 archive
curl -OL https://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz
MD5=$(md5 ./qt-everywhere-src-5.15.2.tar.xz)
[ "${MD5}" == "e1447db4f06c841d8947f0a6ce83a7b5" ] || ( echo "MD5 mismatch. Problem downloading Qt" ; exit 1 )

# Unpack and configure
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
  -no-openssl -securetransport

# Build and install
make -j"${NUMCORES}" -k; make 2>&1 | tee /tmp/qtbuild.log
make install
