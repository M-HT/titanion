/*
 * $Id: preference.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.util.preference;

/**
 * Save/load the preference (e.g. high-score).
 */
public interface Preference {
  public void save();
  public void load();
}
