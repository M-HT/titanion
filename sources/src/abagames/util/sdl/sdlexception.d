/*
 * $Id: sdlexception.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.sdlexception;

/**
 * SDL initialize failed.
 */
public class SDLInitFailedException: Exception {
  public this(const char[] msg) {
    super(msg.idup);
  }
}

/**
 * SDL general exception.
 */
public class SDLException: Exception {
  public this(const char[] msg) {
    super(msg.idup);
  }
}
