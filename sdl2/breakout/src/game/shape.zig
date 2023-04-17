const sdl = @import("sdl-wrapper");
const zg = @import("zig-game");
const color = @import("color.zig");

pub const TextureRect = struct { texture: sdl.Texture, rect: sdl.Rectangle };

pub fn colored_texture(ctx: zg.gfx.Context, width: i32, height: i32, fill: sdl.Color) !TextureRect {
    var texture = try sdl.createTexture(ctx.renderer, ctx.format, sdl.Texture.Access.target, @intCast(u32, width), @intCast(u32, height));
    var rect = sdl.Rectangle{ .x = 0, .y = 0, .width = width, .height = height };
    const r = ctx.renderer;
    try r.setTarget(texture);
    try r.setColor(fill);
    try r.fillRect(rect);
    return .{ .texture = texture, .rect = rect };
}

fn cleanup(ctx: zg.gfx.Context, tr: TextureRect) zg.gfx.Canvas {
    ctx.reset_render_target();
    return zg.gfx.Canvas.init(tr.texture, tr.rect.width, tr.rect.height);
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

pub fn ball(ctx: zg.gfx.Context, radius: i32) !zg.gfx.Canvas {
    var radiusx2: i32 = radius * 2;
    var tr = try colored_texture(ctx, radiusx2, radiusx2, color.SCREEN_COLOR);
    const r = ctx.renderer;
    try r.setColor(color.BALL_BORDER_COLOR);
    try circle(ctx.renderer, radius, radius, radius - 1);
    try r.setColor(color.BALL_FILL_COLOR);
    try circle(ctx.renderer, radius, radius, radius - 2);
    try circle(ctx.renderer, radius, radius, radius - 3);
    try circle(ctx.renderer, radius, radius, radius - 4);
    try circle(ctx.renderer, radius, radius, radius - 5);

    return cleanup(ctx, tr);
}

pub fn brick(ctx: zg.gfx.Context, width: i32, height: i32, row: i32) !zg.gfx.Canvas {
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

    var tr = try colored_texture(ctx, width, height, fill_color);

    const r = ctx.renderer;
    try r.setColor(zg.color.saturate(fill_color, -64));
    try r.drawLine(0, height - 1, width, height - 1);
    try r.drawLine(width - 1, 0, width - 1, height);

    try r.setColor(zg.color.saturate(fill_color, 64));
    try r.drawLine(0, 0, width, 0);
    try r.drawLine(0, 0, 0, height);

    return cleanup(ctx, tr);
}

pub fn bat(ctx: zg.gfx.Context) !zg.gfx.Canvas {
    var tr = try colored_texture(ctx, 80, 16, color.SCREEN_COLOR);

    const r = ctx.renderer;
    try r.setColor(color.BAT_BORDER_COLOR);
    try r.fillRect(tr.rect);

    var inner = resize(tr.rect, -1);
    try r.setColor(color.BAT_FILL_COLOR);
    try r.fillRect(inner);

    return cleanup(ctx, tr);
}

pub fn filled_rect(ctx: zg.gfx.Context, width: i32, height: i32, fill: sdl.Color) !zg.gfx.Canvas {
    var tr = try colored_texture(ctx, width, height, fill);
    return cleanup(ctx, tr);
}
