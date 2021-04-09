#!/bin/bash

set -e

# Set your own NDK here
export NDK=/Users/luxuan/android-sdk/ndk/21.4.7075529

#export NDK=`grep ndk.dir $PROPS | cut -d'=' -f2`

if [ "$NDK" = "" ] || [ ! -d $NDK ]; then
    echo "NDK variable not set or path to NDK is invalid, exiting..."
    exit 1
fi

export TARGET=$1

TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin
SYSROOT=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/sysroot
API=22

FFMPEG_VERSION="4.4"

TOP_ROOT=$PWD
SOURCE=${TOP_ROOT}/src
FFMPEG_SOURCE=$SOURCE/ffmpeg-android
BUILD_DIR=`pwd`/libs/ffmpeg
mkdir -p ${BUILD_DIR}
mkdir -p ${SOURCE}
mkdir -p ${FFMPEG_SOURCE}

cd $SOURCE
if [ ! -e "ffmpeg-${FFMPEG_VERSION}.tar.bz2" ]; then
    echo "Downloading ffmpeg-${FFMPEG_VERSION}.tar.bz2"
    curl -LO http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2
    tar -xvf ffmpeg-${FFMPEG_VERSION}.tar.bz2 -C $FFMPEG_SOURCE --strip-components=1
    cd $FFMPEG_SOURCE
    PATCH_ROOT=${TOP_ROOT}/patches
    # patch the configure script to use an Android-friendly versioning scheme
    patch -u configure ${PATCH_ROOT}/patch_fix_ffmpeg_lib_name.txt
else
    echo "Using ffmpeg-${FFMPEG_VERSION}.tar.bz2"
fi

#for i in `find diffs -type f`; do
#    (cd ffmpeg-${FFMPEG_VERSION} && patch -p1 < ../$i)
#done

######################################################
############### START die ############################
######################################################

#-- error function
function die {
  code=-1
  err="Unknown error!"
  test "$1" && err=$1
  cd ${top_root}
  echo "$err"
  echo "Check the build log: ${build_log}"
  exit -1
}

######################################################
############### END die ############################
######################################################

######################################################
############### START build_one ######################
######################################################

function build_one
{
OPENSSL_DIR=$TOP_ROOT/libs/openssl
OPENSSL_BUILD_DIR=$OPENSSL_DIR/lib/$ABI
OPENSSL_INCLUDE_DIR=$OPENSSL_DIR/include/$ABI
OPENSSL_SRC_DIR=$SOURCE/openssl-android

SSL_EXTRA_LDFLAGS="-L$OPENSSL_BUILD_DIR"
SSL_EXTRA_CFLAGS="-I$OPENSSL_INCLUDE_DIR"

echo $SSL_EXTRA_LDFLAGS
echo $SSL_EXTRA_CFLAGS

if [ $ARCH == "arm" ]
then
    TOOLACHAIN_PREFIX=arm-linux-androideabi
    ANDROID_TARGET=armv7a-linux-androideabi
#added by alexvas
elif [ $ARCH == "arm64" ]
then
    TOOLACHAIN_PREFIX=aarch64-linux-android
    ANDROID_TARGET=aarch64-linux-android
elif [ $ARCH == "x86_64" ]
then
    TOOLACHAIN_PREFIX=x86_64-linux-android
    ANDROID_TARGET=x86_64-linux-android
elif [ $ARCH == "i686" ]
then
    TOOLACHAIN_PREFIX=i686-linux-android
    ANDROID_TARGET=i686-linux-android
fi

pushd $FFMPEG_SOURCE

#export PKG_CONFIG_PATH="${TOP_ROOT}/src/openssl-android"
export ABI="${ABI}"
openssl_addi_ldflags=""
#echo "pkg-config path = '${PKG_CONFIG_PATH}'"
#echo "openssl compile ldflag = '${OPENSSL_BUILD_DIR} ${openssl_addi_ldflags}'"

#    --prefix=$PREFIX \

#--incdir=$BUILD_DIR/include \
#--libdir=$BUILD_DIR/lib/$CPU \

#    --extra-cflags="-fvisibility=hidden -fdata-sections -ffunction-sections -Os -fPIC -DANDROID -DHAVE_SYS_UIO_H=1 -Dipv6mr_interface=ipv6mr_ifindex -fasm -Wno-psabi -fno-short-enums -fno-strict-aliasing -finline-limit=300 $OPTIMIZE_CFLAGS " \
#    --extra-ldflags="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib -lc -lm -ldl -llog" \

# TODO Adding aac decoder brings "libnative.so has text relocations. This is wasting memory and prevents security hardening. Please fix." message in Android.

INCLUDE_DIR=$BUILD_DIR/include/$ABI
BINARIES_DIR=$BUILD_DIR/binaries/$ABI

if [ $TARGET == 'x86' ]; then

./configure \
    --prefix=$PREFIX \
    --target-os=android \
    --incdir=$INCLUDE_DIR \
    --libdir=$BINARIES_DIR \
    --enable-cross-compile \
    --extra-libs="-lgcc" \
    --arch=$ARCH \
    --cc=$TOOLCHAIN/$ANDROID_TARGET$API-clang \
    --cxx=$TOOLCHAIN/$ANDROID_TARGET$API-clang++ \
    --ld=$TOOLCHAIN/$ANDROID_TARGET$API-clang \
    --nm=$TOOLCHAIN/$TOOLACHAIN_PREFIX-nm \
    --cross-prefix=$TOOLCHAIN/$TOOLACHAIN_PREFIX- \
    --sysroot=$SYSROOT \
    --extra-cflags="$OPTIMIZE_CFLAGS $SSL_EXTRA_CFLAGS" \
    --extra-ldflags="-Wl, -nostdlib -lc -lm -ldl -llog -lz $SSL_EXTRA_LDFLAGS -DOPENSSL_API_COMPAT=0x00908000L" \
    --disable-static \
    --disable-ffplay \
    --disable-ffmpeg \
    --disable-ffprobe \
    --disable-doc \
    --disable-symver \
    --enable-gpl \
    --enable-postproc \
    --disable-encoders \
    --disable-muxers \
    --disable-bsfs \
    --disable-indevs \
    --disable-outdevs \
    --disable-devices \
    --disable-asm \
    --enable-shared \
    --enable-small \
    --enable-encoder=png \
    --enable-nonfree \
    --enable-openssl \
    --enable-protocol=file,ftp,http,https,httpproxy,hls,mmsh,mmst,pipe,rtmp,rtmps,rtmpt,rtmpts,rtp,sctp,srtp,tcp,udp \
    $ADDITIONAL_CONFIGURE_FLAG || die "Couldn't configure ffmpeg!"
else

./configure \
    --prefix=$PREFIX \
    --target-os=android \
    --incdir=$INCLUDE_DIR \
    --libdir=$BINARIES_DIR \
    --enable-cross-compile \
    --extra-libs="-lgcc" \
    --arch=$ARCH \
    --cc=$TOOLCHAIN/$ANDROID_TARGET$API-clang \
    --cxx=$TOOLCHAIN/$ANDROID_TARGET$API-clang++ \
    --ld=$TOOLCHAIN/$ANDROID_TARGET$API-clang \
    --nm=$TOOLCHAIN/$TOOLACHAIN_PREFIX-nm \
    --cross-prefix=$TOOLCHAIN/$TOOLACHAIN_PREFIX- \
    --sysroot=$SYSROOT \
    --extra-cflags="$OPTIMIZE_CFLAGS $SSL_EXTRA_CFLAGS" \
    --extra-ldflags="-Wl, -nostdlib -lc -lm -ldl -llog -lz $SSL_EXTRA_LDFLAGS -DOPENSSL_API_COMPAT=0x00908000L" \
    --disable-static \
    --disable-ffplay \
    --disable-ffmpeg \
    --disable-ffprobe \
    --disable-doc \
    --disable-symver \
    --enable-gpl \
    --enable-postproc \
    --disable-encoders \
    --disable-muxers \
    --disable-bsfs \
    --disable-indevs \
    --disable-outdevs \
    --disable-devices \
    --enable-asm \
    --enable-shared \
    --enable-small \
    --enable-encoder=png \
    --enable-nonfree \
    --enable-openssl \
    --enable-protocol=file,ftp,http,https,httpproxy,hls,mmsh,mmst,pipe,rtmp,rtmps,rtmpt,rtmpts,rtp,sctp,srtp,tcp,udp \
    $ADDITIONAL_CONFIGURE_FLAG || die "Couldn't configure ffmpeg!"
fi

make clean
make -j8 install V=1
$TOOLCHAIN/$TOOLACHAIN_PREFIX-ar d libavcodec/libavcodec.a inverse.o

#$PREBUILT/bin/$HOST-ld -rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib  -soname libffmpeg.so -shared -nostdlib  -z,noexecstack -Bsymbolic --whole-archive --no-undefined -o $PREFIX/libffmpeg.so libavcodec/libavcodec.a libavformat/libavformat.a libavutil/libavutil.a libswscale/libswscale.a -lc -lm -lz -ldl -llog  --warn-once  --dynamic-linker=/system/bin/linker $PREBUILT/lib/gcc/$HOST/4.6/libgcc.a
popd

# copy the binaries
LIB_DIR=$BUILD_DIR/lib
LIBAVCODEC_DIR=$LIB_DIR/libavcodec/$ABI
LIBAVDEVICE_DIR=$LIB_DIR/libavdevice/$ABI
LIBAVFILTER_DIR=$LIB_DIR/libavfilter/$ABI
LIBAVFORMAT_DIR=$LIB_DIR/libavformat/$ABI
LIBAVUTIL_DIR=$LIB_DIR/libavutil/$ABI
LIBSWRESAMPLE_DIR=$LIB_DIR/libswresample/$ABI
LIBSWSCALE_DIR=$LIB_DIR/libswscale/$ABI
LIBPOSTPROC=$LIB_DIR/libpostproc/$ABI
mkdir -p ${LIBAVCODEC_DIR}
mkdir -p ${LIBAVDEVICE_DIR}
mkdir -p ${LIBAVFILTER_DIR}
mkdir -p ${LIBAVFORMAT_DIR}
mkdir -p ${LIBAVUTIL_DIR}
mkdir -p ${LIBSWRESAMPLE_DIR}
mkdir -p ${LIBSWSCALE_DIR}
mkdir -p ${LIBPOSTPROC}
cp -r $BINARIES_DIR/libavcodec* 	${LIBAVCODEC_DIR}/.
cp -r $BINARIES_DIR/libavdevice* 	${LIBAVDEVICE_DIR}/.
cp -r $BINARIES_DIR/libavfilter* 	${LIBAVFILTER_DIR}/.
cp -r $BINARIES_DIR/libavformat* 	${LIBAVFORMAT_DIR}/.
cp -r $BINARIES_DIR/libavutil* 		${LIBAVUTIL_DIR}/.
cp -r $BINARIES_DIR/libswresample* 	${LIBSWRESAMPLE_DIR}/.
cp -r $BINARIES_DIR/libswscale* 	${LIBSWSCALE_DIR}/.
cp -r $BINARIES_DIR/libpostproc* 	${LIBPOSTPROC}/.
#rsync -a --include '*/' --include 'libavcoded' --exclude '*' BUILD_DIR/$ABI/binaries ${dist_lib_root}/
# copy the executables
#cp -r ${src_root}/openssl-android/libs/armeabi/openssl ${dist_bin_root}/. # work only for one abi folder
#rsync -a --include '*/openssl' --exclude '*.so' ${src_root}/openssl-android/libs/ ${dist_bin_root}/
#cp -r ${src_root}/openssl-android/libs/armeabi/ssltest ${dist_bin_root}/. # work only for one abi folder
#rsync -a --include '*/ssltest' --exclude '*.so' ${src_root}/openssl-android/libs/ ${dist_bin_root}/
# copy the headers
#cp -r ${src_root}/openssl-android/include/* ${dist_include_root}/.
}

######################################################
############### END build_one ########################
######################################################

if [ $TARGET == 'arm-v5te' ]; then
    #arm v5te
    ABI=armeabi
    CPU=armv5te
    ARCH=arm
    OPTIMIZE_CFLAGS="-marm -march=$CPU"
    PREFIX=$BUILD_DIR/$CPU
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi

if [ $TARGET == 'arm-v6' ]; then
    #arm v6
    ABI=armeabi
    CPU=armv6
    ARCH=arm
    OPTIMIZE_CFLAGS="-marm -march=$CPU"
    PREFIX=`pwd`/ffmpeg-android/$CPU
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi

if [ $TARGET == 'arm-v7vfpv3' ]; then
    #arm v7vfpv3
    ABI=armeabi-v7a
    CPU=armv7-a
    ARCH=arm
    OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=vfpv3-d16 -marm -march=$CPU "
    PREFIX=$BUILD_DIR/$CPU
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi

if [ $TARGET == 'arm-v7vfp' ]; then
    #arm v7vfp
    ABI=armeabi-v7a
    CPU=armv7-a
    ARCH=arm
    OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=vfp -marm -march=$CPU "
    PREFIX=`pwd`/ffmpeg-android/$CPU-vfp
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi

if [ $TARGET == 'arm-v7n' ]; then
    #arm v7n
    ABI=armeabi-v7a
    CPU=armv7-a
    ARCH=arm
    OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=neon -marm -march=$CPU -mtune=cortex-a8"
    PREFIX=`pwd`/ffmpeg-android/$CPU
    ADDITIONAL_CONFIGURE_FLAG=--enable-neon
    build_one
fi

if [ $TARGET == 'arm-v6+vfp' ]; then
    #arm v6+vfp
    ABI=armeabi
    CPU=armv6
    ARCH=arm
    OPTIMIZE_CFLAGS="-DCMP_HAVE_VFP -mfloat-abi=softfp -mfpu=vfp -marm -march=$CPU"
    PREFIX=`pwd`/ffmpeg-android/${CPU}_vfp
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi

if [ $TARGET == 'arm64-v8a' ]; then
    #arm64-v8a
    ABI=arm64-v8a
    CPU=arm64-v8a
    ARCH=arm64
    OPTIMIZE_CFLAGS=
    PREFIX=$BUILD_DIR/$CPU
    PREFIX=`pwd`/../jni/ffmpeg/ffmpeg/arm64-v8a
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi

if [ $TARGET == 'x86_64' ]; then
    #x86_64
    ABI=x86_64
    CPU=x86_64
    ARCH=x86_64
    OPTIMIZE_CFLAGS="-fomit-frame-pointer"
    #PREFIX=$BUILD_DIR/$CPU
    PREFIX=`pwd`/../jni/ffmpeg/ffmpeg/x86_64
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi

if [ $TARGET == 'x86' ]; then
    #x86
    ABI=x86
    CPU=i686
    ARCH=i686
    OPTIMIZE_CFLAGS="-fomit-frame-pointer"
    #PREFIX=$BUILD_DIR/$CPU
    PREFIX=`pwd`/../jni/ffmpeg/ffmpeg/x86
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi

if [ $TARGET == 'armv7-a' ]; then
    #arm armv7-a
    ABI=armeabi-v7a
    CPU=armv7-a
    ARCH=arm
    OPTIMIZE_CFLAGS="-mfloat-abi=softfp -marm -march=$CPU "
    #PREFIX=`pwd`/ffmpeg-android/$CPU
    PREFIX=`pwd`/../jni/ffmpeg/ffmpeg/armeabi-v7a
    ADDITIONAL_CONFIGURE_FLAG=
    build_one
fi