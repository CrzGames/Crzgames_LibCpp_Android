# Crzgames - Libraries C/C++ - Android

## Informations sur les types de fichier des bibliothèques C/C++ pour Android par rapport au system ou/et du compiler pour Android :
Compiler : NDK (CLang) <br />

Bibliothèque dynamique/partagée : .so <br />
Bibliothèque statique : .a <br />

<br /><br /><br /><br />


## Supported architecture for Android system :
### List architectures :
- armeabi-v7a <br />
- armeabi-v7a with NEON <br />
- arm64-v8a

### Conseils : 
- Pour éviter de construire 2 fois pour l'architecture : armeabi-v7a si on construit à partir de l'API/SDK 23 d'Android ça sera compatible pour NEON et SANS NEON
    
### Lien utile :
https://developer.android.com/ndk/guides/cmake?hl=fr

<br /><br /><br /><br />


## Documentation des dépendances pour chacune des librairies :
 OpenSSL : 
  1. dossier include (openssl) -> à linker
  3. libcrypto.so libssl.so -> à linker
     
<br /><br /><br /><br />


## Documentation pour construire les librairies, permet de récupérer les .h / .a / .so des librairies (pour mettre à jour les librairies si il faut) :
### Build the library 
1. Create directory
```bash
mkdir build && cd build
```
2. Build for different architectures Android, exemples : 
```bash
cmake \
-DCMAKE_TOOLCHAIN_FILE=/home/debian/android-ndk/android-ndk-r27c/build/cmake/android.toolchain.cmake \
-DANDROID_NDK=/home/debian/android-ndk/android-ndk-r27c \
-DCMAKE_BUILD_TYPE=Release \ # change Release OR Debug
-DANDROID_ABI=armeabi-v7a \ # change for differents architectures : armeabi-v7a, arm64-v8a, x86 and x86_64
-DANDROID_STL=c++_shared \
-DANDROID_PLATFORM=android-23 \ # use minimal API Android
..
```

<br /><br />


### Librairies à récupérer (via Linux) :
OpenSSL : 
1. Installer les outils nécessaire pour les diffèrentes étapes (zip and make) :
```bash
sudo apt update
sudo apt install build-essential
sudo apt install zip
```

2. Télécharger et extraire le NDK :
```bash
cd ~
wget https://dl.google.com/android/repository/android-ndk-r27c-linux.zip
unzip android-ndk-r27c-linux.zip
mv android-ndk-r27c ndk
```

3. Définir les variables d’environnement dans ~/.bashrc ou ~/.profile :
```bash
nano ~/.bashrc
export ANDROID_NDK_ROOT=$HOME/ndk
export PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
source ~/.bashrc
```

4. Il faudra cloner le github de OpenSSL officiel à partir d'une branche spécifique pour cibler la version comme ceci :
```bash
# Changer la version de la branche de OpenSSL si besoin
git clone -b openssl-3.5.0 https://github.com/openssl/openssl.git
cd openssl/
```

5. Construire OpenSSL pour chaque architecture Android :
```bash
# Correspond réellement à l'architecture Android : arm64-v8a (arm64)
./Configure android-arm64 -D__ANDROID_API__=24 -fPIC no-shared
make -j$(nproc)
make install DESTDIR=./openssl-build-arm64-v8a
# Pour récupérer le dossier include des headers de OpenSSL :
cd openssl-build-arm64-v8a/usr/local/include/
# Pour récupérer les librairies static OpenSSL construite (libcrypto.a / libssl.a) :
cd openssl-build-arm64-v8a/usr/local/lib/
make clean

# Correspond réellement à l'architecture Android : armeabi-v7a (arm32)
./Configure android-arm -D__ANDROID_API__=24 -fPIC no-shared
make -j$(nproc)
make install DESTDIR=./openssl-build-armeabi-v7a
# Pour récupérer le dossier include des headers de OpenSSL :
cd openssl-build-armeabi-v7a/usr/local/include/
# Pour récupérer les librairies static OpenSSL construite (libcrypto.a / libssl.a) :
cd openssl-build-armeabi-v7a/usr/local/lib/
make clean
```

FFMPEG (on macos for android): 
3. :
```bash
../configure \
  --prefix=../install-android \
  --target-os=android --host-os=darwin-x86_64 --enable-shared \
  --enable-cross-compile --arch=${ARCH} --cpu=${CPU} \
  --enable-jni --enable-mediacodec \
  --disable-doc --disable-programs --enable-small \
  --disable-autodetect --disable-everything \
  --enable-avcodec --enable-avformat --enable-avutil --enable-swresample --enable-swscale \
  --enable-protocol=file \
  --enable-demuxer=mov,matroska,webm,mp3,ogg,wav,flac \
  --enable-parser=h264,hevc,aac,mp3,opus,vorbis,flac \
  --enable-decoder=h264,hevc,aac,mp3,opus,vorbis,flac,pcm_s16le,pcm_f32le \
  --sysroot=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot \
  --sysinclude=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/ \
  --cc=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/darwin-x86_64/bin/${TOOLCHAIN_ARCH}24-clang \
  --cxx=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/darwin-x86_64/bin/${TOOLCHAIN_ARCH}24-clang++ \
  --strip=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip
```
