/*
 * $Id: logger.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.util.logger;

private import std.stdio;
private import std.conv;
private import std.string;

/**
 * Logger for error and info messages.
 */
version(Win32_release) {

private import std.string;
private import std.c.windows.windows;

public class Logger {

  public static void info(const char[] msg, bool nline = true) {
  }

  public static void info(double n, bool nline = true) {
  }

  private static void putMessage(const char[] msg) {
    MessageBoxA(null, std.string.toStringz(msg), "Error", MB_OK | MB_ICONEXCLAMATION);
  }

  public static void error(const char[] msg) {
    putMessage("Error: " ~ msg);
  }

  public static void error(Exception e) {
    putMessage("Error: " ~ e.toString());
  }

  public static void error(Error e) {
    putMessage("Error: " ~ e.toString());
  }
}

} else {

public class Logger {

  public static void info(const char[] msg, bool nline = true) {
    if (nline)
      writefln(msg);
    else
      writef(msg);
  }

  public static void info(double n, bool nline = true) {
    if (nline)
      writefln(to!string(n));
    else
      writef(to!string(n));
  }

  public static void error(const char[] msg) {
    writefln("Error: %s", msg);
  }

  public static void error(Exception e) {
    writefln("Error: %s", e.toString());
  }

  public static void error(Error e) {
    writefln("Error: %s", e.toString());
    if (e.next)
      error(cast(Error)e.next);
  }
}

}
