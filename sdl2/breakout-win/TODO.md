# Feature and Bug Tracker

## TODO

- integrate/convert some of this: https://github.com/ferzkopp/SDL_gfx
- implement transparency on textures
- implement a polymorphic sprite group container
- sprite polymorphism
- game (basic functionality)
  - remaining game states
  - sounds
  - levels
  - high scores
- game (improved functionality)
  - gradient font rendering
  - drawing: more primitives (filled circle, rectangle with rounded edges, ...)
- installation and setup
  - fix zig sdl library hack

## DONE

- basic SDL bootstrapping
- game (basic functionality)
  - most game states
  - ticker/state ticker
  - scoring
  - sprite collisions (using intersecting rectangles)
  - sprites
  - shape (texture) abstractions
  - mouse/bat movements
  - drawing: circle primitive
  - fonts and text (using a bitmap font and pixel-plotting)
- game (improved functionality)
  - brighten/darken colors using a saturate function
  - an extended rect type including top, bottom, etc. to better map to pygame
- installation and setup
  - scripts to pull down the SDL libs and headers
  - scripts to pull down the sdl zig wrapper (temp solution)
  - links to libs/references other projects