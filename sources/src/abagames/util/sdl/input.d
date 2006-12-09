/*
 * $Id: input.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.input;

private import SDL;

/**
 * Input device interface.
 */
public interface Input {
  public void handleEvent(SDL_Event *event);
}

public class MultipleInputDevice: Input {
 public:
  Input[] inputs;

  public void handleEvent(SDL_Event *event) {
    foreach (Input i; inputs)
      i.handleEvent(event);
  }
}
