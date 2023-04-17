const std = @import("std");

// TODO: replace with module in build file
const c_sdl = @cImport({
    @cInclude("SDL.h");
});
//pub const c_sdl = @import("sdl-native");

//pub const sdl = @import("wrapper/sdl.zig");
pub const sdl = @import("sdl-wrapper"); // configured in build.zig

// import/export sub-modules
pub const gfx = @import("gfx.zig");
pub const sprite = @import("sprite.zig");
pub const text = @import("text.zig");
pub const util = @import("util.zig");
pub const system = @import("system.zig");
pub const time = @import("time.zig");
pub const color = @import("color.zig");
pub const _type = @import("_type.zig");

// TODO
// Rect converters: Rect <-> sdl.Rectangle, Rect <-> c_sdl.SDL_Rect

