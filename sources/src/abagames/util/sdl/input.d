/*
 * $Id: input.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.input;

private import bindbc.sdl;

/**
 * Input device interface.
 */
public interface Input {
  public void handleEvents();
}

public class MultipleInputDevice: Input {
 public:
  Input[] inputs;

  public void handleEvents() {
    foreach (Input i; inputs)
      i.handleEvents();
  }
}
