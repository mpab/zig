pub const sdl = @import("sdl-wrapper"); // configured in build.zig

fn clamp(v: i16) u8 {
    if (v > 255) return 255;
    if (v < 0) return 0;
    return @intCast(u8, v);
}

pub fn saturate(in: sdl.Color, level: i16) sdl.Color {
    var r = clamp(in.r + level);
    var g = clamp(in.g + level);
    var b = clamp(in.b + level);
    var clr = sdl.Color.rgb(r, g, b);
    return clr;
}
