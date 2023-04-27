pub const sdl = @import("sdl-wrapper"); // configured in build.zig
pub const sprite = @import("sprite.zig");

pub const Canvas = struct {
    width: i32,
    height: i32,
    texture: sdl.Texture,

    pub fn init(tex: sdl.Texture, width: i32, height: i32) Canvas {
        return .{ .texture = tex, .width = width, .height = height };
    }
};

pub const Point = struct { x: i32, y: i32 };

pub const Rect = struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,

    pub fn from_sdl_rect(r: sdl.Rectangle) Rect {
        return .{ .left = r.x, .top = r.y, .right = r.x + r.width, .bottom = r.y + r.height };
    }
};

pub const FontInfo = struct {
    width: u8,
    height: u8,
    data: [128]u64,
};

pub const TextDrawInfo = struct {
    fg: sdl.Color,
    bg: sdl.Color,
    scaling: u8,
    renderer: sdl.Renderer,
};
