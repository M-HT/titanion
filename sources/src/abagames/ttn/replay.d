/*
 * $Id: replay.d,v 1.4 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.replay;

private import std.stdio;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.recordableinput;

/**
 * Save/Load a replay data.
 */
public class ReplayData {
 public:
  static string DIR = "replay";
  static const int VERSION_NUM = 30;
  InputRecord!(PadState) inputRecord;
  long seed;
  int score = 0;
  int mode;
  bool stageRandomized;
 private:

  public void save(string fileName) {
    int write_data_int[1];
    long write_data_long[1];
    byte write_data_byte[1];
    scope File fd;
    fd.open(DIR ~ "/" ~ fileName, "wb");
    write_data_int[0] = VERSION_NUM;
    fd.rawWrite(write_data_int);
    write_data_long[0] = seed;
    fd.rawWrite(write_data_long);
    write_data_int[0] = score;
    fd.rawWrite(write_data_int);
    write_data_int[0] = mode;
    fd.rawWrite(write_data_int);
    write_data_byte[0] = cast(byte) stageRandomized;
    fd.rawWrite(write_data_byte);
    inputRecord.save(fd);
    fd.close();
  }

  public void load(string fileName) {
    int read_data_int[1];
    long read_data_long[1];
    byte read_data_byte[1];
    scope File fd;
    fd.open(DIR ~ "/" ~ fileName);
    fd.rawRead(read_data_int);
    if (read_data_int[0] != VERSION_NUM)
      throw new Exception("Wrong version num");
    fd.rawRead(read_data_long);
    seed = read_data_long[0];
    fd.rawRead(read_data_int);
    score = read_data_int[0];
    fd.rawRead(read_data_int);
    mode = read_data_int[0];
    fd.rawRead(read_data_byte);
    stageRandomized = cast(bool) (read_data_byte[0]);
    inputRecord = new InputRecord!(PadState);
    inputRecord.load(fd);
    fd.close();
  }
}
