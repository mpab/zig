pub const sdl = @import("sdl-wrapper"); // configured in build.zig
// TODO: replace with module in build file
const c_sdl = @cImport({
    @cInclude("SDL.h");
});

pub const system = @import("system.zig");

fn to_wrapped_sdl_Rectangle(raw_rect: c_sdl.SDL_Rect) sdl.Rectangle {
    return sdl.Rectangle{ .x = 0, .y = 0, .width = raw_rect.w, .height = raw_rect.w };
}

pub const Canvas = struct {
    width: i32,
    height: i32,
    texture: sdl.Texture,

    pub fn init(tex: sdl.Texture, width: i32, height: i32) Canvas {
        return Canvas{ .texture = tex, .width = width, .height = height };
    }
};

pub const Context = struct {
    window: sdl.Window,
    renderer: sdl.Renderer,
    surface: sdl.Surface,
    texture: sdl.Texture,
    format: sdl.PixelFormatEnum,
    size: sdl.Renderer.OutputSize,

    pub fn init(window_width: u32, window_height: u32) !Context {
        var raw_window_ptr = c_sdl.SDL_CreateWindow("zig-game", c_sdl.SDL_WINDOWPOS_CENTERED, c_sdl.SDL_WINDOWPOS_CENTERED, @intCast(c_int, window_width), @intCast(c_int, window_height), 0) orelse system.panic();

        var window = sdl.Window{ .ptr = raw_window_ptr };
        var raw_renderer_ptr = c_sdl.SDL_CreateRenderer(raw_window_ptr, 0, c_sdl.SDL_RENDERER_PRESENTVSYNC) orelse system.panic();
        var renderer = sdl.Renderer{ .ptr = raw_renderer_ptr };
        var surface = window.getSurface() catch |err| return err;
        var texture = sdl.createTextureFromSurface(renderer, surface) catch |err| return err;
        var info = texture.query() catch |err| return err;
        var format = info.format;
        var size = renderer.getOutputSize() catch |err| return err;

        return Context{ .window = window, .renderer = renderer, .surface = surface, .texture = texture, .format = format, .size = size };
    }

    pub fn reset_render_target(self: Context) void {
        _ = c_sdl.SDL_SetRenderTarget(self.renderer.ptr, null);
    }

    pub fn create_surface(self: Context, width: u32, height: u32) !sdl.Surface {
        return sdl.createRgbSurfaceWithFormat(@intCast(u31, width), @intCast(u31, height), self.format) catch |err| return err;
    }

    pub fn create_texture(self: Context, width: u32, height: u32) !sdl.Texture {
        var t = sdl.createTexture(self.renderer, self.format, sdl.Texture.Access.target, width, height) catch |err| return err;
        //defer t.destroy();
        return t;
    }

    pub fn create_raw_texture(self: Context, width: u32, height: u32) !*c_sdl.SDL_Texture {
        const ptr = c_sdl.SDL_CreateTexture(
            self.renderer.ptr,
            @enumToInt(self.format),
            @enumToInt(sdl.Texture.Access.target),
            @intCast(c_int, width),
            @intCast(c_int, height),
        ) orelse return error.SdlError;
        return ptr;
    }
};
