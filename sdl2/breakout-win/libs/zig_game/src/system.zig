const std = @import("std");

// TODO: replace with module in build file
const c_sdl = @cImport({
    @cInclude("SDL.h");
});

pub fn panic() noreturn {
    const str = @as(?[*:0]const u8, c_sdl.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

pub fn init() void {
    if (c_sdl.SDL_Init(c_sdl.SDL_INIT_VIDEO | c_sdl.SDL_INIT_EVENTS | c_sdl.SDL_INIT_AUDIO) < 0) {
        panic();
    }
    //sdl.ttf.init() catch return;
    //defer c_sdl.SDL_Quit();
}

pub fn shutdown() void {
    c_sdl.SDL_Quit();
}
