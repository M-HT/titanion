#!/bin/sh

FLAGS="-frelease -fdata-sections -ffunction-sections -fno-section-anchors -c -O2 -Wall -pipe -fversion=BindSDL_Static -fversion=SDL_201 -fversion=SDL_Mixer_202 -I`pwd`/import"

rm import/*.o*
rm import/sdl/*.o*
rm import/bindbc/sdl/*.o*
rm src/abagames/util/*.o*
rm src/abagames/util/sdl/*.o*
rm src/abagames/ttn/*.o*

cd import
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd ../bindbc/sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd ../../..

cd src/abagames/util
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../.. \{\} \;
cd ../../..

cd src/abagames/util/sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../../.. \{\} \;
cd ../../../..

cd src/abagames/ttn
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../.. \{\} \;
cd ../../..

gdc -o Titanion -s -Wl,--gc-sections -static-libphobos import/*.o* src/abagames/util/*.o* import/sdl/*.o* import/bindbc/sdl/*.o* src/abagames/util/sdl/*.o* src/abagames/ttn/*.o*  -lGLU -lGL -lSDL2_mixer -lSDL2
