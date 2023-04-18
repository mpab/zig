const std = @import("std");
const gfx = @import("gfx.zig");
const sdl = @import("sdl-wrapper"); // configured in build.zig

pub const ExtendedAttributes = struct {
    vel: i32,
    dx: i32,
    dy: i32,
    state: i32,
    string: [:0]const u8,
};

pub const Sprite = struct {
    // hack for function override
    // TODO: make more idiomatic, or reimplement with a 'property bag' approach using key, value pairs
    const Update = *const fn (base: *Sprite) void;
    const Draw = *const fn (base: Sprite, ctx: *gfx.Context) void;
    __v_update: Update,
    __v_draw: Draw,

    // attributes
    canvas: gfx.Canvas,
    bounds: sdl.Rectangle,
    x: i32,
    y: i32,

    ext: ExtendedAttributes, // replace with k, v dict of types?

    pub fn draw(self: Sprite, ctx: *gfx.Context) void {
        self.__v_draw(self, ctx);
    }

    pub fn update(self: *Sprite) void {
        self.__v_update(self);
    }

    pub fn move_abs(self: *Sprite, x: i32, y: i32) void {
        self.x = x;
        self.y = y;
    }
};

pub fn rectangle(self: *Sprite) sdl.Rectangle {
    return sdl.Rectangle{ .x = self.x, .y = self.y, .width = self.canvas.width, .height = self.canvas.height };
}

pub const CollisionResult = struct { collided: bool, index: usize, sprite: ?*Sprite };

pub fn collide_rect(s1: *Sprite, s2: *Sprite) bool {
    return rectangle(s1).hasIntersection(rectangle(s2));
}

// pub const ListOfSprites = std.ArrayList(Sprite);
// pub const Group = struct {
//     list: ?*ListOfSprites = null,

//     pub fn init() Group {
//         //var list = ListOfSprites.init(std.heap.page_allocator);
//         return Group{ .list = null };
//     }

//     pub fn create(list: ListOfSprites) Group {
//         return Group{ .list = list };
//     }

//     pub fn set(self: *Group, list: *ListOfSprites) void {
//         self.list = list;
//     }

//     pub fn add(self: *Group, s: Sprite) !void {
//         try self.list.?.append(s);
//     }

//     pub fn remove(self: *Group, i: usize) Sprite {
//         return self.list.?.swapRemove(i);
//     }

//     pub fn update(self: *Group) void {
//         if (self.list == null) {
//             return;
//         }
//         for (self.list.?.items, 0..) |_, idx| {
//             var s = &self.list.?.items[idx];
//             s.update();
//         }
//     }

//     pub fn draw(self: Group, ctx: gfx.Context) void {
//         if (self.list == null) {
//             return;
//         }
//         for (self.list.?.items) |s| {
//             s.draw(ctx);
//         }
//     }

//     pub fn collision_result(self: Group, s1: *Sprite) CollisionResult {
//         for (self.list.?.items, 0..) |s2, i| {
//             if (collide_rect(s1, @constCast(&s2))) {
//                 return .{ .collided = true, .index = i, .sprite = @constCast(&s2) };
//             }
//         }
//         return .{ .collided = false, .index = 0, .sprite = null };
//     }
// };

pub const ListOfSprites = std.ArrayList(Sprite);
pub const Group = struct {
    list: ListOfSprites,

    pub fn init() Group {
        return Group{ .list = ListOfSprites.init(std.heap.page_allocator) };
    }

    pub fn add(self: *Group, s: Sprite) !void {
        try self.list.append(s);
    }

    pub fn remove(self: *Group, i: usize) Sprite {
        return self.list.swapRemove(i);
    }

    pub fn update(self: *Group) void {
        var idx: usize = 0;
        while (idx != self.list.items.len) : (idx += 1) {
            var s = &self.list.items[idx];
            s.update();
        }
    }

    pub fn draw(self: Group, ctx: *gfx.Context) void {
        for (self.list.items) |s| {
            s.draw(ctx);
        }
    }

    pub fn collision_result(self: Group, s1: *Sprite) CollisionResult {
        var idx: usize = 0;
        while (idx != self.list.items.len) : (idx += 1) {
            var s2 = &self.list.items[idx];
            if (collide_rect(s1, s2)) {
                return .{ .collided = true, .index = idx, .sprite = s2 };
            }
        }
        return .{ .collided = false, .index = 0, .sprite = null };
    }
};
