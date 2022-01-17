#!/bin/bash
# Cross-compile environment for Android
#

export WORKING_DIR=`pwd`

export NDK=/home/luxuan/Program/android-sdk/ndk/23.1.7779620

export ANDROID_NDK_ROOT=$NDK

export ANDROID_NDK_HOME=$NDK

if [ $# -ne 1 ];
  then echo "illegal number of parameters"
  echo "usage: build_openssl.sh TARGET"
  exit 1
fi

export TARGET=$1

OPENSSL_VERSION="3.0.1" #1.0.2j #"1.1.0c"

TOP_ROOT=`pwd`
BUILD_DIR=${TOP_ROOT}/libs/openssl
SOURCE=${TOP_ROOT}/src
SOURCE_OPENSSL=$SOURCE/openssl-android
mkdir -p ${BUILD_DIR}
mkdir -p ${SOURCE}
mkdir -p ${SOURCE_OPENSSL}

cd $SOURCE

if [ ! -e "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
  echo "Downloading openssl-${OPENSSL_VERSION}.tar.gz"
  curl -LO https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
  tar -xvf openssl-${OPENSSL_VERSION}.tar.gz -C $SOURCE_OPENSSL --strip-components=1
else
  echo "Using openssl-${OPENSSL_VERSION}.tar.gz"
fi

#if [ -d openssl-${OPENSSL_VERSION} ]
#then
#    rm -rf openssl-${OPENSSL_VERSION}
#fi

function build_one
{

INSTALL_DIR=$BUILD_DIR/build/$ABI
mkdir -p ${INSTALL_DIR}

cd $SOURCE_OPENSSL

API=22
CC=clang
PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

export CC=clang

if [ $TARGET == "x86_64" ]
then
    ./Configure android-x86_64 -D__ANDROID_API__=$API shared no-ssl2 no-ssl3 no-comp no-hw no-engine --openssldir=$INSTALL_DIR --prefix=$INSTALL_DIR
elif [ $TARGET == "x86" ]
then
   ./Configure android-x86 -D__ANDROID_API__=$API shared no-ssl2 no-ssl3 no-comp no-hw no-engine --openssldir=$INSTALL_DIR --prefix=$INSTALL_DIR
elif [ $TARGET == "arm64-v8a" ]
then
   ./Configure android-arm64 -D__ANDROID_API__=$API shared no-ssl2 no-ssl3 no-comp no-hw no-engine --openssldir=$INSTALL_DIR --prefix=$INSTALL_DIR
elif [ $TARGET == "armv7-a" ]
then
    ./Configure android-arm -D__ANDROID_API__=$API shared no-ssl2 no-ssl3 no-comp no-hw no-engine --openssldir=$INSTALL_DIR --prefix=$INSTALL_DIR
fi

make clean
make depend
make CALC_VERSIONS="SHLIB_COMPAT=; SHLIB_SOVER=" MAKE="make -e" all

echo $ANDROID_TOOLCHAIN
echo $PREBUILT/bin

mkdir -p $INSTALL_DIR/lib
echo "place-holder make target for avoiding symlinks" >> $INSTALL_DIR/lib/link-shared
make SHLIB_EXT=.so install_sw
#make install CC=$PREBUILT/bin/$HOST-gcc RANLIB=$PREBUILT/bin/$HOST-ranlib

# copy the binaries
OPENSSL_LIB_DIR=$BUILD_DIR/lib/$ABI
OPENSSL_INCLUDE_DIR=$BUILD_DIR/include/$ABI
mkdir -p ${OPENSSL_LIB_DIR}
mkdir -p ${OPENSSL_INCLUDE_DIR}
cp -r $INSTALL_DIR/lib/*.so 	${OPENSSL_LIB_DIR}/.
cp -r $INSTALL_DIR/include/* 	${OPENSSL_INCLUDE_DIR}/.
}

if [ $TARGET == 'armv7-a' ]; then
  ABI=armeabi-v7a
  CPU=armv7-a
  ARCH=arm
  PREFIX=`pwd`/../jni/openssl-android/armeabi-v7a
  build_one
fi

if [ $TARGET == 'x86' ]; then
  ABI=x86
  CPU=i686
  ARCH=i686
  PREFIX=`pwd`/../jni/openssl-android/x86
  build_one
fi

if [ $TARGET == 'x86_64' ]; then
  ABI=x86_64
  CPU=x86_64
  ARCH=x86_64
  PREFIX=`pwd`/../jni/openssl-android/x86_64
  build_one
fi

if [ $TARGET == 'arm64-v8a' ]; then
  ABI=arm64-v8a
  CPU=arm64-v8a
  ARCH=arm64
  PREFIX=`pwd`/../jni/openssl-android/arm64-v8a
  build_one
fi
