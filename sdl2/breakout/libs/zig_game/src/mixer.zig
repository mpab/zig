const std = @import("std");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_mixer.h");
});

pub const Sound = struct {
    audio_ptr: *c.Mix_Chunk,

    pub fn init(audio_file: [:0]const u8) !Sound {
        const audio_rw = c.SDL_RWFromConstMem(
            @ptrCast(*const anyopaque, audio_file),
            @intCast(c_int, audio_file.len),
        ) orelse {
            c.SDL_Log("Unable to get RWFromConstMem: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        defer std.debug.assert(c.SDL_RWclose(audio_rw) == 0);

        var audio_ptr = c.Mix_LoadWAV_RW(audio_rw, 0) orelse {
            c.SDL_Log("Unable to load audio: %s", c.Mix_GetError());
            return error.SDLInitializationFailed;
        };

        return .{ .audio_ptr = audio_ptr };
    }

    pub fn play(self: Sound) void {
        _ = c.Mix_PlayChannel(-1, self.audio_ptr, 0);
    }
};

pub const Mixer = struct {
    pub fn init() !c_int {
        var init_flags = c.Mix_Init(c.MIX_INIT_OGG);
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

        return init_flags;
    }
};
