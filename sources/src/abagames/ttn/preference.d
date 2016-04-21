/*
 * $Id: preference.d,v 1.4 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.preference;

private import std.stdio;
private import abagames.util.preference;

/**
 * Load/Save/Record a high score table.
 */
public class Preference: abagames.util.preference.Preference {
 public:
  static const int RANKING_NUM = 10;
  static const int MODE_NUM = 3;
  static int C4Amode = 0;
 private:
  static const int VERSION_NUM = 30;
  static string PREF_FILE_NAME = "ttn.prf";
  int[RANKING_NUM][MODE_NUM] _highScore;
  int _lastMode;

  public void load() {
    scope File fd;
    try {
      int read_data[1];
      fd.open(PREF_FILE_NAME);
      fd.rawRead(read_data);
      if (read_data[0] != VERSION_NUM)
        throw new Exception("Wrong version num");
      fd.rawRead(read_data);
      _lastMode = read_data[0];
      fd.rawRead(_highScore);
    } catch (Exception e) {
      init();
    } finally {
      if (fd.isOpen())
        fd.close();
    }

    if (C4Amode == 1) {
        _lastMode = 0;
    } else if (C4Amode == 2) {
        _lastMode = 1;
    } else if (C4Amode == 3) {
        _lastMode = 2;
    }
  }

  private void init() {
    _lastMode = 2;
    for(int j = 0; j < MODE_NUM; j++)
      for(int i = 0; i < RANKING_NUM; i++)
        _highScore[j][i] = (10 - i) * 10000;
  }

  public void save() {
    scope File fd;
    try {
      fd.open(PREF_FILE_NAME, "wb");
      int write_data[2] = [VERSION_NUM, _lastMode];
      fd.rawWrite(write_data);
      fd.rawWrite(_highScore);
    } finally {
      fd.close();
    }
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
