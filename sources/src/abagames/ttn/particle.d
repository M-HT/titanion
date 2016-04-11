/*
 * $Id: particle.d,v 1.3 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.particle;

private import opengl;
private import std.math;
private import abagames.util.vector;
private import abagames.util.math;
private import abagames.util.actor;
private import abagames.util.rand;
private import abagames.ttn.token;
private import abagames.ttn.field;
private import abagames.ttn.screen;
private import abagames.ttn.shape;
private import abagames.ttn.letter;
private import abagames.ttn.player;

/**
 * Particles (Triangle / Line / Quad / Bonus).
 */
public class ParticlePool: ActorPool!(Particle) {
}

public class Particle: Token!(ParticleState, ParticleSpec) {
 public:
  static const enum Shape {
    TRIANGLE, LINE, QUAD, BONUS,
  };
 private:
  private TriangleParticleSpec triangleParticleSpec;
  private LineParticleSpec lineParticleSpec;
  private QuadParticleSpec quadParticleSpec;
  private BonusParticleSpec bonusParticleSpec;

  public override void init(Object[] args) {
    super.init(args);
    triangleParticleSpec = cast(TriangleParticleSpec) args[0];
    lineParticleSpec = cast(LineParticleSpec) args[1];
    quadParticleSpec = cast(QuadParticleSpec) args[2];
    bonusParticleSpec = cast(BonusParticleSpec) args[3];
  }

  public void set(int type,
                  float x, float y, float deg, float speed,
                  float sz, float r, float g, float b,
                  int c = 60, bool ebg = true, float num = 0, int waitCnt = 0) {
    switch (type) {
    case Shape.TRIANGLE:
      spec = triangleParticleSpec;
      break;
    case Shape.LINE:
      spec = lineParticleSpec;
      break;
    case Shape.QUAD:
      spec = quadParticleSpec;
      break;
    case Shape.BONUS:
      spec = bonusParticleSpec;
      break;
    default:
      break;
    }
    this.spec = spec;
    super.set(x, y, deg, speed);
    state.size = sz;
    const float degSin = sin(deg);
    const float degCos = cos(deg);
    state.vel.x = -degSin * speed;
    state.vel.y = degCos * speed;
    state.r = r;
    state.g = g;
    state.b = b;
    state.cnt = state.startCnt = c;
    state.effectedByGravity = ebg;
    state.trgNum = num;
    state.waitCnt = waitCnt;
    if (type == Shape.BONUS)
      (cast(BonusParticleSpec) spec).setSize(state, sz);
  }

  public void setByVelocity(float x, float y, float vx, float vy,
                            float sz, float r, float g, float b, float a,
                            int c = 60, bool ebg = true) {
    spec = triangleParticleSpec;
    super.set(x, y, 0, 0);
    state.vel.x = vx;
    state.vel.y = vy;
    state.size = sz;
    state.r = r;
    state.g = g;
    state.b = b;
    state.a = a;
    state.cnt = state.startCnt = c;
    state.effectedByGravity = ebg;
  }
}

public class ParticleState: TokenState {
 private:
  Vector vel;
  Vector tailPos;
  float size;
  int cnt, startCnt;
  float r, g, b, a;
  float d1, d2;
  float vd1, vd2;
  bool effectedByGravity;
  float num, trgNum;
  float trgSize;
  int waitCnt;

  invariant() {
    if (isInitialized) {
      assert(pos.x <>= 0);
      assert(pos.y <>= 0);
      assert(vel.x <>= 0);
      assert(vel.y <>= 0);
      assert(tailPos.x <>= 0);
      assert(tailPos.y <>= 0);
      assert(size > 0 && size < 20);
      assert(r >= 0 && r <= 1);
      assert(g >= 0 && g <= 1);
      assert(b >= 0 && b <= 1);
      assert(a >= 0 && a <= 1);
      assert(d1 <>= 0);
      assert(d2 <>= 0);
      assert(vd1 <>= 0);
      assert(vd2 <>= 0);
      assert(num <>= 0);
      assert(trgNum <>= 0);
      assert(trgSize > 0);
    }
  }

  public this() {
    super();
    vel = new Vector;
    tailPos = new Vector;
  }

  public override void clear() {
    vel.x = vel.y = 0;
    size = 1;
    cnt = 0;
    r = g = b = 0;
    a = 1;
    d1 = d2 = 0;
    vd1 = vd2 = 0;
    effectedByGravity = false;
    num = trgNum = 1;
    trgSize = 1;
    waitCnt = 0;
    super.clear();
  }
}

public class ParticleSpec: TokenSpec!(ParticleState) {
  mixin StaticRandImpl;
 private:
  Player player;

  public void setPlayer(Player player) {
    this.player = player;
  }

  protected float calcNearPlayerAlpha(Vector pos) {
    if (!player.isActive)
      return 1;
    float pd = player.pos.dist(pos);
    if (pd < 20)
      return pd / 20;
    else
      return 1;
  }
}

public class TriangleParticleSpec: ParticleSpec {
 private:
  static const float SLOW_DOWN_RATIO = 0.05f;
  static const float GRAVITY = 0.003f;
  Shape particleShape;
  ParticlePool particles;

  public this(Field field) {
    this.field = field;
    particleShape = new TriangleParticleShape;
  }

  public void setParticles(ParticlePool particles) {
    this.particles = particles;
  }

  public override void set(ParticleState ps) {
    with (ps) {
      d1 = rand.nextFloat(PI * 2);
      d2 = rand.nextFloat(PI * 2);
      vd1 = rand.nextSignedFloat(0.1f);
      vd2 = rand.nextSignedFloat(0.1f);
    }
  }

  public override bool move(ParticleState ps) {
    with (ps) {
      pos += vel;
      pos.x = field.normalizeX(pos.x);
      if (effectedByGravity)
        vel.y -= GRAVITY;
      vel *= (1 - SLOW_DOWN_RATIO);
      d1 += vd1;
      d2 += vd2;
      vd1 *= (1 - SLOW_DOWN_RATIO * 0.2f);
      vd2 *= (1 - SLOW_DOWN_RATIO * 0.2f);
      float cfr = 1.0f - (1.0f / cast(float) startCnt);
      if (cfr < 0)
        cfr = 0;
      r *= cfr;
      g *= cfr;
      b *= cfr;
      a *= cfr;
      float fs = 0;
      if (size > 2.0f && rand.nextInt(45) == 0)
        fs = 0.5f - rand.nextFloat(0.2f);
      else if (size > 0.5f && rand.nextInt(10) == 0)
        fs = 0.1f + rand.nextSignedFloat(0.05f);
      if (fs > 0) {
        float vx = vel.x * rand.nextSignedFloat(0.8f);
        float vy = vel.y * rand.nextSignedFloat(0.8f);
        vel.x -= vx * fs;
        vel.y -= vy * fs;
        float cr = 1 - fs * 0.2f;
        vel /= cr;
        Particle p = particles.getInstanceForced();
        int nc = cast(int) (cnt * (0.8f + fs * 0.2f));
        if (nc > 0)
          p.setByVelocity(pos.x, pos.y, vx, vy, size * fs, r, g, b, a,
                          nc, effectedByGravity);
        size *= (1 - fs);
        cnt *= cr;
      }
      cnt--;
      if (cnt <= 0)
        return false;
      return true;
    }
  }

  public override void draw(ParticleState ps) {
    with (ps) {
      Vector3 p = field.calcCircularPos(pos);
      float aa = a * calcNearPlayerAlpha(pos);
      Screen.setColor(r, g, b, aa);
      particleShape.draw(p, d1, d2);
    }
  }
}

public class LineParticleSpec: ParticleSpec {
 private:
  static const float SLOW_DOWN_RATIO = 0.03f;

  public this(Field field) {
    this.field = field;
  }

  public override void set(ParticleState ps) {
    with (ps) {
      tailPos.x = pos.x;
      tailPos.y = pos.y;
    }
  }


  public override bool move(ParticleState ps) {
    with (ps) {
      ps.stepForward();
      tailPos.x += (pos.x - tailPos.x) * 0.05f;
      tailPos.y += (pos.y - tailPos.y) * 0.05f;
      speed *= (1 - SLOW_DOWN_RATIO);
      pos.x = field.normalizeX(pos.x);
      float cfr = 1.0f - (1.0f / cast(float) startCnt);
      if (cfr < 0)
        cfr = 0;
      r *= cfr;
      g *= cfr;
      b *= cfr;
      a *= cfr;
      cnt--;
      if (cnt <= 0)
        return false;
      return true;
    }
  }

  public override void draw(ParticleState ps) {
    with (ps) {
      Vector3 p;
      glBegin(GL_LINES);
      float aa = a;// * calcNearPlayerAlpha(pos);
      Screen.setColor(r, g, b, aa);
      p = field.calcCircularPos(pos);
      Screen.glVertex(p);
      p = field.calcCircularPos(tailPos);
      Screen.glVertex(p);
      glEnd();
    }
  }
}

public class QuadParticleSpec: ParticleSpec {
 private:
  static const float SLOW_DOWN_RATIO = 0.07f;
  static const float GRAVITY = 0.002f;

  public this(Field field) {
    this.field = field;
  }

  public override bool move(ParticleState ps) {
    with (ps) {
      pos += vel;
      pos.x = field.normalizeX(pos.x);
      if (effectedByGravity)
        vel.y -= GRAVITY;
      vel *= (1 - SLOW_DOWN_RATIO);
      float cfr = 1.0f - (1.0f / cast(float) startCnt);
      if (cfr < 0)
        cfr = 0;
      r *= cfr;
      g *= cfr;
      b *= cfr;
      a *= cfr;
      size *= (1 - (1 - cfr) * 0.5f);
      cnt--;
      if (cnt <= 0)
        return false;
      return true;
    }
  }

  public override void draw(ParticleState ps) {
    with (ps) {
      Vector3 p;
      float sz = size * 0.5f;
      float aa = a * calcNearPlayerAlpha(pos);
      Screen.setColor(r, g, b, aa);
      glBegin(GL_QUADS);
      p = field.calcCircularPos(pos.x - sz, pos.y - sz);
      Screen.glVertex(p);
      p = field.calcCircularPos(pos.x + sz, pos.y - sz);
      Screen.glVertex(p);
      p = field.calcCircularPos(pos.x + sz, pos.y + sz);
      Screen.glVertex(p);
      p = field.calcCircularPos(pos.x - sz, pos.y + sz);
      Screen.glVertex(p);
      glEnd();
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      Screen.setColor(0, 0, 0, aa * 0.66f);
      glBegin(GL_LINE_LOOP);
      p = field.calcCircularPos(pos.x - sz, pos.y - sz);
      Screen.glVertex(p);
      p = field.calcCircularPos(pos.x + sz, pos.y - sz);
      Screen.glVertex(p);
      p = field.calcCircularPos(pos.x + sz, pos.y + sz);
      Screen.glVertex(p);
      p = field.calcCircularPos(pos.x - sz, pos.y + sz);
      Screen.glVertex(p);
      glEnd();
      glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    }
  }
}

public class BonusParticleSpec: ParticleSpec {
 private:
  static const float SLOW_DOWN_RATIO = 0.04f;

  public this(Field field) {
    this.field = field;
  }

  public void setSize(ParticleState ps, float sz) {
    with (ps) {
      trgSize = sz;
      size = 0.1f;
    }
  }

  public override bool move(ParticleState ps) {
    with (ps) {
      if (waitCnt > 0) {
        waitCnt--;
        return true;
      }
      ps.stepForward();
      speed *= (1 - SLOW_DOWN_RATIO);
      field.addSlowdownRatio(0.01f);
      pos.x = field.normalizeX(pos.x);
      float cfr = 1.0f - (1.0f / cast(float) startCnt);
      if (cfr < 0)
        cfr = 0;
      a *= cfr;
      num += (trgNum - num) * 0.2f;
      if (fabs(trgNum - num) < 0.5f)
        num = trgNum;
      size += (trgSize - size) * 0.1f;
      cnt--;
      if (cnt <= 0)
        return false;
      return true;
    }
  }

  public override void draw(ParticleState ps) {
    with (ps) {
      if (waitCnt > 0)
        return;
      glPushMatrix();
      Vector3 p = field.calcCircularPos(pos);
      float aa = a * calcNearPlayerAlpha(pos);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      Screen.setColor(1, 1, 1, aa * 0.5f);
      Screen.glTranslate(p);
      Letter.drawNumSign(cast(int) num, 0, 0, size, 33, 0, 1);
      Screen.setColor(1, 1, 1, aa);
      Letter.drawNumSign(cast(int) num, 0, 0, size, 33, 0, 2);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      glPopMatrix();
    }
  }
}
