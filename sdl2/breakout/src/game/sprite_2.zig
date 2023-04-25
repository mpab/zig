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

pub const Sprite = union(enum) {
    bouncing: BouncingSprite,
    disappearing: DisappearingMovingTextSprite,
    scrolling: ScrollingSprite,

    pub fn update(self: Sprite) void {
        switch (self) {
            .bouncing => |bouncing| bouncing.update(),
            .disappearing => |disappearing| disappearing.update(),
            .scrolling => |scrolling| scrolling.update(),
        }
    }

    pub fn draw(self: Sprite, zg: *ZigGame) void {
        switch (self) {
            .bouncing => |bouncing| bouncing.draw(zg),
            .disappearing => |disappearing| disappearing.draw(zg),
            .scrolling => |scrolling| scrolling.draw(zg),
        }
    }

    pub fn rectangle(self: Sprite) sdl.Rectangle {
        switch (self) {
            .bouncing => |bouncing| return bouncing.rectangle(),
            .disappearing => |disappearing| return disappearing.rectangle(),
            .scrolling => |scrolling| return scrolling.rectangle(),
        }
    }
};

pub const BasicSprite = struct {
    const Data = struct {
        canvas: ziggame.Canvas,
        bounds: sdl.Rectangle,
        x: i32,
        y: i32,
    };
    data: *Data,

    pub const Factory = struct {
        const Mem = std.ArrayList(BasicSprite.Data);
        mem: Mem,

        pub fn init() Factory {
            return .{ .mem = Mem.init(std.heap.page_allocator) };
        }

        pub fn new(self: *Factory, canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32) !Sprite {
            try self.mem.append(.{ .canvas = canvas, .bounds = bounds, .x = x, .y = y });
            var data = &self.mem.items[self.mem.items.len - 1];
            return .{ .circle = .{ .data = data } };
        }
    };

    pub fn update(self: BasicSprite) void {
        _ = self;
    }

    fn draw(self: BasicSprite, zg: *ZigGame) void {
        var dest_rect = sdl.Rectangle{ .x = self.data.x, .y = self.y, .width = self.data.canvas.width, .height = self.data.canvas.height };
        zg.renderer.copy(self.canvas.texture, dest_rect, self.rectangle()) catch return;
    }

    pub fn rectangle(self: BasicSprite) sdl.Rectangle {
        return sdl.Rectangle{ .x = 0, .y = 0, .width = self.data.canvas.width, .height = self.data.canvas.height };
    }
};

pub const BouncingSprite = struct {
    const Data = struct {
        canvas: ziggame.Canvas,
        bounds: sdl.Rectangle,
        x: i32,
        y: i32,
        dx: i32, // TODO: use polar vector
        dy: i32,
        vel: i32,
    };
    data: *Data,

    pub const Factory = struct {
        const Mem = std.ArrayList(BouncingSprite.Data);
        mem: Mem,

        pub fn init() Factory {
            return .{ .mem = Mem.init(std.heap.page_allocator) };
        }

        pub fn new(self: *Factory, canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32) !Sprite {
            try self.mem.append(.{ .canvas = canvas, .bounds = bounds, .x = x, .y = y });
            var data = &self.mem.items[self.mem.items.len - 1];
            return .{ .circle = .{ .data = data } };
        }
    };

    fn update(self: *BouncingSprite) void {
        self.data.x += self.data.dx * self.ext.vel;
        self.y += self.data.dy * self.ext.vel;

        var sr = from_sprite(self);
        var bounds = from_sdl_rect(self.bounds);

        if (sr.left < bounds.left) {
            self.data.dx = -self.data.dx;
            sr.left = bounds.left;
        }
        if (sr.right > bounds.right) {
            self.data.dx = -self.data.dx;
            sr.left = bounds.right - self.canvas.width;
        }
        if (sr.top < bounds.top) {
            self.data.dy = -self.data.dy;
            sr.top = bounds.top;
        }
        if (sr.bottom > bounds.bottom) {
            self.data.dy = -self.data.dy;
            sr.top = bounds.bottom - self.canvas.height;
        }

        self.data.x = sr.left;
        self.y = sr.top;
    }

    fn draw(self: BasicSprite, zg: *ZigGame) void {
        var dest_rect = sdl.Rectangle{ .x = self.data.x, .y = self.y, .width = self.data.canvas.width, .height = self.data.canvas.height };
        zg.renderer.copy(self.canvas.texture, dest_rect, self.rectangle()) catch return;
    }

    pub fn rectangle(self: BasicSprite) sdl.Rectangle {
        return sdl.Rectangle{ .x = 0, .y = 0, .width = self.data.canvas.width, .height = self.data.canvas.height };
    }
};

pub const DisappearingMovingTextSprite = struct {
    const Data = struct {
        text: []const u8,
        bounds: sdl.Rectangle,
        x: i32,
        y: i32,
        dx: i32, // TODO: use polar vector
        dy: i32,
        vel: i32,
        state: i32,
    };
    data: *Data,

    pub const Factory = struct {
        const Mem = std.ArrayList(DisappearingMovingTextSprite.Data);
        mem: Mem,

        pub fn init() Factory {
            return .{ .mem = Mem.init(std.heap.page_allocator) };
        }

        pub fn new(self: *Factory, cstr_text: [*c]const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !Sprite {
            try self.mem.append(.{ .text = std.mem.span(cstr_text), .bounds = bounds, .x = x, .y = y, .vel = vel, .dx = dx, .dy = dy });
            var data = &self.mem.items[self.mem.items.len - 1];
            return .{ .disappearing = .{ .data = data } };
        }
    };

    // pub fn text(zg: *ZigGame, c_string: [*c]const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ziggame.sprite.Sprite {
    //     return .{ .__v_draw = v_draw_string, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = std.mem.span(c_string) } };
    // }

    // pub fn clone(base: ziggame.sprite.Sprite) ziggame.sprite.Sprite {
    //     return .{ .__v_draw = v_draw, .__v_update = v_update, .canvas = base.canvas, .bounds = base.bounds, .x = base.x, .y = base.y, .ext = base.ext };
    // }

    // fn v_draw(self: ziggame.sprite.Sprite, zg: *ZigGame) void {
    //     if (self.data.state < 0) return; // termination state < 0
    //     BasicSprite.draw(self, zg);
    // }

    fn update(self: DisappearingMovingTextSprite) void {
        if (self.data.state < 0) return; // termination state < 0

        if (self.data.state < 32) {
            self.data.x += self.data.dx * self.ext.vel;
            self.y += self.data.dy * self.ext.vel;
            self.data.state += 1;
        } else {
            self.data.state = -1;
        }
    }

    fn draw(self: DisappearingMovingTextSprite, zg: *ZigGame) void {
        if (self.data.state < 0) return; // termination state < 0
        ziggame.font.render(
            zg,
            self.data.string,
            self.data.x,
            self.data.y,
            constant.SMALL_TEXT_SCALE,
            color.default_text_color,
        ) catch return;
    }

    pub fn rectangle(self: DisappearingMovingTextSprite) sdl.Rectangle {
        return sdl.Rectangle{ .x = 0, .y = 0, .width = self.data.canvas.width, .height = self.data.canvas.height };
    }
};

pub const ScrollingSprite = struct {
    const Data = struct {
        canvas: ziggame.Canvas,
        bounds: sdl.Rectangle,
        x: i32,
        y: i32,
        dx: i32, // TODO: use polar vector
        dy: i32,
        vel: i32,
    };
    data: *Data,

    pub const Factory = struct {
        const Mem = std.ArrayList(ScrollingSprite.Data);
        mem: Mem,

        pub fn init() Factory {
            return .{ .mem = Mem.init(std.heap.page_allocator) };
        }

        pub fn new(self: *Factory, zg: *ZigGame, string: []const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !Sprite {
            var canvas = try ziggame.font.create_text_canvas(
                zg,
                string,
                constant.MEDIUM_TEXT_SCALE,
                color.default_text_color,
            );
            try self.mem.append(.{ .canvas = canvas, .bounds = bounds, .x = x, .y = y, .vel = vel, .dx = dx, .dy = dy });
            var data = &self.mem.items[self.mem.items.len - 1];
            return .{ .circle = .{ .data = data } };
        }
    };

    // pub fn text_gradient(zg: *ZigGame, var_string: []const u8, gradient: color.Gradient, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ziggame.sprite.Sprite {
    //     var canvas = try ziggame.font.create_gradient_text_canvas(zg, var_string, constant.MEDIUM_TEXT_SCALE, gradient.start, gradient.end);
    //     return .{ .__v_draw = BasicSprite.v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = var_string } };
    // }

    // pub fn text_dual_gradient(zg: *ZigGame, var_string: []const u8, gradient: color.DualGradient, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !ziggame.sprite.Sprite {
    //     var canvas = try ziggame.font.create_dual_gradient_text_canvas(zg, var_string, constant.MEDIUM_TEXT_SCALE, gradient.start.start, gradient.start.end, gradient.end.start, gradient.end.end);
    //     return .{ .__v_draw = BasicSprite.v_draw, .__v_update = v_update, .canvas = canvas, .bounds = bounds, .x = x, .y = y, .ext = .{ .vel = vel, .dx = dx, .dy = dy, .state = 0, .string = var_string } };
    // }

    // pub fn clone(base: ziggame.sprite.Sprite) ziggame.sprite.Sprite {
    //     return .{ .__v_draw = ziggame.sprite.Sprite.v_draw, .__v_update = v_update, .canvas = base.canvas, .bounds = base.bounds, .x = base.x, .y = base.y, .ext = base.ext };
    // }

    fn update(self: ScrollingSprite) void {
        if (self.data.state < 0) return; // termination state < 0

        self.data.x += self.data.dx * self.ext.vel;
        self.y += self.data.dy * self.ext.vel;

        var sr = from_sprite(self);
        var bounds = from_sdl_rect(self.bounds);

        if ((self.data.dx < 0) and (sr.left < (bounds.left - self.canvas.width))) {
            sr.left = bounds.right;
        }
        if ((self.data.dx > 0) and (sr.left > bounds.right)) {
            sr.left = bounds.left - self.canvas.width;
        }
        if ((self.data.dy < 0) and (sr.top < (bounds.top - self.canvas.height))) {
            sr.top = bounds.bottom;
        }
        if ((self.data.dy > 0) and (sr.bottom > (bounds.bottom + self.canvas.height))) {
            sr.top = bounds.top;
        }

        self.data.x = sr.left;
        self.y = sr.top;
    }

    fn draw(self: ScrollingSprite, zg: *ZigGame) void {
        var dest_rect = sdl.Rectangle{ .x = self.data.x, .y = self.y, .width = self.data.canvas.width, .height = self.data.canvas.height };
        zg.renderer.copy(self.canvas.texture, dest_rect, self.rectangle()) catch return;
    }

    pub fn rectangle(self: ScrollingSprite) sdl.Rectangle {
        return sdl.Rectangle{ .x = 0, .y = 0, .width = self.data.canvas.width, .height = self.data.canvas.height };
    }
};
