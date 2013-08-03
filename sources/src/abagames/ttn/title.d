/*
 * $Id: title.d,v 1.4 2006/12/04 16:04:27 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.title;

private import std.string;
private import std.conv;
private import opengl;
private import abagames.util.vector;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.texture;
private import abagames.ttn.screen;
private import abagames.ttn.letter;
private import abagames.ttn.preference;
private import abagames.ttn.frame;

/**
 * Title screen.
 */
public class Title {
 private:
  Preference preference;
  RecordablePad pad;
  Frame frame;
  int cnt;
  bool aPressed, udPressed;
  Texture titleTexture;
  Vector titlePos;
  float titleSize;
  int cursorIdx;

  public this(Preference preference, Pad pad, Frame frame) {
    this.preference = preference;
    this.pad = cast(RecordablePad) pad;
    this.frame = frame;
    titlePos = new Vector;
    cursorIdx = 0;
  }

  public void init() {
    titleTexture = new Texture("title.bmp");
  }

  public void close() {
    titleTexture.close();
  }

  public void setMode(int mode) {
    cursorIdx = mode;
  }

  public void start() {
    cnt = 0;
    aPressed = true;
    udPressed = true;
    titlePos.x = 150;
    titlePos.y = 150;
    titleSize = 1.0f;
  }

  public void move() {
    PadState input;
    input = pad.getState(false);
    if (input.button & PadState.Button.A) {
      if (!aPressed) {
        aPressed = true;
        frame.startInGame(cursorIdx);
      }
    } else {
      aPressed = false;
    }
    if (input.dir & (PadState.Dir.UP | PadState.Dir.DOWN)) {
      if (!udPressed) {
        udPressed = true;
        if (input.dir & PadState.Dir.UP)
          cursorIdx--;
        else if (input.dir & PadState.Dir.DOWN)
          cursorIdx++;
        if (cursorIdx < 0)
          cursorIdx = GameState.MODE_NUM - 1;
        else if (cursorIdx > GameState.MODE_NUM - 1)
          cursorIdx = 0;
      }
    } else {
      udPressed = false;
    }
    if (cnt > 180 && cnt < 235)
      titlePos.y -= 2;
    if (cnt > 600 && cnt < 675) {
      titlePos.x -= 2;
      titlePos.y++;
      titleSize -= 0.007f;
    }
    cnt++;
  }

  public void draw() {
    Screen.setColor(1, 1, 1);
    glEnable(GL_TEXTURE_2D);
    titleTexture.bind();
    drawBoard(titlePos.x, titlePos.y, 280 * titleSize, 64 * titleSize);
    glDisable(GL_TEXTURE_2D);
    if ((cnt % 120) < 60) {
      float x = 175, sz = 6;
      if (cnt >= 600) {
        int c = cnt - 600;
        if (c > 75)
          c = 75;
        x += c * 4.33f;
        sz -= c * 0.045f;
      }
      Letter.drawString("PUSH SHOT BUTTON TO START", x, 440, sz);
    }
    if (cnt >= 240) {
      drawRanking();
    }
    if ((cnt % 60) < 30) {
      drawTriangle(575, 398, 180);
      drawTriangle(575, 417, 0);
    }
    Letter.drawString(GameState.MODE_NAME[cursorIdx], 540, 400, 5);
  }

  private void drawBoard(float x, float y, float w, float h) {
    glBegin(GL_TRIANGLE_FAN);
    glTexCoord2f(0, 0);
    glVertex3f(x, y, 0);
    glTexCoord2f(1, 0);
    glVertex3f(x + w, y, 0);
    glTexCoord2f(1, 1);
    glVertex3f(x + w, y + h, 0);
    glTexCoord2f(0, 1);
    glVertex3f(x, y + h, 0);
    glEnd();
  }

  private void drawTriangle(float x, float y, float d) {
    glPushMatrix();
    glTranslatef(x, y, 0);
    glRotatef(d, 0, 0, 1);
    glScalef(5, 5, 1);
    glBegin(GL_TRIANGLE_FAN);
    Screen.setColor(1, 1, 1, 0.5f);
    glVertex3f(0, 1.7f, 0);
    glVertex3f(1, 0, 0);
    glVertex3f(-1, 0, 0);
    glEnd();
    glBegin(GL_LINE_LOOP);
    Screen.setColor(1, 1, 1, 1);
    glVertex3f(0, 1.7f, 0);
    glVertex3f(1, 0, 0);
    glVertex3f(-1, 0, 0);
    glEnd();
    glPopMatrix();
  }

  private void drawRanking() {
    int rn = (cnt - 240) / 30;
    if (rn > Preference.RANKING_NUM)
      rn = Preference.RANKING_NUM;
    float y = 140;
    for (int i = 0; i < rn; i++) {
      if (cnt < 600) {
      string rstr;
        switch (i) {
        case 0:
          rstr = "1ST";
          break;
        case 1:
          rstr = "2ND";
          break;
        case 2:
          rstr = "3RD";
          break;
        default:
          rstr = to!string(i + 1) ~ "TH";
          break;
        }
        if (i < 9)
          Letter.drawString(rstr, 180, y, 7);
        else
          Letter.drawString(rstr, 166, y, 7);
      }
      float sx = 450, sy = y, sz = 6;
      if (cnt >= 600) {
        int c = cnt - 600;
        if (c > 75)
          c = 75;
        sx += cast(int) (c * 2.35f);
        sz -= c * 0.03f;
      }
      Letter.drawNum(preference.highScore[cursorIdx][i], sx, sy, sz);
      y += 24;
    }
  }
}
