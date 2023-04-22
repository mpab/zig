const std = @import("std");
const ziggame = @import("zig_game.zig"); // namespace
const ZigGame = ziggame.ZigGame; // context
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

pub fn draw_glyph(zg: *ZigGame, letter: u8, x: i32, y: i32, scaling: u8) !void {
    try font.draw(zg, letter, .{ .x = x, .y = y }, scaling);
}

pub fn render(zg: *ZigGame, text: []const u8, x: i32, y: i32, scaling: u8, color: ziggame.sdl.Color) !void {
    try zg.renderer.setColor(color);
    var dx: i32 = 0;
    for (text) |letter| {
        try draw_glyph(zg, letter, x + dx, y, scaling);
        dx += font.info.width * scaling;
    }
}

pub fn render_centered(zg: *ZigGame, text: []const u8, x: i32, y: i32, scaling: u8, color: ziggame.sdl.Color) !void {
    try zg.renderer.setColor(color);
    var center_x: i32 = x - @intCast(i32, (text.len * font.info.width * scaling) / 2);
    var center_y: i32 = y - (font.info.height * scaling) / 2;
    var dx: i32 = 0;
    for (text) |letter| {
        try draw_glyph(zg, letter, center_x + dx, center_y, scaling);
        dx += font.info.width * scaling;
    }
}

const dbg = std.log.debug;

// uses color alpha to determine transparency
pub fn create_text_canvas(zg: *ZigGame, text: []const u8, scaling: u8, color: ziggame.sdl.Color) !_type.Canvas {
    var w: i32 = @intCast(i32, text.len * font.info.width * scaling);
    var h: i32 = @intCast(i32, font.info.height * scaling);
    var canvas = if (color.a == 0) try zg.create_transparent_canvas(w, h, color) else try zg.create_canvas(w, h);
    try zg.renderer.setTarget(canvas.texture);
    var solid_color = color;
    solid_color.a = 255; // reset alpha otherwise text will be invisible
    try zg.renderer.setColor(solid_color);
    var dx: i32 = 0;
    for (text) |letter| {
        try draw_glyph(zg, letter, dx, 0, scaling);
        dx += font.info.width * scaling;
    }
    zg.reset_render_target();
    return canvas;
}

pub fn x_create_text_canvas(zg: *ZigGame, text: []const u8, scaling: u8, color: ziggame.sdl.Color) !_type.Canvas {
    _ = color;
    var w: i32 = @intCast(i32, text.len * font.info.width * scaling);
    var h: i32 = @intCast(i32, font.info.height * scaling);

    var rect = ziggame.sdl.Rectangle{ .x = 0, .y = 0, .width = w, .height = h };
    var gradient_canvas = try zg.create_transparent_canvas(rect.width, rect.height, ziggame.sdl.Color.rgba(0, 0, 0, 0));
    try zg.fill_vertical_gradient(gradient_canvas, ziggame.sdl.Color.rgb(255, 0, 0), ziggame.sdl.Color.rgb(0, 0, 255));

    // try zg.renderer.setTarget(gradient_canvas.texture);
    // rect.x += 4;
    // rect.y += 4;
    // rect.width -= 8;
    // rect.height -= 8;
    // try zg.renderer.setColor(ziggame.sdl.Color.rgba(0, 0, 0, 0));
    // try zg.renderer.fillRect(rect);

    var mask_canvas = try zg.create_transparent_canvas(w, h, ziggame.sdl.Color.rgba(0, 0, 0, 255));
    try zg.renderer.setTarget(mask_canvas.texture);
    try zg.renderer.setColor(ziggame.sdl.Color.rgba(255, 255, 255, 0));
    var dx: i32 = 0;
    for (text) |letter| {
        try draw_glyph(zg, letter, dx, 0, scaling);
        dx += font.info.width * scaling;
    }
    try zg.renderer.setTarget(gradient_canvas.texture);
    try zg.renderer.copy(mask_canvas.texture, rect, rect);

    // try zg.renderer.setTarget(mask_canvas.texture);
    // try zg.renderer.setColor(color);
    // var dx: i32 = 0;
    // for (text) |letter| {
    //     try draw_glyph(zg, letter, dx, 0, scaling);
    //     dx += font.info.width * scaling;
    // }

    // try zg.renderer.setTarget(gradient_canvas.texture);
    // try zg.renderer.copy(mask_canvas.texture, rect, rect);

    zg.reset_render_target();
    return gradient_canvas;
}
