const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const color = @import("color.zig");

pub fn filled_rect(zg: *ZigGame, width: i32, height: i32, fill: sdl.Color) !ziggame.Canvas {
    var canvas = try zg.create_canvas(width, height);
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

pub fn filled_circle(renderer: sdl.Renderer, xcc: i32, ycc: i32, radius: i32) !void {
    var d_e: i32 = 3;
    var d_se = -2 * radius + 5;

    var cx: i32 = 0;
    var cy = radius;
    var df = 1 - radius;

    var ymcy = ycc - cy;
    var ypcy = ycc + cy;
    var xmcy = xcc - cy;
    var xpcy = xcc + cy;

    try renderer.drawLine(xmcy, ycc, xpcy, ycc); // fill center horizontal

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

    while (cy >= cx) {
        ypcy = ycc + cy;
        ymcy = ycc - cy;
        var xpcx = xcc + cx;
        var xmcx = xcc - cx;
        try renderer.drawLine(xmcx, ymcy, xpcx - 1, ymcy); // top
        try renderer.drawLine(xmcx - 1, ypcy - 1, xpcx, ypcy - 1); // bottom

        xpcy = xcc + cy;
        xmcy = xcc - cy;
        var ypcx = ycc + cx;
        var ymcx = ycc - cx;
        try renderer.drawLine(xmcy, ymcx, xpcy - 1, ymcx); // top mid
        try renderer.drawLine(xmcy, ypcx, xpcy - 1, ypcx); // bottom mid
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

pub fn circle(renderer: sdl.Renderer, xcc: i32, ycc: i32, radius: i32) !void {
    var d_e: i32 = 3;
    var d_se = -2 * radius + 5;

    var cx: i32 = 0;
    var cy = radius;
    var df = 1 - radius;

    var ymcy = ycc - cy;
    var ypcy = ycc + cy;
    var xmcy = xcc - cy;
    var xpcy = xcc + cy;
    try renderer.drawPoint(xcc, ymcy); // top mid
    try renderer.drawPoint(xcc, ypcy - 1); // bottom mid
    try renderer.drawPoint(xmcy, ycc); // left mid
    try renderer.drawPoint(xpcy - 1, ycc); // right mid

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

    while (cy >= cx) {
        ypcy = ycc + cy;
        ymcy = ycc - cy;
        var xpcx = xcc + cx;
        var xmcx = xcc - cx;
        try renderer.drawPoint(xmcx, ymcy); // top left
        try renderer.drawPoint(xpcx - 1, ymcy); // top right
        try renderer.drawPoint(xmcx, ypcy - 1); // bottom left
        try renderer.drawPoint(xpcx - 1, ypcy - 1); // bottom right

        xpcy = xcc + cy;
        xmcy = xcc - cy;
        var ypcx = ycc + cx;
        var ymcx = ycc - cx;
        try renderer.drawPoint(xmcy, ymcx); // center top left
        try renderer.drawPoint(xpcy - 1, ymcx); // center bottom right
        try renderer.drawPoint(xmcy, ypcx); // center bottom left
        try renderer.drawPoint(xpcy - 1, ypcx); // center bottom right

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
    var canvas = try zg.create_transparent_canvas(radiusx2, radiusx2, sdl.Color.rgba(0, 0, 0, 0));
    const r = zg.renderer;
    try r.setTarget(canvas.texture);
    try r.setColor(color.BALL_BORDER_COLOR);
    try filled_circle(zg.renderer, radius, radius, radius);
    try r.setColor(color.BALL_FILL_COLOR);
    try circle(zg.renderer, radius, radius, radius - 1);
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
    var canvas = try zg.vertical_gradient_filled_canvas(80, 16, color.green, color.SCREEN_COLOR);
    return canvas;
}
