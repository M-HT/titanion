/*
 * $Id: pillar.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.pillar;

private import std.math;
private import std.algorithm;
private import abagames.util.actor;
private import abagames.ttn.field;
private import abagames.ttn.token;
private import abagames.ttn.shape;
private import abagames.ttn.enemy;

/**
 * Pillars at the center and on the background.
 */
public class PillarPool: ActorPool!(Pillar) {
 private:

  public void setEnd() {
    foreach (Pillar a; actors)
      if (a.exists)
        a.setEnd();
  }

  public void drawCenter() {
    foreach (Object o; sort(cast(Object[])actors)) {
      Pillar a = cast(Pillar) o;
      if (a.exists && !a.state.isOutside)
        a.draw();
    }
  }

  public void drawOutside() {
    foreach (Pillar a; actors)
      if (a.exists && a.state.isOutside)
        a.draw();
  }
}

public class Pillar: Token!(PillarState, PillarSpec) {
 private:

  public void set(PillarSpec ps, float y, float maxY, Pillar pp, PillarShape s, float vdeg, bool outside = false) {
    super.set(ps, 0, y, 0, 0);
    state.maxY = maxY;
    state.previousPillar = pp;
    state.pshape = s;
    state.vdeg = vdeg;
    state.isOutside = outside;
  }

  public void setEnd() {
    state.isEnded = true;
  }


  public override int opCmp(Object o) {
    Pillar p = cast(Pillar) o;
    if (!p)
      return 0;
    return cast(int) (fabs(p.pos.y) - fabs(pos.y));
  }
}

public class PillarState: TokenState {
 private:
  Pillar previousPillar;
  float vy, vdeg;
  float maxY;
  PillarShape pshape;
  bool isEnded;
  bool isOutside;

  public override void clear() {
    previousPillar = null;
    vy = 0;
    vdeg = 0;
    maxY = 0;
    isEnded = false;
    isOutside = false;
    super.clear();
  }
}

public class PillarSpec:TokenSpec!(PillarState) {
 private:
  static const VELOCITY_Y = 0.025f;

  public this(Field field) {
    this.field = field;
  }

  public override bool move(PillarState ps) {
    with (ps) {
      if (!isOutside) {
      vy += VELOCITY_Y;
        vy *= 0.98f;
        pos.y += vy;
        if (vy > 0) {
          float ty;
          if (previousPillar && previousPillar.exists)
            ty = previousPillar.pos.y - PillarShape.TICKNESS;
          else
            ty = maxY;
          ty -= PillarShape.TICKNESS;
          if (!isEnded && pos.y > ty) {
            vy *= -0.5f;
            pos.y += (ty - pos.y) * 0.5f;
            if (previousPillar)
              previousPillar.state.vy -= vy * 0.5f;
          }
          if (pos.y > 100)
            return false;
        }
      } else {
        pos.y -= 0.2f;
        if (pos.y < -50)
          return false;
      }
      deg += vdeg;
      return true;
    }
  }

  public override void draw(PillarState ps) {
    ps.pshape.draw(ps.pos.y, ps.deg);
  }
}
