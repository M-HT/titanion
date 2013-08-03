/*
 * $Id: actor.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.util.actor;

private import core.vararg;

/**
 * Actor that has an interface to move and draw.
 */
public class Actor {
 protected:
  bool _exists;
 private:

  public bool exists() {
    return _exists;
  }

  public bool exists(bool v) {
    return _exists = v;
  }

  public abstract void init(Object[] args);
  public abstract void move();
  public abstract void draw();
}

/**
 * Object pool for actors.
 */
public class ActorPool(T) {
 public:
  T[] actors;
 protected:
  int actorIdx = 0;
 private:
  bool hasNoActor;

  public this() {}

  /*public void init(int n, Object[] args = null) {
    createActors(n, args);
  }*/

  public void init(int n, ...) {
    Object[] args = null;
    for (int i = 0; i < _arguments.length; i++)
      args ~= va_arg!(Object)(_argptr);
    createActors(n, args);
  }

  protected void createActors(int n, Object[] args = null) {
    actors = new T[n];
    foreach (ref T a; actors) {
      a = new T;
      a.exists = false;
      a.init(args);
    }
    actorIdx = 0;
    hasNoActor = false;
  }

  public T getInstance() {
    if (hasNoActor)
      return null;
    for (int i = 0; i < actors.length; i++) {
      actorIdx--;
      if (actorIdx < 0)
        actorIdx = cast(int)(actors.length - 1);
      if (!actors[actorIdx].exists)
        return actors[actorIdx];
    }
    hasNoActor = true;
    return null;
  }

  public T getInstanceForced() {
    actorIdx--;
    if (actorIdx < 0)
      actorIdx = cast(int)(actors.length - 1);
    return actors[actorIdx];
  }

  public T[] getMultipleInstances(int n) {
    if (hasNoActor)
      return null;
    T[] rsl;
    for (int i = 0; i < n; i++) {
      T inst = getInstance();
      if (!inst) {
        foreach (T r; rsl)
          r.exists = false;
        return null;
      }
      inst.exists = true;
      rsl ~= inst;
    }
    foreach (T r; rsl)
      r.exists = false;
    return rsl;
  }

  public void move() {
    hasNoActor = false;
    foreach (T a; actors)
      if (a.exists)
        a.move();
  }

  public void draw() {
    foreach (T a; actors)
      if (a.exists)
        a.draw();
  }

  public void clear() {
    foreach (T a; actors)
      a.exists = false;
    actorIdx = 0;
  }
}
