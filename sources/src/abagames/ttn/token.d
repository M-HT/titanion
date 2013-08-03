/*
 * $Id: token.d,v 1.2 2006/11/23 02:29:44 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.ttn.token;

private import std.math;
private import abagames.util.vector;
private import abagames.util.math;
private import abagames.util.actor;
private import abagames.ttn.field;
private import abagames.ttn.shape;

/**
 * Tokens of a player, enemies, bullets, particles, etc.
 * Handling these states (position, direction, speed, etc.) and
 *  specs (maneuver, method of attack, etc.).
 */
public class Token(ST, SP): Actor {
 protected:
  ST state;
  SP spec;

  public override void init(Object[] args) {
    state = new ST;
  }

  public void set(SP spec, Vector pos, float deg, float speed) {
    set(spec, pos.x, pos.y, deg, speed);
  }

  public void set(SP spec, float x, float y, float deg, float speed) {
    this.spec = spec;
    set(x, y, deg, speed);
  }

  public void set(float x, float y, float deg, float speed) {
    state.clear();
    state.pos.x = x;
    state.pos.y = y;
    state.deg = deg;
    state.speed = speed;
    spec.set(state);
    _exists = true;
  }

  public override void move() {
    if (!spec.move(state))
      remove();
  }

  public void remove() {
    _exists = false;
    spec.removed(state);
  }

  public override void draw() {
    spec.draw(state);
  }

  public Vector pos() {
    return state.pos;
  }
}

/**
 * Holding a state of a token.
 */
public class TokenState {
 protected:
  bool isInitialized = false;
  Vector pos;
  float deg;
  float speed;

  invariant() {
    if (isInitialized) {
      assert(pos.x <>= 0);
      assert(pos.y <>= 0);
      assert(deg <>= 0);
      assert(speed <>= 0);
    }
  }

  public this() {
    pos = new Vector;
  }

  public void clear() {
    pos.x = pos.y = 0;
    deg = 0;
    speed = 0;
    isInitialized = true;
  }

  public void stepForward() {
    pos.x -= sin(deg) * speed;
    pos.y += cos(deg) * speed;
  }
}

/**
 * Base class of a token's specification.
 */
public class TokenSpec(T) {
 protected:
  Field field;
  Shape shape;

  public void set(T state) {}
  public void removed(T state) {}

  public bool move(T state) {
    return true;
  }

  public void draw(T state) {
    with (state) {
      Vector3 p = field.calcCircularPos(pos);
      float cd = field.calcCircularDeg(pos.x);
      shape.draw(p, cd, deg);
    }
  }
}
