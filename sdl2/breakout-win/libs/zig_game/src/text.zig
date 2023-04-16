const gfx = @import("gfx.zig");
const util = @import("util.zig");
const _type = @import("_type.zig");
//const font = @import("font_opengameart.zig");
const font = @import("font_ibm_vga.zig");

const range = util.range;

// TODO
// BitFont structure
// width, height, scaling (create with scaling)
// draw method
// extend later with pre-rendered textures
// use this in all text draw calls

pub fn draw_text(ctx: *gfx.Context, text: []const u8, x: i32, y: i32, scaling: u8) !void {
    var dx: i32 = 0;
    for (text) |letter| {
        try font.draw_letter_scaled(ctx, letter, .{ .x = x + dx, .y = y }, scaling);
        dx += font.info.width * scaling;
    }
}

pub fn draw_text_centered(ctx: *gfx.Context, text: []const u8, x: i32, y: i32, scaling: u8) !void {
    var center_x: i32 = x - @intCast(i32, (text.len * font.info.width * scaling) / 2);
    var center_y: i32 = y - (font.info.height * scaling) / 2;
    var dx: i32 = 0;
    for (text) |letter| {
        try font.draw_letter_scaled(ctx, letter, .{ .x = center_x + dx, .y = center_y }, scaling);
        dx += font.info.width * scaling;
    }
}
