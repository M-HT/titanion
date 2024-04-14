/*
 * $Id: sound.d,v 1.2 2006/12/04 16:04:27 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.sound;

private import std.string;
private import std.conv;
private import bindbc.sdl;
private import abagames.util.sdl.sdlexception;

/**
 * Initialize and close SDL_mixer.
 */
public class Sound {
 public:
  static bool noSound = false;
  static int bgmVol = 100;
  static int seVol = 100;
 private:

  public static void init() {
    if (noSound)
      return;
    int audio_rate;
    ushort audio_format;
    int audio_channels;
    int audio_buffers;
    if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
      noSound = true;
      throw new SDLInitFailedException
        ("Unable to initialize SDL_AUDIO: " ~ to!string(SDL_GetError()));
    }
    audio_rate = 44100;
    audio_format = AUDIO_S16;
    audio_channels = 1;
    audio_buffers = 4096;
    bool sound_opened = false;
    static if (SDL_MIXER_VERSION_ATLEAST(2, 0, 2)) {
      const SDL_version *link_version = Mix_Linked_Version();
      if (SDL_version(link_version.major, link_version.minor, link_version.patch) >= SDL_version(2, 0, 2)) {
        sound_opened = true;
        if (Mix_OpenAudioDevice(audio_rate, audio_format, audio_channels, audio_buffers, null, 0xff) < 0) {
          noSound = 1;
          throw new SDLInitFailedException
            ("Couldn't open audio: " ~ to!string(SDL_GetError()));
        }
      }
    }
    if (!sound_opened) {
      if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers) < 0) {
        noSound = true;
        throw new SDLInitFailedException
          ("Couldn't open audio: " ~ to!string(SDL_GetError()));
      }
    }
    Mix_QuerySpec(&audio_rate, &audio_format, &audio_channels);
    Mix_VolumeMusic(bgmVol);
    Mix_Volume(-1, seVol);
  }

  public static void close() {
    if (noSound)
      return;
    if (Mix_PlayingMusic())
      Mix_HaltMusic();
    Mix_CloseAudio();
  }
}

/**
 * Music.
 */
public class Music {
 public:
  static int fadeOutSpeed = 1280;
  static string dir = "sounds/musics";
 private:
  Mix_Music* music;

  public void load(const char[] name) {
    if (Sound.noSound)
      return;
    const char[] fileName = dir ~ "/" ~ name;
    music = Mix_LoadMUS(std.string.toStringz(fileName));
    if (!music) {
      Sound.noSound = true;
      throw new SDLException("Couldn't load: " ~ fileName ~
                             " (" ~ to!string(Mix_GetError()) ~ ")");
    }
  }

  public void free() {
    if (music) {
      halt();
      Mix_FreeMusic(music);
    }
  }

  public void play() {
    if (Sound.noSound)
      return;
    Mix_PlayMusic(music, -1);
  }

  public void playOnce() {
    if (Sound.noSound)
      return;
    Mix_PlayMusic(music, 1);
  }

  public static void fade() {
    if (Sound.noSound)
      return;
    Mix_FadeOutMusic(fadeOutSpeed);
  }

  public static void halt() {
    if (Sound.noSound)
      return;
    if (Mix_PlayingMusic())
      Mix_HaltMusic();
  }
}

/**
 * Sound chunk.
 */
public class Chunk {
 public:
  static string dir = "sounds/chunks";
 private:
  Mix_Chunk* chunk;
  int chunkChannel;

  public void load(const char[] name, int ch) {
    if (Sound.noSound)
      return;
    const char[] fileName = dir ~ "/" ~ name;
    chunk = Mix_LoadWAV(std.string.toStringz(fileName));
    if (!chunk) {
      Sound.noSound = true;
      throw new SDLException("Couldn't load: " ~ fileName ~
                             " (" ~ to!string(Mix_GetError()) ~ ")");
    }
    chunkChannel = ch;
  }

  public void free() {
    if (chunk) {
      halt();
      Mix_FreeChunk(chunk);
    }
  }

  public void play() {
    if (Sound.noSound)
      return;
    Mix_PlayChannel(chunkChannel, chunk, 0);
  }

  public void halt() {
    if (Sound.noSound)
      return;
    Mix_HaltChannel(chunkChannel);
  }
}
