const c_sdl = @cImport({
    @cInclude("SDL.h");
});

pub fn get_ticks() u64 {
    return c_sdl.SDL_GetTicks64();
}

pub fn delay(ms: u32) void {
    c_sdl.SDL_Delay(ms);
}
