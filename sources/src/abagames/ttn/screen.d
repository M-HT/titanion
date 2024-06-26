/*
 * $Id: screen.d,v 1.2 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.screen;

private import std.string;
private import bindbc.sdl;
private import opengl;
//private import openglu;
private import abagames.util.sdl.screen3d;
private import abagames.ttn.field;

/**
 * OpenGL screen.
 */
public class Screen: Screen3D {
 private:
  static string CAPTION = "Titanion";
  static string ICON_FILE_NAME = "images/ttn_icon32.bmp";
  Field field;

  protected override void setIcon() {
    SDL_SetWindowIcon(window, SDL_LoadBMP(std.string.toStringz(ICON_FILE_NAME)));
  }

  protected override void init() {
    setCaption(CAPTION);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glEnable(GL_BLEND);
    glEnable(GL_LINE_SMOOTH);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_COLOR_MATERIAL);
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    setClearColor(0, 0, 0, 1);
  }

  public void setField(Field field) {
    this.field = field;
    screenResized();
  }

  protected override void close() {}

  public override void screenResized() {
    super.screenResized();
    float lw = (cast(float) screenWidth / 640 + cast(float) screenHeight / 480) / 2;
    if (lw < 1)
      lw = 1;
    else if (lw > 4)
      lw = 4;
    glLineWidth(lw);
    glViewport(screenStartX, screenStartY, screenWidth, screenHeight);
    if (field)
      field.setLookAt();
  }
}
