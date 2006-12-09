/*
 * $Id: preference.d,v 1.4 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.preference;

private import std.stream;
private import abagames.util.preference;

/**
 * Load/Save/Record a high score table.
 */
public class Preference: abagames.util.preference.Preference {
 public:
  static const int RANKING_NUM = 10;
  static const int MODE_NUM = 3;
 private:
  static const int VERSION_NUM = 30;
  static const char[] PREF_FILE_NAME = "ttn.prf";
  int[RANKING_NUM][MODE_NUM] _highScore;
  int _lastMode;

  public void load() {
    auto File fd = null;
    try {
      fd = new File(PREF_FILE_NAME, FileMode.In);
      int ver;
      fd.read(ver);
      if (ver != VERSION_NUM)
        throw new Error("Wrong version num");
      fd.read(_lastMode);
      for(int j = 0; j < MODE_NUM; j++)
        for(int i = 0; i < RANKING_NUM; i++)
          fd.read(_highScore[j][i]);
    } catch (Object e) {
      init();
    } finally {
      if (fd)
        if (fd.isOpen())
          fd.close();
    }
  }

  private void init() {
    _lastMode = 2;
    for(int j = 0; j < MODE_NUM; j++)
      for(int i = 0; i < RANKING_NUM; i++)
        _highScore[j][i] = (10 - i) * 10000;
  }

  public void save() {
    auto File fd = new File(PREF_FILE_NAME, FileMode.OutNew);
    fd.write(VERSION_NUM);
    fd.write(_lastMode);
    for(int j = 0; j < MODE_NUM; j++)
      for(int i = 0; i < RANKING_NUM; i++)
        fd.write(_highScore[j][i]);
    fd.close();
  }

  public void setMode(int mode) {
    _lastMode = mode;
  }

  public void recordResult(int score, int mode) {
    setMode(mode);
    for (int i = 0; i < RANKING_NUM; i++) {
      if (score > _highScore[mode][i]) {
        for (int j = RANKING_NUM - 1; j >= i + 1; j--) {
          _highScore[mode][j] = _highScore[mode][j - 1];
        }
        _highScore[mode][i] = score;
        return;
      }
    }
  }

  public int[RANKING_NUM][] highScore() {
    return _highScore;
  }

  public int lastMode() {
    return _lastMode;
  }
}
