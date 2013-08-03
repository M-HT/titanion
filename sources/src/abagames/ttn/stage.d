/*
 * $Id: stage.d,v 1.6 2006/12/09 04:17:40 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.stage;

private import std.math;
private import abagames.util.rand;
private import abagames.util.vector;
private import abagames.ttn.field;
private import abagames.ttn.token;
private import abagames.ttn.enemy;
private import abagames.ttn.bullet;
private import abagames.ttn.player;
private import abagames.ttn.particle;
private import abagames.ttn.pillar;
private import abagames.ttn.shape;
private import abagames.ttn.sound;
private import abagames.ttn.frame;
private import abagames.ttn.letter;

/**
 * Enemy appearance pattern handler.
 */
public class Stage {
 public:
  bool randomized;
 private:
  static const int PHASE_RESULT_SHOW_CNT = 150;
  static const int PHASE_START_SHOW_CNT = 90;
  Field field;
  EnemyPool enemies;
  BulletPool bullets;
  Player player;
  ParticlePool particles, bonusParticles;
  PillarPool pillars;
  GameState gameState;
  Rand rand;
  int appCnt;
  EnemySpec middleEnemySpec, smallEnemy1Spec, smallEnemy2Spec;
  EnemyShape enemy1Shape, enemy2Shape, enemy3Shape;
  EnemyShape enemy1TrailShape, enemy2TrailShape, enemy3TrailShape;
  BulletSpec bulletSpec, middleBulletSpec, counterBulletSpec;
  BulletShapeBase bulletShape, bulletLineShape, middleBulletShape, middleBulletLineShape;
  RollBulletShapeBase counterBulletShape, counterBulletLineShape;
  PillarSpec pillarSpec;
  PillarShape[] pillarShapes;
  PillarShape outsidePillarShape;
  int smallEnemyNum;
  int smallEnemyFormationNum;
  float rank;
  int phaseTime;
  bool stageStarted, waitNextFormationPhase;
  int middleEnemyAppInterval;
  int _attackSmallEnemyNum;
  float goingDownBeforeStandByRatio;
  int appCntInterval;
  int formationIdx;
  int cnt;
  float rankTrg;
  int phaseNum;
  int shotFiredNum, shotHitNum;
  int shotFiredNumRsl, shotHitNumRsl;
  int shotFiredNumTotal, shotHitNumTotal;
  float hitRatio;
  int hitRatioBonus;
  bool _existsCounterBullet;

  public this(Field field, EnemyPool enemies, BulletPool bullets, Player player,
              ParticlePool particles, ParticlePool bonusParticles,
              PillarPool pillars, GameState gameState) {
    this.field = field;
    this.enemies = enemies;
    this.bullets = bullets;
    this.player = player;
    this.particles = particles;
    this.bonusParticles = bonusParticles;
    this.pillars = pillars;
    this.gameState = gameState;
    rand = new Rand;
    enemy1Shape = new Enemy1Shape;
    enemy2Shape = new Enemy2Shape;
    enemy3Shape = new Enemy3Shape;
    enemy1TrailShape = new Enemy1TrailShape;
    enemy2TrailShape = new Enemy2TrailShape;
    enemy3TrailShape = new Enemy3TrailShape;
    bulletShape = new BulletShape;
    bulletLineShape = new BulletLineShape;
    middleBulletShape = new MiddleBulletShape;
    middleBulletLineShape = new MiddleBulletLineShape;
    counterBulletShape = new CounterBulletShape;
    counterBulletLineShape = new CounterBulletLineShape;
    bulletSpec = new BulletSpec(field, player, enemies, particles,
                                bulletShape, bulletLineShape, gameState);
    middleBulletSpec = new BulletSpec(field, player, enemies, particles,
                                      middleBulletShape, middleBulletLineShape, gameState);
    counterBulletSpec = new BulletSpec(field, player, enemies, particles,
                                       counterBulletShape, counterBulletLineShape, gameState);
    pillarSpec = new PillarSpec(field);
    pillarShapes ~= new Pillar1Shape;
    pillarShapes ~= new Pillar2Shape;
    pillarShapes ~= new Pillar3Shape;
    pillarShapes ~= new Pillar4Shape;
    outsidePillarShape = new OutsidePillarShape;
  }

  public void close() {
    enemy1Shape.close();
    enemy2Shape.close();
    enemy3Shape.close();
    enemy1TrailShape.close();
    enemy2TrailShape.close();
    enemy3TrailShape.close();
    bulletShape.close();
    bulletLineShape.close();
    middleBulletShape.close();
    middleBulletLineShape.close();
    counterBulletShape.close();
    counterBulletLineShape.close();
    foreach (PillarShape ps; pillarShapes)
      ps.close();
    outsidePillarShape.close();
  }

  public void start(long randSeed) {
    clear();
    rand.setSeed(randSeed);
    EnemySpec.setRandSeed(randSeed);
    TurretSpec.setRandSeed(randSeed);
    PlayerSpec.setRandSeed(randSeed);
    ParticleSpec.setRandSeed(randSeed);
    Sound.setRandSeed(randSeed);
    rank = rankTrg = 0;
    phaseNum = 0;
    cnt = 0;
    shotFiredNumTotal = shotHitNumTotal = 0;
    for (int i = 0; i < 1000; i++) {
      cnt++;
      moveOutsidePillars();
      pillars.move();
    }
    startPhase();
  }

  private void clear() {
    smallEnemyNum = smallEnemyFormationNum = 0;
    rank = 0;
    phaseTime = 0;
    stageStarted = waitNextFormationPhase = false;
    middleEnemyAppInterval = 0;
    _attackSmallEnemyNum = 0;
    goingDownBeforeStandByRatio = 0;
    appCntInterval = 0;
    formationIdx = 0;
    cnt = 0;
    rankTrg = 0;
    phaseNum = 0;
    shotFiredNum = shotHitNum = 0;
    shotFiredNumRsl = shotHitNumRsl = 0;
    shotFiredNumTotal = shotHitNumTotal = 0;
    hitRatio = 0;
    hitRatioBonus = 0;
    _existsCounterBullet = false;
  }

  private void startPhase() {
    phaseTime = 0;
    phaseNum++;
    if (phaseNum > 1)
      calcHitRatioBonus();
    if (phaseNum % 10 == 0)
      Sound.fadeBgm();
    setEnemySpecs();
    initPillars();
  }

  private void calcHitRatioBonus() {
    shotFiredNumRsl = shotFiredNum;
    shotHitNumRsl = shotHitNum;
    shotFiredNum = shotHitNum = 0;
    if (shotFiredNumRsl <= 0) {
      hitRatio = 0;
    } else {
      hitRatio = cast(float) shotHitNumRsl / shotFiredNumRsl;
    }
    float r = cast(float) (cast(int) (hitRatio * 100)) / 100;
    if (r > 1)
      r = 1;
    hitRatioBonus = cast(int) (10000.0f * r * r * r * r);
    if (gameState.mode == GameState.Mode.MODERN)
      return;
    if (gameState.mode == GameState.Mode.BASIC)
      hitRatioBonus *= 10;
    gameState.addScore(hitRatioBonus, true);
  }

  private void setEnemySpecs() {
    rankTrg += 1.25f;
    rank += (rankTrg - rank) * 0.33f;
    if (phaseNum % 10 == 0)
      rank *= 0.1f;
    if (!randomized) {
      long rs = phaseNum;
      switch (gameState.mode) {
      case GameState.Mode.CLASSIC:
        rs *= 2;
        break;
      case GameState.Mode.BASIC:
        break;
      case GameState.Mode.MODERN:
        rs *= 3;
        break;
      default:
        break;
      }
      rand.setSeed(rs);
      EnemySpec.setRandSeed(rs);
      TurretSpec.setRandSeed(rs);
    }
    _existsCounterBullet = false;
    int en;
    switch (gameState.mode) {
    case GameState.Mode.CLASSIC:
      en = 24 + cast(int) ((50 + rand.nextInt(10)) * sqrt(rank) * 0.2f);
      smallEnemyNum = 4 + rand.nextInt(2);
      if (rank > 10)
        _existsCounterBullet = true;
      middleEnemyAppInterval = 6 + rand.nextInt(2);
      break;
    case GameState.Mode.BASIC:
      en = 32 + cast(int) ((50 + rand.nextInt(10)) * sqrt(rank) * 0.33f);
      smallEnemyNum = 7 + rand.nextInt(4);
      middleEnemyAppInterval = 5 + rand.nextInt(2);
      break;
    case GameState.Mode.MODERN:
      en = 24 + cast(int) ((50 + rand.nextInt(10)) * sqrt(rank) * 0.5);
      smallEnemyNum = 4 + rand.nextInt(2);
      middleEnemyAppInterval = 7 + rand.nextInt(3);
      break;
    default:
      break;
    }
    smallEnemyFormationNum = cast(int) (en / smallEnemyNum) + 1;
    middleEnemySpec = new MiddleEnemySpec
      (field, bullets, player, particles, bonusParticles, enemies,
       this, enemy3Shape, enemy3TrailShape,
       middleBulletSpec, counterBulletSpec, gameState);
    middleEnemySpec.setRank(rank * 0.15f);
    smallEnemy1Spec = new SE1Spec
      (field, bullets, player, particles, bonusParticles, enemies,
       this, enemy1Shape, enemy1TrailShape,
       bulletSpec, counterBulletSpec, gameState);
    (cast(SE1Spec) smallEnemy1Spec).setRank(rank * 0.22f);
    smallEnemy2Spec = new SE2Spec
      (field, bullets, player, particles, bonusParticles, enemies,
       this, enemy2Shape, enemy2TrailShape,
       bulletSpec, counterBulletSpec, gameState);
    (cast(SE2Spec) smallEnemy2Spec).setRank(rank * 0.22f);
    _attackSmallEnemyNum = cast(int) sqrt(rank + 2);
    goingDownBeforeStandByRatio = 0;
    if (rand.nextFloat(rank + 1) > 2)
      goingDownBeforeStandByRatio = rand.nextFloat(0.2f) + 0.1f;
    appCntInterval = 48 + rand.nextSignedInt(10);
    appCntInterval *= (0.5f + 0.5f / sqrt(rank));
    if (gameState.mode == GameState.Mode.MODERN) {
      appCntInterval *= 0.75f;
      _attackSmallEnemyNum *= 2;
    }
    appCnt = 0;
    formationIdx = 0;
    stageStarted = false;
    waitNextFormationPhase = false;
  }

  private void initPillars() {
    pillars.setEnd();
    Pillar pp = null;
    int pln = 0;
    int pn = phaseNum;
    int[] pshapes;
    for (;;) {
      if (pn <= 0)
        break;
      if (pn >= 20) {
        pshapes ~= 3;
        pn -= 20;
      } else if (pn >= 10) {
        pshapes ~= 2;
        pn -= 10;
      } else if (pn >= 5) {
        pshapes ~= 1;
        pn -= 5;
      } else {
        pshapes ~= 0;
        pn--;
      }
      pln++;
    }
    float maxY = -15 + pln * 8;
    for (int i = 0; i < pln; i++) {
      Pillar p = pillars.getInstance();
      if (!p)
        break;
      p.set(pillarSpec, -80 - i * 10, maxY, pp, pillarShapes[pshapes[i]], (pln - i) * 0.03f);
      pp = p;
    }
  }

  public void move() {
    if (appCnt <= 0) {
      if ((formationIdx % middleEnemyAppInterval) == middleEnemyAppInterval - 1) {
        Enemy me = enemies.getInstance();
        if (!me)
          return;
        float x = rand.nextFloat(field.circularDistance);
        x = field.normalizeX(x);
        float sp = 0.1f + rand.nextSignedFloat(0.01f);
        float av = sp * 0.4f + rand.nextSignedFloat(0.005f);
        float er = rand.nextFloat(0.5f);
        float ed = rand.nextFloat(PI * 2);
        me.set(middleEnemySpec, x, field.size.y * Field.PIT_SIZE_Y_RATIO, PI, sp);
        me.setMiddleEnemyState(sp, av, er, ed);
      }
      float x = rand.nextFloat(field.circularDistance);
      x = field.normalizeX(x);
      float sp = 0.15f + rand.nextSignedFloat(0.01f);
      float av = sp * 0.5f + rand.nextSignedFloat(0.005f);
      float dst = sp * 6.0f;
      float er = rand.nextFloat(0.8f);
      float ed = rand.nextFloat(PI * 2);
      Enemy fe = null;
      float fir = 0;
      for (int i = 0; i < smallEnemyNum; i++) {
        Enemy e = enemies.getInstance();
        if (!e)
          break;
        SmallEnemySpec ses;
        int appPattern = formationIdx % 2;
        switch (formationIdx % 3) {
        case 0:
        case 1:
          ses = cast(SmallEnemySpec) smallEnemy1Spec;
          break;
        case 2:
          ses = cast(SmallEnemySpec) smallEnemy2Spec;
          break;
        default:
          break;
        }
        e.set(ses, x, field.size.y * Field.PIT_SIZE_Y_RATIO + i * dst, PI, sp);
        bool gd = false;
        if (rand.nextFloat(1) < goingDownBeforeStandByRatio)
          gd = true;
        if (!fe) {
          e.setSmallEnemyState(sp, av, cast(int) (i * (dst / sp)), appPattern,
                               er, ed, gd);
          fe = e;
        } else {
          e.setSmallEnemyState(sp, av, cast(int) (i * (dst / sp)), appPattern,
                               er, ed, gd, fir, fe);
        }
        fir += (1.0f / smallEnemyNum);
      }
      smallEnemyFormationNum--;
      formationIdx++;
      if (smallEnemyFormationNum <= 0) {
        stageStarted = true;
        appCnt = 9999999;
      } else {
        appCnt += appCntInterval * (1 - 1 / (enemies.num + 1));
      }
    }
    appCnt--;
    phaseTime++;
    if (phaseNum >= 10 && phaseNum % 10 == 0 && phaseTime == 120 &&
        gameState.isInGameAndNotGameOver)
      Sound.nextBgm();
    cnt++;
    moveOutsidePillars();
    if (enemies.numInScreen() > 0)
      gameState.mulMultiplier(0.999f);
    if (stageStarted && enemies.num <= 0)
      startPhase();
  }

  public void moveOutsidePillars() {
    if (cnt % 120 == 0) {
      Pillar p = pillars.getInstance();
      if (p)
        p.set(pillarSpec, 180, 0, null, outsidePillarShape, ((cast(int) cnt / 120) % 2 * 2 - 1) * 0.003f, true);
    }
  }

  public void countShotFired() {
    if (phaseTime >= PHASE_RESULT_SHOW_CNT) {
      shotFiredNum++;
      shotFiredNumTotal++;
    }
  }

  public void countShotHit() {
    if (phaseTime >= PHASE_RESULT_SHOW_CNT) {
      shotHitNum++;
      shotHitNumTotal++;
    }
  }

  public void draw() {
    if (gameState.mode != GameState.Mode.MODERN &&
        phaseTime < PHASE_RESULT_SHOW_CNT && phaseNum > 1) {
      Letter.drawString("SHOTS FIRED", 152, 250, 6, Letter.Direction.TO_RIGHT,
                        false, 0, 1, 1, 0.33f);
      Letter.drawNum(shotFiredNumRsl, 480, 250, 6);
      Letter.drawString("NUMBER OF HITS", 152, 280, 6, Letter.Direction.TO_RIGHT,
                        false, 0, 1, 1, 0.33f);
      Letter.drawNum(shotHitNumRsl, 480, 280, 6);
      Letter.drawString("HIT-MISS RATIO", 152, 310, 6);
      Letter.drawNum(cast(int) (hitRatio * 10000), 480, 310, 6, 3, -1, 2);
      Letter.drawString("BONUS", 200, 350, 6, Letter.Direction.TO_RIGHT,
                        false, 0, 1, 0.33f, 0.33f);
      Letter.drawNum(hitRatioBonus, 440, 350, 6);
    } else if (phaseTime < PHASE_RESULT_SHOW_CNT + PHASE_START_SHOW_CNT) {
      Letter.drawNum(phaseNum, 392, 200, 10);
      Letter.drawString("PHASE", 232, 200, 10);
    }
  }

  public void drawPhaseNum() {
    Letter.drawNum(phaseNum, 622, 448, 10);
  }

  public void drawGameover() {
    float hr = 0;
    if (shotFiredNumTotal > 0)
      hr = cast(float) shotHitNumTotal / shotFiredNumTotal;
    Letter.drawString("SHOTS FIRED", 152, 250, 6, Letter.Direction.TO_RIGHT,
                      false, 0, 1, 1, 0.33f);
    Letter.drawNum(shotFiredNumTotal, 480, 250, 6);
    Letter.drawString("NUMBER OF HITS", 152, 280, 6, Letter.Direction.TO_RIGHT,
                      false, 0, 1, 1, 0.33f);
    Letter.drawNum(shotHitNumTotal, 480, 280, 6);
    Letter.drawString("HIT-MISS RATIO", 152, 310, 6);
    Letter.drawNum(cast(int) (hr * 10000), 480, 310, 6, 3, -1, 2);
  }

  public int attackSmallEnemyNum() {
    return _attackSmallEnemyNum;
  }

  public bool existsCounterBullet() {
    return (_existsCounterBullet && stageStarted && enemies.numBeforeAlign <= 0);
  }
}
