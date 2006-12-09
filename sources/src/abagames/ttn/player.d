/*
 * $Id: player.d,v 1.4 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.player;

private import std.math;
private import opengl;
private import abagames.util.vector;
private import abagames.util.rand;
private import abagames.util.math;
private import abagames.util.actor;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.recordableinput;
private import abagames.ttn.field;
private import abagames.ttn.frame;
private import abagames.ttn.screen;
private import abagames.ttn.shape;
private import abagames.ttn.token;
private import abagames.ttn.enemy;
private import abagames.ttn.bullet;
private import abagames.ttn.particle;
private import abagames.ttn.sound;
private import abagames.ttn.letter;

/**
 * Player and shots.
 */
public class Player: Token!(PlayerState, PlayerSpec) {
 private:
  Vector hitOffset;

  public this(PlayerSpec spec) {
    state = new PlayerState;
    this.spec = spec;
    spec.setState(state);
    state.setSpec(spec);
    hitOffset = new Vector;
  }

  public bool replayMode(bool v) {
    return state.replayMode = v;
  }

  public void set() {
    state.set();
    spec.start();
    hitOffset.x = hitOffset.y = 0;
    spec.field.setEyePos(pos);
  }

  public bool checkBulletHit(Vector p, Vector pp) {
    with (state) {
      if (!hasCollision)
        return false;
      if (spec.field.checkHitDist(pos, p, pp, spec.bulletHitWidth)) {
        destroy();
        return true;
      }
      return false;
    }
  }

  public bool checkEnemyHit(Vector p, Vector v, Vector size) {
    if (spec.gameState.mode == GameState.Mode.MODERN)
      return false;
    with (state) {
      if (!hasCollision)
        return false;
      if (fabs(pos.x - p.x) < size.x && fabs(pos.y - p.y) < size.y) {
        switch (spec.gameState.mode) {
        case GameState.Mode.CLASSIC:
          destroy();
          break;
        case GameState.Mode.BASIC:
          hitOffset.x = pos.x - p.x;
          hitOffset.y = pos.y - p.y;
          spec.addVelocity(state, v, hitOffset);
          break;
        }
        return true;
      }
      return false;
    }
  }

  public void destroy() {
    remove();
    spec.destroyed(state);
  }

  public void drawState() {
    if (spec.gameState.mode == GameState.Mode.CLASSIC)
      spec.drawState(state);
  }

  public void destroyCapturedEnemies(int idx) {
    state.destroyCapturedEnemies(idx);
  }

  public bool isInTractorBeam(Vector p) {
    return spec.tractorBeam.contains(p);
  }

  public int addCapturedEnemy(Enemy e) {
    return state.addCapturedEnemy(e);
  }

  public float capturedEnemyWidth() {
    return state.capturedEnemyWidth;
  }

  public void midEnemyProvacated() {
    state.midEnemyProvacated = true;
  }

  public void addScore(int sc) {
    spec.addScore(sc);
  }

  public void addMultiplier(float mp) {
    spec.addMultiplier(mp);
  }

  public float multiplier() {
    return spec.multiplier;
  }

  public float deg() {
    return state.deg;
  }

  public bool isActive() {
    return state.isActive;
  }

  public bool hasCollision() {
    return state.hasCollision;
  }

  public bool enemiesHasCollision() {
    switch (spec.gameState.mode) {
    case GameState.Mode.CLASSIC:
      return state.hasCollision;
    case GameState.Mode.BASIC:
      return true;
    case GameState.Mode.MODERN:
      return false;
    }
  }
}

public class PlayerState: TokenState {
 public:
  bool replayMode;
 private:
  static const int RESPAWN_INTERVAL = 72;
  static const int INVINCIBLE_INTERVAL_RESPAWN = 240;
  static const int MAX_CAPTURED_ENEMIES_NUM = 10;
  PlayerSpec spec;
  Enemy[] capturedEnemies;
  int capturedEnemyNum;
  int respawnCnt;
  bool isInRespawn;
  int invincibleCnt;
  bool isInvincible;
  int shotCnt;
  int capturedEnemyShotCnt;
  bool aPressed, bPressed;
  Vector vel;
  float capturedEnemyWidth;
  int colorCnt;
  bool isFirstShot;
  float captureBeamEnergy;
  bool captureBeamReleased;
  int ghostCnt;
  int ghostShotCnt;
  bool midEnemyProvacated;

  invariant {
    if (isInitialized) {
      assert(vel.x <>= 0);
      assert(vel.y <>= 0);
      assert(capturedEnemyWidth >= 0);
      assert(captureBeamEnergy <>= 0);
    }
  }

  public this() {
    capturedEnemies = new Enemy[MAX_CAPTURED_ENEMIES_NUM];
    vel = new Vector;
  }

  public void setSpec(PlayerSpec spec) {
    this.spec = spec;
  }

  public void set() {
    reset();
    pos.x = 0;
    respawnCnt = 0;
    isInRespawn = false;
    aPressed = bPressed = true;
    shotCnt = 60;
  }

  public override void clear() {
    capturedEnemyNum = 0;
    respawnCnt = invincibleCnt = 0;
    isInRespawn = isInvincible = false;
    shotCnt = 0;
    capturedEnemyShotCnt = 0;
    vel.x = vel.y = 0;
    capturedEnemyWidth = 1.0f;
    colorCnt = 0;
    isFirstShot = false;
    captureBeamEnergy = 0;
    captureBeamReleased = false;
    ghostCnt = 0;
    ghostShotCnt = 0;
    midEnemyProvacated = false;
    super.clear();
  }

  private void reset() {
    float x = pos.x;
    clear();
    pos.x = x;
    pos.y = -10.0f;
    speed = PlayerSpec.BASE_SPEED;
    invincibleCnt = INVINCIBLE_INTERVAL_RESPAWN;
    isInvincible = true;
    isFirstShot = true;
    captureBeamEnergy = 1;
    spec.respawn(this);
  }

  public void move() {
    colorCnt++;
    ghostCnt++;
    if (isInRespawn) {
      respawnCnt--;
      if (respawnCnt <= 0) {
        reset();
        isInRespawn = false;
      }
    } else if (isInvincible) {
      invincibleCnt--;
      if (invincibleCnt <= 0)
        isInvincible = false;
    }
    midEnemyProvacated = false;
  }

  public bool isActive() {
    return !isInRespawn;
  }

  public bool hasCollision() {
    return (!isInRespawn && !isInvincible);
  }

  public bool hasShape() {
    if (isInRespawn)
      return false;
    if (!isInvincible)
      return true;
    if (invincibleCnt % 60 < 30)
      return false;
    else
      return true;
  }

  public void destroyed() {
    respawnCnt = RESPAWN_INTERVAL;
    destroyCapturedEnemies(0);
    isInRespawn = true;
  }

  public int addCapturedEnemy(Enemy e) {
    if (isInRespawn || capturedEnemyNum >= MAX_CAPTURED_ENEMIES_NUM)
      return -1;
    capturedEnemies[capturedEnemyNum] = e;
    capturedEnemyNum++;
    return capturedEnemyNum - 1;
  }

  public void destroyCapturedEnemies(int idx) {
    for (int i = idx; i < capturedEnemyNum; i++)
      if (capturedEnemies[i].exists)
        capturedEnemies[i].destroyed();
    capturedEnemyNum = idx;
  }

  public void countShotHit() {
    captureBeamEnergy += 0.02f / (capturedEnemyNum + 1);
    if (captureBeamEnergy > 1)
      captureBeamEnergy = 1;
  }
}

public class PlayerSpec: TokenSpec!(PlayerState) {
  mixin StaticRandImpl;
 public:
  static const float BASE_SPEED = 0.15f;
  static const float BASE_VELOCITY = 0.03f;
  static const float CAPTURED_ENEMIES_INTERVAL_LENGTH = 1.2f;
 private:
  static const float TILT_DEG = 1.0f;
  static const float SHOT_INTERVAL = 3;
  static const float FIRST_SHOT_INTERVAL = 6;
  static const int TWIN_SHOT_MAX_NUM = 2;
  ShotPool shots, capturedEnemiesShots;
  ShotSpec shotSpec;
  EnemyPool enemies;
  BulletPool bullets;
  ParticlePool particles;
  RecordablePad pad;
  GameState gameState;
  PlayerState playerState;
  TractorBeam tractorBeam;
  Shape lineShape;
  float bulletHitWidth;
  GhostEnemySpec ghostEnemySpec;
  EnemyShape ghostEnemyShape;
  int shotMaxNum;

  public this(Pad pad, GameState gameState, Field field,
              EnemyPool enemies, BulletPool bullets, ParticlePool particles) {
    this.pad = cast(RecordablePad) pad;
    this.gameState = gameState;
    this.field = field;
    this.enemies = enemies;
    this.bullets = bullets;
    this.particles = particles;
    shots = new ShotPool;
    shots.init(16);
    capturedEnemiesShots = new ShotPool;
    capturedEnemiesShots.init(64);
    shotSpec = new ShotSpec(field, enemies, bullets, gameState);
    shape = new PlayerShape;
    lineShape = new PlayerLineShape;
    ghostEnemyShape = new Enemy1TrailShape;
    ghostEnemySpec = new GhostEnemySpec(field, ghostEnemyShape);
  }

  public void setState(PlayerState ps) {
    playerState = ps;
    shotSpec.setPlayerState(ps);
    tractorBeam = new TractorBeam(field, ps, gameState);
  }

  public void close() {
    ghostEnemyShape.close();
    (cast(PlayerShape) shape).close();
    shotSpec.close();
  }

  public void start() {
    clear();
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      bulletHitWidth = 0.4f;
      shotMaxNum = 3;
      break;
    case GameState.Mode.BASIC:
      bulletHitWidth = 0.2f;
      shotMaxNum = 3;
      break;
    case GameState.Mode.MODERN:
      bulletHitWidth = 0.1f;
      shotMaxNum = 16;
      break;
    }
  }

  public void respawn(PlayerState ps) {
    if (gameState.mode == GameState.Mode.MODERN) {
      for (int i = 0; i < 4; i++) {
        Enemy e = enemies.getInstance();
        if (!e)
          break;
        e.set(ghostEnemySpec, ps.pos.x, ps.pos.y, 0, 0);
        playerState.addCapturedEnemy(e);
      }
    }
  }

  public void clear() {
    tractorBeam.clear();
    shots.clear();
    capturedEnemiesShots.clear();
  }

  public override bool move(PlayerState ps) {
    with (ps) {
      PadState input;
      if (!replayMode) {
        input = pad.getState();
      } else {
        try {
          input = pad.replay();
        } catch (NoRecordDataException e) {
          gameState.startGameOverWithoutRecording();
          input = pad.getNullState();
        }
      }
      shots.move();
      capturedEnemiesShots.move();
      capturedEnemiesShots.checkParent();
      if (gameState.isGameOver) {
        if (input.button & PadState.Button.A) {
          if (!aPressed) {
            aPressed = true;
            if (!replayMode)
              gameState.backToTitle();
          }
        } else {
          aPressed = false;
        }
        return true;
      }
      ps.move();
      if (!isActive())
        return true;
      float vx = 0, vy = 0;
      if (input.dir & PadState.Dir.RIGHT)
        vx = 1;
      else if (input.dir & PadState.Dir.LEFT)
        vx = -1;
      if (input.dir & PadState.Dir.UP)
        vy = 1;
      else if (input.dir & PadState.Dir.DOWN)
        vy = -1;
      if (vx != 0 && vy != 0) {
        vx *= 0.7f;
        vy *= 0.7f;
      }
      float px = pos.x;
      pos.x += (vx * speed);
      if (gameState.mode == GameState.Mode.CLASSIC)
        vy *= 0.5f;
      pos.y += (vy * speed);
      if (!(input.button & PadState.Button.B))
        deg += (-TILT_DEG * (vx * speed) - deg) * 0.1f;
      assert(deg <>= 0);
      pos += vel;
      vel *= 0.9f;
      if (gameState.mode == GameState.Mode.MODERN) {
        float d = ghostCnt * 0.05f;
        for (int i = 0; i < capturedEnemyNum; i++) {
          Enemy e = capturedEnemies[i];
          e.setGhostEnemyState(pos.x + sin(d) * capturedEnemyWidth * 2, pos.y, deg, cast(int) (d * 180 / PI / 3));
          d += PI / 2;
        }
      }
      switch (gameState.mode) {
      case GameState.Mode.CLASSIC:
        /*if (input.button & PadState.Button.A) {
          if (!aPressed) {
            aPressed = true;
            if (!captureBeamReleased)
              fireShot(ps);
          }
        } else {
          aPressed = false;
        }*/
        if ((input.button & PadState.Button.A) && !captureBeamReleased) {
          if (shotCnt <= 0)
            fireShot(ps);
        } else {
          isFirstShot = true;
        }
        break;
      case GameState.Mode.BASIC:
        if ((input.button & PadState.Button.A) && !(input.button & PadState.Button.B)) {
          if (shotCnt <= 0)
            fireShot(ps);
        } else {
          isFirstShot = true;
        }
        break;
      case GameState.Mode.MODERN:
        if (input.button & PadState.Button.A) {
          if (shotCnt <= 0)
            fireShot(ps);
        } else {
          isFirstShot = true;
        }
        break;
      }
      if (input.button & PadState.Button.B) {
        speed += (BASE_SPEED * 1.2f - speed) * 0.33f;
        deg *= 0.9f;
        if (gameState.mode == GameState.Mode.MODERN) {
          capturedEnemyWidth -= 0.05f;
          if (capturedEnemyWidth < 0.2f)
            capturedEnemyWidth = 0.2f;
        }
      } else {
        speed += (BASE_SPEED * 2.0f - speed) * 0.33f;
        if (gameState.mode == GameState.Mode.MODERN) {
          capturedEnemyWidth += 0.05f;
          if (capturedEnemyWidth > 1)
            capturedEnemyWidth = 1;
        }
      }
      switch (gameState.mode) {
      case GameState.Mode.CLASSIC:
        if (input.button & PadState.Button.B &&
            !captureBeamReleased && captureBeamEnergy >= 1 &&
            capturedEnemyNum < PlayerState.MAX_CAPTURED_ENEMIES_NUM) {
          captureBeamReleased = true;
          isInvincible = true;
          invincibleCnt = 99999;
        }
        if (captureBeamReleased) {
          if (captureBeamEnergy <= 0 || capturedEnemyNum >= MAX_CAPTURED_ENEMIES_NUM) {
            captureBeamEnergy = 0;
            if (tractorBeam.reduceLength(0.5f)) {
              captureBeamReleased = false;
              invincibleCnt = 120;
            }
          } else {
            tractorBeam.extendLength(0.5f);
            captureBeamEnergy -= 0.005f;
          }
        }
        break;
      case GameState.Mode.BASIC:
        if (input.button & PadState.Button.B &&
            capturedEnemyNum < PlayerState.MAX_CAPTURED_ENEMIES_NUM)
          tractorBeam.extendLength();
        else
          tractorBeam.reduceLength();
        break;
      case GameState.Mode.MODERN:
        if ((input.button & PadState.Button.B) &&
            !(input.button & PadState.Button.A))
          tractorBeam.extendLength();
        else
          tractorBeam.reduceLength();
        break;
      }
      tractorBeam.move();
      if (shotCnt > 0)
        shotCnt--;
      if (capturedEnemyShotCnt > 0)
        capturedEnemyShotCnt--;
      switch (gameState.mode) {
      case GameState.Mode.CLASSIC:
      case GameState.Mode.BASIC:
        if (pos.y > 0)
          pos.y = 0;
        break;
      case GameState.Mode.MODERN:
        if (pos.y > field.size.y)
          pos.y = field.size.y;
        break;
      }
      if (pos.y < -field.size.y)
        pos.y = -field.size.y;
      if (pos.x > field.size.x)
        pos.x = field.size.x;
      else if (pos.x < -field.size.x)
        pos.x = -field.size.x;
      pos.x = field.normalizeX(pos.x);
      field.setEyePos(pos);
      return true;
    }
  }

  private void fireShot(PlayerState ps) {
    with (ps) {
      if (shots.num >= shotMaxNum)
        return;
      Shot s = shots.getInstance();
      if (s) {
        s.set(shotSpec, pos, deg, 0.66f);
        if (isFirstShot) {
          isFirstShot = false;
          shotCnt += FIRST_SHOT_INTERVAL;
        } else {
          shotCnt += SHOT_INTERVAL;
        }
        gameState.countShotFired();
        addShotParticle(pos, deg);
        Sound.playSe("shot.wav");
        for (int i = 0; i < capturedEnemyNum; i++) {
          if (gameState.mode == GameState.Mode.MODERN && ((i + ghostShotCnt) % 4 == 0))
            continue;
          if (capturedEnemies[i].isCaptured) {
            Shot ces = capturedEnemiesShots.getInstance();
            if (!ces)
              break;
            float d = deg;
            if (gameState.mode == GameState.Mode.MODERN)
              d -= (capturedEnemies[i].pos.x - pos.x) * 0.3f;
            ces.set(shotSpec, capturedEnemies[i].pos, d, 0.66f);
            if (gameState.mode != GameState.Mode.MODERN)
              ces.setParent(s);
            else
              gameState.countShotFired();
            addShotParticle(capturedEnemies[i].pos, deg);
          }
        }
        if (gameState.mode == GameState.Mode.MODERN)
          ghostShotCnt++;
      }
    }
  }

  private void addShotParticle(Vector p, float d) {
    for (int i = 0; i < 5; i++) {
      Particle pt;
      pt = particles.getInstanceForced();
      pt.set(Particle.Shape.LINE, p.x - 0.5f, p.y,
             -d + rand.nextSignedFloat(0.5f), 0.25f + rand.nextFloat(0.75f),
             1, 1.0f, 0.25f, 0.5f, 10);
      pt = particles.getInstanceForced();
      pt.set(Particle.Shape.LINE, p.x + 0.5f, p.y,
             -d + rand.nextSignedFloat(0.5f), 0.25f + rand.nextFloat(0.75f),
             1, 1.0f, 0.25f, 0.5f, 10);
    }
  }

  public void addVelocity(PlayerState ps, Vector v, Vector o) {
    Vector rv = v.getElement(o, 0.05f, 0.25f);
    rv *= 5;
    ps.vel += rv;
    float d = atan2(rv.x, -rv.y);
    float sp = rv.vctSize();
    for (int i = 0; i < 36; i++) {
      Particle pt;
      pt = particles.getInstanceForced();
      float r, g, b;
      r = 0.5f + rand.nextFloat(0.5f);
      g = 0.3f + rand.nextFloat(0.3f);
      b = 0.8f + rand.nextFloat(0.2f);
      pt.set(Particle.Shape.LINE, ps.pos.x, ps.pos.y,
             d + rand.nextSignedFloat(0.3f), sp * (1 + rand.nextFloat(2)),
             1, r, g, b, 30 + rand.nextInt(30));
    }
    Sound.playSe("flick.wav");
  }

  public void destroyed(PlayerState ps) {
    with (ps) {
      if (!isActive)
        return;
      ps.destroyed();
      tractorBeam.clear();
      gameState.destroyedPlayer();
      float r, g, b;
      r = 0.5f + rand.nextFloat(0.5f);
      g = 0.3f + rand.nextFloat(0.3f);
      b = 0.8f + rand.nextFloat(0.2f);
      for (int i = 0; i < 100; i++) {
        Particle p = particles.getInstanceForced();
        p.set(Particle.Shape.QUAD, pos.x, pos.y, rand.nextFloat(PI * 2), 0.01f + rand.nextFloat(1.0f),
              1 + rand.nextFloat(4), r, g, b, 10 + rand.nextInt(200));
      }
      r = 0.5f + rand.nextFloat(0.5f);
      g = 0.3f + rand.nextFloat(0.3f);
      b = 0.8f + rand.nextFloat(0.2f);
      for (int i = 0; i < 30; i++) {
        Particle p = particles.getInstanceForced();
        p.set(Particle.Shape.TRIANGLE, pos.x, pos.y, rand.nextFloat(PI * 2), 0.03f + rand.nextFloat(0.3f),
              3, r, g, b, 50 + rand.nextInt(150));
      }
      r = 0.5f + rand.nextFloat(0.5f);
      g = 0.3f + rand.nextFloat(0.3f);
      b = 0.8f + rand.nextFloat(0.2f);
      for (int i = 0; i < 300; i++) {
        Particle p = particles.getInstanceForced();
        p.set(Particle.Shape.LINE, pos.x, pos.y, rand.nextFloat(PI * 2), 0.07f + rand.nextFloat(0.7f),
              1, r, g, b, 100 + rand.nextInt(100));
      }
      Sound.playSe("player_explosion.wav");
    }
  }

  public void addScore(int sc) {
    gameState.addScore(sc);
  }

  public void addMultiplier(float mp) {
    gameState.addMultiplier(mp);
  }

  public float multiplier() {
    return gameState.multiplier;
  }

  public override void draw(PlayerState ps) {
    with (ps) {
      shots.draw();
      capturedEnemiesShots.draw();
      tractorBeam.draw();
      if (!isActive)
        return;
      Vector3 p = field.calcCircularPos(pos);
      float cd = field.calcCircularDeg(pos.x);
      if (hasShape)
        shape.draw(p, cd, deg);
      int c = colorCnt % 60;
      float a;
      if (c < 30)
        a = cast(float) c / 30;
      else
        a = 1 - cast(float) (c - 30) / 30;
      Screen.setColor(a, a, a);
      lineShape.draw(p, cd, deg);
    }
  }

  public void drawState(PlayerState ps) {
    with (ps) {
      Screen.setColor(1, 1, 1, 0.5f);
      glBegin(GL_TRIANGLE_FAN);
      glVertex3f(15, 400, 0);
      glVertex3f(15 + captureBeamEnergy * 100, 400, 0);
      glVertex3f(25 + captureBeamEnergy * 100, 420, 0);
      glVertex3f(25, 420, 0);
      glEnd();
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      float a;
      if (captureBeamEnergy < 1) {
        a = captureBeamEnergy;
      } else {
        int c = colorCnt % 60;
        if (c < 30)
          a = cast(float) c / 30;
        else
          a = 1 - cast(float) (c - 30) / 30;
      }
      Screen.setColor(1, 1, 1, a);
      glBegin(GL_LINE_LOOP);
      glVertex3f(15, 400, 0);
      glVertex3f(115, 400, 0);
      glVertex3f(125, 420, 0);
      glVertex3f(25, 420, 0);
      glEnd();
      glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      if (captureBeamEnergy >= 1)
        Letter.drawString("READY", 50, 390, 4);
    }
  }
}

public class ShotPool: ActorPool!(Shot) {
 private:

  public void checkParent() {
    foreach (Shot a; actors)
      if (a.exists)
        if (!a.spec.checkParent(a.state))
          a.remove();
  }

  public int num() {
    int n = 0;
    foreach (Shot a; actors)
      if (a.exists)
        n++;
    return n;
  }
}

public class Shot: Token!(ShotState, ShotSpec) {
 private:
  
  public void setParent(Shot s) {
    spec.setParent(state, s);
  }
}

public class ShotState: TokenState {
 private:
  Shot parent;
  int cnt;

  public override void clear() {
    parent = null;
    cnt = 0;
    super.clear();
  }
}

public class ShotSpec: TokenSpec!(ShotState) {
 private:
  EnemyPool enemies;
  BulletPool bullets;
  PlayerState playerState;
  GameState gameState;

  public this(Field field, EnemyPool enemies, BulletPool bullets, GameState gameState) {
    this.field = field;
    this.enemies = enemies;
    this.bullets = bullets;
    this.gameState = gameState;
    shape = new ShotShape;
  }

  public void setPlayerState(PlayerState ps) {
    playerState = ps;
  }

  public void close() {
    (cast(ShotShape) shape).close();
  }

  public override void set(ShotState ss) {
    ss.parent = null;
    ss.cnt = 0;
  }

  public void setParent(ShotState ss, Shot s) {
    ss.parent = s;
  }

  public override bool move(ShotState ss) {
    with (ss) {
      if (ss.parent)
        if (ss.parent.exists == false)
          return false;
      stepForward();
      pos.x = field.normalizeX(pos.x);
      if (!field.containsOuterY(pos.y)) {
        return false;
      }
      if (enemies.checkShotHit(pos, deg, 2)) {
        if (parent)
          parent.remove();
        gameState.countShotHit();
        playerState.countShotHit();
        return false;
      }
      cnt++;
      return true;
    }
  }

  public bool checkParent(ShotState ss) {
    if (ss.parent)
      if (ss.parent.exists == false)
        return false;
    return true;
  }
}

public class TractorBeam {
  static const float MAX_LENGTH = 10;
  static const float WIDTH = 3.0f;
  static const float SHAPE_INTERVAL_TIME = 10;
  static const float SHAPE_INTERVAL_LENGTH = 0.5f;
  Field field;
  PlayerState playerState;
  GameState gameState;
  TractorBeamShape[] shapes;
  float length = 0;
  int cnt;
  bool isExtending;

  invariant {
    assert(length <>= 0);
  }

  public this(Field field, PlayerState playerState, GameState gameState) {
    this.field = field;
    this.playerState = playerState;
    this.gameState = gameState;
    shapes ~= new TractorBeamShapeRed;
    shapes ~= new TractorBeamShapeBlue;
    shapes ~= new TractorBeamShapePurple;
    shapes ~= new TractorBeamShapeDarkRed;
    shapes ~= new TractorBeamShapeDarkBlue;
    shapes ~= new TractorBeamShapeDarkPurple;
    clear();
  }

  public void clear() {
    length = 0;
    cnt = 0;
    isExtending = false;
  }

  public void move() {
    if (length <= 0)
      return;
    cnt++;
    if (cnt % 12 == 0 && isExtending)
      Sound.playSe("tractor.wav");
  }

  public void extendLength(float ratio = 1) {
    length += (MAX_LENGTH - length) * 0.05f * ratio;
    isExtending = true;
  }

  public bool reduceLength(float ratio = 1) {
    length += (0 - length) * 0.1f * ratio;
    if (length < 0.33f) {
      length = 0;
      return true;
    }
    isExtending = false;
    return false;
  }

  public bool contains(Vector p) {
    if (length <= 0)
      return false;
    return (p.x > playerState.pos.x - WIDTH / 2 &&
            p.x < playerState.pos.x + WIDTH / 2 &&
            p.y > playerState.pos.y && p.y < playerState.pos.y + length + WIDTH);
  }

  public void draw() {
    if (length <= 0)
      return;
    float y = SHAPE_INTERVAL_LENGTH -
      (cnt % SHAPE_INTERVAL_TIME) * SHAPE_INTERVAL_LENGTH / SHAPE_INTERVAL_TIME;
    int c = cast(int) (cnt / SHAPE_INTERVAL_TIME);
    for (;;) {
      if (y > length)
        break;
      glPushMatrix();
      Vector3 p = field.calcCircularPos(playerState.pos.x, playerState.pos.y + y);
      Screen.glTranslate(p);
      float s = y;
      if (s > 1)
        s = 1;
      glScalef(s, s, s);
      switch (gameState.mode) {
      case GameState.Mode.CLASSIC:
      case GameState.Mode.BASIC:
        shapes[c % 3].draw();
        break;
      case GameState.Mode.MODERN:
        if (playerState.midEnemyProvacated)
          shapes[c % 3].draw();
        else
          shapes[c % 3 + 3].draw();
        break;
      }
      c++;
      glPopMatrix();
      y += SHAPE_INTERVAL_LENGTH;
    }
  }
}
