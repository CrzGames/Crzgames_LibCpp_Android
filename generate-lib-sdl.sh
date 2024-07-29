#!/bin/bash

###  FIX HERE VERSION IF NECESSARY  ###
src_SDL2=SDL2-2.30.0 # Obligatory for libs SDL2_image, SDL2_mixer, SDL2_ttf
src_SDL2_image=SDL2_image-2.8.2
src_SDL2_ttf=SDL2_ttf-2.22.0
src_SDL2_mixer=SDL2_mixer-2.8.0
#src_SDL2_net=SDL2_net-2.2.0

# Color messages #
txtbld=$(tput bold)
txtred=$(tput setaf 1)
txtgreen=$(tput setaf 2)
txtrst=$(tput sgr0)

# Global Variables #
ARCHS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64") # Change if necessary
DOWNLOADER=""
NDK_DIR="$ANDROID_NDK_HOME"
NDK_OPTIONS="$NDK_OPTIONS"
INSTALL_DIR=$(pwd)
API="23"
MK_ADDON=""
cp_opt=""

function MESSAGE { printf "$txtgreen$1 $txtrst\n"; }

function ERROR 
{ 
    if [ $? -ne 0 ]; then 
        printf "$txtred\nERROR: $1 $txtrst\n\n"; 
        exit 1; 
    fi
}

function STATUS
{
    if [ $? -ne 0 ]; then 
        printf "$txtred\nERROR: $1 $txtrst\n\n"; 
        exit 1;
    else
        printf "$txtgreen$1 - done $txtrst\n";    
    fi
}

function copyLibs
{
    local LIB_NAME=$1
    local ARCH=$2
    local LIB_PATH=$3
    mkdir -p "$INSTALL_DIR/dist/libs/$LIB_NAME/$ARCH"
    cp -av $LIB_PATH "$INSTALL_DIR/dist/libs/$LIB_NAME/$ARCH/"
}

function copyIncludes
{
    local LIB_NAME=$1
    local INCLUDE_PATH=$2

    mkdir -p "$INSTALL_DIR/dist/include/$LIB_NAME"
    cp -av $INCLUDE_PATH "$INSTALL_DIR/dist/include/$LIB_NAME/"
}

function downloadPackage
{
    MESSAGE "Downloading $1"
    $DOWNLOADER $1
    ERROR "Could not download $1 \nFix address or package version in the script"
    MESSAGE "Downloaded $1"
}

function buildPackage
{
    src=$1
    url=$2
    ARCH=$3

    if [[ ! -e "$src" ]]; then
        if [[ ! -e "$src.tar.gz" ]]; then
        	downloadPackage $url;
        fi

        tar xzf $INSTALL_DIR/$src.tar.gz -C $INSTALL_DIR;
        STATUS "Unpack $src.tar.gz";
    fi    

    case $src in
        "$src_SDL2")
            build_SDL2 $ARCH ;;
        "$src_SDL2_image")
            build_SDL2_image $ARCH ;;            
        "$src_SDL2_mixer")
            build_SDL2_mixer $ARCH ;;
        "$src_SDL2_net")
            build_SDL2_net $ARCH ;;
        "$src_SDL2_ttf")
            build_SDL2_ttf $ARCH ;; 
        *)
            printf "$txtred ERROR: unknown parameter \"$src\"\n $txtrst"
            exit 1 ;;
    esac
}

function verifyAndDownloadDependencies 
{
    local DIR=$1
    shift
    local DEPENDENCIES=("$@")
    local MISSING_DEPENDENCIES=false

    for dep in "${DEPENDENCIES[@]}"; do
        if [[ ! -d "$DIR/external/$dep" ]]; then
            MESSAGE "Dependency $dep is missing in $DIR/external."
            MISSING_DEPENDENCIES=true
            break
        fi
    done

    if [[ "$MISSING_DEPENDENCIES" = true ]]; then
        MESSAGE "Downloading missing external dependencies for $(basename $DIR)..."
        pushd $DIR/external > /dev/null
        ./download.sh
        STATUS "Missing external dependencies for $(basename $DIR) downloaded"
        popd > /dev/null
    else
        MESSAGE "All external dependencies for $(basename $DIR) are already present. No download needed."
    fi
}


function build_SDL2
{
    local ARCH=$1

    if [[ -e "$INSTALL_DIR/lib/$ARCH/libSDL2.so" ]]; then return 0; fi

    $NDK_DIR/ndk-build -C $INSTALL_DIR/$src_SDL2 NDK_PROJECT_PATH=$NDK_DIR \
        APP_BUILD_SCRIPT=$INSTALL_DIR/$src_SDL2/Android.mk \
        APP_PLATFORM=android-$API APP_ABI=$ARCH $NDK_OPTIONS \
        NDK_OUT=$INSTALL_DIR/obj NDK_LIBS_OUT=$INSTALL_DIR/obj/libs
    STATUS "Building SDL2"

    printf "$txtgreen"
    copyLibs "SDL2" "$ARCH" "$INSTALL_DIR/obj/local/$ARCH/lib*.*"
    copyIncludes "SDL2" "$INSTALL_DIR/$src_SDL2/include/*"
    printf "$txtrst"  
}

function build_SDL2_image
{
    local ARCH=$1

    local DEPENDENCIES=("SDL" "aom" "dav1d" "jpeg" "libavif" "libjxl" "libpng" "libtiff" "libwebp" "zlib")

    if [[ -e "$INSTALL_DIR/lib/$ARCH/libSDL2_image.so" ]]; then return 0; fi
    
    DIR=$INSTALL_DIR/$src_SDL2_image
    if [[ -e $DIR/tmp.mk ]]; then mv -f $DIR/tmp.mk $DIR/Android.mk; fi
    cp -fva $DIR/Android.mk $DIR/tmp.mk
    sed -e $'/(call my-dir)/a\\\n'"$MK_ADDON" $DIR/Android.mk 1<> $DIR/Android.mk

    if [[ -e "$DIR/external/download.sh" ]]; then
        verifyAndDownloadDependencies "$DIR" "${DEPENDENCIES[@]}"
    else
        ERROR "download.sh for SDL2_image external dependencies not found"
    fi
    
    $NDK_DIR/ndk-build -C $DIR NDK_PROJECT_PATH=$NDK_DIR APP_BUILD_SCRIPT=$DIR/Android.mk \
        APP_PLATFORM=android-$API APP_ABI=$ARCH APP_ALLOW_MISSING_DEPS=true $NDK_OPTIONS \
        NDK_OUT=$INSTALL_DIR/obj NDK_LIBS_OUT=$INSTALL_DIR/obj/libs
    STATUS "Building SDL2_image"

    printf "$txtgreen"
    copyLibs "SDL2_image" "$ARCH" "$INSTALL_DIR/obj/local/$ARCH/lib*.*"
    copyIncludes "SDL2_image" "$INSTALL_DIR/$src_SDL2_image/include/*"
    printf "$txtrst"

    mv -f $DIR/tmp.mk $DIR/Android.mk
}

function build_SDL2_mixer
{
    local ARCH=$1

    local DEPENDENCIES=("SDL" "flac" "libgme" "libxmp" "mpg123" "ogg" "opus" "opusfile" "tremor" "vorbis" "wavpack")

    if [[ -e "$INSTALL_DIR/lib/$ARCH/libSDL2_mixer.so" ]]; then return 0; fi
    
    DIR=$INSTALL_DIR/$src_SDL2_mixer
    if [[ -e $DIR/tmp.mk ]]; then mv -f $DIR/tmp.mk $DIR/Android.mk; fi
    cp -fva $DIR/Android.mk $DIR/tmp.mk
    sed -e $'/(call my-dir)/a\\\n'"$MK_ADDON" $DIR/Android.mk 1<> $DIR/Android.mk

    if [[ -e "$DIR/external/download.sh" ]]; then
        verifyAndDownloadDependencies "$DIR" "${DEPENDENCIES[@]}"
    else
        ERROR "download.sh for SDL2_mixer external dependencies not found"
    fi
    
	$NDK_DIR/ndk-build -C $DIR NDK_PROJECT_PATH=$NDK_DIR APP_BUILD_SCRIPT=$DIR/Android.mk \
        APP_PLATFORM=android-$API APP_ABI=$ARCH APP_ALLOW_MISSING_DEPS=true $NDK_OPTIONS \
        NDK_OUT=$INSTALL_DIR/obj NDK_LIBS_OUT=$INSTALL_DIR/obj/libs
    STATUS "Building SDL2_mixer"

    printf "$txtgreen"
    copyLibs "SDL2_mixer" "$ARCH" "$INSTALL_DIR/obj/local/$ARCH/lib*.*"
    copyIncludes "SDL2_mixer" "$INSTALL_DIR/$src_SDL2_mixer/include/*"
    printf "$txtrst"

    mv -f $DIR/tmp.mk $DIR/Android.mk
}

function build_SDL2_net
{
    local ARCH=$1

    if [[ -e "$INSTALL_DIR/lib/$ARCH/libSDL2_net.so" ]]; then return 0; fi
    
    DIR=$INSTALL_DIR/$src_SDL2_net
    if [[ -e $DIR/tmp.mk ]]; then mv -f $DIR/tmp.mk $DIR/Android.mk; fi
    cp -fva $DIR/Android.mk $DIR/tmp.mk
    sed -e $'/(call my-dir)/a\\\n'"$MK_ADDON" $DIR/Android.mk 1<> $DIR/Android.mk

	$NDK_DIR/ndk-build -C $DIR NDK_PROJECT_PATH=$NDK_DIR APP_BUILD_SCRIPT=$DIR/Android.mk \
        APP_PLATFORM=android-$API APP_ABI=$ARCH APP_ALLOW_MISSING_DEPS=true $NDK_OPTIONS \
        NDK_OUT=$INSTALL_DIR/obj NDK_LIBS_OUT=$INSTALL_DIR/obj/libs
    STATUS "Building SDL2_net"

    printf "$txtgreen"
    copyLibs "SDL2_net" "$ARCH" "$INSTALL_DIR/obj/local/$ARCH/lib*.*"
    printf "$txtrst"

    mv -f $DIR/tmp.mk $DIR/Android.mk	
}

function build_SDL2_ttf
{
    local ARCH=$1
    local DEPENDENCIES=("SDL" "freetype" "harfbuzz")

    if [[ -e "$INSTALL_DIR/lib/$ARCH/libSDL2_ttf.so" ]]; then return 0; fi
    
    DIR=$INSTALL_DIR/$src_SDL2_ttf
    if [[ -e $DIR/tmp.mk ]]; then mv -f $DIR/tmp.mk $DIR/Android.mk; fi
    cp -fva $DIR/Android.mk $DIR/tmp.mk
    sed -e $'/(call my-dir)/a\\\n'"$MK_ADDON" $DIR/Android.mk 1<> $DIR/Android.mk

    if [[ -e "$DIR/external/download.sh" ]]; then
        verifyAndDownloadDependencies "$DIR" "${DEPENDENCIES[@]}"
    else
        ERROR "download.sh for SDL2_ttf external dependencies not found"
    fi
    
	$NDK_DIR/ndk-build -C $DIR NDK_PROJECT_PATH=$NDK_DIR APP_BUILD_SCRIPT=$DIR/Android.mk \
        APP_PLATFORM=android-$API APP_ABI=$ARCH APP_ALLOW_MISSING_DEPS=true $NDK_OPTIONS \
        NDK_OUT=$INSTALL_DIR/obj NDK_LIBS_OUT=$INSTALL_DIR/obj/libs
    STATUS "Building SDL2_ttf"

    printf "$txtgreen"
    copyLibs "SDL2_ttf" "$ARCH" "$INSTALL_DIR/obj/local/$ARCH/lib*.*"
    copyIncludes "SDL2_ttf" "$INSTALL_DIR/$src_SDL2_ttf/SDL_ttf.h"
    printf "$txtrst"

    mv -f $DIR/tmp.mk $DIR/Android.mk	
}

function osCommands
{
   case "$(uname -s)" in
   Darwin)
     cp_opt="-avf" ;;
   *)
     cp_opt="-avu" ;;
   esac
}

function parseArgs
{
    if [[ "$1" == "" ]]; then usage; exit; fi 

    while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage; exit ;;
        --prefix)
            INSTALL_DIR=$VALUE ;;
        --ndkdir)
            NDK_DIR=$VALUE ;;
        --api)
            API=$VALUE ;;
        *)
            printf "$txtred ERROR: unknown parameter \"$PARAM\"\n $txtrst"
            usage; exit ;;
    esac
    shift
    done
}

function usage
{
    printf "$txtgreen"
    printf "\n\t Usage: ./generate-lib-sdl.sh <options>\n" 
    printf "\n\t -h --help                Brief help"
    printf "\n\t --prefix=<PREFIX>        Download and build in PREFIX, default path is \"generate-lib-sdl.sh\" script directory"
    printf "\n\t --ndkdir=<PATH>          Path to NDK directory"
    printf "\n\t --api=<id>               Set minimal Android API level, example --api=23"
    printf "\n\n\t              Example of usage:"
    printf "\n\n\t ./generate-lib-sdl.sh --prefix=/home/debian/build --ndkdir=/home/user/NDK --api=23 \n\n$txtrst"
}

#################################################################################

for ARCH in "${ARCHS[@]}"; do
    MESSAGE "Building for architecture: $ARCH"
    
    parseArgs "$@"
    osCommands

    MESSAGE "Used \"NDK_OPTIONS\":\n$NDK_OPTIONS"

    NDK=$NDK_DIR/ndk-build

    if [[ ! -e "$NDK" ]]; then
        printf "$txtred\nERROR: Can not find ndk-build $txtrst\n\n"; 
        exit 1;        
    fi

    DOWNLOADER=$(which curl);

    if [[ ! $DOWNLOADER ]]; 
        then DOWNLOADER=$(which wget);
        else DOWNLOADER="$DOWNLOADER -O -f -L"
    fi
    ERROR "Please install curl or wget."

    if [[ $INSTALL_DIR && ! -e $INSTALL_DIR ]]; then
        mkdir -p $INSTALL_DIR
        STATUS "Create $INSTALL_DIR directory"
    fi
    
    MK_ADDON=""
    MK_ADDON+=$'include $(CLEAR_VARS)\\\n'
    MK_ADDON+=$'LOCAL_MODULE := SDL2\\\n'
    MK_ADDON+=$'LOCAL_SRC_FILES := '"$INSTALL_DIR/dist/libs/SDL2/$ARCH/libSDL2.so"$'\\\n'
    MK_ADDON+=$'LOCAL_EXPORT_C_INCLUDES += '"$INSTALL_DIR/$src_SDL2/include"$'\\\n'
    MK_ADDON+="include \$(PREBUILT_SHARED_LIBRARY)"

    pushd $INSTALL_DIR     

    ### FIX URL HERE IF DOWNLOAD FAILS ### 
    if [ ! -z "$src_SDL2" ]; then
        URL=https://www.libsdl.org/release/$src_SDL2.tar.gz
        buildPackage $src_SDL2 $URL $ARCH
    fi 

    if [ ! -z "$src_SDL2_image" ]; then
        URL=https://www.libsdl.org/projects/SDL_image/release/$src_SDL2_image.tar.gz
        buildPackage $src_SDL2_image $URL $ARCH
    fi 

    if [ ! -z "$src_SDL2_mixer" ]; then
        URL=https://www.libsdl.org/projects/SDL_mixer/release/$src_SDL2_mixer.tar.gz
        buildPackage $src_SDL2_mixer $URL $ARCH
    fi 

    if [ ! -z "$src_SDL2_net" ]; then
        URL=https://www.libsdl.org/projects/SDL_net/release/$src_SDL2_net.tar.gz
        buildPackage $src_SDL2_net $URL $ARCH
    fi 

    if [ ! -z "$src_SDL2_ttf" ]; then
        URL=https://www.libsdl.org/projects/SDL_ttf/release/$src_SDL2_ttf.tar.gz
        buildPackage $src_SDL2_ttf $URL $ARCH
    fi

    popd

    rm -rf "$INSTALL_DIR/obj"
done

MESSAGE "\n\n ******** Generate all lib SDL_* finish, go to directory : $INSTALL_DIR ******** \n\n"