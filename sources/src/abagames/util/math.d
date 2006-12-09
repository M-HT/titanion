/*
 * $Id: math.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.util.math;

private import std.math;

/**
 * Math utility methods.
 */
public class Math {
 private:

  public static float normalizeDeg(float d) {
    float rd = d;
    if (rd < -PI)
      rd = PI * 2 - (-rd % (PI * 2));
    return (rd + PI) % (PI * 2) - PI;
  }

  public static float normalizeDeg360(float d) {
    float rd = d;
    if (rd < -180)
      return 360 - (-rd % 360);
    return (rd + 180) % 360 - 180;
  }
}
