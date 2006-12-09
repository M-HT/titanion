/*
 * $Id: shape.d,v 1.5 2006/12/04 16:04:27 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.shape;

private import std.math;
private import opengl;
private import abagames.util.vector;
private import abagames.util.sdl.displaylist;
private import abagames.ttn.screen;
private import abagames.ttn.field;

/**
 * 3D shapes of a player, enemies, particles, etc.
 */
public interface Shape {
  public void draw(Vector3 pos, float cd, float deg);
}

public class DisplayListShape: Shape {
 private:
  DisplayList displayList;

  public this() {
    displayList = new DisplayList(1);
    displayList.beginNewList();
    drawList();
    displayList.endNewList();
  }

  protected abstract void drawList();

  public void draw() {
    drawList();
  }

  public void draw(Vector3 pos, float cd, float deg) {
    glPushMatrix();
    Screen.glTranslate(pos);
    glRotatef(cd * 180 / PI, 0, 1, 0);
    Screen.glRotate(deg);
    displayList.call();
    glPopMatrix();
  }

  public void close() {
    displayList.close();
  }
}

public class PyramidShape {
 private:

  public static void draw() {
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0, 0, 0);
    glVertex3f(1, 1, 1);
    glVertex3f(1, 1, -1);
    glVertex3f(-1, 1, -1);
    glVertex3f(-1, 1, 1);
    glVertex3f(1, 1, 1);
    glEnd();
    Screen.setColor(0.1f, 0.1f, 0.1f, 0.5f);
    glBegin(GL_LINE_STRIP);
    glVertex3f(0, 0, 0);
    glVertex3f(1, 1, 1);
    glVertex3f(1, 1, -1);
    glVertex3f(0, 0, 0);
    glVertex3f(-1, 1, -1);
    glVertex3f(-1, 1, 1);
    glVertex3f(0, 0, 0);
    glEnd();
    glBegin(GL_LINES);
    glVertex3f(1, 1, 1);
    glVertex3f(-1, 1, 1);
    glVertex3f(1, 1, -1);
    glVertex3f(-1, 1, -1);
    glEnd();
  }

  public static void drawShadow(float r, float g, float b, bool noAlpha = false) {
    glBegin(GL_TRIANGLE_FAN);
    Screen.setColor(r, g, b);
    glVertex3f(0, 0, 0);
    if (!noAlpha)
      Screen.setColor(r * 0.75f, g * 0.75f, b * 0.75f, 0.33f);
    else
      Screen.setColor(r * 0.75f, g * 0.75f, b * 0.75f, 0.75f);
    glVertex3f(1, 1, 1);
    glVertex3f(1, 1, -1);
    glVertex3f(-1, 1, -1);
    glVertex3f(-1, 1, 1);
    glVertex3f(1, 1, 1);
    glEnd();
  }

  public static void drawPolygonShape() {
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0, 0, 0);
    glVertex3f(1, 1, 1);
    glVertex3f(1, 1, -1);
    glVertex3f(-1, 1, -1);
    glVertex3f(-1, 1, 1);
    glVertex3f(1, 1, 1);
    glEnd();
  }

  public static void drawLineShape() {
    glBegin(GL_LINE_STRIP);
    glVertex3f(0, 0, 0);
    glVertex3f(1, 1, 1);
    glVertex3f(1, 1, -1);
    glVertex3f(0, 0, 0);
    glVertex3f(-1, 1, -1);
    glVertex3f(-1, 1, 1);
    glVertex3f(0, 0, 0);
    glEnd();
    glBegin(GL_LINES);
    glVertex3f(1, 1, 1);
    glVertex3f(-1, 1, 1);
    glVertex3f(1, 1, -1);
    glVertex3f(-1, 1, -1);
    glEnd();
  }
}

public class PlayerShape: DisplayListShape {
 private:

  protected override void drawList() {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(0, -0.6f, 0);
    glScalef(0.4f, 1.3f, 0.4f);
    PyramidShape.drawShadow(1, 0.5f, 0.5f, true);
    glPopMatrix();
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(0.5f, -0.2f, 0);
    glScalef(0.3f, 0.9f, 0.3f);
    PyramidShape.drawShadow(1, 1, 1, true);
    glPopMatrix();
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(-0.5f, -0.2f, 0);
    glScalef(0.3f, 0.9f, 0.3f);
    PyramidShape.drawShadow(1, 1, 1, true);
    glPopMatrix();
    Screen.setColor(1, 0.5f, 0.5f);
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(0, -0.6f, 0);
    glScalef(0.3f, 1.2f, 0.3f);
    PyramidShape.drawPolygonShape();
    glPopMatrix();
    Screen.setColor(1, 1, 1);
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(0.5f, -0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.drawPolygonShape();
    glPopMatrix();
    Screen.setColor(1, 1, 1);
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(-0.5f, -0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.drawPolygonShape();
    glPopMatrix();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }
}

public class PlayerLineShape: DisplayListShape {
 private:

  protected override void drawList() {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(0, -0.6f, 0);
    glScalef(0.3f, 1.2f, 0.3f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(0.5f, -0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(-0.5f, -0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }
}

public class ShotShape: DisplayListShape {
 private:

  protected override void drawList() {
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(0.5f, -0.5f, 0);
    glScalef(0.1f, 1.0f, 0.1f);
    Screen.setColor(0.4f, 0.2f, 0.8f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(180, 0, 0, 1);
    glTranslatef(-0.5f, -0.5f, 0);
    glScalef(0.1f, 1.0f, 0.1f);
    Screen.setColor(0.4f, 0.2f, 0.8f);
    PyramidShape.drawLineShape();
    glPopMatrix();
  }
}

public class TractorBeamShape: DisplayListShape {
 private:

  protected void drawTractorBeam(float r, float g, float b) {
    Screen.setColor(r, g, b, 0.5f);
    glBegin(GL_QUADS);
    glVertex3f(-1, 0, -1);
    glVertex3f(1, 0, -1);
    glVertex3f(1, 0, 1);
    glVertex3f(-1, 0, 1);
    glEnd();
    Screen.setColor(r, g, b);
    glBegin(GL_LINE_LOOP);
    glVertex3f(-1, 0, -1);
    glVertex3f(1, 0, -1);
    glVertex3f(1, 0, 1);
    glVertex3f(-1, 0, 1);
    glEnd();
  }

  protected void drawTractorBeamLine(float r, float g, float b) {
    Screen.setColor(r, g, b);
    glBegin(GL_LINE_LOOP);
    glVertex3f(-1, 0, -1);
    glVertex3f(1, 0, -1);
    glVertex3f(1, 0, 1);
    glVertex3f(-1, 0, 1);
    glEnd();
  }
}

public class TractorBeamShapeRed: TractorBeamShape {
 private:

  protected override void drawList() {
    drawTractorBeam(0.5f, 0.2f, 0.2f);
  }
}

public class TractorBeamShapeBlue: TractorBeamShape {
 private:

  protected override void drawList() {
    drawTractorBeam(0.2f, 0.2f, 0.5f);
  }
}

public class TractorBeamShapePurple: TractorBeamShape {
 private:

  protected override void drawList() {
    drawTractorBeam(0.5f, 0.2f, 0.5f);
  }
}

public class TractorBeamShapeDarkRed: TractorBeamShape {
 private:

  protected override void drawList() {
    drawTractorBeamLine(0.4f, 0.1f, 0.1f);
  }
}

public class TractorBeamShapeDarkBlue: TractorBeamShape {
 private:

  protected override void drawList() {
    drawTractorBeamLine(0.1f, 0.1f, 0.4f);
  }
}

public class TractorBeamShapeDarkPurple: TractorBeamShape {
 private:

  protected override void drawList() {
    drawTractorBeamLine(0.4f, 0.1f, 0.4f);
  }
}

public class BulletShapeBase: DisplayListShape {
 private:

  public void draw(Vector3 pos, float cd, float deg, float rd) {
    glPushMatrix();
    Screen.glTranslate(pos);
    glRotatef(cd * 180 / PI, 0, 1, 0);
    Screen.glRotate(deg);
    glRotatef(rd, 0, 1, 0);
    displayList.call();
    glPopMatrix();
  }
}

public class BulletShape: BulletShapeBase {
 private:

  protected override void drawList() {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen.setColor(0, 0, 0);
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glEnd();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glScalef(1.2f, 1.2f, 1.2f);
    Screen.setColor(0.1f, 0.3f, 0.3f);
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glEnd();
  }
}

public class BulletLineShape: BulletShapeBase {
 private:

  protected override void drawList() {
    glScalef(1.2f, 1.2f, 1.2f);
    glBegin(GL_LINES);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(0, -0.3f, 0.4f);
    glEnd();
    glBegin(GL_LINE_LOOP);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glEnd();
  }
}

public class MiddleBulletShape: BulletShapeBase {
 private:

  protected override void drawList() {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glScalef(1.1f, 1.0f, 1.1f);
    Screen.setColor(0, 0, 0);
    glBegin(GL_QUADS);
    glVertex3f(-0.17f, 0.3f, -0.1f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0.17f, 0.3f, -0.1f);
    glVertex3f(0.17f, 0.3f, -0.1f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glVertex3f(0, 0.3f, 0.2f);
    glVertex3f(0, 0.3f, 0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(-0.17f, 0.3f, -0.1f);
    glEnd();
    glBegin(GL_TRIANGLES);
    glVertex3f(-0.17f, -0.3f, -0.1f);
    glVertex3f(0.17f, -0.3f, -0.1f);
    glVertex3f(0, -0.3f, 0.2f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glEnd();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glScalef(1.4f, 1.3f, 1.4f);
    Screen.setColor(0.1f, 0.2f, 0.3f);
    glBegin(GL_QUADS);
    glVertex3f(-0.17f, 0.3f, -0.1f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0.17f, 0.3f, -0.1f);
    glVertex3f(0.17f, 0.3f, -0.1f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glVertex3f(0, 0.3f, 0.2f);
    glVertex3f(0, 0.3f, 0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(-0.17f, 0.3f, -0.1f);
    glEnd();
    glBegin(GL_TRIANGLES);
    glVertex3f(-0.17f, 0.3f, -0.1f);
    glVertex3f(0.17f, 0.3f, -0.1f);
    glVertex3f(0, 0.3f, 0.2f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glEnd();
  }
}

public class MiddleBulletLineShape: BulletShapeBase {
 private:

  protected override void drawList() {
    glScalef(1.4f, 1.3f, 1.4f);
    glBegin(GL_LINES);
    glVertex3f(-0.17f, 0.3f, -0.1f);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.17f, 0.3f, -0.1f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, 0.3f, 0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glEnd();
    glBegin(GL_LINE_LOOP);
    glVertex3f(-0.17f, 0.3f, -0.1f);
    glVertex3f(0.17f, 0.3f, -0.1f);
    glVertex3f(0, 0.3f, 0.2f);
    glEnd();
    glBegin(GL_LINE_LOOP);
    glVertex3f(-0.34f, -0.3f, -0.2f);
    glVertex3f(0.34f, -0.3f, -0.2f);
    glVertex3f(0, -0.3f, 0.4f);
    glEnd();
  }
}

public class RollBulletShapeBase: BulletShapeBase {
 private:

  public override void draw(Vector3 pos, float cd, float deg, float rd) {
    glPushMatrix();
    Screen.glTranslate(pos);
    glRotatef(cd * 180 / PI, 0, 1, 0);
    glRotatef(rd, 0, 0, 1);
    displayList.call();
    glPopMatrix();
  }
}

public class CounterBulletShape: RollBulletShapeBase {
 private:

  protected override void drawList() {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen.setColor(0, 0, 0);
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0, 0, 0.5f);
    glVertex3f(0.5f, 0, 0);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(-0.5f, 0, 0);
    glVertex3f(0, -0.5f, 0);
    glVertex3f(0.5f, 0, 0);
    glEnd();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glScalef(1.2f, 1.2f, 1.2f);
    Screen.setColor(0.5f, 0.5f, 0.5f);
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0, 0, 0.5f);
    glVertex3f(0.5f, 0, 0);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(-0.5f, 0, 0);
    glVertex3f(0, -0.5f, 0);
    glVertex3f(0.5f, 0, 0);
    glEnd();
  }
}

public class CounterBulletLineShape: RollBulletShapeBase {
 private:

  protected override void drawList() {
    glScalef(1.2f, 1.2f, 1.2f);
    glBegin(GL_LINE_LOOP);
    glVertex3f(0.5f, 0, 0);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(-0.5f, 0, 0);
    glVertex3f(0, -0.5f, 0);
    glEnd();
    glBegin(GL_LINES);
    glVertex3f(0, 0, 0.5f);
    glVertex3f(0.5f, 0, 0);
    glVertex3f(0, 0, 0.5f);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(0, 0, 0.5f);
    glVertex3f(-0.5f, 0, 0);
    glVertex3f(0, 0, 0.5f);
    glVertex3f(0, -0.5f, 0);
    glEnd();
  }
}

public class EnemyShape: DisplayListShape {
 private:

  public void draw(Vector3 pos, float cd, float deg, float cnt, Vector size) {
    draw(pos, cd, deg, cnt, size.x, size.y);
  }

  public void draw(Vector3 pos, float cd, float deg, float cnt, float sx, float sy) {
    glPushMatrix();
    Screen.glTranslate(pos);
    glRotatef(cd * 180 / PI, 0, 1, 0);
    Screen.glRotate(deg);
    glScalef(sx, sy, 1);
    glRotatef(cnt * 3.0f, 0, 1, 0);
    displayList.call();
    glPopMatrix();
  }
}

public class Enemy1Shape: EnemyShape {
 private:

  protected override void drawList() {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glPushMatrix();
    glTranslatef(0, -0.6f, 0);
    glScalef(0.5f, 1.4f, 0.5f);
    PyramidShape.drawShadow(0.5f, 0.5f, 0.3f);
    glPopMatrix();
    glPushMatrix();
    glRotatef(120, 0, 0, 1);
    glTranslatef(0.5f, -0.2f, 0);
    glScalef(0.4f, 1.0f, 0.4f);
    PyramidShape.drawShadow(0.2f, 0.2f, 0.5f);
    glPopMatrix();
    Screen.setColor(0.2f, 0.2f, 0.5f);
    glPushMatrix();
    glRotatef(240, 0, 0, 1);
    glTranslatef(-0.5f, -0.2f, 0);
    glScalef(0.4f, 1.0f, 0.4f);
    PyramidShape.drawShadow(0.2f, 0.2f, 0.5f);
    glPopMatrix();
    Screen.setColor(1, 1, 0.6f);
    glPushMatrix();
    glTranslatef(0, -0.6f, 0);
    glScalef(0.3f, 1.2f, 0.3f);
    PyramidShape.draw();
    glPopMatrix();
    Screen.setColor(0.5f, 0.5f, 1);
    glPushMatrix();
    glRotatef(120, 0, 0, 1);
    glTranslatef(0.5f, -0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.draw();
    glPopMatrix();
    Screen.setColor(0.5f, 0.5f, 1);
    glPushMatrix();
    glRotatef(240, 0, 0, 1);
    glTranslatef(-0.5f, -0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.draw();
    glPopMatrix();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }
}

public class Enemy1TrailShape: EnemyShape {
 private:

  protected override void drawList() {
    glPushMatrix();
    glTranslatef(0, -0.6f, 0);
    glScalef(0.3f, 1.2f, 0.3f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(120, 0, 0, 1);
    glTranslatef(0.5f, -0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(240, 0, 0, 1);
    glTranslatef(-0.5f, -0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.drawLineShape();
    glPopMatrix();
  }
}

public class Enemy2Shape: EnemyShape {
 private:

  protected override void drawList() {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glPushMatrix();
    glTranslatef(0, -0.5f, 0);
    glScalef(0.5f, 1.2f, 0.5f);
    PyramidShape.drawShadow(0.5f, 0.4f, 0.5f);
    glPopMatrix();
    glPushMatrix();
    glRotatef(60, 0, 0, 1);
    glTranslatef(0.6f, -0.7f, 0);
    glScalef(0.4f, 1.4f, 0.4f);
    PyramidShape.drawShadow(0.9f, 0.6f, 0.5f);
    glPopMatrix();
    glPushMatrix();
    glRotatef(300, 0, 0, 1);
    glTranslatef(-0.6f, -0.7f, 0);
    glScalef(0.4f, 1.4f, 0.4f);
    PyramidShape.drawShadow(0.9f, 0.6f, 0.5f);
    glPopMatrix();
    Screen.setColor(1, 0.9f, 1.0f);
    glPushMatrix();
    glTranslatef(0, -0.5f, 0);
    glScalef(0.3f, 1.0f, 0.3f);
    PyramidShape.draw();
    glPopMatrix();
    Screen.setColor(0.9f, 0.6f, 0.5f);
    glPushMatrix();
    glRotatef(60, 0, 0, 1);
    glTranslatef(0.6f, -0.7f, 0);
    glScalef(0.2f, 1.2f, 0.2f);
    PyramidShape.draw();
    glPopMatrix();
    Screen.setColor(0.9f, 0.6f, 0.5f);
    glPushMatrix();
    glRotatef(300, 0, 0, 1);
    glTranslatef(-0.6f, -0.7f, 0);
    glScalef(0.2f, 1.2f, 0.2f);
    PyramidShape.draw();
    glPopMatrix();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }
}

public class Enemy2TrailShape: EnemyShape {
 private:

  protected override void drawList() {
    glPushMatrix();
    glTranslatef(0, -0.5f, 0);
    glScalef(0.3f, 1.0f, 0.3f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(60, 0, 0, 1);
    glTranslatef(0.6f, -0.7f, 0);
    glScalef(0.2f, 1.2f, 0.2f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(300, 0, 0, 1);
    glTranslatef(-0.6f, -0.7f, 0);
    glScalef(0.2f, 1.2f, 0.2f);
    PyramidShape.drawLineShape();
    glPopMatrix();
  }
}

public class Enemy3Shape: EnemyShape {
 private:

  protected override void drawList() {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glPushMatrix();
    glTranslatef(0, -0.4f, 0);
    glScalef(0.5f, 1.4f, 0.5f);
    PyramidShape.drawShadow(0.5f, 0.5f, 0.3f);
    glPopMatrix();
    glPushMatrix();
    glRotatef(150, 0, 0, 1);
    glTranslatef(0.5f, 0.2f, 0);
    glScalef(0.4f, 1.0f, 0.4f);
    PyramidShape.drawShadow(0.2f, 0.2f, 0.5f);
    glPopMatrix();
    Screen.setColor(0.2f, 0.2f, 0.5f);
    glPushMatrix();
    glRotatef(210, 0, 0, 1);
    glTranslatef(-0.5f, 0.2f, 0);
    glScalef(0.4f, 1.0f, 0.4f);
    PyramidShape.drawShadow(0.2f, 0.2f, 0.5f);
    glPopMatrix();
    Screen.setColor(1, 0.6f, 0.9f);
    glPushMatrix();
    glTranslatef(0, -0.4f, 0);
    glScalef(0.3f, 1.2f, 0.3f);
    PyramidShape.draw();
    glPopMatrix();
    Screen.setColor(0.3f, 0.5f, 1);
    glPushMatrix();
    glRotatef(150, 0, 0, 1);
    glTranslatef(0.5f, 0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.draw();
    glPopMatrix();
    Screen.setColor(0.3f, 0.5f, 1);
    glPushMatrix();
    glRotatef(210, 0, 0, 1);
    glTranslatef(-0.5f, 0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.draw();
    glPopMatrix();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }
}

public class Enemy3TrailShape: EnemyShape {
 private:

  protected override void drawList() {
    glPushMatrix();
    glTranslatef(0, -0.4f, 0);
    glScalef(0.3f, 1.2f, 0.3f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(150, 0, 0, 1);
    glTranslatef(0.5f, 0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.drawLineShape();
    glPopMatrix();
    glPushMatrix();
    glRotatef(210, 0, 0, 1);
    glTranslatef(-0.5f, 0.2f, 0);
    glScalef(0.2f, 0.8f, 0.2f);
    PyramidShape.drawLineShape();
    glPopMatrix();
  }
}

public class TriangleParticleShape: DisplayListShape {
 private:

  protected override void drawList() {
    glBegin(GL_LINE_LOOP);
    glVertex3f(0, 0.5f, 0);
    glVertex3f(0.4f, -0.3f, 0);
    glVertex3f(-0.4f, -0.3f, 0);
    glEnd();
  }
}

public class PillarShape: DisplayListShape {
 public:
  static const float TICKNESS = 4.0f;
 private:
  static const float RADIUS_RATIO = 0.3f;

  protected void drawPillar(float r, float g, float b, bool outside = false) {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBegin(GL_QUADS);
    Screen.setColor(r, g, b);
    for (int i = 0; i < 8; i++) {
      float d = PI * 2 * i / 8;
      glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      d += PI * 2 / 8;
      glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 -TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      d -= PI * 2 / 8;
      glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 -TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
    }
    glEnd();
    if (!outside) {
      Screen.setColor(r, g, b);
      glBegin(GL_TRIANGLES);
      for (int i = 0; i < 8; i++) {
        float d = PI * 2 * i / 8;
        glVertex3f(0, TICKNESS, 0);
        glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                   TICKNESS,
                   cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
        d += PI * 2 / 8;
        glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                   TICKNESS,
                   cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
        d -= PI * 2 / 8;
        glVertex3f(0, -TICKNESS, 0);
        glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                   -TICKNESS,
                   cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
        d += PI * 2 / 8;
        glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                   -TICKNESS,
                   cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      }
      glEnd();
    }
    Screen.setColor(0.1f, 0.1f, 0.1f);
    for (int i = 0; i < 8; i++) {
      float d = PI * 2 * i / 8; 
      glBegin(GL_LINE_STRIP);
      glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      d += PI * 2 / 8;
      glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 -TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      d -= PI * 2 / 8;
      glVertex3f(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 -TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      glEnd();
    }
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }

  public void draw(float y, float deg) {
    glPushMatrix();
    glTranslatef(0, y, 0);
    glRotatef(deg * 180 / PI, 0, 1, 0);
    displayList.call();
    glPopMatrix();
  }
}

public class Pillar1Shape: PillarShape {
 private:

  protected override void drawList() {
    glScalef(0.6f, 1.0f, 0.6f);
    drawPillar(0.5f, 0.4f, 0.4f);
  }
}

public class Pillar2Shape: PillarShape {
 private:

  protected override void drawList() {
    glScalef(0.8f, 1.0f, 0.8f);
    drawPillar(0.6f, 0.3f, 0.3f);
  }
}

public class Pillar3Shape: PillarShape {
 private:

  protected override void drawList() {
    drawPillar(0.5f, 0.5f, 0.4f);
  }
}

public class Pillar4Shape: PillarShape {
 private:

  protected override void drawList() {
    glScalef(1.1f, 1.0f, 1.1f);
    drawPillar(0.5f, 0.4f, 0.5f);
  }
}

public class OutsidePillarShape: PillarShape {
 private:

  protected override void drawList() {
    glScalef(7.0f, 3.0f, 7.0f);
    drawPillar(0.2f, 0.2f, 0.3f, true);
  }
}
