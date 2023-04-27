const std = @import("std");
const dbg = std.log.debug;
const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const shape = @import("shape.zig");
const color = @import("color.zig");
const constant = @import("constant.zig");
const mixer = @import("mixer.zig");

pub fn from_sdl_rect(r: sdl.Rectangle) ziggame.Rect {
    return .{ .left = r.x, .top = r.y, .right = r.x + r.width, .bottom = r.y + r.height };
}

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

    basic: BasicSprite,
    bouncing: BouncingSprite,
    disappearing: DisappearingMovingTextSprite,
    scrolling: ScrollingSprite,

    pub fn data(self: Sprite) *Data {
        switch (self) {
            .basic => |basic| return &basic.data.sdata,
            .bouncing => |bouncing| return &bouncing.data.sdata,
            .disappearing => |disappearing| return &disappearing.data.sdata,
            .scrolling => |scrolling| return &scrolling.data.sdata,
        }
    }

    pub fn update(self: Sprite) void {
        switch (self) {
            .basic => |basic| basic.update(),
            .bouncing => |bouncing| bouncing.update(),
            .disappearing => |disappearing| disappearing.update(),
            .scrolling => |scrolling| scrolling.update(),
        }
    }

    pub fn draw(self: Sprite, zg: *ZigGame) void {
        switch (self) {
            .basic => |basic| basic.draw(zg),
            .bouncing => |bouncing| bouncing.draw(zg),
            .disappearing => |disappearing| disappearing.draw(zg),
            .scrolling => |scrolling| scrolling.draw(zg),
        }
    }

    pub fn size_rect(self: Sprite) sdl.Rectangle {
        switch (self) {
            .basic => |basic| return basic.size_rect(),
            .bouncing => |bouncing| return bouncing.size_rect(),
            .disappearing => |disappearing| return disappearing.size_rect(),
            .scrolling => |scrolling| return scrolling.size_rect(),
        }
    }

    pub fn position_rect(self: Sprite) sdl.Rectangle {
        switch (self) {
            .basic => |basic| return basic.position_rect(),
            .bouncing => |bouncing| return bouncing.position_rect(),
            .disappearing => |disappearing| return disappearing.position_rect(),
            .scrolling => |scrolling| return scrolling.position_rect(),
        }
    }
};

pub const BasicSprite = struct {
    const Self = BasicSprite;

    const Data = struct {
        sdata: Sprite.Data,
        canvas: ziggame.Canvas,
    };
    data: *Data,
    handle: usize,

    // ArrayList moves data around in memory, invalidating pointers
    // which means that I have to use handles
    // This is arguably a flyweight pattern
    pub const Factory = struct {
        const Mem = std.ArrayList(Self.Data);
        mem: Mem = Mem.init(std.heap.page_allocator),

        pub fn store(self: *Factory, canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32) !usize {
            var sdata = .{ .bounds = bounds, .x = x, .y = y, .width = canvas.width, .height = canvas.height };
            var data = .{ .canvas = canvas, .sdata = sdata };
            try self.mem.append(data);
            return self.mem.items.len - 1;
        }

        pub fn inflate(self: *Factory, handle: usize) !Sprite {
            var data = &self.mem.items[handle];
            return .{ .basic = .{ .handle = handle, .data = data } };
        }
    };

    // pub fn init(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32) Sprite {
    //     var sdata = .{ .bounds = bounds, .x = x, .y = y, .width = canvas.width, .height = canvas.height };
    //     var data: Data = .{ .canvas = canvas, .sdata = sdata };
    //     return .{ .basic = .{ .data = data } };
    // }

    pub fn update(self: Self) void {
        _ = self;
    }

    fn draw(self: Self, zg: *ZigGame) void {
        zg.renderer.copy(self.data.canvas.texture, self.position_rect(), self.size_rect()) catch return;
    }

    pub fn size_rect(self: Self) sdl.Rectangle {
        var sd = self.data.sdata;
        return sdl.Rectangle{ .x = 0, .y = 0, .width = sd.width, .height = sd.height };
    }

    pub fn position_rect(self: Self) sdl.Rectangle {
        var sd = self.data.sdata;
        return sdl.Rectangle{ .x = sd.x, .y = sd.y, .width = sd.width, .height = sd.height };
    }
};

pub const BouncingSprite = struct {
    const Self = BouncingSprite;

    const Data = struct {
        sdata: Sprite.Data,
        canvas: ziggame.Canvas,
        sound: mixer.Sound,
    };
    data: *Data,
    handle: usize,

    pub const Factory = struct {
        const Mem = std.ArrayList(Self.Data);
        mem: Mem = Mem.init(std.heap.page_allocator),

        pub fn store(self: *Factory, canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32, dx: i32, dy: i32, vel: i32, sound: mixer.Sound) !usize {
            var data = Self.make_data(canvas, bounds, x, y, dx, dy, vel, sound);
            try self.mem.append(data);
            return self.mem.items.len - 1;
        }

        pub fn inflate(self: *Factory, handle: usize) !Sprite {
            var data = &self.mem.items[handle];
            return .{ .bouncing = .{ .handle = handle, .data = data } };
        }
    };

    pub fn make_data(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32, dx: i32, dy: i32, vel: i32, sound: mixer.Sound) Data {
        var sdata = .{ .bounds = bounds, .x = x, .y = y, .width = canvas.width, .height = canvas.height, .dx = dx, .dy = dy, .vel = vel };
        return .{ .canvas = canvas, .sound = sound, .sdata = sdata };
    }

    pub fn init(data: *Data) Sprite {
        return .{ .bouncing = .{ .handle = 0, .data = data } };
    }

    // pub fn init(canvas: ziggame.Canvas, bounds: sdl.Rectangle, x: i32, y: i32, dx: i32, dy: i32, vel: i32, sound: mixer.Sound) Sprite {
    //     var sdata = .{ .bounds = bounds, .x = x, .y = y, .width = canvas.width, .height = canvas.height, .dx = dx, .dy = dy, .vel = vel };
    //     var data: Data = .{ .canvas = canvas, .sound = sound, .sdata = sdata };
    //     return .{ .bouncing = .{ .data = data } };
    // }

    // TODO: use .data.state for enabling/disabling update
    fn update(self: Self) void {
        var sd = &self.data.sdata;
        var sound = &self.data.sound;

        sd.x += sd.dx * sd.vel;
        sd.y += sd.dy * sd.vel;

        var sr = from_sdl_rect(self.position_rect());
        var bounds = from_sdl_rect(sd.bounds);

        if (sr.left < bounds.left) {
            sd.dx = -sd.dx;
            sr.left = bounds.left;
            sound.play();
        }
        if (sr.right > bounds.right) {
            sd.dx = -sd.dx;
            sr.left = bounds.right - sd.width;
            sound.play();
        }
        if (sr.top < bounds.top) {
            sd.dy = -sd.dy;
            sr.top = bounds.top;
            sound.play();
        }
        if (sr.bottom > bounds.bottom) {
            sd.dy = -sd.dy;
            sr.top = bounds.bottom - sd.height;
            sound.play();
        }

        sd.x = sr.left;
        sd.y = sr.top;
    }

    fn draw(self: Self, zg: *ZigGame) void {
        zg.renderer.copy(self.data.canvas.texture, self.position_rect(), self.size_rect()) catch return;
    }

    pub fn size_rect(self: Self) sdl.Rectangle {
        var sd = &self.data.sdata;
        return sdl.Rectangle{ .x = 0, .y = 0, .width = sd.width, .height = sd.height };
    }

    pub fn position_rect(self: Self) sdl.Rectangle {
        var sd = &self.data.sdata;
        return sdl.Rectangle{ .x = sd.x, .y = sd.y, .width = sd.width, .height = sd.height };
    }
};

pub const DisappearingMovingTextSprite = struct {
    const Self = DisappearingMovingTextSprite;

    const Data = struct {
        sdata: Sprite.Data,
        text: []const u8,
        state: i32,
    };
    data: *Data,
    handle: usize,

    pub const Factory = struct {
        const Mem = std.ArrayList(Self.MemItem);
        mem: Mem = Mem.init(std.heap.page_allocator),

        pub fn new(self: *Factory, cstr_text: [*c]const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !Sprite {
            var data = .{ .bounds = bounds, .x = x, .y = y, .width = 0, .height = 0, .dx = dx, .dy = dy, .vel = vel };
            var ext = .{ .text = std.mem.span(cstr_text), .state = 64 };
            try self.mem.append(.{ .data = data, .ext = ext });
            var item = &self.mem.items[self.mem.items.len - 1];
            return .{ .disappearing = .{ .data = &item.data, .ext = &item.ext } };
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

    fn update(self: Self) void {
        var state = self.data.state;
        if (state < 0) return; // termination state < 0

        var sd = self.data.sdata;
        if (state < 32) {
            sd.x += sd.dx * sd.vel;
            sd.y += sd.dy * sd.vel;
            state += 1;
        } else {
            state = -1;
        }
    }

    fn draw(self: Self, zg: *ZigGame) void {
        var state = self.data.state;
        if (state < 0) return; // termination state < 0
        var sd = self.data.sdata;
        ziggame.font.render(
            zg,
            self.data.text,
            sd.x,
            sd.y,
            constant.SMALL_TEXT_SCALE,
            color.default_text_color,
        ) catch return;
    }

    pub fn size_rect(self: Self) sdl.Rectangle {
        var sd = &self.data.sdata;
        return sdl.Rectangle{ .x = 0, .y = 0, .width = sd.width, .height = sd.height };
    }

    pub fn position_rect(self: Self) sdl.Rectangle {
        var sd = &self.data.sdata;
        return sdl.Rectangle{ .x = sd.x, .y = sd.y, .width = sd.width, .height = sd.height };
    }
};

pub const ScrollingSprite = struct {
    const Self = ScrollingSprite;

    const Data = struct {
        sdata: Sprite.Data,
        canvas: ziggame.Canvas,
        state: i32 = 0,
    };
    data: *Data,
    handle: usize,

    pub const Factory = struct {
        const Mem = std.ArrayList(Self.MemItem);
        mem: Mem = Mem.init(std.heap.page_allocator),

        pub fn new(self: *Factory, zg: *ZigGame, string: []const u8, bounds: sdl.Rectangle, x: i32, y: i32, vel: i32, dx: i32, dy: i32) !Sprite {
            var data = .{ .bounds = bounds, .x = x, .y = y, .width = 0, .height = 0 };

            var canvas = try ziggame.font.create_text_canvas(
                zg,
                string,
                constant.MEDIUM_TEXT_SCALE,
                color.default_text_color,
            );
            var ext = .{ .canvas = canvas, .dx = dx, .dy = dy, .vel = vel };

            try self.mem.append(.{ .data = data, .ext = ext });
            var item = &self.mem.items[self.mem.items.len - 1];
            return .{ .scrolling = .{ .data = &item.data, .ext = &item.ext } };
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

    fn update(self: Self) void {
        var state = self.data.state;

        if (state < 0) return; // termination state < 0
        var sd = self.data.sdata;

        sd.x += sd.dx * sd.vel;
        sd.y += sd.dy * sd.vel;

        var sr = from_sdl_rect(self.position_rect());
        var bounds = from_sdl_rect(sd.bounds);

        if ((sd.dx < 0) and (sr.left < (bounds.left - sd.width))) {
            sr.left = bounds.right;
        }
        if ((sd.dx > 0) and (sr.left > bounds.right)) {
            sr.left = bounds.left - sd.width;
        }
        if ((sd.dy < 0) and (sr.top < (bounds.top - sd.height))) {
            sr.top = bounds.bottom;
        }
        if ((sd.dy > 0) and (sr.bottom > (bounds.bottom + sd.height))) {
            sr.top = bounds.top;
        }

        sd.x = sr.left;
        sd.y = sr.top;
    }

    fn draw(self: Self, zg: *ZigGame) void {
        zg.renderer.copy(self.data.canvas.texture, self.position_rect(), self.size_rect()) catch return;
    }

    pub fn size_rect(self: Self) sdl.Rectangle {
        var sd = &self.data.sdata;
        return sdl.Rectangle{ .x = 0, .y = 0, .width = sd.width, .height = sd.height };
    }

    pub fn position_rect(self: Self) sdl.Rectangle {
        var sd = &self.data.sdata;
        return sdl.Rectangle{ .x = sd.x, .y = sd.y, .width = sd.width, .height = sd.height };
    }
};
