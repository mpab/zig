const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub fn get_ticks() u64 {
    //return c.SDL_GetTicks64();
    // kludge for older SDL versions
    return c.SDL_GetTicks();
}

pub fn delay(ms: u32) void {
    c.SDL_Delay(ms);
}
