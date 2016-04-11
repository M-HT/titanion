/*
 * $Id: field.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.field;

private import std.math;
private import opengl;
private import openglu;
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
    const float dSin = sin(d);
    const float dCos = cos(d);
    if (y < _size.y) {
      circlePos.x = dSin * CIRCLE_RADIUS;
      circlePos.z = dCos * CIRCLE_RADIUS;
      circlePos.y = y;
    } else if (y < _size.y * 3) {
      float cd = (y - _size.y) * PI / 2 / (_size.y * 2);
      const float cdSin = sin(cd);
      const float cdCos = cos(cd);
      float cr = CIRCLE_RADIUS * (0.8f + 0.2f * cdCos);
      circlePos.x = dSin * cr;
      circlePos.z = dCos * cr;
      circlePos.y = _size.y + cdSin * CIRCLE_RADIUS * 0.2f;
    } else if (y < _size.y * 7) {
      float cd = (y - _size.y * 3) * PI / 2 / (_size.y * 4);
      const float cdSin = sin(cd);
      const float cdCos = cos(cd);
      float cr = CIRCLE_RADIUS * (0.8f - 0.4f * cdSin);
      circlePos.x = dSin * cr;
      circlePos.z = dCos * cr;
      circlePos.y = _size.y - CIRCLE_RADIUS * 0.2f + cdCos * CIRCLE_RADIUS * 0.4f;
    } else {
      float cr = CIRCLE_RADIUS * 0.4f;
      circlePos.x = dSin * cr;
      circlePos.z = dCos * cr;
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
    const float eyeDegSin = sin(eyeDeg);
    const float eyeDegCos = cos(eyeDeg);
    _eyePos.x = eyeDegSin * CIRCLE_RADIUS * EYE_POS_DIST_RATIO;
    _eyePos.z = eyeDegCos * CIRCLE_RADIUS * EYE_POS_DIST_RATIO;
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
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen.setColor(0.25f, 0.25f, 0.25f, 0.5f);
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0, 0, 0);
    glVertex3f(SIDEWALL_WIDTH, 0, 0);
    glVertex3f(SIDEWALL_WIDTH, 480, 0);
    glVertex3f(0, 480, 0);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(640, 0, 0);
    glVertex3f(640 - SIDEWALL_WIDTH, 0, 0);
    glVertex3f(640 - SIDEWALL_WIDTH, 480, 0);
    glVertex3f(640, 480, 0);
    glEnd();
    Screen.setColor(1.0f, 1.0f, 1.0f, 0.8f);
    glBegin(GL_LINES);
    glVertex3f(SIDEWALL_WIDTH, 0, 0);
    glVertex3f(SIDEWALL_WIDTH, 480, 0);
    glVertex3f(640 - SIDEWALL_WIDTH, 0, 0);
    glVertex3f(640 - SIDEWALL_WIDTH, 480, 0);
    glEnd();
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
    Vector3 cp = new Vector3;
    cp.y = 0;
    Vector3 ringOfs = new Vector3;
    float torusRad = CIRCLE_RADIUS * 0.9f;
    float ringRad;
    float d1;
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBegin(GL_QUADS);
    ringRad = CIRCLE_RADIUS * 0.3f;
    d1 = d1s;
    for (int i = 0; i < 16; i++, d1 += PI * 2 / 32) {
      float d2 = cnt * 0.003f;
      const float d1Sin0 = sin(d1);
      const float d1Cos0 = cos(d1);
      const float d1Sin0TR = d1Sin0 * torusRad;
      const float d1Cos0TR = d1Cos0 * torusRad;
      const float d1Sin1 = sin(d1 + cast(float)(PI * 2 / 32));
      const float d1Cos1 = cos(d1 + cast(float)(PI * 2 / 32));
      const float d1Sin1TR = d1Sin1 * torusRad;
      const float d1Cos1TR = d1Cos1 * torusRad;
      for (int j = 0; j < 16; j++, d2 += PI * 2 / 16) {
        cp.x = d1Sin0TR;
        cp.z = d1Cos0TR;
        createRingOffset(ringOfs, cp, ringRad, d1, d2);
        Screen.setColor(0.3f, 0.3f, 0.3f, 0.8f);
        Screen.glVertex(ringOfs);
        createRingOffset(ringOfs, cp, ringRad, d1, d2 + PI * 2 / 16);
        Screen.glVertex(ringOfs);
        cp.x = d1Sin1TR;
        cp.z = d1Cos1TR;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32, d2 + PI * 2 / 16);
        Screen.glVertex(ringOfs);
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32, d2);
        Screen.setColor(0.3f, 0.3f, 0.3f, 0.2f);
        Screen.glVertex(ringOfs);
      }
    }
    glEnd();
    glBegin(GL_LINE_STRIP);
    ringRad = CIRCLE_RADIUS * 0.3f;
    Screen.setColor(0.1f, 0.1f, 0.1f);
    d1 = d1s;
    for (int i = 0; i < 16; i++, d1 += PI * 2 / 32) {
      float d2 = cnt * 0.003f;
      const float d1Sin2 = sin(d1 + cast(float)(PI * 2 / 32 * 0.1f));
      const float d1Cos2 = cos(d1 + cast(float)(PI * 2 / 32 * 0.1f));
      const float d1Sin2TR = d1Sin2 * torusRad;
      const float d1Cos2TR = d1Cos2 * torusRad;
      const float d1Sin3 = sin(d1 + cast(float)(PI * 2 / 32 * 0.9f));
      const float d1Cos3 = cos(d1 + cast(float)(PI * 2 / 32 * 0.9f));
      const float d1Sin3TR = d1Sin3 * torusRad;
      const float d1Cos3TR = d1Cos3 * torusRad;
      for (int j = 0; j < 16; j++, d2 += PI * 2 / 16) {
        cp.x = d1Sin2TR;
        cp.z = d1Cos2TR;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32 * 0.1f, d2 + PI * 2 / 16 * 0.1f);
        Screen.glVertex(ringOfs);
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32 * 0.1f, d2 + PI * 2 / 16 * 0.9f);
        Screen.glVertex(ringOfs);
        cp.x = d1Sin3TR;
        cp.z = d1Cos3TR;
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32 * 0.9f, d2 + PI * 2 / 32 * 0.1f);
        Screen.glVertex(ringOfs);
        createRingOffset(ringOfs, cp, ringRad, d1 + PI * 2 / 32 * 0.9f, d2 + PI * 2 / 16 * 0.9f);
        Screen.glVertex(ringOfs);
      }
    }
    glEnd();
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
