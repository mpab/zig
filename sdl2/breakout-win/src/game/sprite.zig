const zg = @import("zig-game");

pub fn from_sdl_rect(r: zg.sdl.Rectangle) zg._type.Rect {
    return .{ .left = r.x, .top = r.y, .right = r.x + r.width, .bottom = r.y + r.height };
}

pub fn from_sprite(s: *zg.sprite.Sprite) zg._type.Rect {
    return .{ .left = s.x, .top = s.y, .right = s.x + s.canvas.width, .bottom = s.y + s.canvas.height };
}

pub const Ball = struct {
    pub fn new(canvas: zg.gfx.Canvas, bounds: zg.sdl.Rectangle, x: i32, y: i32, vx: i32, vy: i32) zg.sprite.Sprite {
        return .{ .__v_update = update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vx = vx, .vy = vy, .state = 0 } };
    }

    pub fn update(base: *zg.sprite.Sprite) void {
        base.x += base.ext.vx;
        base.y += base.ext.vy;

        var sr = from_sprite(base);
        var bounds = from_sdl_rect(base.bounds);

        if (sr.left < bounds.left) {
            base.ext.vx = -base.ext.vx;
            sr.left = bounds.left;
        }
        if (sr.right > bounds.right) {
            base.ext.vx = -base.ext.vx;
            sr.left = bounds.right - base.canvas.width;
        }
        if (sr.top < bounds.top) {
            base.ext.vy = -base.ext.vy;
            sr.top = bounds.top;
        }
        if (sr.bottom > bounds.bottom) {
            base.ext.vy = -base.ext.vy;
            sr.top = bounds.bottom - base.canvas.height;
        }

        base.x = sr.left;
        base.y = sr.top;
    }
};

pub const Sprite = struct {
    pub fn new(canvas: zg.gfx.Canvas, bounds: zg.sdl.Rectangle, x: i32, y: i32) zg.sprite.Sprite {
        return .{ .__v_update = Sprite.update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vx = 0, .vy = 0, .state = 0 } };
    }
    pub fn update(base: *zg.sprite.Sprite) void {
        _ = base;
    }
};

pub const Brick = struct {
    pub fn new(canvas: zg.gfx.Canvas, bounds: zg.sdl.Rectangle, x: i32, y: i32) zg.sprite.Sprite {
        return .{ .__v_update = update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vx = 0, .vy = 0, .state = 0 } };
    }

    pub fn update(base: *zg.sprite.Sprite) void {
        base.x += base.ext.vx;
        base.y += base.ext.vy;

        var sr = from_sprite(base);
        var bounds = from_sdl_rect(base.bounds);

        if (sr.left < bounds.left) {
            base.ext.vx = -base.ext.vx;
            sr.left = bounds.left;
        }
        if (sr.right > bounds.right) {
            base.ext.vx = -base.ext.vx;
            sr.left = bounds.right - base.canvas.width;
        }
        if (sr.top < bounds.top) {
            base.ext.vy = -base.ext.vy;
            sr.top = bounds.top;
        }
        if (sr.bottom > bounds.bottom) {
            base.ext.vy = -base.ext.vy;
            sr.top = bounds.bottom - base.canvas.height;
        }

        base.x = sr.left;
        base.y = sr.top;
    }
};

// pub const DisappearingBrick = struct {
//     //base: zg.sprite.Sprite,

//     pub fn new(target: zg.gfx.Canvas, bounds: zg.sdl.Rectangle, x: i32, y: i32, vx: i32, vy: i32, countdown: i32) Ball {
//         return DisappearingBrick{ .base = .{ .target = target, .bounds = bounds, .x = x, .y = y }, .vx = vx, .vy = vy, .countdown = countdown };
//     }

//     pub fn draw(self: Ball, ctx: zg.Context) void {
//         if (self.countdown > 0)
//             self.base.draw(ctx);
//     }

//     pub fn update(self: *Ball) void {
//         self.base.x += self.vx;
//         self.base.y += self.vy;

//         self.countdown = if (self.countdown > 0) self.countdown - 1 else self.countdown;
//     }
// };
