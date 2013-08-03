/*
 * $Id: sound.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.sound;

private import std.path;
private import std.file;
private import abagames.util.rand;
private import abagames.util.logger;
private import abagames.util.sdl.sound;

/**
 * Manage BGMs and SEs.
 */
public class Sound: abagames.util.sdl.sound.Sound {
  mixin StaticRandImpl;
 private static:
  string[] seFileName =
    ["shot.wav", "explosion1.wav", "explosion2.wav", "explosion3.wav",
     "tractor.wav", "flying_down.wav", "player_explosion.wav", "flick.wav", "extend.wav"];
  int[] seChannel =
    [0, 1, 2, 3, 4, 5, 6, 6, 7];
  Music[string] bgm;
  Chunk[string] se;
  bool[string] seMark;
  string[] bgmFileName;
  string currentBgm;
  int prevBgmIdx;
  int nextIdxMv;
  bool _bgmEnabled = true;
  bool _seEnabled = true;

  public static void load() {
    loadMusics();
    loadChunks();
  }

  private static void loadMusics() {
    Music[string] musics;
    auto files = dirEntries(Music.dir, SpanMode.shallow);
    foreach (string fileName; files) {
      string ext = extension(fileName);
      if (ext != ".ogg" && ext != ".wav")
        continue;
      string fileBaseName = baseName(fileName);
      Music music = new Music();
      music.load(fileBaseName);
      bgm[fileBaseName] = music;
      bgmFileName ~= fileBaseName;
      Logger.info("Load bgm: " ~ fileBaseName);
    }
  }

  private static void loadChunks() {
    int i = 0;
    foreach (string fileName; seFileName) {
      Chunk chunk = new Chunk();
      chunk.load(fileName, seChannel[i]);
      se[fileName] = chunk;
      seMark[fileName] = false;
      Logger.info("Load SE: " ~ fileName);
      i++;
    }
  }

  public static void playBgm(string name) {
    currentBgm = name;
    if (!_bgmEnabled)
      return;
    Music.halt();
    bgm[name].play();
  }

  public static void playBgm() {
    int bgmIdx = rand.nextInt(cast(int)(bgm.length));
    nextIdxMv = rand.nextInt(2) * 2 - 1;
    prevBgmIdx = bgmIdx;
    playBgm(bgmFileName[bgmIdx]);
  }

  public static void nextBgm() {
    int bgmIdx = prevBgmIdx + nextIdxMv;
    if (bgmIdx < 0)
      bgmIdx = cast(int)(bgm.length - 1);
    else if (bgmIdx >= bgm.length)
      bgmIdx = 0;
    prevBgmIdx = bgmIdx;
    playBgm(bgmFileName[bgmIdx]);
  }

  public static void playCurrentBgm() {
    playBgm(currentBgm);
  }

  public static void fadeBgm() {
    Music.fade();
  }

  public static void haltBgm() {
    Music.halt();
  }

  public static void playSe(string name) {
    if (!_seEnabled)
      return;
    seMark[name] = true;
  }

  public static void playMarkedSes() {
    string[] keys = seMark.keys;
    foreach (string key; keys) {
      if (seMark[key]) {
        se[key].play();
        seMark[key] = false;
      }
    }
  }

  public static void clearMarkedSes() {
    string[] keys = seMark.keys;
    foreach (string key; keys)
      seMark[key] = false;
  }

  public static bool bgmEnabled(bool v) {
    return _bgmEnabled = v;
  }

  public static bool seEnabled(bool v) {
    return _seEnabled = v;
  }
}
