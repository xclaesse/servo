#! /bin/bash

set -e

SOURCE_DIR=gst-build
BUILD_DIR=_build
INSTALL_DIR=_install
INSTALL_REAL_DIR=$(realpath $INSTALL_DIR)

rm -rf $BUILD_DIR
rm -rf $INSTALL_DIR

# FIXME: Download, build and install GNU libiconv because MLSDK has an old
# version of bionic that does not include iconv.
ICONV_NAME=libiconv-1.16
if [[ ! -d $ICONV_NAME ]]; then
  curl -O -L https://ftp.gnu.org/pub/gnu/libiconv/$ICONV_NAME.tar.gz
  tar xzf $ICONV_NAME.tar.gz
fi
mkdir -p $BUILD_DIR/$ICONV_NAME
HOST=aarch64-linux-android
SYSROOT=$MAGICLEAP_SDK/lumin/usr
env -C $BUILD_DIR/$ICONV_NAME \
    CFLAGS=--sysroot=$SYSROOT \
    CPPFLAGS=--sysroot=$SYSROOT \
    CC=$MAGICLEAP_SDK/tools/toolchains/bin/$HOST-clang \
    ../../$ICONV_NAME/configure --host=$HOST \
                --with-sysroot=$SYSROOT \
                --prefix /system \
                --libdir /system/lib64
make -C $BUILD_DIR/$ICONV_NAME
DESTDIR=$INSTALL_REAL_DIR make -C $BUILD_DIR/$ICONV_NAME install

# Clone custom repo/branch of gst-build
if [[ ! -d $SOURCE_DIR ]]; then
  git clone https://gitlab.collabora.com/mozilla/gst-build.git --branch mozilla $SOURCE_DIR
fi

# Generate cross file by replacing the MLSDK location
cat mlsdk.txt.in | sed s#@MAGICLEAP_SDK@#$MAGICLEAP_SDK# \
                 | sed s#@INSTALL_DIR@#$INSTALL_REAL_DIR# > mlsdk.txt

meson --cross-file mlsdk.txt \
      --prefix /system \
      --libdir lib64 \
      --libexecdir bin \
      -Db_pie=true \
      -Dcpp_std=c++11 \
      -Dpython=disabled \
      -Dlibav=disabled \
      -Ddevtools=disabled \
      -Dges=disabled \
      -Drtsp_server=disabled \
      -Domx=disabled \
      -Dvaapi=disabled \
      -Dsharp=disabled \
      -Dexamples=disabled \
      -Dgtk_doc=disabled \
      -Dintrospection=disabled \
      -Dnls=disabled \
      -Dbad=enabled \
      -Dgst-plugins-base:gl=enabled \
      -Dgst-plugins-base:gl_platform=egl \
      -Dgst-plugins-base:gl_winsys=android \
      -Dgst-plugins-bad:gl=enabled \
      -Dgst-plugins-bad:magicleap=enabled \
      -Dglib:iconv=gnu \
      $BUILD_DIR \
      $SOURCE_DIR

# Build and install
ninja -C $BUILD_DIR
DESTDIR=$INSTALL_REAL_DIR ninja -C $BUILD_DIR install
