const std = @import("std");
const ziggame = @import("zig_game.zig");
const ZigGame = ziggame.ZigGame;
const sdl = @import("sdl-wrapper"); // configured in build.zig

pub const Sprite = struct {
    // hack for function override
    // TODO: make more idiomatic, or reimplement with a 'property bag' approach using key, value pairs

    pub const CanvasOrText = union(enum) {
        canvas: ziggame.Canvas,
        text: []const u8,
    };

    pub const SoundOrEmpty = union(enum) {
        sound: ziggame.mixer.Sound,
        empty: void,
    };

    const Update = *const fn (base: *Sprite) void;
    const Draw = *const fn (base: Sprite, zg: *ZigGame) void;
    __v_update: Update,
    __v_draw: Draw,

    // attributes
    bounds: sdl.Rectangle,
    x: i32 = 0,
    y: i32 = 0,
    width: i32,
    height: i32,
    vel: i32 = 0,
    dx: i32 = 0,
    dy: i32 = 0,
    state: i32 = 0,

    // replace with k, v dict of types?
    source: CanvasOrText,
    sound_cue: SoundOrEmpty,

    pub fn text(self: Sprite) []const u8 {
        return self.source.text;
    }

    pub fn canvas(self: Sprite) ziggame.Canvas {
        return self.source.canvas;
    }

    pub fn sound(self: Sprite) ziggame.mixer.Sound {
        return self.sound_cue.sound;
    }

    pub fn draw(self: Sprite, zg: *ZigGame) void {
        self.__v_draw(self, zg);
    }

    pub fn update(self: *Sprite) void {
        self.__v_update(self);
    }

    pub fn move_abs(self: *Sprite, x: i32, y: i32) void {
        self.x = x;
        self.y = y;
    }

    pub fn size_rect(self: Sprite) sdl.Rectangle {
        return sdl.Rectangle{
            .x = 0,
            .y = 0,
            .width = self.width,
            .height = self.height,
        };
    }

    pub fn position_rect(self: Sprite) sdl.Rectangle {
        return sdl.Rectangle{
            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = self.height,
        };
    }
};

pub fn rectangle(self: *Sprite) sdl.Rectangle {
    return sdl.Rectangle{ .x = self.x, .y = self.y, .width = self.width, .height = self.height };
}

pub fn collide_rect(s1: *Sprite, s2: *Sprite) bool {
    return rectangle(s1).hasIntersection(rectangle(s2));
}

// uses the visitor pattern to forward calls to implementing classes
pub fn Group(comptime Type: type) type {
    const Context = ZigGame;
    const CollisionResult = struct { collided: bool, index: usize, item: ?*Type };
    return struct {
        const Self = @This();

        pub const CollectionArrayList = std.ArrayList(Type);
        list: CollectionArrayList = CollectionArrayList.init(std.heap.page_allocator),

        pub fn add(self: *Self, item: Type) !usize {
            try self.list.append(item);
            return self.list.items.len - 1;
        }

        pub fn remove(self: *Self, index: usize) Type {
            return self.list.swapRemove(index);
        }

        pub fn update(self: Self) void {
            var idx: usize = 0;
            while (idx != self.list.items.len) : (idx += 1) {
                var s = &self.list.items[idx];
                s.update();
            }
        }

        pub fn draw(self: Self, context: *Context) void {
            for (self.list.items) |item| {
                item.draw(context);
            }
        }

        pub fn rectangle(self: Self, context: *Context) void {
            for (self.list.items) |item| {
                item.draw(context);
            }
        }

        pub fn collision(self: Self, s1: *Type) CollisionResult {
            var idx: usize = 0;
            while (idx != self.list.items.len) : (idx += 1) {
                var s2 = &self.list.items[idx];
                var collided = s1.position_rect().hasIntersection(s2.position_rect());
                if (collided) {
                    return .{ .collided = collided, .index = idx, .item = s2 };
                }
            }
            return .{ .collided = false, .index = 0, .item = null };
        }
    };
}
