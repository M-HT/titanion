/*
 * $Id: bullet.d,v 1.4 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.bullet;

private import std.math;
private import opengl;
private import abagames.util.vector;
private import abagames.util.actor;
private import abagames.util.math;
private import abagames.ttn.token;
private import abagames.ttn.field;
private import abagames.ttn.shape;
private import abagames.ttn.player;
private import abagames.ttn.particle;
private import abagames.ttn.enemy;
private import abagames.ttn.screen;
private import abagames.ttn.frame;

/**
 * Enemies' bullets.
 */
public class BulletPool: ActorPool!(Bullet) {
 private:
  static const float BULLET_REMOVED_RANGE = 2.0f;

  public override void move() {
    super.move();
    BulletState.move();
  }

  public void removeAround(ref int cnt, Vector pos,
                           ParticlePool particles, ParticlePool bonusParticles,
                           Player player) {
    foreach (Bullet b; actors) {
      if (b.exists) {
        if (b.pos.dist(pos) < BULLET_REMOVED_RANGE) {
          b.remove();
          player.addScore(cnt);
          cnt++;
          int wc;
          if (cnt <= 50)
            wc = cnt;
          else
            wc = 50 + cast(int) sqrt(cast(float) (cnt - 50));
          Particle bp = bonusParticles.getInstanceForced();
          bp.set(Particle.Shape.BONUS, b.state.pos.x, b.state.pos.y, 0, 0.2f,
                 0.5f, 1, 1, 1, 60, false, cnt, wc);
          Particle p = particles.getInstanceForced();
          p.set(Particle.Shape.QUAD, b.state.pos.x, b.state.pos.y,
                b.state.deg, b.state.speed,
                1.5f, 0.5f, 0.75f, 1.0f, 60, false);
          this.removeAround(cnt, b.pos, particles, bonusParticles, player);
        }
      }
    }
  }
}

public class Bullet: Token!(BulletState, BulletSpec) {
 private:

  public void setWaitCnt(int c) {
    state.waitCnt = c;
  }
}

public class BulletState: TokenState {
 private:
  static int colorCnt = 0;
  static float colorAlpha = 0;
  Vector ppos;
  Vector tailPos;
  int cnt;
  int waitCnt;
  float speedRatio;

  public this() {
    super();
    ppos = new Vector;
    tailPos = new Vector;
  }

  public static void move() {
    colorCnt++;
    int c = colorCnt % 30;
    if (c < 15)
      colorAlpha = cast(float) c / 15;
    else
      colorAlpha = 1 - cast(float) (c - 15) / 15;
  }

  public override void clear() {
    ppos.x = ppos.y = 0;
    tailPos.x = tailPos.y = 0;
    cnt = 0;
    waitCnt = 0;
    speedRatio = 0;
    super.clear();
  }
}

public class BulletSpec: TokenSpec!(BulletState) {
 private:
  static const float DISAPPEAR_CNT = 300;
  Player player;
  EnemyPool enemies;
  ParticlePool particles;
  Shape lineShape;
  GameState gameState;

  public this(Field field, Player player, EnemyPool enemies, ParticlePool particles,
              Shape shape, Shape lineShape, GameState gameState) {
    this.field = field;
    this.player = player;
    this.enemies = enemies;
    this.particles = particles;
    this.shape = shape;
    this.lineShape = lineShape;
    this.gameState = gameState;
  }

  public override void set(BulletState bs) {
    with (bs) {
      ppos.x = pos.x;
      ppos.y = pos.y;
      tailPos.x = pos.x;
      tailPos.y = pos.y;
      assert(deg <>= 0);
    }
  }

  public override bool move(BulletState bs) {
    with (bs) {
      if (waitCnt > 0) {
        waitCnt--;
        return true;
      }
      ppos.x = pos.x;
      ppos.y = pos.y;
      float sp = speed;
      if (gameState.mode != GameState.Mode.CLASSIC && cnt < 40)
        sp *= (cast(float) (cnt + 10) / 50);
      const float degSin = sin(deg);
      const float degCos = cos(deg);
      tailPos.x -= degSin * sp * 0.7f;
      tailPos.y += degCos * sp * 0.7f;
      pos.x -= degSin * sp;
      pos.y += degCos * sp;
      field.addSlowdownRatio(speed * 0.04f);
      pos.x = field.normalizeX(pos.x);
      if (!field.containsOuter(pos))
        return false;
      if (!field.contains(pos) || cnt >= DISAPPEAR_CNT * 0.9f) {
        tailPos.x += (pos.x - tailPos.x) * 0.1f;
        tailPos.y += (pos.y - tailPos.y) * 0.1f;
      }
      tailPos.x = field.normalizeX(tailPos.x);
      if (player.enemiesHasCollision())
        if (enemies.checkBulletHit(pos, ppos))
          return false;
      if (player.checkBulletHit(pos, ppos))
        return false;
      cnt++;
      if (cnt >= DISAPPEAR_CNT)
        return false;
      return true;
    }
  }

  public override void draw(BulletState bs) {
    with (bs) {
      if (waitCnt > 0)
        return;
      Vector3 p;
      glBegin(GL_LINES);
      Screen.setColor(0.1f, 0.4f, 0.4f, 0.5f);
      p = field.calcCircularPos(tailPos);
      Screen.glVertex(p);
      Screen.setColor(0.2f * colorAlpha, 0.8f * colorAlpha, 0.8f * colorAlpha);
      p = field.calcCircularPos(pos);
      Screen.glVertex(p);
      glEnd();
      p = field.calcCircularPos(pos);
      float d;
      switch (gameState.mode) {
      case GameState.Mode.CLASSIC:
        d = PI;
        break;
      case GameState.Mode.BASIC:
      case GameState.Mode.MODERN:
        d = deg;
        break;
      default:
        break;
      }
      float cd = field.calcCircularDeg(pos.x);
      (cast(BulletShapeBase) shape).draw(p, cd, d, cnt * 3.0f);
      Screen.setColor(0.6f * colorAlpha, 0.9f * colorAlpha, 0.9f * colorAlpha);
      (cast(BulletShapeBase) lineShape).draw(p, cd, d, cnt * 3.0f);
    }
  }
}
