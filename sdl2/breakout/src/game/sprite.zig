const std = @import("std");
const dbg = std.log.debug;
const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const shape = @import("shape.zig");
const color = @import("color.zig");
const constant = @import("constant.zig");
const ZgSprite = Sprite;

const BouncingSprite = @import("./sprite/bouncing.zig").BouncingSprite;
const MovingSprite = @import("./sprite/moving.zig").MovingSprite;
const ScrollingSprite = @import("./sprite/scrolling.zig").ScrollingSprite;

// Facade pattern
pub const Sprite = union(enum) { // Facade
    pub const Data = struct { // 'common' data - Adapter
        x: i32 = 0,
        y: i32 = 0,
        width: i32 = 0,
        height: i32 = 0,
        dx: i32 = 0, // TODO: use polar vector
        dy: i32 = 0,
        vel: i32 = 0,
        state: i32 = 0,
    };

    basic: BasicSprite,
    bouncing: BouncingSprite,
    moving: MovingSprite,
    scrolling: ScrollingSprite,

    pub fn destroy(self: *Sprite) void {
        switch (self.*) {
            .basic => |*s| s.destroy(),
            .bouncing => |*s| s.destroy(),
            .moving => |*s| s.destroy(),
            .scrolling => |*s| s.destroy(),
        }
    }

    pub fn get(self: Sprite) Data {
        var d: Data = .{};
        switch (self) {
            .basic => |s| {
                d.x = s.x;
                d.y = s.y;
                d.width = s.width;
                d.height = s.height;
                d.state = s.state;
            },
            .bouncing => |s| {
                d.x = s.x;
                d.y = s.y;
                d.width = s.width;
                d.height = s.height;
                d.dx = s.dx;
                d.dy = s.dy;
                d.vel = s.vel;
                d.state = s.state;
            },
            .moving => |s| {
                d.x = s.x;
                d.y = s.y;
                d.width = s.width;
                d.height = s.height;
                d.dx = s.dx;
                d.dy = s.dy;
                d.vel = s.vel;
                d.state = s.state;
            },
            .scrolling => |s| {
                d.x = s.x;
                d.y = s.y;
                d.width = s.width;
                d.height = s.height;
                d.dx = s.dx;
                d.dy = s.dy;
                d.vel = s.vel;
                d.state = s.state;
            },
        }
        return d;
    }

    pub fn set(self: *Sprite, d: Data) void {
        switch (self.*) {
            .basic => |*s| {
                s.x = d.x;
                s.y = d.y;
                s.width = d.width;
                s.height = d.height;
                s.state = d.state;
            },
            .bouncing => |*s| {
                s.x = d.x;
                s.y = d.y;
                s.width = d.width;
                s.height = d.height;
                s.dx = d.dx;
                s.dy = d.dy;
                s.vel = d.vel;
                s.state = d.state;
            },
            .moving => |*s| {
                s.x = d.x;
                s.y = d.y;
                s.width = d.width;
                s.height = d.height;
                s.dx = d.dx;
                s.dy = d.dy;
                s.vel = d.vel;
                s.state = d.state;
            },
            .scrolling => |*s| {
                s.x = d.x;
                s.y = d.y;
                s.width = d.width;
                s.height = d.height;
                s.dx = d.dx;
                s.dy = d.dy;
                s.vel = d.vel;
                s.state = d.state;
            },
        }
    }

    pub fn canvas(self: Sprite) ziggame.Canvas {
        switch (self) {
            .basic => |s| return s.canvas,
            .bouncing => |s| return s.canvas,
            .moving => |s| return s.canvas,
            .scrolling => |s| return s.canvas,
        }
    }

    pub fn update(self: *Sprite) void {
        switch (self.*) {
            .basic => |*s| s.update(),
            .bouncing => |*s| s.update(),
            .moving => |*s| s.update(),
            .scrolling => |*s| s.update(),
        }
    }

    pub fn draw(self: Sprite, zg: *ZigGame) void {
        switch (self) {
            .basic => |s| s.draw(zg),
            .bouncing => |s| s.draw(zg),
            .moving => |s| s.draw(zg),
            .scrolling => |s| s.draw(zg),
        }
    }

    pub fn size_rect(self: Sprite) sdl.Rectangle {
        switch (self) {
            .basic => |s| return s.size_rect(),
            .bouncing => |s| return s.size_rect(),
            .moving => |s| return s.size_rect(),
            .scrolling => |s| return s.size_rect(),
        }
    }

    pub fn position_rect(self: Sprite) sdl.Rectangle {
        switch (self) {
            .basic => |s| return s.position_rect(),
            .bouncing => |s| return s.position_rect(),
            .moving => |s| return s.position_rect(),
            .scrolling => |s| return s.position_rect(),
        }
    }
};

const BasicSprite = struct {
    const Self = BasicSprite;
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    canvas: ziggame.Canvas,
    state: i32 = 0,

    fn destroy(self: *Self) void {
        self.canvas.texture.destroy();
    }

    fn update(self: *Self) void {
        _ = self;
    }

    fn draw(self: Self, zg: *ZigGame) void {
        if (self.state < 0) return; // termination state < 0
        zg.renderer.copy(self.canvas.texture, self.position_rect(), self.size_rect()) catch return;
    }

    pub fn size_rect(self: Self) sdl.Rectangle {
        return sdl.Rectangle{
            .x = 0,
            .y = 0,
            .width = self.width,
            .height = self.height,
        };
    }

    pub fn position_rect(self: Self) sdl.Rectangle {
        return sdl.Rectangle{
            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = self.height,
        };
    }
};

pub const Factory = struct {
    pub const Type = ZgSprite;

    pub fn new(canvas: ziggame.Canvas, x: i32, y: i32) ZgSprite {
        return .{ .basic = .{
            .x = x,
            .y = y,
            .width = canvas.width,
            .height = canvas.height,
            .canvas = canvas,
        } };
    }

    pub const Bouncing = struct {
        pub fn new(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32, sound: ziggame.mixer.Sound) ZgSprite {
            return .{ .bouncing = .{
                .x = x,
                .y = y,
                .vel = vel,
                .dx = dx,
                .dy = dy,
                .width = canvas.width,
                .height = canvas.height,
                .canvas = canvas,
                .sound = sound,
                .bounds = bounds,
            } };
        }
    };

    pub const Moving = struct {
        pub fn text(zg: *ZigGame, string: [*c]const u8, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ZgSprite {
            var canvas = try ziggame.font.create_text_canvas(
                zg,
                std.mem.span(string),
                constant.SMALL_TEXT_SCALE, // TODO: pass as a parameter
                color.default_text_color,
            );
            return .{ .moving = .{
                .x = x,
                .y = y,
                .vel = vel,
                .dx = dx,
                .dy = dy,
                .canvas = canvas,
                .width = canvas.width,
                .height = canvas.height,
            } };
        }

        pub fn copy(s: *ZgSprite) ZgSprite {
            var d = s.get();
            var n: ZgSprite =
                .{ .moving = .{
                .x = d.x,
                .y = d.y,
                .vel = d.vel,
                .dx = d.dx,
                .dy = d.dy,
                .canvas = s.canvas(),
                .width = d.width,
                .height = d.height,
            } };
            return n;
        }
    };

    pub const Scrolling = struct {
        pub fn text(zg: *ZigGame, string: []const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ZgSprite {
            var canvas = try ziggame.font.create_text_canvas(
                zg,
                string,
                constant.MEDIUM_TEXT_SCALE,
                color.default_text_color,
            );
            return .{
                .canvas = canvas,
                .bounds = bounds,
                .x = x,
                .y = y,
                .vel = vel,
                .dx = dx,
                .dy = dy,
                .state = 0,
            };
        }

        pub fn text_gradient(zg: *ZigGame, string: []const u8, gradient: color.Gradient, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ZgSprite {
            var canvas = try ziggame.font.create_gradient_text_canvas(
                zg,
                string,
                constant.MEDIUM_TEXT_SCALE,
                gradient.start,
                gradient.end,
            );
            return .{
                .bounds = bounds,
                .x = x,
                .y = y,
                .vel = vel,
                .dx = dx,
                .dy = dy,
                .width = canvas.width,
                .height = canvas.height,
                .canvas = canvas,
            };
        }

        pub fn text_dual_gradient(zg: *ZigGame, string: []const u8, gradient: color.DualGradient, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ZgSprite {
            var canvas = try ziggame.font.create_dual_gradient_text_canvas(
                zg,
                string,
                constant.MEDIUM_TEXT_SCALE,
                gradient.start.start,
                gradient.start.end,
                gradient.end.start,
                gradient.end.end,
            );
            return .{ .scrolling = .{
                .bounds = bounds,
                .x = x,
                .y = y,
                .vel = vel,
                .dx = dx,
                .dy = dy,
                .canvas = canvas,
                .width = canvas.width,
                .height = canvas.height,
            } };
        }
    };
};
