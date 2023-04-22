const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const color = @import("color.zig");

pub fn draw_centered(zg: *ZigGame, text_string: []const u8, point: ziggame.Point, scaling: u8) !void {
    try ziggame.font.render_centered(zg, text_string, point.x, point.y, scaling, color.default_text_color);
}

pub fn draw(zg: *ZigGame, text_string: []const u8, point: ziggame.Point, scaling: u8) !void {
    try ziggame.font.render(zg, text_string, point.x, point.y, scaling, color.default_text_color);
}
