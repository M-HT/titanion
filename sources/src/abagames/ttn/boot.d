/*
 * $Id: boot.d,v 1.3 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.boot;

private import std.string;
//private import std.stream;
private import std.conv;
private import std.math;
private import core.stdc.stdlib;
private import abagames.util.logger;
private import abagames.util.tokenizer;
private import abagames.util.sdl.mainloop;
private import abagames.util.sdl.input;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.recordableinput;
private import abagames.util.sdl.sound;
private import abagames.ttn.screen;
private import abagames.ttn.frame;
private import abagames.ttn.preference;
private import abagames.ttn.enemy;

/**
 * Boot the game.
 */
private:
Screen screen;
RecordablePad input;
Frame frame;
Preference preference;
MainLoop mainLoop;

version (Win32_release) {
  // Boot as the Windows executable.
  private import std.c.windows.windows;
  private import std.string;

  extern (C) void gc_init();
  extern (C) void gc_term();
  extern (C) void _minit();
  extern (C) void _moduleCtor();

  extern (Windows)
    public int WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR lpCmdLine,
                     int nCmdShow) {
    int result;
    gc_init();
    _minit();
    try {
      _moduleCtor();
      char[4096] exe;
      GetModuleFileNameA(null, exe, 4096);
      string[1] prog;
      prog[0] = std.string.toString(exe);
      result = boot(prog ~ std.string.split(std.string.toString(lpCmdLine)));
    } catch (Exception o) {
      Logger.error("Exception: " ~ o.toString());
      result = EXIT_FAILURE;
    }
    gc_term();
    return result;
  }
} else {
  // Boot as the general executable.
  public int main(string[] args) {
    return boot(args);
  }
}

public int boot(string[] args) {
  screen = new Screen;
  input = new RecordablePad;
  frame = new Frame;
  preference = new Preference;
  mainLoop = new MainLoop(screen, input, frame, preference);
  try {
    parseArgs(args, screen, input, mainLoop);
  } catch (Exception e) {
    return EXIT_FAILURE;
  }
  mainLoop.loop();
  return EXIT_SUCCESS;
}

private void parseArgs(string[] commandArgs, Screen screen, RecordablePad pad, MainLoop mainLoop) {
  string[] args = readOptionsIniFile();
  for (int i = 1; i < commandArgs.length; i++)
    args ~= commandArgs[i];
  string progName = commandArgs[0];
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
    case "-fullscreen":
      screen.windowMode = false;
      break;
    case "-window":
      screen.windowMode = true;
      break;
    case "-res":
      if (i >= args.length - 2) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      int w = to!int(args[i]);
      i++;
      int h = to!int(args[i]);
      screen.screenWidth = w;
      screen.screenHeight = h;
      break;
    case "-brightness":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      float b = cast(float) to!int(args[i]) / 100;
      if (b < 0 || b > 1) {
        usage(args[0]);
        throw new Exception("Invalid options");
      }
      Screen.brightness = b;
      break;
    case "-nosound":
      Sound.noSound = true;
      break;
    case "-bgmvol":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      int v = to!int(args[i]);
      if (v < 0 || v > 128) {
        usage(args[0]);
        throw new Exception("Invalid options");
      }
      Sound.bgmVol = v;
      break;
    case "-sevol":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      int v = to!int(args[i]);
      if (v < 0 || v > 128) {
        usage(args[0]);
        throw new Exception("Invalid options");
      }
      Sound.seVol = v;
      break;
    case "-exchange":
      pad.buttonsExchanged = true;
      break;
    case "-trail":
      EnemyPool.trailEffect = true;
      break;
    case "-noslowdown":
      mainLoop.noSlowdown = true;
      break;
    case "-randomized":
      GameState.stageRandomized = true;
      break;
    case "-c4amode":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      int c = to!int(args[i]);
      Preference.C4Amode = c;
      break;
    default:
      usage(progName);
      throw new Exception("Invalid options");
    }
  }
}

private string OPTIONS_INI_FILE = "options.ini";

private string[] readOptionsIniFile() {
  try {
    return Tokenizer.readFile(OPTIONS_INI_FILE, " ");
  } catch (Exception e) {
    return null;
  }
}

private void usage(string progName) {
  Logger.error
    ("Usage: " ~ progName ~ " [-fullscreen] [-res x y] [-brightness [0-100]] [-nosound] [-bgmvol [0-128]] [-sevol [0-128]] [-exchange] [-trail] [-noslowdown] [-randomized]");
}
