/*
 * $Id: frame.d,v 1.5 2006/12/04 16:04:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.frame;

private import std.math;
private import SDL;
private import opengl;
version (PANDORA) {
    import std.conv;
    import std.process;
}
private import abagames.util.rand;
private import abagames.util.vector;
private import abagames.util.sdl.frame;
private import abagames.util.sdl.pad;
private import abagames.ttn.field;
private import abagames.ttn.screen;
private import abagames.ttn.token;
private import abagames.ttn.player;
private import abagames.ttn.enemy;
private import abagames.ttn.bullet;
private import abagames.ttn.particle;
private import abagames.ttn.pillar;
private import abagames.ttn.stage;
private import abagames.ttn.letter;
private import abagames.ttn.replay;
private import abagames.ttn.sound;
private import abagames.ttn.title;
private import abagames.ttn.preference;
private import abagames.ttn.shape;

/**
 * Game frame and actor pools.
 */
public class Frame: abagames.util.sdl.frame.Frame {
 private:
  static string LAST_REPLAY_FILE_NAME = "last.rpl";
  Pad pad;
  Screen screen;
  Field field;
  Player player;
  PlayerSpec playerSpec;
  EnemyPool enemies;
  BulletPool bullets;
  ParticlePool particles, bonusParticles;
  PillarPool pillars;
  Stage stage;
  Title title;
  Preference preference;
  GameState gameState;
  ReplayData replayData;
  Rand rand;

  public override void init() {
    Sound.load();
    preference = cast(Preference) abstractPreference;
    preference.load();
    Letter.init();
    pad = cast(Pad) abstractInput;
    pad.openJoystick();
    screen = cast(Screen) abstractScreen;
    field = new Field(this, screen);
    enemies = new EnemyPool;
    enemies.field = field;
    bullets = new BulletPool;
    particles = new ParticlePool;
    bonusParticles = new ParticlePool;
    pillars = new PillarPool;
    enemies.init(128);
    bullets.init(1024);
    TriangleParticleSpec triangleParticleSpec = new TriangleParticleSpec(field);
    LineParticleSpec lineParticleSpec = new LineParticleSpec(field);
    QuadParticleSpec quadParticleSpec = new QuadParticleSpec(field);
    BonusParticleSpec bonusParticleSpec = new BonusParticleSpec(field);
    particles.init(1024, triangleParticleSpec, lineParticleSpec,
                   quadParticleSpec, bonusParticleSpec);
    bonusParticles.init(256, triangleParticleSpec, lineParticleSpec,
                        quadParticleSpec, bonusParticleSpec);
    triangleParticleSpec.setParticles(particles);
    pillars.init(48);
    gameState = new GameState(this, preference);
    title = new Title(preference, pad, this);
    title.setMode(preference.lastMode);
    title.init();
    playerSpec = new PlayerSpec(pad, gameState, field, enemies, bullets, particles);
    player = new Player(playerSpec);
    triangleParticleSpec.setPlayer(player);
    lineParticleSpec.setPlayer(player);
    quadParticleSpec.setPlayer(player);
    bonusParticleSpec.setPlayer(player);
    stage = new Stage(field, enemies, bullets, player,
                      particles, bonusParticles, pillars, gameState);
    gameState.setStage(stage);
    rand = new Rand;
    loadLastReplay();
  }

  public override void quit() {
    title.close();
    playerSpec.close();
    gameState.close();
    stage.close();
    Letter.close();
  }

  public override void start() {
    startTitle();
  }

  public void startInGame(int mode) {
    gameState.startInGame(cast(GameState.Mode) mode);
    player.replayMode = false;
    RecordablePad rp = cast(RecordablePad) pad;
    rp.startRecord();
    replayData = new ReplayData;
    replayData.inputRecord = rp.inputRecord;
    replayData.seed = rand.nextInt32();
    clearAll();
    field.set();
    player.set();
    stage.start(replayData.seed);
    Sound.clearMarkedSes();
    Sound.playBgm();
  }

  public void startTitle() {
    startReplay();
    title.start();
  }

  public void startReplay() {
    gameState.startTitle();
    if (replayData) {
      player.replayMode = true;
      RecordablePad rp = cast(RecordablePad) pad;
      rp.startReplay(replayData.inputRecord);
    }
    clearAll();
    field.set();
    if (replayData) {
      gameState.mode = cast(GameState.Mode) replayData.mode;
      gameState.setExtendScore();
      gameState.inReplay = true;
      player.set();
      stage.start(replayData.seed);
    } else {
      field.setEyePos(new Vector(0, 0));
    }
    Sound.clearMarkedSes();
    Sound.haltBgm();
  }

  private void clearAll() {
    enemies.clear();
    bullets.clear();
    particles.clear();
    bonusParticles.clear();
    pillars.clear();
  }

  public void breakLoop() {
    mainLoop.breakLoop();
  }

  public override void move() {
    gameState.move();
    field.move();
    if (gameState.isInGame || replayData) {
      if (!gameState.paused) {
        stage.move();
        pillars.move();
        player.move();
        enemies.move();
        bullets.move();
        particles.move();
        bonusParticles.move();
      }
    }
    if (gameState.isTitle)
      title.move();
  }

  public void handleSound() {
    Sound.playMarkedSes();
  }

  public void addSlowdownRatio(float sr) {
    mainLoop.addSlowdownRatio(sr);
  }

  public override void draw() {
    SDL_Event e = mainLoop.event;
    if (e.type == SDL_VIDEORESIZE) {
      SDL_ResizeEvent re = e.resize;
      if (re.w > 150 && re.h > 100)
        screen.resized(re.w, re.h);
    }
    field.setLookAt();
    if (gameState.isInGame || replayData) {
      version (PANDORA) {
        // on Pandora, drawing outside pillars make the game unplayable, so
        // I just draw a colored background (the same color as outside pillars)
        // and the pillars wireframes
        {
          static const int backgroundNumVertices = 4;
          static const GLfloat[3*backgroundNumVertices] backgroundVertices = [
            -3*32, -3*24, 0,
             3*32, -3*24, 0,
             3*32,  3*24, 0,
            -3*32,  3*24, 0
          ];

          glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
          glEnableClientState(GL_VERTEX_ARRAY);
          glVertexPointer(3, GL_FLOAT, 0, cast(void *)(backgroundVertices.ptr));

          Screen.setColor(0.2f, 0.2f, 0.3f);
          glDrawArrays(GL_TRIANGLE_FAN, 0, backgroundNumVertices);

          glDisableClientState(GL_VERTEX_ARRAY);
          glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        }

        glCullFace(GL_FRONT_AND_BACK);
        glEnable(GL_CULL_FACE);

        pillars.drawOutside();

        glDisable(GL_CULL_FACE);
        glCullFace(GL_BACK);
      } else {
        pillars.drawOutside();
      }

      field.drawBack();
      enemies.drawPillarBack();
      pillars.drawCenter();
      enemies.drawBack();
      field.drawFront();
      particles.draw();
      bonusParticles.draw();
      enemies.drawFront();
      player.draw();
      bullets.draw();
      field.beginDrawingFront();
      gameState.draw();
      if (gameState.isTitle)
        title.draw();
      player.drawState();
      field.resetLookAt();
      gameState.drawLeft();
    } else {
      version (PANDORA) {
      } else {
        pillars.drawOutside();
      }
      field.drawBack();
      field.drawFront();
      field.beginDrawingFront();
      if (gameState.isTitle)
        title.draw();
    }
  }

  public Uint8* keys() {
    return pad.keys;
  }

  // Handle a replay data.
  public void saveLastReplay() {
    try {
      replayData.score = gameState.score;
      replayData.mode = gameState.mode;
      replayData.stageRandomized = stage.randomized;
      saveReplay(LAST_REPLAY_FILE_NAME);
    } catch (Exception o) {}
  }

  public void loadLastReplay() {
    try {
      loadReplay(LAST_REPLAY_FILE_NAME);
      gameState.lastGameScore = replayData.score;
      gameState.lastGameMode = replayData.mode;
      stage.randomized = replayData.stageRandomized;
    } catch (Exception o) {
      resetReplay();
    }
  }

  public void saveReplay(string fileName) {
    replayData.save(fileName);
  }

  public void loadReplay(string fileName) {
    replayData = new ReplayData;
    replayData.load(fileName);
  }

  public void resetReplay() {
    replayData = null;
  }
}

public class GameState {
 public:
  static const enum Mode {
    CLASSIC, BASIC, MODERN,
  };
  static const int MODE_NUM = 3;
  static string[] MODE_NAME = ["CLASSIC", " BASIC ", "MODERN"];
  static bool stageRandomized = false;
 private:
  static const enum Scene {
    TITLE, IN_GAME,
  };
  static const int MAX_LEFT = 4;
  Frame frame;
  Preference preference;
  Scene scene;
  Stage stage;
  int score;
  int _lastGameScore;
  int _lastGameMode;
  int nextExtendScore;
  float _multiplier;
  int left;
  bool escPressed, pPressed;
  bool _paused;
  int pauseCnt;
  bool _isGameOver;
  int gameOverCnt;
  PlayerShape playerShape;
  PlayerLineShape playerLineShape;
  bool _inReplay;
  Mode _mode;
  int extendScore;
  int proximityMultiplier, pmDispCnt;

  invariant() {
    assert(_multiplier >= 1.0f);
  }

  public this(Frame frame, Preference preference) {
    this.frame = frame;
    this.preference = preference;
    playerShape = new PlayerShape;
    playerLineShape = new PlayerLineShape;
    clear();
    _lastGameScore = -1;
  }

  public void setStage(Stage stage) {
    this.stage = stage;
  }

  public void close() {
    playerShape.close();
    playerLineShape.close();
  }

  public void startInGame(Mode m) {
    scene = Scene.IN_GAME;
    clear();
    _mode = m;
    left = 2;
    setExtendScore();
    _lastGameScore = -1;
    preference.setMode(_mode);
    stage.randomized = stageRandomized;
  }

  public void setExtendScore() {
    switch(_mode) {
    case Mode.CLASSIC:
      extendScore = 100000;
      break;
    case Mode.BASIC:
    case Mode.MODERN:
      extendScore = 1000000;
      break;
    default:
      break;
    }
    nextExtendScore = extendScore;
  }

  public void startTitle() {
    scene = Scene.TITLE;
    clear();
    left = 2;
  }

  private void clear() {
    score = 0;
    _multiplier = 1.0f;
    left = 0;
    gameOverCnt = 0;
    _isGameOver = _paused = false;
    _inReplay = false;
    pmDispCnt = 0;
  }

  public void startGameOver() {
    if (!isInGameAndNotGameOver)
      return;
    _isGameOver = true;
    gameOverCnt = 0;
    Sound.fadeBgm();
    _lastGameScore = score;
    _lastGameMode = mode;
    preference.recordResult(score, _mode);
    preference.save();

    version (PANDORA) {
      if (mode == Mode.CLASSIC)
        system(escapeShellCommand("fusilli", "--cache", "push", "titanion_classic", to!string(score), "0") ~ " >/dev/null 2>&1");
      else if (mode == Mode.BASIC)
        system(escapeShellCommand("fusilli", "--cache", "push", "titanion_basic", to!string(score), "0") ~ " >/dev/null 2>&1");
      else
        system(escapeShellCommand("fusilli", "--cache", "push", "titanion_modern", to!string(score), "0") ~ " >/dev/null 2>&1");
    }
  }

  public void startGameOverWithoutRecording() {
    if (_isGameOver)
      return;
    _isGameOver = true;
    gameOverCnt = 0;
    Sound.fadeBgm();
  }

  public void backToTitle() {
    if (isTitle) {
      frame.startReplay();
      return;
    }
    if (gameOverCnt > 120) {
      frame.saveLastReplay();
      frame.startTitle();
    }
  }

  public void move() {
    handleEscKey();
    if (isInGameAndNotGameOver) {
      handlePauseKey();
      if (_paused) {
        pauseCnt++;
        return;
      }
    }
    if (isInGame) {
      if (!_isGameOver) {
        frame.handleSound();
      } else {
        gameOverCnt++;
        if (gameOverCnt < 60)
          frame.handleSound();
        if (gameOverCnt > 1000)
          backToTitle();
      }
    } else {
      if (_inReplay)
        frame.handleSound();
      if (_isGameOver) {
        gameOverCnt++;
        if (_inReplay && gameOverCnt < 60)
          frame.handleSound();
        if (gameOverCnt > 120)
          backToTitle();
      }
    }
    if (pmDispCnt > 0)
      pmDispCnt--;
  }

  private void handleEscKey() {
    if (frame.keys[SDLK_ESCAPE] == SDL_PRESSED) {
      if (!escPressed) {
        escPressed = true;
        if (scene == Scene.IN_GAME) {
          frame.loadLastReplay();
          frame.startTitle();
        } else {
          frame.breakLoop();
        }
      }
    } else {
      escPressed = false;
    }
  }

  private void handlePauseKey() {
    if (frame.keys[SDLK_p] == SDL_PRESSED) {
      if (!pPressed) {
        pPressed = true;
        _paused = !_paused;
        pauseCnt = 0;
      }
    } else {
      pPressed = false;
    }
  }

  public void addScore(int sc, bool noMultiplier = false) {
    if (!_isGameOver) {
      if (noMultiplier)
        score += sc;
      else
        score += sc * _multiplier;
      if (score >= nextExtendScore) {
        if (left < MAX_LEFT) {
          left++;
          Sound.playSe("extend.wav");
        }
        nextExtendScore += extendScore;
        if (_mode == Mode.MODERN)
          extendScore += 1000000;
      }
    }
  }

  public void addMultiplier(float mp) {
    if (!_isGameOver)
      _multiplier += mp;
  }

  public void mulMultiplier(float mp) {
    if (!_isGameOver) {
      _multiplier *= mp;
      if (_multiplier < 1)
        _multiplier = 1;
    }
  }

  public void setProximityMultiplier(int pm) {
    proximityMultiplier = pm;
    pmDispCnt = 60;
  }

  public void destroyedPlayer() {
    left--;
    if (left < 0) {
      if (isInGame)
        startGameOver();
      else
        startGameOverWithoutRecording();
    }
  }

  public void countShotFired() {
    stage.countShotFired();
  }

  public void countShotHit() {
    stage.countShotHit();
  }

  public void draw() {
    Letter.drawNum(score, 132, 5, 7);
    Letter.drawNum(nextExtendScore, 134, 25, 5);
    if (_lastGameScore >= 0) {
      Letter.drawNum(_lastGameScore, 360, 5, 7);
      //Letter.drawString(GameState.MODE_NAME[_lastGameMode], 292, 24, 5);
    }
    Letter.drawNum(cast(int) (_multiplier * 100), 626, 4, 9, 3, 33, 2);
    if (pmDispCnt > 0)
      Letter.drawNum(proximityMultiplier, 626, 30, 7, 0, 33);
    stage.drawPhaseNum();
    if (isInGame) {
      if (!_isGameOver)
        stage.draw();
      if (_isGameOver) {
        if (gameOverCnt > 60) {
          Letter.drawString("GAME OVER", 214, 200, 12);
          stage.drawGameover();
        }
      } else if (_paused) {
        if (pauseCnt % 120 < 60)
          Letter.drawString("PAUSE", 290, 420, 7);
      }
      Letter.drawString(GameState.MODE_NAME[mode], 540, 400, 5);
    }
  }

  public void drawLeft() {
    for (int i = 0; i < left; i++) {
      glPushMatrix();
      glTranslatef(-10.2f + i, -7.5f, -10);
      glScalef(0.6f, 0.6f, 0.6f);
      playerShape.draw();
      Screen.setColor(0, 0, 0);
      playerLineShape.draw();
      glPopMatrix();
    }
  }

  public bool isInGame() {
    return (scene == Scene.IN_GAME);
  }

  public bool isInGameAndNotGameOver() {
    return (scene == Scene.IN_GAME && !_isGameOver);
  }

  public bool isTitle() {
    return (scene == Scene.TITLE);
  }

  public bool isGameOver() {
    return _isGameOver;
  }

  public bool paused() {
    return _paused;
  }

  public float multiplier() {
    return _multiplier;
  }

  public bool inReplay(bool v) {
    return _inReplay = v;
  }

  public int lastGameScore(int v) {
    return _lastGameScore = v;
  }

  public int lastGameMode(int v) {
    return _lastGameMode = v;
  }

  public Mode mode() {
    return _mode;
  }

  public Mode mode(Mode v) {
    return _mode = v;
  }
}
