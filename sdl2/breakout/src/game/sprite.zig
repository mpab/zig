const std = @import("std");
const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const shape = @import("shape.zig");
const color = @import("color.zig");
const constant = @import("constant.zig");
const ZgSprite = ziggame.sprite.Sprite;

pub const Sprite = union(enum) {
    pub const Data = struct { // common data
        bounds: sdl.Rectangle,
        x: i32,
        y: i32,
        width: i32,
        height: i32,
        dx: i32 = 0, // TODO: use polar vector
        dy: i32 = 0,
        vel: i32 = 0,
    };

    basic: SpriteBase,
    bouncing: BouncingSprite,

    pub fn data(self: Sprite) *Data {
        switch (self) {
            .basic => |basic| return &basic.data.sdata,
            .bouncing => |bouncing| return &bouncing.data.sdata,
        }
    }

    pub fn update(self: Sprite) void {
        switch (self) {
            .basic => |basic| basic.update(),
            .bouncing => |bouncing| bouncing.update(),
        }
    }

    pub fn draw(self: Sprite, zg: *ZigGame) void {
        switch (self) {
            .basic => |basic| basic.draw(zg),
            .bouncing => |bouncing| bouncing.draw(zg),
        }
    }

    pub fn size_rect(self: Sprite) sdl.Rectangle {
        switch (self) {
            .basic => |basic| return basic.size_rect(),
            .bouncing => |bouncing| return bouncing.size_rect(),
        }
    }

    pub fn position_rect(self: Sprite) sdl.Rectangle {
        switch (self) {
            .basic => |basic| return basic.position_rect(),
            .bouncing => |bouncing| return bouncing.position_rect(),
        }
    }
};

pub fn from_sdl_rect(r: sdl.Rectangle) ziggame.Rect {
    return .{ .left = r.x, .top = r.y, .right = r.x + r.width, .bottom = r.y + r.height };
}

pub const SpriteBase = struct {
    pub fn new(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32) ZgSprite {
        var source: ZgSprite.CanvasOrText = .{
            .canvas = canvas,
        };

        return .{
            .__v_draw = v_draw,
            .__v_update = v_update,
            .bounds = bounds,
            .x = x,
            .y = y,
            .width = canvas.width,
            .height = canvas.height,
            .source = source,
            .sound_cue = .{ .empty = {} },
        };
    }

    pub fn new_with_sound(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32, sound: ziggame.mixer.Sound) ZgSprite {
        var source: ZgSprite.CanvasOrText = .{
            .canvas = canvas,
        };

        return .{
            .__v_draw = v_draw,
            .__v_update = v_update,
            .bounds = bounds,
            .x = x,
            .y = y,
            .width = canvas.width,
            .height = canvas.height,
            .source = source,
            .sound_cue = .{ .sound = sound },
        };
    }

    fn v_draw(self: ZgSprite, zg: *ZigGame) void {
        zg.renderer.copy(self.canvas().texture, self.position_rect(), self.size_rect()) catch return;
    }

    pub fn v_update(self: *ZgSprite) void {
        _ = self;
    }
};

pub const BouncingSprite = struct {
    pub fn new(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32, sound: ziggame.mixer.Sound) ZgSprite {
        var source: ZgSprite.CanvasOrText = .{
            .canvas = canvas,
        };

        return .{
            .__v_draw = SpriteBase.v_draw,
            .__v_update = v_update,
            .bounds = bounds,
            .x = x,
            .y = y,
            .vel = vel,
            .dx = dx,
            .dy = dy,
            .width = canvas.width,
            .height = canvas.height,
            .source = source,
            .sound_cue = .{ .sound = sound },
        };
    }

    fn v_update(self: *ZgSprite) void {
        self.x += self.dx * self.vel;
        self.y += self.dy * self.vel;

        var sr = from_sdl_rect(self.position_rect());
        var bounds = from_sdl_rect(self.bounds);

        if (sr.left < bounds.left) {
            self.dx = -self.dx;
            sr.left = bounds.left;
            self.sound().play();
        }
        if (sr.right > bounds.right) {
            self.dx = -self.dx;
            sr.left = bounds.right - self.canvas().width;
            self.sound().play();
        }
        if (sr.top < bounds.top) {
            self.dy = -self.dy;
            sr.top = bounds.top;
            self.sound().play();
        }
        if (sr.bottom > bounds.bottom) {
            self.dy = -self.dy;
            sr.top = bounds.bottom - self.canvas().height;
            self.sound().play();
        }

        self.x = sr.left;
        self.y = sr.top;
    }
};

pub const DisappearingMovingSprite = struct {
    pub fn text(c_string: [*c]const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ZgSprite {
        var source: ZgSprite.CanvasOrText = .{
            .text = std.mem.span(c_string),
        };
        return .{
            .__v_draw = v_draw_string,
            .__v_update = v_update,
            .bounds = bounds,
            .x = x,
            .y = y,
            .vel = vel,
            .dx = dx,
            .dy = dy,
            .source = source,
            .sound_cue = .{ .empty = {} },
            .width = -1,
            .height = -1,
        };
    }

    pub fn clone(base: ZgSprite) ZgSprite {
        return .{
            .__v_draw = v_draw,
            .__v_update = v_update,
            .bounds = base.bounds,
            .x = base.x,
            .y = base.y,
            .source = base.source,
            .width = base.width,
            .height = base.height,
            .sound_cue = base.sound_cue,
        };
    }

    fn v_draw(self: ZgSprite, zg: *ZigGame) void {
        if (self.state < 0) return; // termination state < 0
        SpriteBase.v_draw(self, zg);
    }

    fn v_draw_string(self: ZgSprite, zg: *ZigGame) void {
        if (self.state < 0) return; // termination state < 0
        ziggame.font.render(
            zg,
            self.text(),
            self.x,
            self.y,
            constant.SMALL_TEXT_SCALE, //TODO: fix magic number
            color.default_text_color,
        ) catch return;
    }

    fn v_update(self: *ZgSprite) void {
        if (self.state < 0) return; // termination state < 0

        if (self.state < 32) {
            self.x += self.dx * self.vel;
            self.y += self.dy * self.vel;
            self.state += 1;
        } else {
            self.state = -1;
        }
    }
};

pub const ScrollingSprite = struct {
    pub fn text(zg: *ZigGame, string: []const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ZgSprite {
        var canvas = try ziggame.font.create_text_canvas(
            zg,
            string,
            constant.MEDIUM_TEXT_SCALE,
            color.default_text_color,
        );
        return .{
            .__v_draw = SpriteBase.v_draw,
            .__v_update = v_update,
            .canvas = canvas,
            .bounds = bounds,
            .x = x,
            .y = y,
            .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = string },
        };
    }

    pub fn text_gradient(zg: *ZigGame, var_string: []const u8, gradient: color.Gradient, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ZgSprite {
        var canvas = try ziggame.font.create_gradient_text_canvas(zg, var_string, constant.MEDIUM_TEXT_SCALE, gradient.start, gradient.end);
        return .{ .__v_draw = SpriteBase.v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{
            .vel = vel,
            .dx = dx,
            .dy = dy,
            .state = 0,
            .string = var_string,
        } };
    }

    pub fn text_dual_gradient(zg: *ZigGame, var_string: []const u8, gradient: color.DualGradient, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ZgSprite {
        var canvas = try ziggame.font.create_dual_gradient_text_canvas(zg, var_string, constant.MEDIUM_TEXT_SCALE, gradient.start.start, gradient.start.end, gradient.end.start, gradient.end.end);
        var source: ZgSprite.CanvasOrText = .{
            .canvas = canvas,
        };
        return .{
            .__v_draw = SpriteBase.v_draw,
            .__v_update = v_update,
            .source = source,
            .bounds = bounds,
            .x = x,
            .y = y,
            .vel = vel,
            .dx = dx,
            .dy = dy,
            .width = canvas.width,
            .height = canvas.height,
            .sound_cue = .{ .empty = {} },
        };
    }

    pub fn clone(base: ZgSprite) ZgSprite {
        return .{
            .__v_draw = ZgSprite.v_draw,
            .__v_update = v_update,
            .source = base.ext,
            .bounds = base.bounds,
            .x = base.x,
            .y = base.y,
            .sound_cue = base.sound_cue,
        };
    }

    fn v_update(self: *ZgSprite) void {
        if (self.state < 0) return; // termination state < 0

        self.x += self.dx * self.vel;
        self.y += self.dy * self.vel;

        var sr = from_sdl_rect(self.position_rect());
        var bounds = from_sdl_rect(self.bounds);

        if ((self.dx < 0) and (sr.left < (bounds.left - self.canvas().width))) {
            sr.left = bounds.right;
        }
        if ((self.dx > 0) and (sr.left > bounds.right)) {
            sr.left = bounds.left - self.canvas().width;
        }
        if ((self.dy < 0) and (sr.top < (bounds.top - self.canvas().height))) {
            sr.top = bounds.bottom;
        }
        if ((self.dy > 0) and (sr.bottom > (bounds.bottom + self.canvas().height))) {
            sr.top = bounds.top;
        }

        self.x = sr.left;
        self.y = sr.top;
    }
};
