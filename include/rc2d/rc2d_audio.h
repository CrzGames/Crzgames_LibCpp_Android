#ifndef RC2D_AUDIO_H
#define RC2D_AUDIO_H

#include <SDL_mixer.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Enumération des types de fichiers audio pris en charge.
 *
 * @typedef {Enum} RC2D_FileAudioType
 * @property {Number} RC2D_FILE_TYPE_WAV - Le type de fichier audio est WAV.
 * @property {Number} RC2D_FILE_TYPE_MP3 - Le type de fichier audio est MP3.
 * @property {Number} RC2D_FILE_TYPE_UNKNOWN - Le type de fichier audio est inconnu.
 */
typedef enum RC2D_FileAudioType {
    RC2D_FILE_TYPE_WAV,
    RC2D_FILE_TYPE_MP3,
    RC2D_FILE_TYPE_UNKNOWN
} RC2D_FileAudioType;

/**
 * Enumération des types de sources audio.
 *
 * @typedef {Enum} RC2D_AudioType
 * @property {Number} RC2D_AUDIO_TYPE_MUSIC - Le type de source audio est une musique.
 * @property {Number} RC2D_AUDIO_TYPE_SOUND - Le type de source audio est un son.
 * @property {Number} RC2D_AUDIO_TYPE_UNKNOWN - Le type de source audio est inconnu.
 */
typedef enum RC2D_AudioType {
    RC2D_AUDIO_TYPE_MUSIC,
    RC2D_AUDIO_TYPE_SOUND,
    RC2D_AUDIO_TYPE_UNKNOWN
} RC2D_AudioType;

/**
 * Structure représentant une source audio pouvant être un effet sonore ou de la musique.
 * @typedef {object} RC2D_SourceAudio
 * @property {Mix_Chunk} sound - Pointeur vers un effet sonore chargé avec SDL_mixer
 * @property {Mix_Music} music - Pointeur vers une musique chargée avec SDL_mixer
 * @property {RC2D_FileAudioType} type - Type de source audio (musique ou son).
 * @property {RC2D_AudioType} fileType - Type de fichier audio (WAV ou MP3).
 */
typedef struct RC2D_SourceAudio {
    Mix_Chunk* sound; 
    Mix_Music* music;
    RC2D_AudioType audioType;
    RC2D_FileAudioType fileType;
} RC2D_SourceAudio;

RC2D_SourceAudio rc2d_audio_newSource(const char* filePath, const RC2D_FileAudioType fileType, const RC2D_AudioType type);
void rc2d_audio_freeSource(RC2D_SourceAudio* sourceAudio);

void rc2d_audio_play(const RC2D_SourceAudio* sourceAudio, const int loops);
void rc2d_audio_pause(const RC2D_SourceAudio* sourceAudio);
void rc2d_audio_stop(const RC2D_SourceAudio* sourceAudio);

void rc2d_audio_setVolume(const int volume);

#ifdef __cplusplus
}
#endif

#endif // RC2D_AUDIO_H