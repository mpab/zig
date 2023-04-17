const std = @import("std");
const zg = @import("zig-game");
const shape = @import("shape.zig");

pub fn from_sdl_rect(r: zg.sdl.Rectangle) zg._type.Rect {
    return .{ .left = r.x, .top = r.y, .right = r.x + r.width, .bottom = r.y + r.height };
}

pub fn from_sprite(s: *zg.sprite.Sprite) zg._type.Rect {
    return .{ .left = s.x, .top = s.y, .right = s.x + s.canvas.width, .bottom = s.y + s.canvas.height };
}

fn init_ext(vel: i32, dx: i32, dy: i32) zg.sprite.ExtendedAttributes {
    return .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = "" };
}

pub const BasicSprite = struct {
    pub fn new(canvas: zg.gfx.Canvas, bounds: zg.sdl.Rectangle, x: i32, y: i32) zg.sprite.Sprite {
        return .{ .__v_draw = v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = init_ext(0, 0, 0) };
    }

    fn v_draw(self: zg.sprite.Sprite, ctx: zg.gfx.Context) void {
        var src_rect = zg.sdl.Rectangle{ .x = 0, .y = 0, .width = self.canvas.width, .height = self.canvas.height };
        var dest_rect = zg.sdl.Rectangle{ .x = self.x, .y = self.y, .width = self.canvas.width, .height = self.canvas.height };
        ctx.renderer.copy(self.canvas.texture, dest_rect, src_rect) catch return;
    }

    pub fn v_update(self: *zg.sprite.Sprite) void {
        _ = self;
    }
};

pub const BouncingSprite = struct {
    pub fn new(canvas: zg.gfx.Canvas, bounds: zg.sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) zg.sprite.Sprite {
        return .{ .__v_draw = BasicSprite.v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = init_ext(vel, dx, dy) };
    }

    fn v_update(self: *zg.sprite.Sprite) void {
        self.x += self.ext.dx * self.ext.vel;
        self.y += self.ext.dy * self.ext.vel;

        var sr = from_sprite(self);
        var bounds = from_sdl_rect(self.bounds);

        if (sr.left < bounds.left) {
            self.ext.dx = -self.ext.dx;
            sr.left = bounds.left;
        }
        if (sr.right > bounds.right) {
            self.ext.dx = -self.ext.dx;
            sr.left = bounds.right - self.canvas.width;
        }
        if (sr.top < bounds.top) {
            self.ext.dy = -self.ext.dy;
            sr.top = bounds.top;
        }
        if (sr.bottom > bounds.bottom) {
            self.ext.dy = -self.ext.dy;
            sr.top = bounds.bottom - self.canvas.height;
        }

        self.x = sr.left;
        self.y = sr.top;
    }
};

pub const DisappearingMovingSprite = struct {
    pub fn text(ctx: zg.gfx.Context, c_string: [*c]const u8, bounds: zg.sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !zg.sprite.Sprite {
        var canvas = try shape.create_canvas(ctx, 1, 1);
        return .{ .__v_draw = v_draw_string, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = std.mem.span(c_string) } };
    }

    pub fn clone(base: zg.sprite.Sprite) zg.sprite.Sprite {
        return .{ .__v_draw = v_draw, .__v_update = v_update, .canvas = base.canvas, .bounds = base.bounds, .x = base.x, .y = base.y, .ext = base.ext };
    }

    fn v_draw(self: zg.sprite.Sprite, ctx: zg.gfx.Context) void {
        if (self.ext.state < 0) return; // termination state < 0
        BasicSprite.v_draw(self, ctx);
    }

    fn v_draw_string(self: zg.sprite.Sprite, ctx: zg.gfx.Context) void {
        if (self.ext.state < 0) return; // termination state < 0
        zg.text.draw_text(@constCast(&ctx), self.ext.string, self.x, self.y, 2) catch return;
    }

    fn v_update(self: *zg.sprite.Sprite) void {
        if (self.ext.state < 0) return; // termination state < 0

        if (self.ext.state < 32) {
            self.x += self.ext.dx * self.ext.vel;
            self.y += self.ext.dy * self.ext.vel;
            self.ext.state += 1;
        } else {
            self.ext.state = -1;
        }
    }
};
