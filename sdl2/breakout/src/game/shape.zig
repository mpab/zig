const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const color = @import("color.zig");

pub const TextureRect = struct { texture: sdl.Texture, rect: sdl.Rectangle };

pub fn create_canvas(zg: *ZigGame, width: i32, height: i32) !ziggame.Canvas {
    var texture = try sdl.createTexture(zg.renderer, zg.format, sdl.Texture.Access.target, @intCast(u32, width), @intCast(u32, height));
    var rect = sdl.Rectangle{ .x = 0, .y = 0, .width = width, .height = height };
    return ziggame.Canvas.init(texture, rect.width, rect.height);
}

fn colored_texture(zg: *ZigGame, width: i32, height: i32, fill: sdl.Color) !TextureRect {
    var texture = try sdl.createTexture(zg.renderer, zg.format, sdl.Texture.Access.target, @intCast(u32, width), @intCast(u32, height));
    var rect = sdl.Rectangle{ .x = 0, .y = 0, .width = width, .height = height };
    const r = zg.renderer;
    try r.setTarget(texture);
    try r.setColor(fill);
    try r.fillRect(rect);
    return .{ .texture = texture, .rect = rect };
}

fn cleanup(zg: *ZigGame, tr: TextureRect) ziggame.Canvas {
    zg.reset_render_target();
    return ziggame.Canvas.init(tr.texture, tr.rect.width, tr.rect.height);
}

fn resize(rect: sdl.Rectangle, by: i32) sdl.Rectangle {
    return sdl.Rectangle{ .x = rect.x - by, .y = rect.y - by, .width = rect.width + 2 * by, .height = rect.height + 2 * by };
}

fn draw_circle(renderer: sdl.Renderer, cx: i32, cy: i32, radius: i32) !void {
    const diameter = (radius * 2);

    var x: i32 = (radius - 1);
    var y: i32 = 0;
    var tx: i32 = 1;
    var ty: i32 = 1;
    var err: i32 = tx - diameter;

    while (x >= y) {
        // Each of the following renders an octant of the circle
        try renderer.drawPoint(cx + x, cy - y);
        try renderer.drawPoint(cx + x, cy + y);
        try renderer.drawPoint(cx - x, cy - y);
        try renderer.drawPoint(cx - x, cy + y);
        try renderer.drawPoint(cx + y, cy - x);
        try renderer.drawPoint(cx + y, cy + x);
        try renderer.drawPoint(cx - y, cy - x);
        try renderer.drawPoint(cx - y, cy + x);

        if (err <= 0) {
            y = y - 1;
            err += ty;
            ty += 2;
        }

        if (err > 0) {
            x = x - 1;
            tx += 2;
            err += (tx - diameter);
        }
    }
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
    var tr = try colored_texture(zg, radiusx2, radiusx2, color.SCREEN_COLOR);
    const r = zg.renderer;
    try r.setColor(color.BALL_BORDER_COLOR);
    try circle(zg.renderer, radius, radius, radius - 1);
    try r.setColor(color.BALL_FILL_COLOR);
    try circle(zg.renderer, radius, radius, radius - 2);
    try circle(zg.renderer, radius, radius, radius - 3);
    try circle(zg.renderer, radius, radius, radius - 4);
    try circle(zg.renderer, radius, radius, radius - 5);

    return cleanup(zg, tr);
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

    var tr = try colored_texture(zg, width, height, fill_color);

    const r = zg.renderer;
    try r.setColor(ziggame.color.saturate(fill_color, -64));
    try r.drawLine(0, height - 1, width, height - 1);
    try r.drawLine(width - 1, 0, width - 1, height);

    try r.setColor(ziggame.color.saturate(fill_color, 64));
    try r.drawLine(0, 0, width, 0);
    try r.drawLine(0, 0, 0, height);

    return cleanup(zg, tr);
}

pub fn bat(zg: *ZigGame) !ziggame.Canvas {
    var tr = try colored_texture(zg, 80, 16, color.SCREEN_COLOR);

    const r = zg.renderer;
    try r.setColor(color.BAT_BORDER_COLOR);
    try r.fillRect(tr.rect);

    var inner = resize(tr.rect, -1);
    try r.setColor(color.BAT_FILL_COLOR);
    try r.fillRect(inner);

    return cleanup(zg, tr);
}

pub fn filled_rect(zg: *ZigGame, width: i32, height: i32, fill: sdl.Color) !ziggame.Canvas {
    var tr = try colored_texture(zg, width, height, fill);
    return cleanup(zg, tr);
}

// pub fn vertical_gradient_filled_canvas(size, startcolor, endcolor) !ziggame.Canvas{
//     """
//     Draws a vertical linear gradient filling the entire surface. Returns a
//     surface filled with the gradient (numeric is only 2-3 times faster).
//     """
//     height = size[1]
//     surface = pygame.Surface((1, height)).convert_alpha()
//     dd = 1.0/height
//     sr, sg, sb, sa = startcolor
//     er, eg, eb, ea = endcolor
//     rm = (er-sr)*dd
//     gm = (eg-sg)*dd
//     bm = (eb-sb)*dd
//     am = (ea-sa)*dd
//     for y in range(height):
//         surface.set_at((0, y),
//                        (int(sr + rm*y),
//                         int(sg + gm*y),
//                         int(sb + bm*y),
//                         int(sa + am*y))
//                        )
//     return cleanup(zg, tr);
