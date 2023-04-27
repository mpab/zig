const std = @import("std");
const dbg = std.log.debug;

// TODO: replace with module in build file
pub const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_ttf.h");
});
//pub const c = @import("sdl-native");

//pub const sdl = @import("wrapper/sdl.zig");
pub const sdl = @import("sdl-wrapper"); // configured in build.zig

// import/export sub-modules
pub const sprite = @import("sprite.zig");
pub const font = @import("font.zig");
pub const mixer = @import("mixer.zig");
pub const util = @import("util.zig");
pub const time = @import("time.zig");
pub const color = @import("color.zig");
const _type = @import("_type.zig");

pub fn c_sdl_panic() noreturn {
    const str = @as(?[*:0]const u8, c.SDL_GetError()) orelse "unknown error";
    dbg("{s}", .{str});
    @panic(std.mem.sliceTo(str, 0));
}

pub fn quit() void {
    c.SDL_Quit();
}

fn _init() void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS | c.SDL_INIT_AUDIO) < 0) {
        c_sdl_panic();
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
    //surface: sdl.Surface,
    //texture: sdl.Texture,
    format: sdl.PixelFormatEnum,
    size: sdl.Renderer.OutputSize,
    font_scaling: u8 = 1,

    pub fn init(title: [*c]const u8, window_width: u32, window_height: u32) !ZigGame {
        _init();

        var raw_window_ptr = c.SDL_CreateWindow(title, c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, @intCast(c_int, window_width), @intCast(c_int, window_height), 0) orelse c_sdl_panic();

        var window = sdl.Window{ .ptr = raw_window_ptr };
        var raw_renderer_ptr = c.SDL_CreateRenderer(raw_window_ptr, 0, c.SDL_RENDERER_PRESENTVSYNC) orelse c_sdl_panic();
        var renderer = sdl.Renderer{ .ptr = raw_renderer_ptr };
        var size = renderer.getOutputSize() catch |err| return err;

        var format = sdl.PixelFormatEnum.argb8888;
        if (window.getSurface()) |surface| {
            var texture = sdl.createTextureFromSurface(renderer, surface) catch |err| return err;
            var info = texture.query() catch |err| return err;
            format = info.format;
        } else |_| {
            dbg("WARN: could not get window surface, using default format: {}", .{format});
        }

        return ZigGame{ .window = window, .renderer = renderer, .size = size, .format = format };
    }

    pub fn reset_render_target(self: ZigGame) void {
        _ = c.SDL_SetRenderTarget(self.renderer.ptr, null);
    }

    pub fn create_surface(self: ZigGame, width: u32, height: u32) !sdl.Surface {
        return sdl.createRgbSurfaceWithFormat(@intCast(u31, width), @intCast(u31, height), self.format) catch |err| return err;
    }

    pub fn create_texture(self: ZigGame, width: u32, height: u32) !sdl.Texture {
        var t = sdl.createTexture(self.renderer, self.format, sdl.Texture.Access.target, width, height) catch |err| return err;
        //defer t.destroy();
        return t;
    }

    pub fn create_raw_texture(self: ZigGame, width: u32, height: u32) !*c.SDL_Texture {
        const ptr = c.SDL_CreateTexture(
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
        const r = self.renderer;
        try r.setTarget(canvas.texture);
        try r.setColor(fill);
        try r.clear();
        self.reset_render_target();
        return canvas;
    }

    pub fn fill_vertical_gradient(zg: *ZigGame, canvas: Canvas, start: sdl.Color, end: sdl.Color, start_y: i32, end_y: i32) !void {
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

        var y: i32 = start_y;
        while (y != end_y) : (y += 1) {
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
