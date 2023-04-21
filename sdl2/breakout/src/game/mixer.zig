const std = @import("std");

const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_mixer.h");
});

pub const ball_wall = @embedFile("./assets/ball_wall.ogg");
pub const mouse_press = @embedFile("./assets/mouse_press.ogg");

const dbg = std.log.debug;

pub fn play(audio_file: [:0]const u8) !void {
    _ = c.Mix_Init(c.MIX_INIT_OGG);
    defer c.Mix_Quit();

    if (c.Mix_OpenAudio(
        c.MIX_DEFAULT_FREQUENCY,
        c.MIX_DEFAULT_FORMAT,
        c.MIX_DEFAULT_CHANNELS,
        1024,
    ) != 0) {
        c.SDL_Log("Unable to open audio: %s", c.Mix_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.Mix_CloseAudio();

    const audio_rw = c.SDL_RWFromConstMem(
        @ptrCast(*const anyopaque, audio_file),
        @intCast(c_int, audio_file.len),
    ) orelse {
        c.SDL_Log("Unable to get RWFromConstMem: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer std.debug.assert(c.SDL_RWclose(audio_rw) == 0);

    const audio = c.Mix_LoadWAV_RW(audio_rw, 0) orelse {
        c.SDL_Log("Unable to load audio: %s", c.Mix_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.Mix_FreeChunk(audio);
    _ = c.Mix_PlayChannel(-1, audio, 0);

    c.SDL_Delay(1000);
}
