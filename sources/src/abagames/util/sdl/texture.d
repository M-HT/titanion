/*
 * $Id: texture.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.texture;

private import std.string;
version (USE_GLES) {
  private import opengles;
  private import opengles_glu;
} else {
  private import opengl;
  private import openglu;
}
private import SDL;
private import abagames.util.sdl.sdlexception;

/**
 * OpenGL textures.
 */
public class Texture {
 public:
  static string imagesDir = "images/";
  static SDL_Surface*[char[]] surface;
 private:
  GLuint[] num, maskNum;
  int textureNum, maskTextureNum;
  Uint32[128 * 128] pixels;
  Uint32[128 * 128] maskPixels;

  public static SDL_Surface* loadBmp(const char[] name) {
    if (name in surface) {
      return surface[name];
    } else {
      const char[] fileName = imagesDir ~ name;
      SDL_Surface *s = SDL_LoadBMP(std.string.toStringz(fileName));
      if (!s)
        throw new SDLInitFailedException("Unable to load: " ~ fileName);
      SDL_PixelFormat format;
      format.palette = null;
      format.BitsPerPixel = 32;
      format.BytesPerPixel = 4;
      format.Rmask = 0x000000ff;
      format.Gmask = 0x0000ff00;
      format.Bmask = 0x00ff0000;
      format.Amask = 0xff000000;
      format.Rshift = 0;
      format.Gshift = 8;
      format.Bshift = 16;
      format.Ashift = 24;
      format.Rloss = 0;
      format.Gloss = 0;
      format.Bloss = 0;
      format.Aloss = 0;
      format.alpha = 0;
      SDL_Surface *cs = SDL_ConvertSurface(s, &format, SDL_SWSURFACE);
      surface[name] = cs;
      return cs;
    }
  }

  public this(const char[] name) {
    SDL_Surface *s = loadBmp(name);
    num.length = 1;
    glGenTextures(1, num.ptr);
    glBindTexture(GL_TEXTURE_2D, num[0]);
    gluBuild2DMipmaps(GL_TEXTURE_2D, 4, s.w, s.h,
                      GL_RGBA, GL_UNSIGNED_BYTE, s.pixels);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  }

  public this(const char[] name, int sx, int sy, int xn, int yn, int panelWidth, int panelHeight,
              Uint32 maskColor = 0xffffffffu) {
    SDL_Surface *s = loadBmp(name);
    Uint32* surfacePixels = cast(Uint32*) s.pixels;
    this(surfacePixels, s.w, sx, sy, xn, yn, panelWidth, panelHeight, maskColor);
  }

  public this(Uint32* surfacePixels, int surfaceWidth,
              int sx, int sy, int xn, int yn, int panelWidth, int panelHeight,
              Uint32 maskColor = 0xffffffffu) {
    textureNum = xn * yn;
    num.length = textureNum;
    glGenTextures(textureNum, num.ptr);
    if (maskColor != 0xffffffffu) {
      maskTextureNum = textureNum;
      maskNum.length = maskTextureNum;
      glGenTextures(maskTextureNum, maskNum.ptr);
    }
    int ti = 0;
    for (int oy = 0; oy < yn; oy++) {
      for (int ox = 0; ox < xn; ox++) {
        int pi = 0;
        for (int y = 0; y < panelHeight; y++) {
          for (int x = 0; x < panelWidth; x++) {
            Uint32 p = surfacePixels[ox * panelWidth + x + sx + (oy * panelHeight + y + sy) * surfaceWidth];
            Uint32 m;
            if (p == maskColor) {
              p = 0xff000000u;
              m = 0x00ffffffu;
            } else {
              m = 0x00000000u;
            }
            pixels[pi] = p;
            if (maskColor != 0xffffffffu)
              maskPixels[pi] = m;
            pi++;
          }
        }
        glBindTexture(GL_TEXTURE_2D, num[ti]);
        gluBuild2DMipmaps(GL_TEXTURE_2D, 4, panelWidth, panelHeight,
                          GL_RGBA, GL_UNSIGNED_BYTE, pixels.ptr);
        glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
        glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        if (maskColor != 0xffffffffu) {
          glBindTexture(GL_TEXTURE_2D, maskNum[ti]);
          gluBuild2DMipmaps(GL_TEXTURE_2D, 4, panelWidth, panelHeight,
                            GL_RGBA, GL_UNSIGNED_BYTE, maskPixels.ptr);
          glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
          glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        }
        ti++;
      }
    }
  }

  public void close() {
    glDeleteTextures(textureNum, num.ptr);
    num.length = 0;
    if (maskTextureNum > 0) {
      glDeleteTextures(maskTextureNum, maskNum.ptr);
      maskNum.length = 0;
    }
  }

  public void bind(int idx = 0) {
    glBindTexture(GL_TEXTURE_2D, num[idx]);
  }

  public void bindMask(int idx = 0) {
    glBindTexture(GL_TEXTURE_2D, maskNum[idx]);
  }
}
