const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const color = @import("color.zig");

pub fn create_canvas(zg: *ZigGame, width: i32, height: i32) !ziggame.Canvas {
    var texture = try sdl.createTexture(zg.renderer, zg.format, sdl.Texture.Access.target, @intCast(u32, width), @intCast(u32, height));
    return ziggame.Canvas.init(texture, width, height);
}

pub fn filled_rect(zg: *ZigGame, width: i32, height: i32, fill: sdl.Color) !ziggame.Canvas {
    var canvas = try create_canvas(zg, width, height);
    var rect = sdl.Rectangle{ .x = 0, .y = 0, .width = width, .height = height };
    const r = zg.renderer;
    try r.setTarget(canvas.texture);
    try r.setColor(fill);
    try r.fillRect(rect);
    zg.reset_render_target();
    return canvas;
}

fn resize(rect: sdl.Rectangle, by: i32) sdl.Rectangle {
    return sdl.Rectangle{ .x = rect.x - by, .y = rect.y - by, .width = rect.width + 2 * by, .height = rect.height + 2 * by };
}

pub fn circle(renderer: sdl.Renderer, xcc: i32, ycc: i32, radius: i32) !void {
    var d_e: i32 = 3;
    var d_se = -2 * radius + 5;

    var cx: i32 = 0;
    var cy = radius;
    var df = 1 - radius;

    while (cy >= cx) {
        var ypcy = ycc + cy;
        var ymcy = ycc - cy;
        if (cx > 0) {
            var xpcx = xcc + cx;
            var xmcx = xcc - cx;
            try renderer.drawPoint(xmcx, ypcy);
            try renderer.drawPoint(xpcx, ypcy);
            try renderer.drawPoint(xmcx, ymcy);
            try renderer.drawPoint(xpcx, ymcy);
        } else {
            try renderer.drawPoint(xcc, ymcy);
            try renderer.drawPoint(xcc, ypcy);
        }
        var xpcy = xcc + cy;
        var xmcy = xcc - cy;
        if ((cx > 0) and (cx != cy)) {
            var ypcx = ycc + cx;
            var ymcx = ycc - cx;
            try renderer.drawPoint(xmcy, ypcx);
            try renderer.drawPoint(xpcy, ypcx);
            try renderer.drawPoint(xmcy, ymcx);
            try renderer.drawPoint(xpcy, ymcx);
        } else if (cx == 0) {
            try renderer.drawPoint(xmcy, ycc);
            try renderer.drawPoint(xpcy, ycc);
        }
        // Update
        if (df < 0) {
            df = df + d_e;
            d_e = d_e + 2;
            d_se = d_se + 2;
        } else {
            df = df + d_se;
            d_e = d_e + 2;
            d_se = d_se + 4;
            cy = cy - 1;
        }
        cx = cx + 1;
    }
}

pub fn ball(zg: *ZigGame, radius: i32) !ziggame.Canvas {
    var radiusx2: i32 = radius * 2;
    var canvas = try filled_rect(zg, radiusx2, radiusx2, color.SCREEN_COLOR);
    const r = zg.renderer;
    try r.setTarget(canvas.texture);
    try r.setColor(color.BALL_BORDER_COLOR);
    try circle(zg.renderer, radius, radius, radius - 1);
    try r.setColor(color.BALL_FILL_COLOR);
    try circle(zg.renderer, radius, radius, radius - 2);
    try circle(zg.renderer, radius, radius, radius - 3);
    try circle(zg.renderer, radius, radius, radius - 4);
    try circle(zg.renderer, radius, radius, radius - 5);
    zg.reset_render_target();
    return canvas;
}

pub fn brick(zg: *ZigGame, width: i32, height: i32, row: i32) !ziggame.Canvas {
    var fill_color = color.BRICK_FILL_COLOR;

    switch (@mod(row, 6)) {
        0 => fill_color = color.silver,
        1 => fill_color = color.red,
        2 => fill_color = color.yellow,
        3 => fill_color = color.blue,
        4 => fill_color = color.magenta,
        5 => fill_color = color.green,
        else => unreachable,
    }

    var canvas = try filled_rect(zg, width, height, fill_color);

    const r = zg.renderer;
    try r.setTarget(canvas.texture);
    try r.setColor(ziggame.color.saturate(fill_color, -64));
    try r.drawLine(0, height - 1, width, height - 1);
    try r.drawLine(width - 1, 0, width - 1, height);

    try r.setColor(ziggame.color.saturate(fill_color, 64));
    try r.drawLine(0, 0, width, 0);
    try r.drawLine(0, 0, 0, height);
    zg.reset_render_target();
    return canvas;
}

// pub fn bat(zg: *ZigGame) !ziggame.Canvas {
//     var canvas = try filled_rect(zg, 80, 16, color.BAT_BORDER_COLOR);
//     var rect = sdl.Rectangle{ .x = 0, .y = 0, .width = canvas.width, .height = canvas.height };
//     const r = zg.renderer;
//     var inner = resize(rect, -1);
//     try r.setColor(color.BAT_FILL_COLOR);
//     try r.setTarget(canvas.texture);
//     try r.fillRect(inner);
//     zg.reset_render_target();
//     return canvas;
// }

pub fn bat(zg: *ZigGame) !ziggame.Canvas {
    var canvas = try vertical_gradient_filled_canvas(zg, 80, 16, color.green, color.SCREEN_COLOR);
    return canvas;
}

pub fn vertical_gradient_filled_canvas(zg: *ZigGame, width: i32, height: i32, start: sdl.Color, end: sdl.Color) !ziggame.Canvas {
    // Returns a canvas containing a texture with a vertical linear gradient filling the entire texture

    var canvas = try create_canvas(zg, width, height);

    const r = zg.renderer;
    try r.setTarget(canvas.texture);

    var dd = 1.0 / @intToFloat(f32, height);

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
    while (y != height) : (y += 1) {
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
        try r.drawLine(0, y, width, y);
    }
    zg.reset_render_target();
    return canvas;
}
