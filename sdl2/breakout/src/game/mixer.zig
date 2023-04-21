const std = @import("std");

const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_mixer.h");
});

pub const ball_bat = @embedFile("./assets/ball_bat.ogg");
pub const ball_brick = @embedFile("./assets/ball_brick.ogg");
pub const ball_wall = @embedFile("./assets/ball_wall.ogg");
pub const mouse_press = @embedFile("./assets/mouse_press.ogg");
pub const life_lost = @embedFile("./assets/life_lost.ogg");
pub const get_ready = @embedFile("./assets/get_ready.ogg");
pub const key_press = @embedFile("./assets/key_press.ogg");
pub const high_score = @embedFile("./assets/high_score.ogg");
pub const game_over = @embedFile("./assets/game_over.ogg");
pub const level_complete = @embedFile("./assets/level_complete.ogg");

const dbg = std.log.debug;

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
    ball_bat: Sound,
    ball_brick: Sound,
    ball_wall: Sound,
    mouse_press: Sound,
    life_lost: Sound,
    get_ready: Sound,
    key_press: Sound,
    high_score: Sound,
    game_over: Sound,
    level_complete: Sound,

    pub fn init() !Mixer {
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

        return .{
            .ball_bat = try Sound.init(ball_bat),
            .ball_brick = try Sound.init(ball_brick),
            .ball_wall = try Sound.init(ball_wall),
            .mouse_press = try Sound.init(mouse_press),
            .life_lost = try Sound.init(life_lost),
            .get_ready = try Sound.init(get_ready),
            .key_press = try Sound.init(key_press),
            .high_score = try Sound.init(high_score),
            .game_over = try Sound.init(game_over),
            .level_complete = try Sound.init(level_complete),
        };
    }
};

// pub fn play(audio_file: [:0]const u8) !void {
//     _ = c.Mix_Init(c.MIX_INIT_OGG);
//     defer c.Mix_Quit();

//     if (c.Mix_OpenAudio(
//         c.MIX_DEFAULT_FREQUENCY,
//         c.MIX_DEFAULT_FORMAT,
//         c.MIX_DEFAULT_CHANNELS,
//         1024,
//     ) != 0) {
//         c.SDL_Log("Unable to open audio: %s", c.Mix_GetError());
//         return error.SDLInitializationFailed;
//     }
//     defer c.Mix_CloseAudio();

//     const audio_rw = c.SDL_RWFromConstMem(
//         @ptrCast(*const anyopaque, audio_file),
//         @intCast(c_int, audio_file.len),
//     ) orelse {
//         c.SDL_Log("Unable to get RWFromConstMem: %s", c.SDL_GetError());
//         return error.SDLInitializationFailed;
//     };
//     defer std.debug.assert(c.SDL_RWclose(audio_rw) == 0);

//     const audio = c.Mix_LoadWAV_RW(audio_rw, 0) orelse {
//         c.SDL_Log("Unable to load audio: %s", c.Mix_GetError());
//         return error.SDLInitializationFailed;
//     };
//     defer c.Mix_FreeChunk(audio);
//     _ = c.Mix_PlayChannel(-1, audio, 0);

//     c.SDL_Delay(1000);
// }
