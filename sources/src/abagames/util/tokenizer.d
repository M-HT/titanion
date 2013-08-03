/*
 * $Id: tokenizer.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.util.tokenizer;

private import std.stdio;
private import std.string;

/**
 * Tokenizer.
 */
public class Tokenizer {
 private:

  public static string[] readFile(string fileName, string separator) {
    string[] result;
    scope File fd;
    fd.open(fileName);
    for (;;) {
      char[] line;
      if (!fd.readln(line))
        break;
      char[][] spl = std.string.split(line.stripRight(), separator);
      foreach (char[] s; spl) {
        char[] r = strip(s);
        if (r.length > 0)
          result ~= r.idup;
      }
    }
    fd.close();
    return result;
  }
}

/**
 * CSV format tokenizer.
 */
public class CSVTokenizer {
 private:

  public static string[] readFile(string fileName) {
    return Tokenizer.readFile(fileName, ",");
  }
}
