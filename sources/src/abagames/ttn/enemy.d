/*
 * $Id: enemy.d,v 1.7 2006/12/09 04:17:40 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.enemy;

private import std.math;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
private import abagames.util.rand;
private import abagames.util.vector;
private import abagames.util.actor;
private import abagames.util.math;
private import abagames.ttn.token;
private import abagames.ttn.field;
private import abagames.ttn.shape;
private import abagames.ttn.bullet;
private import abagames.ttn.player;
private import abagames.ttn.particle;
private import abagames.ttn.stage;
private import abagames.ttn.screen;
private import abagames.ttn.sound;
private import abagames.ttn.frame;

/**
 * Enemies and turrets.
 */
public class EnemyPool: ActorPool!(Enemy) {
 public:
  static bool trailEffect = false;
 private:
  Field _field;

  public Enemy getNearestEnemy(Vector p) {
    float dst = 99999;
    Enemy ne = null;
    foreach (Enemy e; actors) {
      if (e.exists && !e.isBeingCaptured) {
        float enemyDst = _field.calcCircularDist(e.pos, p);
        if (enemyDst < dst) {
          dst = enemyDst;
          ne = e;
        }
      }
    }
    return ne;
  }

  public Enemy getNearestMiddleEnemy(Vector p) {
    float dst = 99999;
    Enemy ne = null;
    foreach (Enemy e; actors) {
      if (e.exists && !e.isBeingCaptured)
        if (cast(MiddleEnemySpec) e.spec) {
          float enemyDst = _field.calcCircularDist(e.pos, p);
          if (enemyDst < dst) {
            dst = enemyDst;
            ne = e;
          }
        }
    }
    return ne;
  }

  public bool checkShotHit(Vector p, float deg, float widthRatio = 1.0f) {
    Enemy e = getNearestEnemy(p);
    if (e) {
      float ox = _field.normalizeX(e.pos.x - p.x);
      float oy = e.pos.y - p.y;
      if (fabs(ox) < 1.0f * e.state.size.x && fabs(oy) < 1.0f * e.state.size.y * widthRatio) {
        e.hitShot(deg);
        return true;
      }
    }
    return false;
  }

  public bool checkBulletHit(Vector p, Vector pp) {
    bool hitf = false;
    foreach (Enemy e; actors) {
      if (e.exists && e.isCaptured)
        if (_field.checkHitDist(e.pos, p, pp, EnemySpec.BULLET_HIT_WIDTH)) {
          e.hitCaptured();
          hitf = true;
        }
    }
    return hitf;
  }

  public bool checkEnemyHit(Vector p, Vector size) {
    bool hitf = false;
    foreach (Enemy e; actors) {
      if (e.exists && e.isCaptured) {
        float ox = _field.normalizeX(e.pos.x - p.x);
        float oy = e.pos.y - p.y;
        if (fabs(ox) < 0.5f * (e.state.size.x + size.x) &&
            fabs(oy) < 0.5f * (e.state.size.y + size.y)) {
          e.hitCaptured();
          hitf = true;
        }
      }
    }
    return hitf;
  }

  public bool checkMiddleEnemyExists(float x, float px) {
    foreach (Enemy e; actors) {
      if (e.exists && !e.isBeingCaptured)
        if (cast(MiddleEnemySpec) e.spec)
          if ((e.pos.x - x) * (e.pos.x - px) < 0)
            return true;
    }
    return false;
  }

  public int num() {
    int n = 0;
    foreach (Enemy e; actors)
      if (e.exists && !e.isCaptured)
        n++;
    return n;
  }

  public int numInAttack() {
    int n = 0;
    foreach (Enemy e; actors)
      if (e.exists && e.isInAttack)
        n++;
    return n;
  }

  public int numInScreen() {
    int n = 0;
    foreach (Enemy e; actors)
      if (e.exists && e.isInScreen)
        n++;
    return n;
  }

  public int numBeforeAlign() {
    int n = 0;
    foreach (Enemy e; actors)
      if (e.exists && e.beforeAlign)
        n++;
    return n;
  }

  public void drawFront() {
    if (trailEffect)
      foreach (Enemy a; actors)
        if (a.exists && a.state.pos.y <= _field.size.y * 1.5f)
          a.drawTrails();
    foreach (Enemy a; actors)
      if (a.exists && a.state.pos.y <= _field.size.y * 1.5f)
        a.draw();
  }

  public void drawBack() {
    if (trailEffect)
      foreach (Enemy a; actors)
        if (a.exists &&
            a.state.pos.y > _field.size.y * 1.5f &&
            (a.state.pos.x <= _field.circularDistance / 4 &&
             a.state.pos.x >= -_field.circularDistance / 4))
          a.drawTrails();
    foreach (Enemy a; actors)
      if (a.exists &&
          a.state.pos.y > _field.size.y * 1.5f &&
          (a.state.pos.x <= _field.circularDistance / 4 &&
           a.state.pos.x >= -_field.circularDistance / 4))
        a.draw();
  }

  public void drawPillarBack() {
    if (trailEffect)
      foreach (Enemy a; actors)
        if (a.exists &&
            a.state.pos.y > _field.size.y * 1.5f &&
            (a.state.pos.x > _field.circularDistance / 4 ||
             a.state.pos.x < -_field.circularDistance / 4))
          a.drawTrails();
    foreach (Enemy a; actors)
      if (a.exists &&
          a.state.pos.y > _field.size.y * 1.5f &&
          (a.state.pos.x > _field.circularDistance / 4 ||
           a.state.pos.x < -_field.circularDistance / 4))
        a.draw();
  }

  public Field field(Field v) {
    return _field = v;
  }
}

public class Enemy: Token!(EnemyState, EnemySpec) {
 private:

  public override void init(Object[] args) {
    super.init(args);
    state.enemy = this;
  }

  public void setSmallEnemyState(float baseSpeed, float angVel, int waitCnt, int appPattern,
                                 float er = 0, float ed = 0, bool gd = false,
                                 float fireIntervalRatio = 0, Enemy firstEnemy = null) {
    state.baseBaseSpeed = state.baseSpeed = baseSpeed;
    state.baseAngVel = state.angVel = angVel;
    state.waitCnt = waitCnt;
    state.ellipseRatio = er;
    state.ellipseDeg = ed;
    state.isGoingDownBeforeStandBy = gd;
    switch (appPattern) {
    case 0:
      state.phase = -200;
      break;
    case 1:
      state.phase = -100;
      break;
    default:
      break;
    }
    if (firstEnemy) {
      (cast(SmallEnemySpec) spec).init(state, firstEnemy.state);
      state.isFirstEnemy = false;
    } else {
      spec.init(state);
      state.isFirstEnemy = true;
    }
  }

  public void setMiddleEnemyState(float baseSpeed, float angVel,
                                  float er = 0, float ed = 0) {
    state.baseBaseSpeed = state.baseSpeed = baseSpeed;
    state.baseAngVel = state.angVel = angVel;
    state.ellipseRatio = er;
    state.ellipseDeg = ed;
    spec.init(state);
  }

  public void setGhostEnemyState(float x, float y, float deg, int cnt) {
    state.pos.x = x;
    state.pos.y = y;
    state.deg = deg;
    state.cnt = cnt;
  }

  public void hitShot(float deg = 0) {
    if (spec.hitShot(state, deg))
      remove();
  }

  public void hitCaptured() {
    SmallEnemySpec ses = cast(SmallEnemySpec) spec;
    if (ses)
      ses.hitCaptured(state);
  }

  public void destroyed() {
    spec.destroyed(state);
    _exists = false;
  }

  public bool isInAttack() {
    if (spec.isBeingCaptured(state))
      return false;
    return spec.isInAttack(state);
  }

  public bool isInScreen() {
    if (spec.isBeingCaptured(state))
      return false;
    return spec.isInScreen(state);
  }

  public bool isBeingCaptured() {
    return spec.isBeingCaptured(state);
  }

  public bool isCaptured() {
    GhostEnemySpec ges = cast(GhostEnemySpec) spec;
    if (ges)
      return true;
    SmallEnemySpec ses = cast(SmallEnemySpec) spec;
    if (!ses)
      return false;
    return ses.isCaptured(state);
  }

  public bool beforeAlign() {
    if (spec.isBeingCaptured(state))
      return false;
    return spec.beforeAlign(state);
  }

  public void drawTrails() {
    spec.drawTrails(state);
  }

  public override Vector pos() {
    return state.pos;
  }
}

public class EnemyState: TokenState {
 private:
  static const int TRAIL_NUM = 64;
  static const int TRAIL_INTERVAL = 8;
  static const int TURRET_MAX_NUM = 3;
  TurretState[TURRET_MAX_NUM] turretStates;
  Enemy enemy;
  Vector vel;
  Vector centerPos, centerVel, standByPos;
  float baseBaseSpeed, baseSpeed;
  float baseAngVel, angVel;
  int waitCnt;
  int cnt;
  float ellipseRatio, ellipseDeg;
  float shield;
  int phase;
  int phaseCnt, nextPhaseCnt;
  int captureState, captureIdx;
  bool isGoingDownBeforeStandBy;
  Vector size, targetSize, sizeVel;
  Trail[] trails;
  int trailIdx;
  bool trailLooped;
  bool isFirstEnemy;
  float anger;

  invariant() {
    if (isInitialized) {
      assert(baseBaseSpeed >= 0);
      assert(baseSpeed >= 0);
      assert(baseAngVel >= 0);
      assert(angVel >= 0);
      assert(centerPos.x <>= 0);
      assert(centerPos.y <>= 0);
      assert(centerVel.x <>= 0);
      assert(centerVel.y <>= 0);
      assert(shield <>= 0);
      assert(captureState >= 0);
      assert(size.x <>= 0);
      assert(size.y <>= 0);
      assert(targetSize.x <>= 0);
      assert(targetSize.y <>= 0);
      assert(sizeVel.x <>= 0);
      assert(sizeVel.y <>= 0);
      assert(anger <>= 0);
    }
  }

  public this() {
    super();
    foreach (ref TurretState ts; turretStates)
      ts = new TurretState;
    vel = new Vector;
    centerPos = new Vector;
    centerVel = new Vector;
    standByPos = new Vector;
    size = new Vector;
    targetSize = new Vector;
    sizeVel = new Vector;
    trails = new Trail[TRAIL_NUM];
    foreach (ref Trail t; trails)
      t = new Trail;
  }

  public override void clear() {
    foreach (TurretState ts; turretStates)
      ts.clear();
    vel.x = vel.y = 0;
    centerPos.x = centerPos.y = 0;
    centerVel.x = centerVel.y = 0;
    standByPos.x = standByPos.y = 0;
    baseBaseSpeed = baseSpeed = 0;
    baseAngVel = angVel = 0;
    waitCnt = 0;
    cnt = 0;
    ellipseRatio = 0;
    ellipseDeg = 0;
    shield = 0;
    phase = 0;
    phaseCnt = nextPhaseCnt = 0;
    captureState = 0;
    captureIdx = 0;
    isGoingDownBeforeStandBy = false;
    size.x = size.y = 1;
    targetSize.x = targetSize.y = 1;
    sizeVel.x = sizeVel.y = 0;
    trailIdx = 0;
    trailLooped = false;
    isFirstEnemy = false;
    anger = 0;
    super.clear();
  }

  public void move() {
    cnt++;
    anger *= 0.9995f;
  }

  public void recordTrail() {
    trails[trailIdx].set(pos.x, pos.y, deg, cnt);
    trailIdx++;
    if (trailIdx >= TRAIL_NUM) {
      trailIdx = 0;
      trailLooped = true;
    }
  }

  public void drawTrails(EnemyShape s, float r, float g, float b, Vector size, Field field) {
    int ti = trailIdx;
    float a = 1.0f;
    for (int i = 0; i < TRAIL_NUM / TRAIL_INTERVAL; i++) {
      ti -= TRAIL_INTERVAL;
      if (ti < 0) {
        if (trailLooped)
          ti += TRAIL_NUM;
        else
          break;
      }
      Trail t = trails[ti];
      Screen.setColor(r * a, g * a, b * a, a * 0.66f);
      Vector3 p = field.calcCircularPos(t.pos);
      float cd = field.calcCircularDeg(t.pos.x);
      s.draw(p, cd, t.deg, t.cnt, size);
      a *= 0.7f;
    }
  }
}

public class EnemySpec: TokenSpec!(EnemyState) {
  mixin StaticRandImpl;
 protected:
  static const float BULLET_HIT_WIDTH = 0.8f;
  static const float NEXT_PHASE_DIST = 5;
  static const int TURRET_MAX_NUM = 3;
  BulletPool bullets;
  Player player;
  ParticlePool particles, bonusParticles;
  EnemyPool enemies;
  Stage stage;
  EnemyShape trailShape;
  BulletSpec bulletSpec, counterBulletSpec;
  TurretSpec[TURRET_MAX_NUM] turretSpecs;
  int turretNum;
  float turretWidth = 0;
  GameState gameState;
  float shield = 1;
  float rank = 0;
  bool capturable;
  int score;
  string explosionSeName;
  bool removeBullets;

  invariant() {
    assert(shield > 0);
    assert(rank >= 0);
    assert(turretWidth >= 0);
  }

  public this() {}

  public this(Field field, BulletPool bullets, Player player,
              ParticlePool particles, ParticlePool bonusParticles,
              EnemyPool enemies, Stage stage,
              Shape shape, EnemyShape trailShape,
              BulletSpec bulletSpec, BulletSpec counterBulletSpec,
              GameState gameState) {
    this.field = field;
    this.bullets = bullets;
    this.player = player;
    this.particles = particles;
    this.bonusParticles = bonusParticles;
    this.enemies = enemies;
    this.stage = stage;
    this.shape = shape;
    this.trailShape = trailShape;
    this.bulletSpec = bulletSpec;
    this.counterBulletSpec = counterBulletSpec;
    this.gameState = gameState;
  }

  public override void set(EnemyState es) {
    es.shield = shield;
    for (int i = 0; i < turretNum; i++)
      turretSpecs[i].set(es.turretStates[i]);
  }

  public override bool move(EnemyState es) {
    with (es) {
      es.move();
      if (isInScreen(es) && isFirstEnemy) {
        Sound.playSe("flying_down.wav");
        isFirstEnemy = false;
      }
      if (captureState > 0) {
        moveCaptured(es);
        return true;
      }
      if (player.enemiesHasCollision()) {
        if (enemies.checkEnemyHit(es.pos, size)) {
          destroyed(es);
          return false;
        }
      }
      if (player.checkEnemyHit(es.pos, es.vel, size)) {
        destroyed(es);
        return false;
      }
      if (capturable)
        checkCaptured(es);
      const float deg2Sin = sin(deg + ellipseDeg);
      float er = (1 - ellipseRatio) + fabs(deg2Sin) * ellipseRatio * 2;
      float rk = rank;
      const float degSin = sin(deg);
      const float degCos = cos(deg);
      vel.x -= degSin * speed * er * 0.1f * rk;
      vel.y += degCos * speed * er * 0.1f * rk;
      vel *= 0.9f;
      pos += vel;
      if (isInScreen(es))
        field.addSlowdownRatio(speed * 0.04f * rk);
      pos.x = field.normalizeX(pos.x);
      recordTrail();
      if (phase >= -50 && phase < 0 && !field.containsIncludingPit(pos))
        return false;
      if (waitCnt > 0) {
        waitCnt--;
      } else {
        Vector cp = centerPos;
        centerPos.x = field.normalizeX(centerPos.x);
        phaseCnt++;
        if (field.calcCircularDist(centerPos, pos) < NEXT_PHASE_DIST) {
          nextPhaseCnt--;
          if (nextPhaseCnt <= 0) {
            phase++;
            if (!gotoNextPhase(es))
              return false;
          }
        }
        cp.x = field.normalizeX(cp.x);
        float dst = field.calcCircularDist(cp, pos);
        speed += ((baseSpeed * (1 + dst * 0.1f)) - speed) * 0.05f;
        float av = angVel * rk;
        float td = atan2(field.normalizeX(-(cp.x - pos.x)), cp.y - pos.y);
        float ad = Math.normalizeDeg(td - deg);
        av *= (2.5f - er);
        if (ad > av || ad < -PI * 0.8f)
          deg += av;
        else if (ad < -av)
          deg -= av;
        else
          deg = td;
        assert(deg <>= 0);
        for (int i = 0; i < turretNum; i++) {
          TurretState ts = turretStates[i];
          float tx = pos.x;
          float ty = pos.y;
          switch (i) {
          case 0:
            break;
          case 1:
            tx -= turretWidth;
            break;
          case 2:
            tx += turretWidth;
            break;
          default:
            break;
          }
          float turretDeg =
            atan2(field.normalizeX(-(player.pos.x - tx)), player.pos.y - ty);
          switch (gameState.mode) {
          case GameState.Mode.CLASSIC:
            if (turretDeg >= 0 && turretDeg < PI - PI / 6)
              turretDeg = PI - PI / 6;
            else if (turretDeg < 0 && turretDeg > -PI + PI / 6)
              turretDeg = -PI + PI / 6;
            turretDeg = cast(int) ((turretDeg + PI / 64) / (PI / 32)) * (PI / 32);
            break;
          case GameState.Mode.BASIC:
            if (turretDeg >= 0 && turretDeg < PI - PI / 4)
              turretDeg = PI - PI / 4;
            else if (turretDeg < 0 && turretDeg > -PI + PI / 4)
              turretDeg = -PI + PI / 4;
            break;
          case GameState.Mode.MODERN:
            break;
          default:
            break;
          }
          ts.update(tx, ty, turretDeg);
        }
        movePhase(es);
        sizeVel.x += (targetSize.x - size.x) * 0.2f;
        sizeVel.y += (targetSize.y - size.y) * 0.2f;
        size += sizeVel;
        sizeVel *= 0.95f;
      }
      return true;
    }
  }

  private void moveCaptured(EnemyState es) {
    with (es) {
      switch (captureState) {
      case 1:
        vel.x += (player.pos.x - pos.x) * 0.03f;
        vel.y += (player.pos.y - pos.y) * 0.03f;
        pos.x += (player.pos.x - pos.x) * 0.03f;
        pos.y += (player.pos.y - pos.y) * 0.03f;
        deg *= 0.95f;
        if (player.pos.dist(pos) < 1)
          captureState = 2;
        break;
      case 2:
        float cx = calcCapturePosX(captureIdx);
        vel.x += (player.pos.x + cx - pos.x) * 0.03f;
        pos.x += (player.pos.x + cx - pos.x) * 0.1f;
        pos.y += (player.pos.y - pos.y) * 0.33f;
        vel.y *= 0.6f;
        deg *= 0.95f;
        if (fabs(player.pos.x + cx - pos.x) < 0.2f)
          captureState = 3;
        break;
      case 3:
        float cx = calcCapturePosX(captureIdx);
        pos.x = player.pos.x + cx;
        pos.y = player.pos.y;
        deg = player.deg;
        break;
      default:
        break;
      }
      vel *= 0.9f;
      pos += vel;
    }
  }

  private float calcCapturePosX(int idx) {
    if (idx % 2 == 0)
      return ((idx / 2) + 0.5f) * PlayerSpec.CAPTURED_ENEMIES_INTERVAL_LENGTH * player.capturedEnemyWidth;
    else
      return -((idx / 2) + 0.5f) * PlayerSpec.CAPTURED_ENEMIES_INTERVAL_LENGTH * player.capturedEnemyWidth;
  }

  private void checkCaptured(EnemyState es) {
    with (es) {
      if (player.isInTractorBeam(pos)) {
        if (gameState.mode != GameState.Mode.MODERN) {
          int idx = player.addCapturedEnemy(es.enemy);
          if (idx >= 0) {
            captureState = 1;
            captureIdx = idx;
          }
        } else {
          provacated(es);
        }
      }
    }
  }

  public void hitCaptured(EnemyState es) {
    player.destroyCapturedEnemies(es.captureIdx);
  }

  public bool isBeingCaptured(EnemyState es) {
    return (es.captureState > 0);
  }

  public bool isCaptured(EnemyState es) {
    return (es.captureState == 3);
  }

  public bool beforeAlign(EnemyState es) {
    return (es.phase < -10);
  }

  public bool hitShot(EnemyState es, float dd = 0) {
    with (es) {
      shield--;
      float r = 0.5f + rand.nextFloat(0.5f);
      float g = 0.1f + rand.nextFloat(0.5f);
      float b = 0.5f + rand.nextFloat(0.5f);
      for (int i = 0; i < 10; i++) {
        Particle p;
        float d;
        p = particles.getInstanceForced();
        d = dd + rand.nextSignedFloat(PI / 4);
        p.set(Particle.Shape.LINE, pos.x, pos.y, d, 0.1f + rand.nextFloat(0.5f), 1,
              r, g, b, 30 + rand.nextInt(30));
        p = particles.getInstanceForced();
        d = dd + PI + rand.nextSignedFloat(PI / 4);
        p.set(Particle.Shape.LINE, pos.x, pos.y, d, 0.1f + rand.nextFloat(0.5f), 1,
              r, g, b, 30 + rand.nextInt(30));
      }
      if (shield <= 0) {
        destroyed(es, dd);
        return true;
      }
      switch (gameState.mode) {
      case GameState.Mode.CLASSIC:
        targetSize.x *= 1.3f;
        targetSize.y *= 1.3f;
        break;
      case GameState.Mode.BASIC:
        targetSize.x *= 1.2f;
        targetSize.y *= 1.2f;
        break;
      case GameState.Mode.MODERN:
        targetSize.x *= 1.01f;
        targetSize.y *= 1.01f;
        break;
      default:
        break;
      }
      sizeVel.x = 0.3f;
      sizeVel.y = 0.3f;
      return false;
    }
  }

  public void destroyed(EnemyState es, float dd = 0) {
    with (es) {
      float r = 0.5f + rand.nextFloat(0.5f);
      float g = 0.1f + rand.nextFloat(0.5f);
      float b = 0.5f + rand.nextFloat(0.5f);
      float sz = (targetSize.x + targetSize.y) / 2;
      sz = (sz - 1) * 2 + 1;
      int n = 3 + rand.nextInt(2);
      n *= sz;
      for (int i = 0; i < n; i++) {
        Particle p = particles.getInstanceForced();
        float d = dd + rand.nextSignedFloat(PI / 5);
        p.set(Particle.Shape.TRIANGLE, pos.x, pos.y, d, 0.5f,
              (2 + rand.nextFloat(0.5f)) * sz, r, g, b, 50 + rand.nextInt(100));
      }
      for (int i = 0; i < n; i++) {
        Particle p = particles.getInstanceForced();
        float d = rand.nextFloat(PI * 2);
        p.set(Particle.Shape.QUAD, pos.x, pos.y, d, 0.1f + rand.nextFloat(0.1f),
              (1 + rand.nextFloat(0.5f)) * sz, r, g, b, 50 + rand.nextInt(100));
      }
      if (!isBeingCaptured(es)) {
        if (removeBullets) {
          int cnt = 1;
          bullets.removeAround(cnt, pos, particles, bonusParticles, player);
          Particle p = bonusParticles.getInstanceForced();
          int wc;
          if (cnt <= 50)
            wc = cnt;
          else
            wc = 50 + cast(int) sqrt(cast(float) (cnt - 50));
          p.set(Particle.Shape.BONUS, pos.x, pos.y, 0, 0.1f,
                1.0f + cast(float) wc / 75, 1, 1, 1, 120, false, cnt, wc);
          player.addScore(score * cnt);
        } else {
          if (gameState.mode == GameState.Mode.BASIC) {
            float oy = pos.y - player.pos.y;
            int pm = cast(int) (18 - oy);
            if (pm > 16)
              pm = 16;
            else if (pm < 1)
              pm = 1;
            player.addScore(score * pm);
            Particle p = bonusParticles.getInstanceForced();
            p.set(Particle.Shape.BONUS, pos.x, pos.y, 0, 0.1f,
                  0.5f, 1, 1, 1, 60, false, pm);
            gameState.setProximityMultiplier(pm);
          } else {
            player.addScore(score);
          }
        }
        player.addMultiplier(0.1f);
        if (stage.existsCounterBullet) {
          Bullet blt = bullets.getInstance();
          if (blt)
            blt.set(counterBulletSpec, pos,
                    turretStates[0].deg, turretSpecs[0].speed * TurretSpec.SPEED_RATIO);
        }
      }
      Sound.playSe(explosionSeName);
    }
  }

  public void provacated(EnemyState es) {
    with (es) {
      anger += (1 - anger) * 0.05f;
      if (sizeVel.dist < 0.1f) {
        sizeVel.x = 0.2f;
        sizeVel.y = 0.2f;
      }
      Particle p;
      p = particles.getInstanceForced();
      p.set(Particle.Shape.LINE, pos.x, pos.y, PI / 2 + rand.nextSignedFloat(PI / 4),
            0.1f + rand.nextFloat(0.2f), 1,
            1, 0.5f, 0.5f, 30 + rand.nextInt(30));
      p = particles.getInstanceForced();
      p.set(Particle.Shape.LINE, pos.x, pos.y, -PI / 2 + rand.nextSignedFloat(PI / 4),
            0.1f + rand.nextFloat(0.2f), 1,
            1, 0.5f, 0.5f, 30 + rand.nextInt(30));
      if (removeBullets)
        player.midEnemyProvacated();
    }
  }

  protected bool gotoNextPhaseInAppearing(EnemyState es) {
    with (es) {
      switch (phase) {
      case -300:
        float cpw;
        switch (gameState.mode) {
        case GameState.Mode.CLASSIC:
        case GameState.Mode.BASIC:
          cpw = 0.2f;
          break;
        case GameState.Mode.MODERN:
          cpw = 0.4f;
          break;
        default:
          break;
        }
        centerPos.x = rand.nextSignedFloat(field.size.x * cpw);
        centerPos.y = field.size.y * 2.0f;
        standByPos.x = rand.nextSignedFloat(field.size.x * cpw);
        standByPos.y = field.size.y * (0.7f + rand.nextFloat(0.1f));
        nextPhaseCnt = 15;
        baseSpeed = baseBaseSpeed * 1.5f;
        angVel = baseAngVel * 1.5f;
        phase = -50;
        break;

      case -200:
        centerPos.x = rand.nextSignedFloat(field.size.x * 0.1f);
        centerPos.y = field.size.y * 1.6f;
        if (centerPos.x < 0)
          standByPos.x = field.size.x * (rand.nextSignedFloat(0.4f) + 0.4f);
        else
          standByPos.x = field.size.x * (rand.nextSignedFloat(0.4f) - 0.4f);
        standByPos.y = field.size.y * (0.5f + rand.nextFloat(0.3f));
        nextPhaseCnt = 60;
        baseSpeed = baseBaseSpeed * 1.0f;
        angVel = baseAngVel * 1.0f;
        break;
      case -199:
        if (standByPos.x < 0)
          centerPos.x = field.size.x * 0.75f;
        else
          centerPos.x = -field.size.x * 0.75f;
        centerPos.y = 0;
        if (isGoingDownBeforeStandBy)
          nextPhaseCnt = 20;
        else
          nextPhaseCnt = 60;
        baseSpeed = baseBaseSpeed * 2;
        angVel = baseAngVel * 2;
        phase = -50;
        break;

      case -100:
        centerPos.x = field.size.x * 4.0f;
        if (rand.nextInt(2) == 0)
          centerPos.x *= -1;
        centerPos.y = field.size.y * 1.6f;
        if (centerPos.x < 0)
          standByPos.x = field.size.x * (rand.nextSignedFloat(0.4f) + 0.4f);
        else
          standByPos.x = field.size.x * (rand.nextSignedFloat(0.4f) - 0.4f);
        standByPos.y = field.size.y * (0.5f + rand.nextFloat(0.3f));
        nextPhaseCnt = 20;
        baseSpeed = baseBaseSpeed * 2.0f;
        angVel = baseAngVel * 2.0f;
        break;
      case -99:
        if (centerPos.x > 0)
          centerPos.x = field.size.x * 2.0f;
        else
          centerPos.x = -field.size.x * 2.0f;
        centerPos.y = -field.size.y * 1.2f;
        nextPhaseCnt = 20;
        baseSpeed = baseBaseSpeed * 2;
        angVel = baseAngVel * 2;
        break;
      case -98:
        if (centerPos.x > 0)
          centerPos.x = field.size.x * 0.5f;
        else
          centerPos.x = -field.size.x * 0.5f;
        centerPos.y = 0;
        nextPhaseCnt = 30;
        phase = -50;
        break;

     case -49:
        if (isGoingDownBeforeStandBy) {
          centerPos.x = centerPos.x / 2;
          centerPos.y = 0;
          phase = -30;
          nextPhaseCnt = 10;
          break;
        }
        centerPos.x = standByPos.x;
        centerPos.y = standByPos.y;
        nextPhaseCnt = calcStandByTime(es);
        baseSpeed = baseBaseSpeed;
        angVel = baseAngVel;
        phase = -10;
        break;

      case -29:
        centerPos.x = (centerPos.x + player.pos.x * 2) / 3;
        centerPos.y = -field.size.y * 1.2f;
        baseSpeed = baseBaseSpeed * 1.2f;
        angVel = baseAngVel * 1.2f;
        nextPhaseCnt = 5;
        break;
      case -28:
        centerPos.y = -field.size.y * 1.5f;
        nextPhaseCnt = 10;
        break;
      case -9:
        phase = 0;
        break;
      default:
        return false;
      }
      nextPhaseCnt /= rank;
      phaseCnt = 0;
    }
    return true;
  }

  public void movePhase(EnemyState es) {
    with (es) {
      switch (phase) {
      case -200:
      case -100:
        if (pos.y < field.size.y * 1.5f)
          pos.y = field.size.y * 1.5f;
        break;
      case -99:
        if (centerPos.x < 0 && pos.x > -field.size.x)
          pos.x += (-field.size.x - pos.x) * 0.2f;
        else if (centerPos.x > 0 && pos.x < field.size.x)
          pos.x += (field.size.x - pos.x) * 0.2f;
        break;
      case -50:
      case -49:
      case -10:
        if (pos.y < -field.size.y * 0.5f)
          pos.y += (-field.size.y * 0.5f - pos.y) * 0.2f;
        break;
      default:
        break;
      }
      if (isInAttack(es))
        if (gameState.mode == GameState.Mode.MODERN ||
            phase >= 0 || rand.nextInt(5) == 0)
          for (int i = 0; i < turretNum; i++)
            turretSpecs[i].move(turretStates[i], rank, anger);
    }
  }

  public bool isInScreen(EnemyState es) {
    return (field.size.contains(es.pos));
  }

  public abstract void setRank(float rank);
  public abstract void init(EnemyState es);
  public abstract bool gotoNextPhase(EnemyState es);
  public abstract bool isInAttack(EnemyState es);
  protected abstract int calcStandByTime(EnemyState es);

  public override void draw(EnemyState es) {
    Vector3 p = field.calcCircularPos(es.pos);
    float cd = field.calcCircularDeg(es.pos.x);
    (cast(EnemyShape) shape).draw(p, cd, es.deg, es.cnt, es.size);
    for (int i = 1; i < turretNum; i++) {
      float x = es.pos.x;
      switch (i) {
      case 1:
        x -= turretWidth;
        break;
      case 2:
        x += turretWidth;
        break;
      default:
        break;
      }
      p = field.calcCircularPos(x, es.pos.y);
      cd = field.calcCircularDeg(x);
      Screen.setColor(0.5f, 0.5f, 1);
      (cast(EnemyShape) trailShape).draw(p, cd, es.deg, es.cnt,
                                         es.size.x * 0.5f, es.size.y * 0.5f);
    }
  }

  public void drawTrails(EnemyState es) {
    if (es.captureState > 0)
      return;
    es.drawTrails(trailShape, 0.2f, 0.2f, 0.8f, es.size, field);
  }
}

public class Trail {
 private:
  Vector pos;
  float deg;
  int cnt;

  invariant() {
    assert(pos.x <>= 0);
    assert(pos.y <>= 0);
    assert(deg <>= 0);
  }

  public this() {
    pos = new Vector;
    deg = 0;
  }

  public void set(float x, float y, float d, int c) {
    pos.x = x;
    pos.y = y;
    deg = d;
    cnt = c;
  }
}

public class GhostEnemySpec: EnemySpec {
 private:

  public this(Field field, Shape shape) {
    this.field = field;
    this.shape = shape;
  }

  public override void draw(EnemyState es) {
    with (es) {
      Vector3 p = field.calcCircularPos(pos);
      float cd = field.calcCircularDeg(pos.x);
      Screen.setColor(0.5f, 0.5f, 1, 0.8f);
      (cast(EnemyShape) shape).draw(p, cd, deg, cnt, size);
    }
  }

  public override void set(EnemyState es) {}
  public override bool move(EnemyState es) { return true; }
  public override void destroyed(EnemyState es, float dd = 0) {}
  public override void setRank(float rank) {}
  public override void init(EnemyState es) {}
  public override bool gotoNextPhase(EnemyState es) { return false; }
  public override bool isInAttack(EnemyState es) { return false; }
  protected override int calcStandByTime(EnemyState es) { return 0; }
  public override bool isBeingCaptured(EnemyState es) { return true; }
  public override bool isCaptured(EnemyState es) { return true; }
}

public class MiddleEnemySpec: EnemySpec {
 private:

  public this(Field field, BulletPool bullets, Player player,
              ParticlePool particles, ParticlePool bonusParticles,
              EnemyPool enemies, Stage stage,
              Shape shape, EnemyShape trailShape,
              BulletSpec bulletSpec, BulletSpec counterBulletSpec,
              GameState gameState) {
    super(field, bullets, player, particles, bonusParticles, enemies, stage,
          shape, trailShape, bulletSpec, counterBulletSpec, gameState);
    foreach (ref TurretSpec ts; turretSpecs)
      ts = new TurretSpec(field, bullets, player, enemies, particles,
                          stage, bulletSpec, gameState);
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      shield = 2;
      capturable = false;
      removeBullets = false;
      break;
    case GameState.Mode.BASIC:
      shield = 3;
      capturable = false;
      removeBullets = false;
      break;
    case GameState.Mode.MODERN:
      shield = 32;
      capturable = true;
      removeBullets = true;
      break;
    default:
      break;
    }
    score = 100;
    explosionSeName = "explosion3.wav";
  }

  public override void init(EnemyState es) {
    with (es) {
      size.x = size.y = 1.33f;
      phase = -300;
      gotoNextPhaseInAppearing(es);
    }
  }

  public override void setRank(float r) {
    rank = sqrt(r);
    float tr;
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      rank = sqrt(rank);
      tr = r * 2;
      break;
    case GameState.Mode.BASIC:
      tr = r * 3;
      break;
    case GameState.Mode.MODERN:
      rank = 1;
      tr = r * 15;
      break;
    default:
      break;
    }
    if (rank < 1.5f)
      rank = 1.5f;
    turretSpecs[0].setRankMiddle(tr);
    turretNum = 1;
    if (gameState.mode == GameState.Mode.MODERN) {
      TurretSpec ts = turretSpecs[0];
      int ptn = rand.nextInt(6);
      switch (ptn) {
      case 0:
        break;
      case 1:
      case 2:
      case 4:
        turretSpecs[1].copy(turretSpecs[0]);
        turretSpecs[2].copy(turretSpecs[0]);
        if (ts.nway > 1 && rand.nextInt(2) == 0) {
          float nsa = (ts.speed * (0.2f + ts.nway * 0.05f + rand.nextFloat(0.1f))) / (ts.nway - 1);
          if (rand.nextInt(2) == 0)
            nsa *= -1;
          turretSpecs[1].nwaySpeedAccel = nsa;
          turretSpecs[2].nwaySpeedAccel = -nsa;
        }
        turretWidth = 1.0f + rand.nextFloat(1.0f);
        turretNum = 3;
        if (ptn == 4) {
          turretSpecs[0].setRankMiddle(tr * 2);
          turretSpecs[1].interval *= 4;
          turretSpecs[2].interval *= 4;
          turretSpecs[0].interval = turretSpecs[1].interval;
          turretSpecs[2].fireIntervalRatio = 0.25f;
          turretSpecs[0].fireIntervalRatio = 0.5f;
        } else {
          turretSpecs[0].disabled = true;
          turretSpecs[1].interval *= 2;
          turretSpecs[2].interval *= 2;
          if (rand.nextInt(2) == 0)
            turretSpecs[2].fireIntervalRatio = 0.5f;
        }
        break;
      case 3:
      case 5:
        turretSpecs[0].interval *= 2;
        if (rand.nextInt(3) == 0)
          turretSpecs[0].nwayAngle *= 0.1f;
        turretSpecs[1].setRankMiddle(tr);
        turretSpecs[1].interval *= 2;
        turretSpecs[2].copy(turretSpecs[1]);
        if (ts.nway > 1 && rand.nextInt(2) == 0) {
          float nsa = (ts.speed * (0.2f + ts.nway * 0.05f + rand.nextFloat(0.1f))) / (ts.nway - 1);
          if (rand.nextInt(2) == 0)
            nsa *= -1;
          turretSpecs[1].nwaySpeedAccel = nsa;
          turretSpecs[2].nwaySpeedAccel = -nsa;
        }
        turretSpecs[1].nwayBaseDeg = -PI / 8 - rand.nextFloat(PI / 12);
        if (turretSpecs[1].nway > 1)
          turretSpecs[1].nwayBaseDeg -= turretSpecs[1].nwayAngle * (turretSpecs[1].nway - 1) / 2;
        turretSpecs[2].nwayBaseDeg = -turretSpecs[1].nwayBaseDeg;
        turretWidth = 1.5f + rand.nextFloat(0.5f);
        turretNum = 3;
        break;
      default:
        break;
      }
    }
  }

  public override bool gotoNextPhase(EnemyState es) {
    with (es) {
      if (phase < 0)
        return gotoNextPhaseInAppearing(es);
      switch (phase) {
      case 1:
        if (gameState.mode != GameState.Mode.MODERN && !player.hasCollision) {
          phase = 0;
          nextPhaseCnt = calcStandByTime(es);
          break;
        }
        Sound.playSe("flying_down.wav");
        if (gameState.mode != GameState.Mode.MODERN) {
          centerPos.x = field.size.x * (0.6f + rand.nextSignedFloat(0.1f));
          if (rand.nextInt(2) == 0)
            centerPos.x *= -1;
          centerPos.y = field.size.y * (0.2f + rand.nextFloat(0.2f));
          nextPhaseCnt = 60;
        } else {
          centerPos.x = standByPos.x;
          centerPos.y = field.size.y * 0.95f;
          baseSpeed = baseBaseSpeed * 0.3f;
          nextPhaseCnt = 60;
        }
        break;
      case 2:
        if (gameState.mode != GameState.Mode.MODERN) {
          centerPos.x *= -0.9f;
          centerPos.y = field.size.y * (0.2f + rand.nextFloat(0.2f));
          nextPhaseCnt = 60;
        } else {
          centerPos.x = standByPos.x;
          centerPos.y = 0;
          baseSpeed = baseBaseSpeed * 0.1f;
          nextPhaseCnt = 10;
        }
        break;
      case 3:
        if (gameState.mode != GameState.Mode.MODERN) {
          centerPos.x = standByPos.x;
          centerPos.y = standByPos.y;
          phase = 0;
          nextPhaseCnt = calcStandByTime(es);
        } else {
          centerPos.x = standByPos.x;
          centerPos.y = -field.size.y * 1.5f;
          baseSpeed = baseBaseSpeed * 0.5f;
          nextPhaseCnt = 10;
        }
        break;
      default:
        return false;
      }
      nextPhaseCnt /= rank;
      phaseCnt = 0;
    }
    return true;
  }

  public override bool isInAttack(EnemyState es) {
    return (es.phase == 1 || es.phase == 2);
  }

  protected override int calcStandByTime(EnemyState es) {
    if (es.phase < 0 || gameState.mode == GameState.Mode.MODERN)
      return 30 + rand.nextInt(30);
    else
      return 200 + rand.nextInt(150);
  }
}

public class SmallEnemySpec: EnemySpec {
 private:

  public this(Field field, BulletPool bullets, Player player,
              ParticlePool particles, ParticlePool bonusParticles,
              EnemyPool enemies, Stage stage,
              Shape shape, EnemyShape trailShape,
              BulletSpec bulletSpec, BulletSpec counterBulletSpec,
              GameState gameState) {
    super(field, bullets, player, particles, bonusParticles, enemies, stage,
          shape, trailShape, bulletSpec, counterBulletSpec, gameState);
    turretSpecs[0] = new TurretSpec(field, bullets, player, enemies, particles,
                                    stage, bulletSpec, gameState);
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
    case GameState.Mode.BASIC:
      shield = 1;
      break;
    case GameState.Mode.MODERN:
      shield = 2;
      break;
    default:
      break;
    }
    capturable = true;
    score = 10;
    removeBullets = false;
  }

  public override void init(EnemyState es) {
    gotoNextPhaseInAppearing(es);
  }

  public void init(EnemyState es, EnemyState fes) {
    with (es) {
      centerPos.x = fes.centerPos.x;
      centerPos.y = fes.centerPos.y;
      standByPos.x = fes.standByPos.x;
      standByPos.y = fes.standByPos.y;
      nextPhaseCnt = fes.nextPhaseCnt;
      baseSpeed = fes.baseSpeed;
      angVel = fes.angVel;
      phase = fes.phase;
      size.x = size.y = 1.25f;
    }
  }

  public override void setRank(float r) {
    rank = sqrt(r * 0.5f);
    float tr;
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      rank = sqrt(rank);
      tr = r;
      break;
    case GameState.Mode.BASIC:
      tr = r * 2;
      break;
    case GameState.Mode.MODERN:
      rank = 1;
      tr = r;
      break;
    default:
      break;
    }
    if (rank < 1)
      rank = 1;
    turretSpecs[0].setRankNormal(tr);
    turretNum = 1;
  }

  protected override int calcStandByTime(EnemyState es) {
    return 60 + rand.nextInt(120);
  }
}

public class SE1Spec: SmallEnemySpec {
private:

  public this(Field field, BulletPool bullets, Player player,
              ParticlePool particles, ParticlePool bonusParticles,
              EnemyPool enemies, Stage stage,
              Shape shape, EnemyShape trailShape,
              BulletSpec bulletSpec, BulletSpec counterBulletSpec,
              GameState gameState) {
    super(field, bullets, player, particles, bonusParticles, enemies, stage,
          shape, trailShape, bulletSpec, counterBulletSpec, gameState);
    explosionSeName = "explosion1.wav";
  }

  public override bool gotoNextPhase(EnemyState es) {
    with (es) {
      if (phase < 0)
        return gotoNextPhaseInAppearing(es);
      switch (phase) {
      case 1:
        if (!player.hasCollision || enemies.numInAttack > stage.attackSmallEnemyNum) {
          phase = 0;
          nextPhaseCnt = calcStandByTime(es);
          break;
        }
        Sound.playSe("flying_down.wav");
        centerPos.y = 0;
        centerPos.x = (standByPos.x + player.pos.x) / 2;
        nextPhaseCnt = 60;
        break;
      case 2:
        centerPos.y = -field.size.y * 0.7f;
        centerPos.x = player.pos.x;
        nextPhaseCnt = 30;
        break;
      case 3:
        centerPos.x = standByPos.x;
        centerPos.y = standByPos.y;
        phase = 0;
        nextPhaseCnt = calcStandByTime(es);
        break;
      default:
        break;
      }
      nextPhaseCnt /= rank;
      phaseCnt = 0;
    }
    return true;
  }

  public override bool isInAttack(EnemyState es) {
    return (es.phase < -10 || es.phase == 1 || es.phase == 2);
  }
}

public class SE2Spec: SmallEnemySpec {
private:

  public this(Field field, BulletPool bullets, Player player,
              ParticlePool particles, ParticlePool bonusParticles,
              EnemyPool enemies, Stage stage,
              Shape shape, EnemyShape trailShape,
              BulletSpec bulletSpec, BulletSpec counterBulletSpec,
              GameState gameState) {
    super(field, bullets, player, particles, bonusParticles, enemies, stage,
          shape, trailShape, bulletSpec, counterBulletSpec, gameState);
    explosionSeName = "explosion2.wav";
  }

  public override bool gotoNextPhase(EnemyState es) {
    with (es) {
      if (phase < 0)
        return gotoNextPhaseInAppearing(es);
      switch (phase) {
      case 1:
        if (!player.hasCollision || enemies.numInAttack > stage.attackSmallEnemyNum) {
          phase = 0;
          nextPhaseCnt = calcStandByTime(es);
          break;
        }
        Sound.playSe("flying_down.wav");
        centerPos.y = -field.size.y * 0.3f;
        centerPos.x = (standByPos.x + player.pos.x) / 2;
        baseSpeed = baseBaseSpeed;
        angVel = baseAngVel;
        nextPhaseCnt = 30 + rand.nextInt(60);
        break;
      case 2:
        centerPos.y = -field.size.y * 1.3f;
        centerPos.x *= -1;
        nextPhaseCnt = 30;
        break;
      case 3:
        centerPos.y = -field.size.y * 1.0f;
        if (centerPos.x < 0)
          centerPos.x = -field.size.x * 1.5f;
        else
          centerPos.x = field.size.x * 1.5f;
        baseSpeed = baseBaseSpeed * 1.5f;
        angVel = baseAngVel * 1.5f;
        nextPhaseCnt = 30;
        break;
      case 4:
        centerPos.x = standByPos.x;
        centerPos.y = standByPos.y;
        phase = 0;
        nextPhaseCnt = calcStandByTime(es);
        break;
      default:
        break;
      }
      nextPhaseCnt /= rank;
      phaseCnt = 0;
    }
    return true;
  }

  public override void movePhase(EnemyState es) {
    super.movePhase(es);
    with (es) {
      if (phase == 3) {
        if (centerPos.x < 0) {
          if (pos.x > -field.size.x * 1.2f)
            pos.x += (centerPos.x - pos.x) * 0.2f;
        } else {
          if (pos.x < field.size.x * 1.2f)
            pos.x += (centerPos.x - pos.x) * 0.2f;
        }
      }
    }
  }

  public override bool isInAttack(EnemyState es) {
    return (es.phase < -10 || es.phase == 1 || es.phase == 2 || es.phase == 3);
  }
}

public class TurretState: TokenState {
 private:
  float fireCnt, burstCnt;
  int burstNum;
  int nwaySpeedAccelDir;

  invariant() {
    if (isInitialized) {
      assert(fireCnt <>= 0);
      assert(burstCnt <>= 0);
    }
  }

  public override void clear() {
    fireCnt = burstCnt = 0;
    burstNum = 0;
    nwaySpeedAccelDir = 1;
    super.clear();
  }

  public void update(float x, float y, float d) {
    pos.x = x;
    pos.y = y;
    if (burstNum <= 0)
      deg = d;
  }
}

public class TurretSpec: TokenSpec!(TurretState) {
  mixin StaticRandImpl;
 public:
  static const float SPEED_RATIO = 5.0f;
 private:
  static const float INTERVAL_MAX = 90.0f;
  BulletSpec bulletSpec;
  BulletPool bullets;
  Player player;
  Stage stage;
  GameState gameState;
  int interval;
  float speed;
  float speedAccel;
  int burstNum, burstInterval;
  int nway;
  float nwayAngle;
  float nwayBaseDeg;
  float nwaySpeedAccel;
  bool fireingAtATime;
  float fireIntervalRatio;
  bool _disabled;
  float minimumFireDist;

  invariant() {
    assert(interval > 0);
    assert(speed > 0);
    assert(speedAccel < 1 && speedAccel > -1);
    assert(burstNum >= 1);
    assert(burstInterval >= 0);
    assert(nway >= 1);
    assert(nwayAngle >= 0);
    assert(nwayBaseDeg <>= 0);
    assert(nwaySpeedAccel <>= 0);
    assert(fireIntervalRatio <>= 0);
    assert(minimumFireDist >= 0);
  }

  public this(Field field, BulletPool bullets, Player player,
              EnemyPool enemies, ParticlePool particles,
              Stage stage, BulletSpec bulletSpec, GameState gameState) {
    this.bulletSpec = bulletSpec;
    this.field = field;
    this.bullets = bullets;
    this.player = player;
    this.stage = stage;
    this.gameState = gameState;
    initParam();
  }

  private void initParam() {
    interval = 99999;
    speed = 1;
    speedAccel = 0;
    burstNum = 1;
    burstInterval = 99999;
    nway = 1;
    nwayAngle = 0;
    nwayBaseDeg = 0;
    nwaySpeedAccel = 0;
    fireingAtATime = false;
    fireIntervalRatio = 0;
    _disabled = false;
    minimumFireDist = 0;
  }

  public void copy(TurretSpec ts) {
    interval = ts.interval;
    speed = ts.speed;
    speedAccel = ts.speedAccel;
    burstNum = ts.burstNum;
    burstInterval = ts.burstInterval;
    nway = ts.nway;
    nwayAngle = ts.nwayAngle;
    nwayBaseDeg = ts.nwayBaseDeg;
    nwaySpeedAccel = ts.nwaySpeedAccel;
    fireingAtATime = ts.fireingAtATime;
  }

  public override void set(TurretState ts) {
    setFireIntervalRatio(ts, fireIntervalRatio);
  }

  public void setFireIntervalRatio(TurretState ts, float fir) {
    ts.fireCnt = fir * interval;
  }

  public void setRankNormal(float rank, bool isWide = false) {
    initParam();
    float rr = rand.nextFloat(0.5f);
    float nsr = 0.5f + rand.nextSignedFloat(0.3f);
    float nr, br, ir;
    float intervalMax = INTERVAL_MAX;
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      nr = br = 0;
      ir = sqrt(rank * nsr) * 2;
      burstInterval = 3 + rand.nextInt(2);
      break;
    case GameState.Mode.BASIC:
      if (isWide) {
        nr = (rank * nsr * rr);
        br = 0;
        ir = (rank * nsr * (1 - rr));
      } else {
        nr = 0;
        br = (rank * nsr * rr);
        ir = (rank * nsr * (1 - rr));
      }
      burstInterval = 3 + rand.nextInt(2);
      break;
    case GameState.Mode.MODERN:
      if (isWide) {
        nr = (rank * nsr * rr);
        br = 0;
        ir = (rank * nsr * (1 - rr));
      } else {
        nr = 0;
        br = (rank * nsr * rr);
        ir = (rank * nsr * (1 - rr));
      }
      intervalMax = 120;
      burstInterval = 4 + rand.nextInt(4);
      break;
    default:
      break;
    }
    burstNum = cast(int) sqrt(br) + 1;
    nway = cast(int) sqrt(nr) + 1;
    interval = cast(int) (intervalMax / (ir + 1)) + 1;
    float sr = rank - nway + 1 - burstNum + 1 - ir;
    if (sr < 0.01f)
      sr = 0.01f;
    speed = sqrt(sr * 0.66f);
    assert(speed > 0);
    speed *= 0.2f;
    if (speed < 0.1f)
      speed = 0.1f;
    else
      speed = sqrt(speed * 10) / 10;
    assert(speed > 0);
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      speed *= 0.36f;
      if (speed < 0.05f)
        speed = 0.05f;
      else
        speed = sqrt(speed * 20) / 20;
      break;
    case GameState.Mode.BASIC:
      speed *= 0.33f;
      break;
    case GameState.Mode.MODERN:
      speed *= 0.25f;
      if (speed < 0.04f)
        speed = 0.04f;
      if (speed > 0.04f)
        speed = sqrt(speed * 25) / 25;
      break;
    default:
      break;
    }
    nwayAngle = (1.66f + rand.nextFloat(0.33f)) / (1 + nway * 0.7f) * 0.06f;
    fireingAtATime = true;
    minimumFireDist = 10;
  }

  public void setRankMiddle(float rank) {
    initParam();
    float nr, br, ir;
    float nwayDegRatio;
    float intervalMax = INTERVAL_MAX;
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      nr = br = 0;
      ir = sqrt(rank * (0.5f + rand.nextSignedFloat(0.3f))) * 2;
      nwayDegRatio = 0;
      burstInterval = 3 + rand.nextInt(2);
      break;
    case GameState.Mode.BASIC:
      if (rand.nextInt(3) == 0) {
        nr = 0;
        br = (rank * 0.4f) * (1.0f + rand.nextSignedFloat(0.2f));
        ir = (rank * 0.5f) * (1.0f + rand.nextSignedFloat(0.2f));
      } else {
        rank *= 0.5f;
        nr = (rank * 0.3f) * (1.0f + rand.nextSignedFloat(0.2f));
        br = (rank * 0.3f) * (1.0f + rand.nextSignedFloat(0.2f));
        ir = (rank * 0.3f) * (1.0f + rand.nextSignedFloat(0.2f));
      }
      ir *= 1.5f;
      nwayDegRatio = 0.06f;
      burstInterval = 3 + rand.nextInt(2);
      break;
    case GameState.Mode.MODERN:
      switch (rand.nextInt(5)) {
      case 0:
        rank *= 1.2f;
        nr = 0;
        br = (rank * 0.7f) * (1.0f + rand.nextSignedFloat(0.2f));
        ir = (rank * 0.2f) * (1.0f + rand.nextSignedFloat(0.2f));
        break;
      case 1:
      case 2:
        nr = (rank * 0.7f) * (1.0f + rand.nextSignedFloat(0.2f));
        br = 0;
        ir = (rank * 0.2f) * (1.0f + rand.nextSignedFloat(0.2f));
        break;
      case 3:
      case 4:
        rank *= 0.75f;
        nr = (rank * 0.3f) * (1.0f + rand.nextSignedFloat(0.2f));
        br = (rank * 0.3f) * (1.0f + rand.nextSignedFloat(0.2f));
        ir = (rank * 0.3f) * (1.0f + rand.nextSignedFloat(0.2f));
        break;
      default:
        break;
      }
      nwayDegRatio = 1;
      intervalMax = 120;
      burstInterval = 4 + rand.nextInt(8);
      break;
    default:
      break;
    }
    bool acf = false;
    burstNum = cast(int) sqrt(br) + 1;
    if (burstNum > 1 && rand.nextInt(3) > 0) {
      acf = true;
      nr *= 0.9f;
      ir *= 0.9f;
      rank *= 0.9f;
    }
    nway = cast(int) sqrt(nr) + 1;
    interval = cast(int) (intervalMax / (sqrt(ir + 1))) + 1;
    float sr = rank - burstNum + 1 - nway + 1 - ir;
    if (sr < 0.01f)
      sr = 0.01f;
    speed = sqrt(sr * 0.66f);
    assert(speed > 0);
    speed *= 0.2f;
    if (speed < 0.1f)
      speed = 0.1f;
    else
      speed = sqrt(speed * 10) / 10;
    assert(speed > 0);
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      speed *= 0.36f;
      if (speed < 0.05f)
        speed = 0.05f;
      else
        speed = sqrt(speed * 20) / 20;
      break;
    case GameState.Mode.BASIC:
      speed *= 0.4f;
      break;
    case GameState.Mode.MODERN:
      speed *= 0.22f;
      if (speed < 0.04f)
        speed = 0.04f;
      if (speed > 0.04f)
        speed = sqrt(speed * 25) / 25;
      break;
    default:
      break;
    }
    if (acf) {
      speedAccel = (speed * (0.2f + burstNum * 0.05f + rand.nextFloat(0.1f))) / (burstNum - 1);
      if (rand.nextInt(2) == 0)
        speedAccel *= -1;
    }
    if (gameState.mode == GameState.Mode.BASIC && nway > 1 && rand.nextInt(3) == 0) {
      speed *= 0.9f;
      nwaySpeedAccel = (speed * (0.2f + nway * 0.05f + rand.nextFloat(0.1f))) / (nway - 1);
      if (rand.nextInt(2) == 0)
        nwaySpeedAccel *= -1;
    }
    if (nway > 1)
      nwayAngle = (1.66f + rand.nextFloat(0.33f)) / (1 + nway * 0.7f) * nwayDegRatio;
    if (rand.nextInt(3) == 0)
      fireingAtATime = true;
    minimumFireDist = 5;
  }

  public override bool move(TurretState ts) {
    return move(ts, 1);
  }

  public bool move(TurretState ts, float time, float anger = 0) {
    if (_disabled)
      return true;
    float itv = interval * ((1 - anger) * 0.99f + 0.01f);
    if (itv < 3)
      itv = 3;
    if (ts.fireCnt > itv)
      ts.fireCnt = itv;
    float spd = speed * (1 + anger * 0.2f);
    if (fireingAtATime) {
      ts.fireCnt -= time;
      if (ts.fireCnt <= 0) {
        ts.fireCnt = itv;
        if (ts.fireCnt < 3)
          ts.fireCnt = 3;
        if (isAbleToFire(ts.pos)) {
          float sp = spd - speedAccel * (burstNum - 1) / 2;
          for (int i = 0; i < burstNum; i++) {
            float d = ts.deg - nwayAngle * (nway - 1) / 2 + nwayBaseDeg;
            float nsp = sp - nwaySpeedAccel * ts.nwaySpeedAccelDir * (nway - 1) / 2;
            for (int j = 0; j < nway; j++) {
              Bullet b = bullets.getInstance();
              if (!b)
                break;
              b.set(bulletSpec, ts.pos, d, nsp * SPEED_RATIO);
              b.setWaitCnt(i * burstInterval);
              d += nwayAngle;
              nsp += nwaySpeedAccel * ts.nwaySpeedAccelDir;
            }
            sp += speedAccel;
          }
          ts.nwaySpeedAccelDir *= -1;
        }
      }
    } else {
      if (ts.burstNum <= 0) {
        ts.fireCnt -= time;
        if (ts.fireCnt <= 0) {
          ts.fireCnt = itv;
          if (ts.fireCnt < 3)
            ts.fireCnt = 3;
          ts.burstNum = burstNum;
          ts.burstCnt = 0;
          ts.speed = spd - speedAccel * (ts.burstNum - 1) / 2;
        }
      }
      if (ts.burstNum > 0) {
        ts.burstCnt -= time;
        if (ts.burstCnt <= 0) {
          ts.burstCnt = burstInterval;
          ts.burstNum--;
          if (isAbleToFire(ts.pos)) {
            float d = ts.deg - nwayAngle * (nway - 1) / 2 + nwayBaseDeg;
            float nsp = ts.speed - nwaySpeedAccel * ts.nwaySpeedAccelDir * (nway - 1) / 2;
            for (int i = 0; i < nway; i++) {
              Bullet b = bullets.getInstance();
              if (!b)
                break;
              b.set(bulletSpec, ts.pos, d, nsp * SPEED_RATIO);
              d += nwayAngle;
              nsp += nwaySpeedAccel * ts.nwaySpeedAccelDir;
            }
          }
          ts.speed += speedAccel;
        }
      }
    }
    return true;
  }

  private bool isAbleToFire(Vector p) {
    if (gameState.mode != GameState.Mode.MODERN)
      return (p.y > 0);
    else
      return (p.y > 0 && p.dist(player.pos) > minimumFireDist);
  }

  public bool disabled(bool v) {
    return _disabled = v;
  }
}
