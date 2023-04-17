pub const sdl = @import("sdl-wrapper"); // configured in build.zig
pub const sprite = @import("sprite.zig");

pub const Point = struct { x: i32, y: i32 };

pub const Rect = struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

pub const FontInfo = struct {
    width: u8,
    height: u8,
    data: [128]u64,
};
