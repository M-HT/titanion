/*
 * $Id: letter.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.letter;

private import std.math;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
private import abagames.ttn.screen;

/**
 * Letters.
 */
public class Letter {
 public:
  static const float LETTER_WIDTH = 2.1f;
  static const float LETTER_HEIGHT = 3.0f;
  static const enum Direction {
    TO_RIGHT, TO_DOWN, TO_LEFT, TO_UP,
  };
 private:
  static const int LETTER_NUM = 44;
  static enum Shape {
    NORMAL, POLYGON, LINE,
  };
  static const int partNumVertices = 6;
  static GLfloat[3*partNumVertices][][LETTER_NUM] letterVertices;

  public static void init() {
    foreach (i; 0..LETTER_NUM) {
      prepareLetter(i);
    }
  }

  public static void close() {
  }

  public static float getWidth(int n, float s) {
    return n * s * LETTER_WIDTH;
  }

  public static float getWidthNum(int num, float s) {
    int dg = 1;
    int n = num;
    int c = 1;
    for (;;) {
      if (n < 10)
        break;
      n /= 10;
      c++;
    }
    return c * s * LETTER_WIDTH;
  }

  public static float getHeight(float s) {
    return s * LETTER_HEIGHT;
  }

  public static void drawLetter(int n, int type) {
    glEnableClientState(GL_VERTEX_ARRAY);

    if (type == 0 || type == 1) {
      if (type == 0) {
        Screen.setColor(1, 1, 1, 0.5);
      }
      foreach (i; 0..letterVertices[n].length) {
        glVertexPointer(3, GL_FLOAT, 0, cast(void *)(letterVertices[n][i].ptr));

        glDrawArrays(GL_TRIANGLE_FAN, 0, partNumVertices);
      }
    }

    if (type == 0 || type == 2) {
      if (type == 0) {
        Screen.setColor(1, 1, 1);
      }
      foreach (i; 0..letterVertices[n].length) {
        glVertexPointer(3, GL_FLOAT, 0, cast(void *)(letterVertices[n][i].ptr));

        glDrawArrays(GL_LINE_LOOP, 0, partNumVertices);
      }
    }

    glDisableClientState(GL_VERTEX_ARRAY);
  }

  private static void drawLetter(int n, int type, float x, float y, float s, float d) {
    glPushMatrix();
    glTranslatef(x, y, 0);
    glScalef(s, s, s);
    glRotatef(d, 0, 0, 1);
    drawLetter(n, type);
    glPopMatrix();
  }

  private static void drawLetterRev(int n, int type, float x, float y, float s, float d) {
    glPushMatrix();
    glTranslatef(x, y, 0);
    glScalef(s, -s, s);
    glRotatef(d, 0, 0, 1);
    drawLetter(n, type);
    glPopMatrix();
  }

  public static int convertCharToInt(char c) {
    int idx;
    if (c >= '0' && c <='9') {
      idx = c - '0';
    } else if (c >= 'A' && c <= 'Z') {
      idx = c - 'A' + 10;
    } else if (c >= 'a' && c <= 'z') {
      idx = c - 'a' + 10;
    } else if (c == '.') {
      idx = 36;
    } else if (c == '-') {
      idx = 38;
    } else if (c == '+') {
      idx = 39;
    } else if (c == '_') {
      idx = 37;
    } else if (c == '!') {
      idx = 42;
    } else if (c == '/') {
      idx = 43;
    }
    return idx;
  }

  public static void drawString(const char[] str, float lx, float y, float s,
                                int d = Direction.TO_RIGHT,
                                bool rev = false, float od = 0,
                                float r = 1, float g = 1, float b = 1) {
    lx += LETTER_WIDTH * s / 2;
    y += LETTER_HEIGHT * s / 2;
    float x = lx;
    int idx;
    float ld;
    switch (d) {
    case Direction.TO_RIGHT:
      ld = 0;
      break;
    case Direction.TO_DOWN:
      ld = 90;
      break;
    case Direction.TO_LEFT:
      ld = 180;
      break;
    case Direction.TO_UP:
      ld = 270;
      break;
    default:
      break;
    }
    ld += od;
    const float ldSin = sin(ld * cast(float)(PI / 180));
    const float ldCos = cos(ld * cast(float)(PI / 180));
    foreach (char c; str) {
      if (c != ' ') {
        idx = convertCharToInt(c);
        if (r == 1 && g == 1 && b == 1) {
          if (rev)
            drawLetterRev(idx, 0, x, y, s, ld);
          else
            drawLetter(idx, 0, x, y, s, ld);
        } else {
          Screen.setColor(r, g, b, 0.5f);
          if (rev)
            drawLetterRev(idx, 1, x, y, s, ld);
          else
            drawLetter(idx, 1, x, y, s, ld);
          Screen.setColor(r, g, b);
          if (rev)
            drawLetterRev(idx, 2, x, y, s, ld);
          else
            drawLetter(idx, 2, x, y, s, ld);
        }
      }
      if (od == 0) {
        switch(d) {
        case Direction.TO_RIGHT:
          x += s * LETTER_WIDTH;
          break;
        case Direction.TO_DOWN:
          y += s * LETTER_WIDTH;
          break;
        case Direction.TO_LEFT:
          x -= s * LETTER_WIDTH;
          break;
        case Direction.TO_UP:
          y -= s * LETTER_WIDTH;
          break;
        default:
          break;
        }
      } else {
        x += ldCos * s * LETTER_WIDTH;
        y += ldSin * s * LETTER_WIDTH;
      }
    }
  }

  public static void drawNum(int num, float lx, float y, float s,
                             int dg = 0,
                             int headChar = -1, int floatDigit = -1) {
    lx += LETTER_WIDTH * s / 2;
    y += LETTER_HEIGHT * s / 2;
    int n = num;
    float x = lx;
    float ld = 0;
    int digit = dg;
    int fd = floatDigit;
    for (;;) {
      if (fd <= 0) {
        drawLetter(n % 10, 0, x, y, s, ld);
        x -= s * LETTER_WIDTH;
      } else {
        drawLetter(n % 10, 0, x, y + s * LETTER_WIDTH * 0.25f, s * 0.5f, ld);
        x -= s * LETTER_WIDTH * 0.5f;
      }
      n /= 10;
      digit--;
      fd--;
      if (n <= 0 && digit <= 0 && fd < 0)
        break;
      if (fd == 0) {
        drawLetter(36, 0, x, y + s * LETTER_WIDTH * 0.25f, s * 0.5f, ld);
        x -= s * LETTER_WIDTH * 0.5f;
      }
    }
    if (headChar >= 0)
      drawLetter(headChar, 0, x + s * LETTER_WIDTH * 0.2f, y + s * LETTER_WIDTH * 0.2f,
                 s * 0.6f, ld);
  }

  public static void drawNumSign(int num, float lx, float ly, float s,
                                 int headChar = -1, int floatDigit = -1, int type = 0) {
    float x = lx;
    float y = ly;
    int n = num;
    int fd = floatDigit;
    for (;;) {
      if (fd <= 0) {
        drawLetterRev(n % 10, type, x, y, s, 0);
        x -= s * LETTER_WIDTH;
      } else {
        drawLetterRev(n % 10, type, x, y - s * LETTER_WIDTH * 0.25f, s * 0.5f, 0);
        x -= s * LETTER_WIDTH * 0.5f;
      }
      n /= 10;
      if (n <= 0)
        break;
      fd--;
      if (fd == 0) {
        drawLetterRev(36, type, x, y - s * LETTER_WIDTH * 0.25f, s * 0.5f, 0);
        x -= s * LETTER_WIDTH * 0.5f;
      }
    }
    if (headChar >= 0)
      drawLetterRev(headChar, type, x + s * LETTER_WIDTH * 0.2f, y - s * LETTER_WIDTH * 0.2f,
                    s * 0.6f, 0);
  }

  public static void drawTime(int time, float lx, float y, float s) {
    int n = time;
    if (n < 0)
      n = 0;
    float x = lx;
    for (int i = 0; i < 7; i++) {
      if (i != 4) {
        drawLetter(n % 10, 0, x, y, s, Direction.TO_RIGHT);
        n /= 10;
      } else {
        drawLetter(n % 6, 0, x, y, s, Direction.TO_RIGHT);
        n /= 6;
      }
      if ((i & 1) == 1 || i == 0) {
        switch (i) {
        case 3:
          drawLetter(41, 0, x + s * 1.16f, y, s, Direction.TO_RIGHT);
          break;
        case 5:
          drawLetter(40, 0, x + s * 1.16f, y, s, Direction.TO_RIGHT);
          break;
        default:
          break;
        }
        x -= s * LETTER_WIDTH;
      } else {
        x -= s * LETTER_WIDTH * 1.3f;
      }
      if (n <= 0)
        break;
    }
  }

  private static void prepareLetter(int idx) {
    float x, y, length, size, t;
    float deg;
    for (int i = 0;; i++) {
      deg = cast(int) spData[idx][i][4];
      if (deg > 99990)
        break;
      x = -spData[idx][i][0];
      y = -spData[idx][i][1];
      size = spData[idx][i][2];
      length = spData[idx][i][3];
      y *= 0.9;
      size *= 1.4;
      length *= 1.05;
      x = -x;
      y = y;
      deg %= 180;
      prepareSegmentPart(idx, x, y, size, length, deg);
    }
  }

  private static void prepareSegmentPart(int idx, float x, float y, float width, float height, float deg) {
    GLfloat[3*partNumVertices] partVertices = [
      -width / 2    ,  0         , 0,
      -width / 3 * 1, -height / 2, 0,
       width / 3 * 1, -height / 2, 0,
       width / 2    ,  0         , 0,
       width / 3 * 1,  height / 2, 0,
      -width / 3 * 1,  height / 2, 0
    ];

    if (deg != 0) {
      // rotate part

      const float cdeg = cos(deg * cast(float)(std.math.PI / 180));
      const float sdeg = sin(deg * cast(float)(std.math.PI / 180));

      foreach (i; 0..partNumVertices) {
        const float px = partVertices[3*i + 0];
        const float py = partVertices[3*i + 1];

        partVertices[3*i + 0] = cdeg * px - sdeg * py;
        partVertices[3*i + 1] = sdeg * px + cdeg * py;
      }
    }

    // move part
    foreach (i; 0..partNumVertices) {
      partVertices[3*i + 0] += x - width / 2;
      partVertices[3*i + 1] += y;
    }

    ++letterVertices[idx].length;
    letterVertices[idx][letterVertices[idx].length - 1] = partVertices;
  }

  private static float[5][16][] spData =
    [[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.6f, 0.55f, 0.65f, 0.3f, 90], [0.6f, 0.55f, 0.65f, 0.3f, 90],
     [-0.6f, -0.55f, 0.65f, 0.3f, 90], [0.6f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0.5f, 0.55f, 0.65f, 0.3f, 90],
     [0.5f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//A
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.18f, 1.15f, 0.45f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.45f, 0.55f, 0.65f, 0.3f, 90],
     [-0.18f, 0, 0.45f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.15f, 1.15f, 0.45f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.45f, 0.45f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//F
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0.05f, 0, 0.3f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0.65f, -0.55f, 0.65f, 0.3f, 90], [-0.7f, -0.7f, 0.3f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//K
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.4f, 0.55f, 0.65f, 0.3f, 100],
     [-0.25f, 0, 0.45f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.6f, -0.55f, 0.65f, 0.3f, 80],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.5f, 1.15f, 0.3f, 0.3f, 0], [0.1f, 1.15f, 0.3f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//P
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0.05f, -0.55f, 0.45f, 0.3f, 60],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.2f, 0, 0.45f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.45f, -0.55f, 0.65f, 0.3f, 80],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.5f, 1.15f, 0.55f, 0.3f, 0], [0.5f, 1.15f, 0.55f, 0.3f, 0],
     [0.1f, 0.55f, 0.65f, 0.3f, 90],
     [0.1f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[//U
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.5f, -0.55f, 0.65f, 0.3f, 90], [0.5f, -0.55f, 0.65f, 0.3f, 90],
     [-0.1f, -1.15f, 0.45f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [-0.5f, -1.15f, 0.3f, 0.3f, 0], [0.1f, -1.15f, 0.3f, 0.3f, 0],
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.4f, 0.6f, 0.85f, 0.3f, 360-120],
     [0.4f, 0.6f, 0.85f, 0.3f, 360-60],
     [-0.4f, -0.6f, 0.85f, 0.3f, 360-240],
     [0.4f, -0.6f, 0.85f, 0.3f, 360-300],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.4f, 0.6f, 0.85f, 0.3f, 360-120],
     [0.4f, 0.6f, 0.85f, 0.3f, 360-60],
     [-0.1f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [0.3f, 0.4f, 0.65f, 0.3f, 120],
     [-0.3f, -0.4f, 0.65f, 0.3f, 120],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//.
     [0, -1.15f, 0.3f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//_
     [0, -1.15f, 0.8f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//-
     [0, 0, 0.9f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//+
     [-0.5f, 0, 0.45f, 0.3f, 0], [0.45f, 0, 0.45f, 0.3f, 0],
     [0.1f, 0.55f, 0.65f, 0.3f, 90],
     [0.1f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[//'
     [0, 1.0f, 0.4f, 0.2f, 90],
     [0, 0, 0, 0, 99999],
    ],[//''
     [-0.19f, 1.0f, 0.4f, 0.2f, 90],
     [0.2f, 1.0f, 0.4f, 0.2f, 90],
     [0, 0, 0, 0, 99999],
    ],[//!
     [0.56f, 0.25f, 1.1f, 0.3f, 90],
     [0, -1.0f, 0.3f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[// /
     [0.8f, 0, 1.75f, 0.3f, 120],
     [0, 0, 0, 0, 99999],
    ]];
}
