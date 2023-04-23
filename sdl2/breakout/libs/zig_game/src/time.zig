const c = @cImport({
    @cInclude("SDL.h");
});

pub fn get_ticks() u64 {
    return c.SDL_GetTicks64();
}

pub fn delay(ms: u32) void {
    c.SDL_Delay(ms);
}
