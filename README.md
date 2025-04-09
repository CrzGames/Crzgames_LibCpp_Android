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
- arm64-v8a <br />
- x86 <br />
- x86_64
  
### Conseils : 
- Pour éviter de construire 2 fois pour l'architecture : armeabi-v7a si on construit à partir de l'API/SDK 23 d'Android ça sera compatible pour NEON et SANS NEON
    
### Lien utile :
https://developer.android.com/ndk/guides/cmake?hl=fr

<br /><br /><br /><br />


## Documentation des dépendances pour chacune des librairies :
RCENet : 
  1. dossier include (rcenet) -> à linker
  2. rcenet.a -> à linker <br /><br />

SDL2 (IMPORTANT TRES SPECIFIC) : 
  1. Récupérer le code source COMPLET de la dernière version Release sur github.
  2. Placer le repository entier dans le projet android studio depuis : app/jni/SDL
  3. Il sera compiler avec pendant la construction, obligatoire de faire cela a cause de la contrainte du wrappre SDL pour Android JNI <br /><br />

SDL2_ttf : 
  1. dossier include (SDL2_ttf) -> à linker
  3. libSDL2_ttf.so, libharfbuzz.a, libfreetype.a -> à linker <br /><br />

SDL2_mixer : 
  1. dossier include (SDL2_mixer) -> à linker
  3. libSDL2_mixer.so -> à linker <br /><br />
 
 OpenSSL : 
  1. dossier include (openssl) -> à linker
  3. libcrypto.so libssl.so -> à linker
     
<br /><br /><br /><br />


## Documentation pour construire les librairies, permet de récupérer les .h / .a / .so des librairies (pour mettre à jour les librairies si il faut) :
### Setup Environment
1. Download and Install CMake >= 3.28.1 : https://cmake.org/download/ and add in PATH ENVIRONMENT
2. Download and Install NDK LTS version >= r27c : https://developer.android.com/ndk/downloads?hl=fr
   
<br />

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


### Librairies à récupérer :
SDL : <br />
1. Récupérer le code source COMPLET de la dernière version Release sur github (le fichier .tar.gz IMPORTANT).
2. Placer le repository entier dans le projet android studio depuis : app/jni/SDL (le dossier doit être nommé 'SDL' obligatoirement par rapport au CMake qui utilise le projet android)
3. Il faudra modifier dans les projets android : app/src/main/java/SDLActivity.java, ligne : 60. Il faudra modifier SDL_MAJOR_VERSION, SDL_MINOR_VERSION et SDL_MICRO_VERSION par rapport à la version qu'ont n'as récupérer
4. Il sera compiler avec pendant la construction, obligatoire de faire cela a cause de la contrainte du wrapper SDL pour Android JNI <br /><br />

SDL2_ttf / SDL2_mixer : <br />
1. Il faudra également modifier le début de ce script concernant les versions de SDL2, SDL2_* que vous voulez construire !
2. Ce placer à la racine du dossier de ce repository github.
3. Run command :
```bash
  # --api (optional) : use minimal API Android, default api = 23
  ./generate-lib-sdl.sh --prefix=/home/debian/build --ndkdir=/home/debian/android-ndk/android-ndk-r27c --api=36
```
4. Récupérer les librairies dans : /home/debian/build
<br /><br />

RCENet :
1. Télécharger le repository de la dernière release : https://github.com/corentin35000/Crzgames_RCENet/releases (librcenet-android.zip)
2. Récupérer les fichiers include dans le dossier : ./android/arch/include/ du dossier télécharger précédemment
3. Récupérer la librairie (librcenet.a) depuis le dossier : ./android/arch/lib/ du dossier télécharger précédemment
<br /><br />

OpenSSL : 
1. Il faudra cloner le github de OpenSSL officiel à partir d'une branche spécifique pour cibler la version comme ceci :
```bash
# Changer la version de la branche de OpenSSL si besoin
git clone -b openssl-3.5.0 https://github.com/openssl/openssl.git
cd openssl/
```
2. Construire OpenSSL pour chaque architecture Android :
```bash
# Set (il faut surtout modifier le path de ANDROID_NDK_ROOT pour pointer vers le repertoire racine du NDK pour Android)
export ANDROID_NDK_ROOT=/home/debian/ndk/r27c
PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH

# Construire la librairie pour chaque architecture diffèrente :
./Configure android-arm64 -D__ANDROID_API__=23 -fPIC
make install DESTDIR=./build-arm64-v8a
make clean

./Configure android-arm -D__ANDROID_API__=23 -fPIC
make install DESTDIR=./build-armeabi-v7a
make clean

./Configure android-x86 -D__ANDROID_API__=23 -fPIC
make install DESTDIR=./build-x86
make clean

./Configure android-x86_64 -D__ANDROID_API__=23 -fPIC
make install DESTDIR=./build-x86_64
make clean
```
