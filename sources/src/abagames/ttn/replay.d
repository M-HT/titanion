/*
 * $Id: replay.d,v 1.4 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.replay;

private import std.stream;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.recordableinput;

/**
 * Save/Load a replay data.
 */
public class ReplayData {
 public:
  static const char[] DIR = "replay";
  static const int VERSION_NUM = 30;
  InputRecord!(PadState) inputRecord;
  long seed;
  int score = 0;
  int mode;
  bool stageRandomized;
 private:

  public void save(char[] fileName) {
    auto File fd = new File(DIR ~ "/" ~ fileName, FileMode.OutNew);
    fd.write(VERSION_NUM);
    fd.write(seed);
    fd.write(score);
    fd.write(mode);
    fd.write(cast(byte) stageRandomized);
    inputRecord.save(fd);
    fd.close();
  }

  public void load(char[] fileName) {
    auto File fd = new File(DIR ~ "/" ~ fileName, FileMode.In);
    int ver;
    fd.read(ver);
    if (ver != VERSION_NUM)
      throw new Error("Wrong version num");
    fd.read(seed);
    fd.read(score);
    fd.read(mode);
    byte sr;
    fd.read(sr);
    stageRandomized = cast(bool) sr;
    inputRecord = new InputRecord!(PadState);
    inputRecord.load(fd);
    fd.close();
  }
}
