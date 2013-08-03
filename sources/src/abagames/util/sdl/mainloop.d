/*
 * $Id: mainloop.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.mainloop;

private import SDL;
private import abagames.util.logger;
private import abagames.util.rand;
private import abagames.util.preference;
private import abagames.util.sdl.frame;
private import abagames.util.sdl.screen;
private import abagames.util.sdl.input;
private import abagames.util.sdl.sound;
private import abagames.util.sdl.sdlexception;

/**
 * SDL main loop.
 */
public class MainLoop {
 public:
  const int INTERVAL_BASE = 16;
  const int MAX_SKIP_FRAME = 5;
  bool noSlowdown = false;
  SDL_Event event;
 private:
  Screen screen;
  Input input;
  Frame frame;
  Preference preference;
  float slowdownRatio;
  float interval = INTERVAL_BASE;
  float _slowdownStartRatio = 1;
  float _slowdownMaxRatio = 1.5f;

  public this(Screen screen, Input input, Frame frame, Preference preference) {
    this.screen = screen;
    this.input = input;
    this.frame = frame;
    this.preference = preference;
    frame.setMainLoop(this);
    frame.setUIs(screen, input);
    frame.setPreference(preference);
  }

  // Initialize and load a preference.
  private void initFirst() {
    preference.load();
    try {
      Sound.init();
    } catch (SDLInitFailedException e) {
      Logger.error(e);
    }
    frame.init();
    initInterval();
  }

  // Quit and save a preference.
  private void quitLast() {
    frame.quit();
    Sound.close();
    preference.save();
    screen.closeSDL();
    SDL_Quit();
  }

  private bool done;

  public void breakLoop() {
    done = true;
  }

  public void loop() {
    done = false;
    long prvTickCount = 0;
    int i;
    long nowTick;
    int frameNum;
    screen.initSDL();
    initFirst();
    frame.start();
    while (!done) {
      if (SDL_PollEvent(&event) == 0)
        event.type = SDL_USEREVENT;
      input.handleEvent(&event);
      if (event.type == SDL_QUIT)
        breakLoop();
      nowTick = SDL_GetTicks();
      int itv = cast(int) interval;
      frameNum = cast(int) (nowTick - prvTickCount) / itv;
      if (frameNum <= 0) {
        frameNum = 1;
        SDL_Delay(cast(uint)(prvTickCount + itv - nowTick));
        prvTickCount += interval;
      } else if (frameNum > MAX_SKIP_FRAME) {
        frameNum = MAX_SKIP_FRAME;
        prvTickCount = nowTick;
      } else {
        //prvTickCount += frame * interval;
        prvTickCount = nowTick;
      }
      slowdownRatio = 0;
      for (i = 0; i < frameNum; i++)
        frame.move();
      slowdownRatio /= frameNum;
      screen.clear();
      frame.draw();
      screen.flip();
      if (!noSlowdown)
        calcInterval();
    }
    quitLast();
  }

  // Intentional slowdown.

  public void initInterval() {
    interval = INTERVAL_BASE;
  }

  public void addSlowdownRatio(float sr) {
    slowdownRatio += sr;
  }

  private void calcInterval() {
    if (slowdownRatio > _slowdownStartRatio) {
      float sr = slowdownRatio / _slowdownStartRatio;
      if (sr > _slowdownMaxRatio)
        sr = _slowdownMaxRatio;
      interval += (sr * INTERVAL_BASE - interval) * 0.1;
    } else {
      interval += (INTERVAL_BASE - interval) * 0.08;
    }
  }

  public float slowdownStartRatio(float v) {
    return _slowdownStartRatio = v;
  }

  public float slowdownMaxRatio(float v) {
    return _slowdownMaxRatio = v;
  }
}
