/*
 * $Id: field.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.field;

private import std.math;
version (USE_GLES) {
  private import opengles;
  private import opengles_glu;
  alias glOrthof glOrtho;
} else {
  private import opengl;
  private import openglu;
}
private import abagames.util.vector;
private import abagames.util.math;
private import abagames.ttn.screen;
private import abagames.ttn.frame;

/**
 * Game field.
 */
public class Field {
 public:
  static const float PIT_SIZE_Y_RATIO = 12.0f;
  static const float CIRCLE_RADIUS = 64.0f;
 private:
  static const float EYE_POS_DIST_RATIO = 1.25f;
  static const float X_EXPANSION_RATIO = 1.0f;
  static const float SIDEWALL_WIDTH = 145;
  static const float TORUS_Y = -24.0f;
  Frame frame;
  Screen screen;
  Vector _size, _outerSize;
  Vector3 _eyePos;
  float eyeDeg;
  Vector3 circlePos;
  int cnt;

  public this(Frame frame, Screen screen) {
    this.frame = frame;
    this.screen = screen;
    _size = new Vector(12, 12);
    _outerSize = new Vector(13, 13);
    _eyePos = new Vector3;
    circlePos = new Vector3;
    set();
  }

  public void set() {
    _eyePos.x = _eyePos.y = _eyePos.z = 0;
    eyeDeg = 0;
    cnt = 0;
  }

  public bool contains(Vector p) {
    return contains(p.x, p.y);
  }

  public bool contains(float x, float y) {
    return _size.contains(x, y);
  }

  public bool containsOuter(Vector p) {
    return containsOuter(p.x, p.y);
  }

  public bool containsOuter(float x, float y) {
    return _outerSize.contains(x, y);
  }

  public bool containsOuterY(float y) {
    return (y >= -_outerSize.y && y <= _outerSize.y);
  }

  public bool containsIncludingPit(Vector p) {
    return (p.y >= -_outerSize.y && p.y <= _size.y * PIT_SIZE_Y_RATIO * 1.1f);
  }

  public float normalizeX(float x) {
    float rx = x;
    float hd = CIRCLE_RADIUS * PI / X_EXPANSION_RATIO;
    if (rx < -hd)
      rx = hd * 2 - (-rx % (hd * 2));
    return (rx + hd) % (hd * 2) - hd;
  }

  public float calcCircularDist(Vector p1, Vector p2) {
    float ax = fabs(normalizeX(p1.x - p2.x));
    float ay = fabs(p1.y - p2.y);
    if (ax > ay)
      return ax + ay / 2;
    else
      return ay + ax / 2;
  }

  public float circularDistance() {
    return CIRCLE_RADIUS * PI * 2 / X_EXPANSION_RATIO;
  }

  public Vector3 calcCircularPos(Vector p) {
    return calcCircularPos(p.x, p.y);
  }

  public Vector3 calcCircularPos(float x, float y) {
    float d = calcCircularDeg(x);
    if (y < _size.y) {
      circlePos.x = sin(d) * CIRCLE_RADIUS;
      circlePos.z = cos(d) * CIRCLE_RADIUS;
      circlePos.y = y;
    } else if (y < _size.y * 3) {
      float cd = (y - _size.y) * PI / 2 / (_size.y * 2);
      float cr = CIRCLE_RADIUS * (0.8f + 0.2f * cos(cd));
      circlePos.x = sin(d) * cr;
      circlePos.z = cos(d) * cr;
      circlePos.y = _size.y + sin(cd) * CIRCLE_RADIUS * 0.2f;
    } else if (y < _size.y * 7) {
      float cd = (y - _size.y * 3) * PI / 2 / (_size.y * 4);
      float cr = CIRCLE_RADIUS * (0.8f - 0.4f * sin(cd));
      circlePos.x = sin(d) * cr;
      circlePos.z = cos(d) * cr;
      circlePos.y = _size.y - CIRCLE_RADIUS * 0.2f + cos(cd) * CIRCLE_RADIUS * 0.4f;
    } else {
      float cr = CIRCLE_RADIUS * 0.4f;
      circlePos.x = sin(d) * cr;
      circlePos.z = cos(d) * cr;
      circlePos.y = _size.y - CIRCLE_RADIUS * 0.2f - (y - _size.y * 7);
    }
    return circlePos;
  }

  public float calcCircularDeg(float x) {
    return x * X_EXPANSION_RATIO / CIRCLE_RADIUS;
  }

  public float calcCircularDist(float d) {
    return d * CIRCLE_RADIUS / X_EXPANSION_RATIO ;
  }

  public bool checkHitDist(Vector pos, Vector p, Vector pp, float dist) {
    float bmvx, bmvy, inaa;
    bmvx = pp.x;
    bmvy = pp.y;
    bmvx -= p.x;
    bmvy -= p.y;
    bmvx = normalizeX(bmvx);
    inaa = bmvx * bmvx + bmvy * bmvy;
    if (inaa > 0.00001) {
      float sofsx, sofsy, inab, hd;
      sofsx = pos.x;
      sofsy = pos.y;
      sofsx -= p.x;
      sofsy -= p.y;
      sofsx = normalizeX(sofsx);
      inab = bmvx * sofsx + bmvy * sofsy;
      if (inab >= 0 && inab <= inaa) {
        hd = sofsx * sofsx + sofsy * sofsy - inab * inab / inaa;
        if (hd >= 0 && hd <= dist)
          return true;
      }
    }
    return false;
  }

  public void addSlowdownRatio(float sr) {
    frame.addSlowdownRatio(sr);
  }

  public void setEyePos(Vector p) {
    eyeDeg = calcCircularDeg(p.x) * 0.25f;
    _eyePos.x = sin(eyeDeg) * CIRCLE_RADIUS * EYE_POS_DIST_RATIO;
    _eyePos.z = cos(eyeDeg) * CIRCLE_RADIUS * EYE_POS_DIST_RATIO;
  }

  public void setLookAt() {
    glMatrixMode(GL_PROJECTION);
    screen.setPerspective();
    gluLookAt(_eyePos.x, _eyePos.y, _eyePos.z, 0, _eyePos.y, 0, 0, 1, 0);
    glMatrixMode(GL_MODELVIEW);
  }

  public void resetLookAt() {
    glMatrixMode(GL_PROJECTION);
    screen.setPerspective();
    gluLookAt(0, 0, 1, 0, 0, 0, 0, 1, 0);
    glMatrixMode(GL_MODELVIEW);
  }

  public void beginDrawingFront() {
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 640, 480, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    drawSidewall();
  }

  private void drawSidewall() {
    static const GLfloat[3*12] sidewallVertices = [
      0, 0, 0,
      SIDEWALL_WIDTH, 0, 0,
      SIDEWALL_WIDTH, 480, 0,
      0, 480, 0,

      640, 0, 0,
      640 - SIDEWALL_WIDTH, 0, 0,
      640 - SIDEWALL_WIDTH, 480, 0,
      640, 480, 0,

      SIDEWALL_WIDTH, 0, 0,
      SIDEWALL_WIDTH, 480, 0,
      640 - SIDEWALL_WIDTH, 0, 0,
      640 - SIDEWALL_WIDTH, 480, 0
    ];

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(sidewallVertices.ptr));

    Screen.setColor(0.25f, 0.25f, 0.25f, 0.5f);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

    glDrawArrays(GL_TRIANGLE_FAN, 4, 4);

    Screen.setColor(1.0f, 1.0f, 1.0f, 0.8f);
    glDrawArrays(GL_LINES, 8, 4);

    glDisableClientState(GL_VERTEX_ARRAY);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }

  public void move() {
    cnt++;
  }

  public void drawBack() {
    glPushMatrix();
    glTranslatef(0, TORUS_Y, 0);
    drawTorusShape(PI / 2);
    glPopMatrix();
  }

  public void drawFront() {
    glPushMatrix();
    glTranslatef(0, TORUS_Y, 0);
    drawTorusShape(-PI / 2);
    glPopMatrix();
  }

  private void drawTorusShape(float d1s) {
    const int quadNumVertices = 4;
    GLfloat[4*quadNumVertices] quadColors;
    float brightness = Screen.brightness;

    foreach (i; 0..quadNumVertices) {
      quadColors[4*i + 0] = 0.3f * brightness;
      quadColors[4*i + 1] = 0.3f * brightness;
      quadColors[4*i + 2] = 0.3f * brightness;
      quadColors[4*i + 3] = (i == (quadNumVertices - 1))?0.2f:0.8f;
    }

    Vector3 cp = new Vector3;
    cp.y = 0;
    Vector3 ringOfs = new Vector3;
    float torusRad = CIRCLE_RADIUS * 0.9f;
    float ringRad;
    float d1;
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glColorPointer(4, GL_FLOAT, 0, cast(void *)(quadColors.ptr));
    ringRad = CIRCLE_RADIUS * 0.3f;
    d1 = d1s;
    for (int i = 0; i < 16; i++, d1 += PI * 2 / 32) {
      float d2 = cnt * 0.003f;
      for (int j = 0; j < 16; j++, d2 += PI * 2 / 16) {
        GLfloat[3*quadNumVertices] quadVertices;
        cp.x = sin(d1) * torusRad;
        cp.z = cos(d1) * torusRad;
        createRingOffset(ringOfs, cp, ringRad, d1, d2);
        quadVertices[0*3 + 0] = ringOfs.x;
        quadVertices[0*3 + 1] = ringOfs.y;
        quadVertices[0*3 + 2] = ringOfs.z;
        createRingOffset(ringOfs, cp, ringRad, d1, d2 + PI * 2 / 16);
        quadVertices[1*3 + 0] = ringOfs.x;
        quadVertices[1*3 + 1] = ringOfs.y;
        quadVertices[1*3 + 2] = ringOfs.z;
        cp.x = sin(d1 + PI * 2 / 32) * torusRad;
        cp.z = cos(d1 + PI * 2 / 32) * torusRad;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32, d2 + PI * 2 / 16);
        quadVertices[2*3 + 0] = ringOfs.x;
        quadVertices[2*3 + 1] = ringOfs.y;
        quadVertices[2*3 + 2] = ringOfs.z;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32, d2);
        quadVertices[3*3 + 0] = ringOfs.x;
        quadVertices[3*3 + 1] = ringOfs.y;
        quadVertices[3*3 + 2] = ringOfs.z;

        glVertexPointer(3, GL_FLOAT, 0, cast(void *)(quadVertices.ptr));
        glDrawArrays(GL_TRIANGLE_FAN, 0, quadNumVertices);
      }
    }
    glDisableClientState(GL_COLOR_ARRAY);
    const int lineNumVertices = 16*16*4;
    GLfloat[3*lineNumVertices] lineVertices;
    int lineIdx = 0;
    ringRad = CIRCLE_RADIUS * 0.3f;
    Screen.setColor(0.1f, 0.1f, 0.1f);
    d1 = d1s;
    for (int i = 0; i < 16; i++, d1 += PI * 2 / 32) {
      float d2 = cnt * 0.003f;
      for (int j = 0; j < 16; j++, d2 += PI * 2 / 16) {
        cp.x = sin(d1 + PI * 2 / 32 * 0.1f) * torusRad;
        cp.z = cos(d1 + PI * 2 / 32 * 0.1f) * torusRad;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32 * 0.1f, d2 + PI * 2 / 16 * 0.1f);
        lineVertices[lineIdx + 0] = ringOfs.x;
        lineVertices[lineIdx + 1] = ringOfs.y;
        lineVertices[lineIdx + 2] = ringOfs.z;
        lineIdx += 3;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32 * 0.1f, d2 + PI * 2 / 16 * 0.9f);
        lineVertices[lineIdx + 0] = ringOfs.x;
        lineVertices[lineIdx + 1] = ringOfs.y;
        lineVertices[lineIdx + 2] = ringOfs.z;
        lineIdx += 3;
        cp.x = sin(d1 + PI * 2 / 32 * 0.9f) * torusRad;
        cp.z = cos(d1 + PI * 2 / 32 * 0.9f) * torusRad;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32 * 0.9f, d2 + PI * 2 / 32 * 0.1f);
        lineVertices[lineIdx + 0] = ringOfs.x;
        lineVertices[lineIdx + 1] = ringOfs.y;
        lineVertices[lineIdx + 2] = ringOfs.z;
        lineIdx += 3;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32 * 0.9f, d2 + PI * 2 / 16 * 0.9f);
        lineVertices[lineIdx + 0] = ringOfs.x;
        lineVertices[lineIdx + 1] = ringOfs.y;
        lineVertices[lineIdx + 2] = ringOfs.z;
        lineIdx += 3;
      }
    }
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(lineVertices.ptr));
    glDrawArrays(GL_LINE_STRIP, 0, lineNumVertices);
    glDisableClientState(GL_VERTEX_ARRAY);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }

  public void createRingOffset(Vector3 ringOfs, Vector3 centerPos,
                               float rad, float d1, float d2) {
    ringOfs.x = 0;
    ringOfs.y = 0;
    ringOfs.z = rad;
    ringOfs.rollX(d2);
    ringOfs.rollY(-d1);
    ringOfs += centerPos;
  }

  public Vector3 eyePos() {
    return _eyePos;
  }

  public Vector size() {
    return _size;
  }
}
