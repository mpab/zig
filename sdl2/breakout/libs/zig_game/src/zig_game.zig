const std = @import("std");

// TODO: replace with module in build file
const c_sdl = @cImport({
    @cInclude("SDL.h");
});
//pub const c_sdl = @import("sdl-native");

//pub const sdl = @import("wrapper/sdl.zig");
pub const sdl = @import("sdl-wrapper"); // configured in build.zig

// import/export sub-modules
pub const sprite = @import("sprite.zig");
pub const font = @import("font.zig");
pub const util = @import("util.zig");
pub const time = @import("time.zig");
pub const color = @import("color.zig");
const _type = @import("_type.zig");

pub fn panic() noreturn {
    const str = @as(?[*:0]const u8, c_sdl.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

pub fn quit() void {
    c_sdl.SDL_Quit();
}

fn _init() void {
    if (c_sdl.SDL_Init(c_sdl.SDL_INIT_VIDEO | c_sdl.SDL_INIT_EVENTS | c_sdl.SDL_INIT_AUDIO) < 0) {
        panic();
    }
}

// import/export types
pub const Canvas = _type.Canvas;
pub const Point = _type.Point;
pub const Rect = _type.Rect;
pub const FontInfo = _type.FontInfo;

pub const ZigGame = struct {
    window: sdl.Window,
    renderer: sdl.Renderer,
    surface: sdl.Surface,
    texture: sdl.Texture,
    format: sdl.PixelFormatEnum,
    size: sdl.Renderer.OutputSize,
    font_scaling: u8 = 1,

    pub fn init(title: [*c]const u8, window_width: u32, window_height: u32) !ZigGame {
        _init();

        var raw_window_ptr = c_sdl.SDL_CreateWindow(title, c_sdl.SDL_WINDOWPOS_CENTERED, c_sdl.SDL_WINDOWPOS_CENTERED, @intCast(c_int, window_width), @intCast(c_int, window_height), 0) orelse panic();

        var window = sdl.Window{ .ptr = raw_window_ptr };
        var raw_renderer_ptr = c_sdl.SDL_CreateRenderer(raw_window_ptr, 0, c_sdl.SDL_RENDERER_PRESENTVSYNC) orelse panic();
        var renderer = sdl.Renderer{ .ptr = raw_renderer_ptr };
        var surface = window.getSurface() catch |err| return err;
        var texture = sdl.createTextureFromSurface(renderer, surface) catch |err| return err;
        var info = texture.query() catch |err| return err;
        var format = info.format;
        var size = renderer.getOutputSize() catch |err| return err;

        return ZigGame{ .window = window, .renderer = renderer, .surface = surface, .texture = texture, .format = format, .size = size };
    }

    pub fn reset_render_target(self: ZigGame) void {
        _ = c_sdl.SDL_SetRenderTarget(self.renderer.ptr, null);
    }

    pub fn create_surface(self: ZigGame, width: u32, height: u32) !sdl.Surface {
        return sdl.createRgbSurfaceWithFormat(@intCast(u31, width), @intCast(u31, height), self.format) catch |err| return err;
    }

    pub fn create_texture(self: ZigGame, width: u32, height: u32) !sdl.Texture {
        var t = sdl.createTexture(self.renderer, self.format, sdl.Texture.Access.target, width, height) catch |err| return err;
        //defer t.destroy();
        return t;
    }

    pub fn create_raw_texture(self: ZigGame, width: u32, height: u32) !*c_sdl.SDL_Texture {
        const ptr = c_sdl.SDL_CreateTexture(
            self.renderer.ptr,
            @enumToInt(self.format),
            @enumToInt(sdl.Texture.Access.target),
            @intCast(c_int, width),
            @intCast(c_int, height),
        ) orelse return error.SdlError;
        return ptr;
    }

    pub fn create_canvas(self: *ZigGame, width: i32, height: i32) !Canvas {
        var texture = try sdl.createTexture(self.renderer, self.format, sdl.Texture.Access.target, @intCast(u32, width), @intCast(u32, height));
        return Canvas.init(texture, width, height);
    }

    // color alpha channel sets transparency level
    pub fn create_transparent_canvas(self: *ZigGame, width: i32, height: i32, fill: sdl.Color) !Canvas {
        var canvas = try self.create_canvas(width, height);
        try canvas.texture.setBlendMode(sdl.BlendMode.blend);
        var rect = sdl.Rectangle{ .x = 0, .y = 0, .width = width, .height = height };
        const r = self.renderer;
        try r.setTarget(canvas.texture);
        try r.setColor(fill);
        try r.fillRect(rect);
        self.reset_render_target();
        return canvas;
    }

    pub fn fill_vertical_gradient(zg: *ZigGame, canvas: Canvas, start: sdl.Color, end: sdl.Color) !void {
        // fills an entire canvas texture with a vertical linear gradient

        const r = zg.renderer;
        try r.setTarget(canvas.texture);

        var dd = 1.0 / @intToFloat(f32, canvas.height);

        var sr: f32 = @intToFloat(f32, start.r);
        var sg: f32 = @intToFloat(f32, start.g);
        var sb: f32 = @intToFloat(f32, start.b);
        var sa: f32 = @intToFloat(f32, start.a);

        var er: f32 = @intToFloat(f32, end.r);
        var eg: f32 = @intToFloat(f32, end.g);
        var eb: f32 = @intToFloat(f32, end.b);
        var ea: f32 = @intToFloat(f32, end.a);

        //surface = pygame.Surface((1, height)).convert_alpha()

        var rm = (er - sr) * dd;
        var gm = (eg - sg) * dd;
        var bm = (eb - sb) * dd;
        var am = (ea - sa) * dd;

        var y: i32 = 0;
        while (y != canvas.height) : (y += 1) {
            var fy = @intToFloat(f32, y);
            var fgr = sr + rm * fy;
            var fgg = sg + gm * fy;
            var fgb = sb + bm * fy;
            var fga = sa + am * fy;

            var gcolor = sdl.Color.rgba(
                @floatToInt(u8, fgr),
                @floatToInt(u8, fgg),
                @floatToInt(u8, fgb),
                @floatToInt(u8, fga),
            );

            try r.setColor(gcolor);
            try r.drawLine(0, y, canvas.width, y);
        }
        zg.reset_render_target();
    }
};
