const std = @import("std");

const c_sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_mixer.h");
});

pub fn panic() noreturn {
    const str = @as(?[*:0]const u8, c_sdl.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

pub fn play() !void {
    if (c_sdl.Mix_OpenAudio(22050, c_sdl.MIX_DEFAULT_FORMAT, 2, 4096) < 0) {
        panic();
    }

    var wave = c_sdl.Mix_LoadWAV("./assets/Roland-GR-1-Trumpet-C5.wav");
    // if (wave == NULL)
    //     return -1;

    if (c_sdl.Mix_PlayChannel(-1, wave, 0) < 0) {
        panic();
    }

    while (c_sdl.Mix_PlayingMusic()) {}

    c_sdl.Mix_FreeChunk(wave);
}
