# Feature and Bug Tracker

## TODO

- integrate/convert some of this: https://github.com/ferzkopp/SDL_gfx

- game (basic functionality)
  - sounds
- game (improved functionality)
  - gradient font rendering
  - drawing: more primitives (rectangle with rounded edges, ...)
- improve sprite velocity logic using polar coordinates
- installation and setup
  - fix zig sdl library hack
- zig-game library
  - font selection (currently hard-coded)
  - improved sound support
  - implement less hacky polymorphic sprites
  - create Font object
    - to hold and manage context information such as font size, render centering, etc
    - should also contain a reference to the ZigGame context for rendering

## DONE

- basic SDL bootstrapping
- game (basic functionality)
  - remaining game states
  - high scores
  - levels
  - most game states
  - ticker/state ticker
  - ticker/ball speedup ticker (ball speedup during level)
  - scoring
  - shape (texture) abstractions
  - mouse/bat movements
  - drawing: circle primitive
- game (improved functionality)
  - brighten/darken colors using a saturate function
  - an extended rect type including top, bottom, etc. to better map to pygame
  - drawing: more primitives (filled circle)
- installation and setup
  - scripts to pull down the SDL libs and headers
  - scripts to pull down the sdl zig wrapper (temp solution)
  - links to libs/references other projects
  - now uses vcpkg for pulling down SDL dependencies
  - now uses git for pulling down SDL.zig
- zig-game library
  - transparency on textures
  - sprite polymorphism (hacky version)
  - fonts and text (using a bitmap font and pixel-plotting)
  - sprite collisions (using intersecting rectangles)
  - sprites
  - basic sound support using SDL mixer
- disappearing animation sprite for brick and score
- text sprites (not using textures)
- improved sprite velocity logic using {.vel .dx .dy}
- supports zig v0.10.1 and v0.11.0 build/code
- fixed drift issue with ticker
- fixed bat debounce
