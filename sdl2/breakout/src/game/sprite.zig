const std = @import("std");
const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const shape = @import("shape.zig");
const color = @import("color.zig");
const constant = @import("constant.zig");

pub fn from_sdl_rect(r: sdl.Rectangle) ziggame.Rect {
    return .{ .left = r.x, .top = r.y, .right = r.x + r.width, .bottom = r.y + r.height };
}

pub fn from_sprite(s: *ziggame.sprite.Sprite) ziggame.Rect {
    return .{ .left = s.x, .top = s.y, .right = s.x + s.canvas.width, .bottom = s.y + s.canvas.height };
}

fn init_ext(vel: i32, dx: i32, dy: i32) ziggame.sprite.ExtendedAttributes {
    return .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = "" };
}

pub const BasicSprite = struct {
    pub fn new(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32) ziggame.sprite.Sprite {
        return .{ .__v_draw = v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = init_ext(0, 0, 0) };
    }

    fn v_draw(self: ziggame.sprite.Sprite, zg: *ZigGame) void {
        var src_rect = sdl.Rectangle{ .x = 0, .y = 0, .width = self.canvas.width, .height = self.canvas.height };
        var dest_rect = sdl.Rectangle{ .x = self.x, .y = self.y, .width = self.canvas.width, .height = self.canvas.height };
        //zg.renderer.setDrawBlendMode(sdl.BlendMode.blend) catch return;
        zg.renderer.copy(self.canvas.texture, dest_rect, src_rect) catch return;
    }

    pub fn v_update(self: *ziggame.sprite.Sprite) void {
        _ = self;
    }
};

pub const BouncingSprite = struct {
    pub fn new(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) ziggame.sprite.Sprite {
        return .{ .__v_draw = BasicSprite.v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = init_ext(vel, dx, dy) };
    }

    fn v_update(self: *ziggame.sprite.Sprite) void {
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
    pub fn text(zg: *ZigGame, c_string: [*c]const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ziggame.sprite.Sprite {
        var canvas = try zg.create_canvas(1, 1);
        return .{ .__v_draw = v_draw_string, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = std.mem.span(c_string) } };
    }

    pub fn clone(base: ziggame.sprite.Sprite) ziggame.sprite.Sprite {
        return .{ .__v_draw = v_draw, .__v_update = v_update, .canvas = base.canvas, .bounds = base.bounds, .x = base.x, .y = base.y, .ext = base.ext };
    }

    fn v_draw(self: ziggame.sprite.Sprite, zg: *ZigGame) void {
        if (self.ext.state < 0) return; // termination state < 0
        BasicSprite.v_draw(self, zg);
    }

    fn v_draw_string(self: ziggame.sprite.Sprite, zg: *ZigGame) void {
        if (self.ext.state < 0) return; // termination state < 0
        ziggame.font.render(
            zg,
            self.ext.string,
            self.x,
            self.y,
            constant.SPRITE_TEXT_SCALE - 1, //TODO: fix magic number
            color.default_text_color,
        ) catch return;
    }

    fn v_update(self: *ziggame.sprite.Sprite) void {
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

pub const ScrollingSprite = struct {
    pub fn text(zg: *ZigGame, string: []const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ziggame.sprite.Sprite {
        var canvas = try ziggame.font.create_text_canvas(
            zg,
            string,
            constant.SPRITE_TEXT_SCALE,
            color.default_text_color,
        );
        return .{ .__v_draw = BasicSprite.v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = string } };
    }

    pub fn text_gradient(zg: *ZigGame, var_string: []const u8, gradient: color.Gradient, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ziggame.sprite.Sprite {
        var canvas = try ziggame.font.create_gradient_text_canvas(zg, var_string, constant.SPRITE_TEXT_SCALE, gradient.start, gradient.end);
        return .{ .__v_draw = BasicSprite.v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = var_string } };
    }

    pub fn text_dual_gradient(zg: *ZigGame, var_string: []const u8, gradient: color.DualGradient, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ziggame.sprite.Sprite {
        var canvas = try ziggame.font.create_dual_gradient_text_canvas(zg, var_string, constant.SPRITE_TEXT_SCALE, gradient.start.start, gradient.start.end, gradient.end.start, gradient.end.end);
        return .{ .__v_draw = BasicSprite.v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = var_string } };
    }

    pub fn clone(base: ziggame.sprite.Sprite) ziggame.sprite.Sprite {
        return .{ .__v_draw = ziggame.sprite.Sprite.v_draw, .__v_update = v_update, .canvas = base.canvas, .bounds = base.bounds, .x = base.x, .y = base.y, .ext = base.ext };
    }

    fn v_update(self: *ziggame.sprite.Sprite) void {
        if (self.ext.state < 0) return; // termination state < 0

        self.x += self.ext.dx * self.ext.vel;
        self.y += self.ext.dy * self.ext.vel;

        var sr = from_sprite(self);
        var bounds = from_sdl_rect(self.bounds);

        if ((self.ext.dx < 0) and (sr.left < (bounds.left - self.canvas.width))) {
            sr.left = bounds.right;
        }
        if ((self.ext.dx > 0) and (sr.left > bounds.right)) {
            sr.left = bounds.left - self.canvas.width;
        }
        if ((self.ext.dy < 0) and (sr.top < (bounds.top - self.canvas.height))) {
            sr.top = bounds.bottom;
        }
        if ((self.ext.dy > 0) and (sr.bottom > (bounds.bottom + self.canvas.height))) {
            sr.top = bounds.top;
        }

        self.x = sr.left;
        self.y = sr.top;
    }
};
