/*
 * $Id: shape.d,v 1.5 2006/12/04 16:04:27 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.shape;

private import std.math;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
private import abagames.util.vector;
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
  int currentIdx, firstColorIdx, startBlendIdx, endBlendIdx;
  GLfloat[4] color;
  GLfloat scaleX, scaleY, scaleZ;
  GLenum[] shapeTypes;
  GLfloat[][] shapeVertices;
  GLfloat[][] shapeColors;

  public this() {
    currentIdx = -1;
    firstColorIdx = -1;
    startBlendIdx = -1;
    endBlendIdx = -1;
    color[0] = 1;
    color[1] = 1;
    color[2] = 1;
    color[3] = 1;
    scaleX = 1;
    scaleY = 1;
    scaleZ = 1;
    prepareShape();
  }

  protected abstract void prepareShape();

  protected void drawShape() {
    glEnableClientState(GL_VERTEX_ARRAY);

    foreach(idx; 0..shapeTypes.length) {
      if (idx == startBlendIdx) {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      }

      if (idx == firstColorIdx) {
        glEnableClientState(GL_COLOR_ARRAY);
      }

      if (idx >= firstColorIdx && firstColorIdx >= 0) {
        glColorPointer(4, GL_FLOAT, 0, cast(void *)(shapeColors[idx].ptr));
      }

      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices[idx].ptr));

      glDrawArrays(shapeTypes[idx], 0, cast(int)(shapeVertices[idx].length / 3));

      if (idx == endBlendIdx) {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      }
    }

    if (firstColorIdx >= 0) {
      glDisableClientState(GL_COLOR_ARRAY);
    }

    glDisableClientState(GL_VERTEX_ARRAY);
  }

  protected void prepareAddPart(GLenum type) {
    ++currentIdx;
    shapeTypes.length = currentIdx + 1;
    shapeVertices.length = currentIdx + 1;
    shapeColors.length = currentIdx + 1;

    shapeTypes[currentIdx] = type;
  }

  protected void prepareSetColor(float r, float g, float b, float a = 1) {
    float brightness = Screen.brightness;
    color[0] = r * brightness;
    color[1] = g * brightness;
    color[2] = b * brightness;
    color[3] = a;
    if (firstColorIdx < 0) {
      firstColorIdx = currentIdx + 1;
    }
  }

  protected void prepareStartBlend() {
    startBlendIdx = currentIdx + 1;
  }

  protected void prepareEndBlend() {
    endBlendIdx = currentIdx;
  }

  protected void prepareAddScale(float x, float y, float z) {
    scaleX *= x;
    scaleY *= y;
    scaleZ *= z;
  }

  protected void prepareAddVertex(float x, float y, float z) {
    GLfloat[3] vertex = [x * scaleX, y * scaleY, z * scaleZ];

    shapeVertices[currentIdx] ~= vertex;
    if (firstColorIdx >= 0) {
      shapeColors[currentIdx] ~= color;
    }
  }


  public void draw() {
    drawShape();
  }

  public void draw(Vector3 pos, float cd, float deg) {
    glPushMatrix();
    Screen.glTranslate(pos);
    glRotatef(cd * 180 / PI, 0, 1, 0);
    Screen.glRotate(deg);
    drawShape();
    glPopMatrix();
  }

  public void close() {
  }
}

public class PyramidShape: DisplayListShape {
 private:
  GLfloat pScaleX, pScaleY, pScaleZ;
  GLfloat pTranslateX, pTranslateY, pTranslateZ;
  GLfloat pRotateDegC, pRotateDegS;

  protected void preparePyramidSetScale(float x, float y, float z) {
    pScaleX = x;
    pScaleY = y;
    pScaleZ = z;
  }

  protected void preparePyramidSetTranslate(float x, float y, float z) {
    pTranslateX = x;
    pTranslateY = y;
    pTranslateZ = z;
  }

  protected void preparePyramidSetRotateAngle(float deg) {
    if (deg == 0) {
      pRotateDegC = 1;
      pRotateDegS = 0;
    } else {
      pRotateDegC = cos(deg * std.math.PI / 180);
      pRotateDegS = sin(deg * std.math.PI / 180);
    }
  }

  private void preparePyramidAddVertex(float x, float y, float z) {
    x = (x * pScaleX) + pTranslateX;
    y = (y * pScaleY) + pTranslateY;
    z = (z * pScaleZ) + pTranslateZ;

    prepareAddVertex(pRotateDegC * x - pRotateDegS * y, pRotateDegS * x + pRotateDegC * y, z);
  }


  protected void preparePyramidDraw() {
    prepareAddPart(GL_TRIANGLE_FAN);
    preparePyramidAddVertex(0, 0, 0);
    preparePyramidAddVertex(1, 1, 1);
    preparePyramidAddVertex(1, 1, -1);
    preparePyramidAddVertex(-1, 1, -1);
    preparePyramidAddVertex(-1, 1, 1);
    preparePyramidAddVertex(1, 1, 1);

    prepareSetColor(0.1f, 0.1f, 0.1f, 0.5f);
    prepareAddPart(GL_LINE_STRIP);
    preparePyramidAddVertex(0, 0, 0);
    preparePyramidAddVertex(1, 1, 1);
    preparePyramidAddVertex(1, 1, -1);
    preparePyramidAddVertex(0, 0, 0);
    preparePyramidAddVertex(-1, 1, -1);
    preparePyramidAddVertex(-1, 1, 1);
    preparePyramidAddVertex(0, 0, 0);

    prepareAddPart(GL_LINES);
    preparePyramidAddVertex(1, 1, 1);
    preparePyramidAddVertex(-1, 1, 1);
    preparePyramidAddVertex(1, 1, -1);
    preparePyramidAddVertex(-1, 1, -1);
  }

  protected void preparePyramidDrawShadow(float r, float g, float b, bool noAlpha = false) {
    prepareSetColor(r, g, b);
    prepareAddPart(GL_TRIANGLE_FAN);
    preparePyramidAddVertex(0, 0, 0);
    if (!noAlpha)
      prepareSetColor(r * 0.75f, g * 0.75f, b * 0.75f, 0.33f);
    else
      prepareSetColor(r * 0.75f, g * 0.75f, b * 0.75f, 0.75f);
    preparePyramidAddVertex(1, 1, 1);
    preparePyramidAddVertex(1, 1, -1);
    preparePyramidAddVertex(-1, 1, -1);
    preparePyramidAddVertex(-1, 1, 1);
    preparePyramidAddVertex(1, 1, 1);
  }

  protected void preparePyramidDrawPolygonShape() {
    prepareAddPart(GL_TRIANGLE_FAN);
    preparePyramidAddVertex(0, 0, 0);
    preparePyramidAddVertex(1, 1, 1);
    preparePyramidAddVertex(1, 1, -1);
    preparePyramidAddVertex(-1, 1, -1);
    preparePyramidAddVertex(-1, 1, 1);
    preparePyramidAddVertex(1, 1, 1);
  }

  protected void preparePyramidDrawLineShape() {
    prepareAddPart(GL_LINE_STRIP);
    preparePyramidAddVertex(0, 0, 0);
    preparePyramidAddVertex(1, 1, 1);
    preparePyramidAddVertex(1, 1, -1);
    preparePyramidAddVertex(0, 0, 0);
    preparePyramidAddVertex(-1, 1, -1);
    preparePyramidAddVertex(-1, 1, 1);
    preparePyramidAddVertex(0, 0, 0);

    prepareAddPart(GL_LINES);
    preparePyramidAddVertex(1, 1, 1);
    preparePyramidAddVertex(-1, 1, 1);
    preparePyramidAddVertex(1, 1, -1);
    preparePyramidAddVertex(-1, 1, -1);
  }
}

public class PlayerShape: PyramidShape {
 private:

  protected override void prepareShape() {
    prepareStartBlend();
    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(0, -0.6f, 0);
    preparePyramidSetScale(0.4f, 1.3f, 0.4f);
    preparePyramidDrawShadow(1, 0.5f, 0.5f, true);

    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(0.5f, -0.2f, 0);
    preparePyramidSetScale(0.3f, 0.9f, 0.3f);
    preparePyramidDrawShadow(1, 1, 1, true);

    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(-0.5f, -0.2f, 0);
    preparePyramidSetScale(0.3f, 0.9f, 0.3f);
    preparePyramidDrawShadow(1, 1, 1, true);

    prepareSetColor(1, 0.5f, 0.5f);
    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(0, -0.6f, 0);
    preparePyramidSetScale(0.3f, 1.2f, 0.3f);
    preparePyramidDrawPolygonShape();

    prepareSetColor(1, 1, 1);
    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(0.5f, -0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDrawPolygonShape();

    prepareSetColor(1, 1, 1);
    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(-0.5f, -0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDrawPolygonShape();
    prepareEndBlend();
  }
}

public class PlayerLineShape: PyramidShape {
 private:

  protected override void prepareShape() {
    prepareStartBlend();
    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(0, -0.6f, 0);
    preparePyramidSetScale(0.3f, 1.2f, 0.3f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(0.5f, -0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(-0.5f, -0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDrawLineShape();
    prepareEndBlend();
  }
}

public class ShotShape: PyramidShape {
 private:

  protected override void prepareShape() {
    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(0.5f, -0.5f, 0);
    preparePyramidSetScale(0.1f, 1.0f, 0.1f);
    prepareSetColor(0.4f, 0.2f, 0.8f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(180);
    preparePyramidSetTranslate(-0.5f, -0.5f, 0);
    preparePyramidSetScale(0.1f, 1.0f, 0.1f);
    prepareSetColor(0.4f, 0.2f, 0.8f);
    preparePyramidDrawLineShape();
  }
}

public class TractorBeamShape: DisplayListShape {
 private:

  protected void prepareTractorBeam(float r, float g, float b) {
    prepareSetColor(r, g, b, 0.5f);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(-1, 0, -1);
    prepareAddVertex(1, 0, -1);
    prepareAddVertex(1, 0, 1);
    prepareAddVertex(-1, 0, 1);

    prepareSetColor(r, g, b);
    prepareAddPart(GL_LINE_LOOP);
    prepareAddVertex(-1, 0, -1);
    prepareAddVertex(1, 0, -1);
    prepareAddVertex(1, 0, 1);
    prepareAddVertex(-1, 0, 1);
  }

  protected void prepareTractorBeamLine(float r, float g, float b) {
    prepareSetColor(r, g, b);
    prepareAddPart(GL_LINE_LOOP);
    prepareAddVertex(-1, 0, -1);
    prepareAddVertex(1, 0, -1);
    prepareAddVertex(1, 0, 1);
    prepareAddVertex(-1, 0, 1);
  }
}

public class TractorBeamShapeRed: TractorBeamShape {
 private:

  protected override void prepareShape() {
    prepareTractorBeam(0.5f, 0.2f, 0.2f);
  }
}

public class TractorBeamShapeBlue: TractorBeamShape {
 private:

  protected override void prepareShape() {
    prepareTractorBeam(0.2f, 0.2f, 0.5f);
  }
}

public class TractorBeamShapePurple: TractorBeamShape {
 private:

  protected override void prepareShape() {
    prepareTractorBeam(0.5f, 0.2f, 0.5f);
  }
}

public class TractorBeamShapeDarkRed: TractorBeamShape {
 private:

  protected override void prepareShape() {
    prepareTractorBeamLine(0.4f, 0.1f, 0.1f);
  }
}

public class TractorBeamShapeDarkBlue: TractorBeamShape {
 private:

  protected override void prepareShape() {
    prepareTractorBeamLine(0.1f, 0.1f, 0.4f);
  }
}

public class TractorBeamShapeDarkPurple: TractorBeamShape {
 private:

  protected override void prepareShape() {
    prepareTractorBeamLine(0.4f, 0.1f, 0.4f);
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
    drawShape();
    glPopMatrix();
  }
}

public class BulletShape: BulletShapeBase {
 private:

  protected override void prepareShape() {
    prepareStartBlend();
    prepareSetColor(0, 0, 0);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);

    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);

    prepareEndBlend();
    prepareAddScale(1.2f, 1.2f, 1.2f);
    prepareSetColor(0.1f, 0.3f, 0.3f);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);

    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
  }
}

public class BulletLineShape: BulletShapeBase {
 private:

  protected override void prepareShape() {
    prepareAddScale(1.2f, 1.2f, 1.2f);
    prepareAddPart(GL_LINES);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(0, -0.3f, 0.4f);

    prepareAddPart(GL_LINE_LOOP);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
  }
}

public class MiddleBulletShape: BulletShapeBase {
 private:

  protected override void prepareShape() {
    prepareStartBlend();
    prepareAddScale(1.1f, 1.0f, 1.1f);
    prepareSetColor(0, 0, 0);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(-0.17f, 0.3f, -0.1f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.17f, 0.3f, -0.1f);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(0.17f, 0.3f, -0.1f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
    prepareAddVertex(0, 0.3f, 0.2f);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(0, 0.3f, 0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(-0.17f, 0.3f, -0.1f);

    prepareAddPart(GL_TRIANGLES);
    prepareAddVertex(-0.17f, -0.3f, -0.1f);
    prepareAddVertex(0.17f, -0.3f, -0.1f);
    prepareAddVertex(0, -0.3f, 0.2f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);

    prepareEndBlend();
    prepareAddScale(1.4f, 1.3f, 1.4f);
    prepareSetColor(0.1f, 0.2f, 0.3f);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(-0.17f, 0.3f, -0.1f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.17f, 0.3f, -0.1f);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(0.17f, 0.3f, -0.1f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
    prepareAddVertex(0, 0.3f, 0.2f);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(0, 0.3f, 0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(-0.17f, 0.3f, -0.1f);

    prepareAddPart(GL_TRIANGLES);
    prepareAddVertex(-0.17f, 0.3f, -0.1f);
    prepareAddVertex(0.17f, 0.3f, -0.1f);
    prepareAddVertex(0, 0.3f, 0.2f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
  }
}

public class MiddleBulletLineShape: BulletShapeBase {
 private:

  protected override void prepareShape() {
    prepareAddScale(1.4f, 1.3f, 1.4f);
    prepareAddPart(GL_LINES);
    prepareAddVertex(-0.17f, 0.3f, -0.1f);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.17f, 0.3f, -0.1f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, 0.3f, 0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);

    prepareAddPart(GL_LINE_LOOP);
    prepareAddVertex(-0.17f, 0.3f, -0.1f);
    prepareAddVertex(0.17f, 0.3f, -0.1f);
    prepareAddVertex(0, 0.3f, 0.2f);

    prepareAddPart(GL_LINE_LOOP);
    prepareAddVertex(-0.34f, -0.3f, -0.2f);
    prepareAddVertex(0.34f, -0.3f, -0.2f);
    prepareAddVertex(0, -0.3f, 0.4f);
  }
}

public class RollBulletShapeBase: BulletShapeBase {
 private:

  public override void draw(Vector3 pos, float cd, float deg, float rd) {
    glPushMatrix();
    Screen.glTranslate(pos);
    glRotatef(cd * 180 / PI, 0, 1, 0);
    glRotatef(rd, 0, 0, 1);
    drawShape();
    glPopMatrix();
  }
}

public class CounterBulletShape: RollBulletShapeBase {
 private:

  protected override void prepareShape() {
    prepareStartBlend();
    prepareSetColor(0, 0, 0);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(0, 0, 0.5f);
    prepareAddVertex(0.5f, 0, 0);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(-0.5f, 0, 0);
    prepareAddVertex(0, -0.5f, 0);
    prepareAddVertex(0.5f, 0, 0);

    prepareEndBlend();
    prepareAddScale(1.2f, 1.2f, 1.2f);
    prepareSetColor(0.5f, 0.5f, 0.5f);
    prepareAddPart(GL_TRIANGLE_FAN);
    prepareAddVertex(0, 0, 0.5f);
    prepareAddVertex(0.5f, 0, 0);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(-0.5f, 0, 0);
    prepareAddVertex(0, -0.5f, 0);
    prepareAddVertex(0.5f, 0, 0);
  }
}

public class CounterBulletLineShape: RollBulletShapeBase {
 private:

  protected override void prepareShape() {
    prepareAddScale(1.2f, 1.2f, 1.2f);
    prepareAddPart(GL_LINE_LOOP);
    prepareAddVertex(0.5f, 0, 0);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(-0.5f, 0, 0);
    prepareAddVertex(0, -0.5f, 0);

    prepareAddPart(GL_LINES);
    prepareAddVertex(0, 0, 0.5f);
    prepareAddVertex(0.5f, 0, 0);
    prepareAddVertex(0, 0, 0.5f);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(0, 0, 0.5f);
    prepareAddVertex(-0.5f, 0, 0);
    prepareAddVertex(0, 0, 0.5f);
    prepareAddVertex(0, -0.5f, 0);
  }
}

public class EnemyShape: PyramidShape {
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
    drawShape();
    glPopMatrix();
  }
}

public class Enemy1Shape: EnemyShape {
 private:

  protected override void prepareShape() {
    prepareStartBlend();
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.6f, 0);
    preparePyramidSetScale(0.5f, 1.4f, 0.5f);
    preparePyramidDrawShadow(0.5f, 0.5f, 0.3f);

    preparePyramidSetRotateAngle(120);
    preparePyramidSetTranslate(0.5f, -0.2f, 0);
    preparePyramidSetScale(0.4f, 1.0f, 0.4f);
    preparePyramidDrawShadow(0.2f, 0.2f, 0.5f);

    prepareSetColor(0.2f, 0.2f, 0.5f);
    preparePyramidSetRotateAngle(240);
    preparePyramidSetTranslate(-0.5f, -0.2f, 0);
    preparePyramidSetScale(0.4f, 1.0f, 0.4f);
    preparePyramidDrawShadow(0.2f, 0.2f, 0.5f);

    prepareSetColor(1, 1, 0.6f);
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.6f, 0);
    preparePyramidSetScale(0.3f, 1.2f, 0.3f);
    preparePyramidDraw();

    prepareSetColor(0.5f, 0.5f, 1);
    preparePyramidSetRotateAngle(120);
    preparePyramidSetTranslate(0.5f, -0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDraw();

    prepareSetColor(0.5f, 0.5f, 1);
    preparePyramidSetRotateAngle(240);
    preparePyramidSetTranslate(-0.5f, -0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDraw();
    prepareEndBlend();
  }
}

public class Enemy1TrailShape: EnemyShape {
 private:

  protected override void prepareShape() {
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.6f, 0);
    preparePyramidSetScale(0.3f, 1.2f, 0.3f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(120);
    preparePyramidSetTranslate(0.5f, -0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(240);
    preparePyramidSetTranslate(-0.5f, -0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDrawLineShape();
  }
}

public class Enemy2Shape: EnemyShape {
 private:

  protected override void prepareShape() {
    prepareStartBlend();
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.5f, 0);
    preparePyramidSetScale(0.5f, 1.2f, 0.5f);
    preparePyramidDrawShadow(0.5f, 0.4f, 0.5f);

    preparePyramidSetRotateAngle(60);
    preparePyramidSetTranslate(0.6f, -0.7f, 0);
    preparePyramidSetScale(0.4f, 1.4f, 0.4f);
    preparePyramidDrawShadow(0.9f, 0.6f, 0.5f);

    preparePyramidSetRotateAngle(300);
    preparePyramidSetTranslate(-0.6f, -0.7f, 0);
    preparePyramidSetScale(0.4f, 1.4f, 0.4f);
    preparePyramidDrawShadow(0.9f, 0.6f, 0.5f);

    prepareSetColor(1, 0.9f, 1.0f);
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.5f, 0);
    preparePyramidSetScale(0.3f, 1.0f, 0.3f);
    preparePyramidDraw();

    prepareSetColor(0.9f, 0.6f, 0.5f);
    preparePyramidSetRotateAngle(60);
    preparePyramidSetTranslate(0.6f, -0.7f, 0);
    preparePyramidSetScale(0.2f, 1.2f, 0.2f);
    preparePyramidDraw();

    prepareSetColor(0.9f, 0.6f, 0.5f);
    preparePyramidSetRotateAngle(300);
    preparePyramidSetTranslate(-0.6f, -0.7f, 0);
    preparePyramidSetScale(0.2f, 1.2f, 0.2f);
    preparePyramidDraw();
    prepareEndBlend();
  }
}

public class Enemy2TrailShape: EnemyShape {
 private:

  protected override void prepareShape() {
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.5f, 0);
    preparePyramidSetScale(0.3f, 1.0f, 0.3f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(60);
    preparePyramidSetTranslate(0.6f, -0.7f, 0);
    preparePyramidSetScale(0.2f, 1.2f, 0.2f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(300);
    preparePyramidSetTranslate(-0.6f, -0.7f, 0);
    preparePyramidSetScale(0.2f, 1.2f, 0.2f);
    preparePyramidDrawLineShape();
  }
}

public class Enemy3Shape: EnemyShape {
 private:

  protected override void prepareShape() {
    prepareStartBlend();
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.4f, 0);
    preparePyramidSetScale(0.5f, 1.4f, 0.5f);
    preparePyramidDrawShadow(0.5f, 0.5f, 0.3f);

    preparePyramidSetRotateAngle(150);
    preparePyramidSetTranslate(0.5f, 0.2f, 0);
    preparePyramidSetScale(0.4f, 1.0f, 0.4f);
    preparePyramidDrawShadow(0.2f, 0.2f, 0.5f);

    prepareSetColor(0.2f, 0.2f, 0.5f);
    preparePyramidSetRotateAngle(210);
    preparePyramidSetTranslate(-0.5f, 0.2f, 0);
    preparePyramidSetScale(0.4f, 1.0f, 0.4f);
    preparePyramidDrawShadow(0.2f, 0.2f, 0.5f);

    prepareSetColor(1, 0.6f, 0.9f);
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.4f, 0);
    preparePyramidSetScale(0.3f, 1.2f, 0.3f);
    preparePyramidDraw();

    prepareSetColor(0.3f, 0.5f, 1);
    preparePyramidSetRotateAngle(150);
    preparePyramidSetTranslate(0.5f, 0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDraw();

    prepareSetColor(0.3f, 0.5f, 1);
    preparePyramidSetRotateAngle(210);
    preparePyramidSetTranslate(-0.5f, 0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDraw();
    prepareEndBlend();
  }
}

public class Enemy3TrailShape: EnemyShape {
 private:

  protected override void prepareShape() {
    preparePyramidSetRotateAngle(0);
    preparePyramidSetTranslate(0, -0.4f, 0);
    preparePyramidSetScale(0.3f, 1.2f, 0.3f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(150);
    preparePyramidSetTranslate(0.5f, 0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDrawLineShape();

    preparePyramidSetRotateAngle(210);
    preparePyramidSetTranslate(-0.5f, 0.2f, 0);
    preparePyramidSetScale(0.2f, 0.8f, 0.2f);
    preparePyramidDrawLineShape();
  }
}

public class TriangleParticleShape: DisplayListShape {
 private:

  protected override void prepareShape() {
    prepareAddPart(GL_LINE_LOOP);
    prepareAddVertex(0, 0.5f, 0);
    prepareAddVertex(0.4f, -0.3f, 0);
    prepareAddVertex(-0.4f, -0.3f, 0);
  }
}

public class PillarShape: DisplayListShape {
 public:
  static const float TICKNESS = 4.0f;
 private:
  static const float RADIUS_RATIO = 0.3f;

  protected void preparePillar(float r, float g, float b, bool outside = false) {
    prepareStartBlend();
    prepareSetColor(r, g, b);
    for (int i = 0; i < 8; i++) {
      prepareAddPart(GL_TRIANGLE_FAN);
      float d = PI * 2 * i / 8;
      prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      d += PI * 2 / 8;
      prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 -TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      d -= PI * 2 / 8;
      prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 -TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
    }

    if (!outside) {
      prepareSetColor(r, g, b);
      prepareAddPart(GL_TRIANGLES);
      for (int i = 0; i < 8; i++) {
        float d = PI * 2 * i / 8;
        prepareAddVertex(0, TICKNESS, 0);
        prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                   TICKNESS,
                   cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
        d += PI * 2 / 8;
        prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                   TICKNESS,
                   cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
        d -= PI * 2 / 8;
        prepareAddVertex(0, -TICKNESS, 0);
        prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                   -TICKNESS,
                   cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
        d += PI * 2 / 8;
        prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                   -TICKNESS,
                   cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      }
    }
    prepareSetColor(0.1f, 0.1f, 0.1f);
    for (int i = 0; i < 8; i++) {
      float d = PI * 2 * i / 8;
      prepareAddPart(GL_LINE_STRIP);
      prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      d += PI * 2 / 8;
      prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 -TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
      d -= PI * 2 / 8;
      prepareAddVertex(sin(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO,
                 -TICKNESS,
                 cos(d) * Field.CIRCLE_RADIUS * RADIUS_RATIO);
    }
    prepareEndBlend();
  }

  public void draw(float y, float deg) {
    glPushMatrix();
    glTranslatef(0, y, 0);
    glRotatef(deg * 180 / PI, 0, 1, 0);
    drawShape();
    glPopMatrix();
  }
}

public class Pillar1Shape: PillarShape {
 private:

  protected override void prepareShape() {
    prepareAddScale(0.6f, 1.0f, 0.6f);
    preparePillar(0.5f, 0.4f, 0.4f);
  }
}

public class Pillar2Shape: PillarShape {
 private:

  protected override void prepareShape() {
    prepareAddScale(0.8f, 1.0f, 0.8f);
    preparePillar(0.6f, 0.3f, 0.3f);
  }
}

public class Pillar3Shape: PillarShape {
 private:

  protected override void prepareShape() {
    preparePillar(0.5f, 0.5f, 0.4f);
  }
}

public class Pillar4Shape: PillarShape {
 private:

  protected override void prepareShape() {
    prepareAddScale(1.1f, 1.0f, 1.1f);
    preparePillar(0.5f, 0.4f, 0.5f);
  }
}

public class OutsidePillarShape: PillarShape {
 private:

  protected override void prepareShape() {
    prepareAddScale(7.0f, 3.0f, 7.0f);
    preparePillar(0.2f, 0.2f, 0.3f, true);
  }
}
