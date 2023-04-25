const std = @import("std");
const ziggame = @import("zig_game.zig");
const ZigGame = ziggame.ZigGame;
const sdl = @import("sdl-wrapper"); // configured in build.zig

// pub const ExtendedAttributes = struct {
//     vel: i32,
//     dx: i32,
//     dy: i32,
//     state: i32,
//     string: []const u8,
// };

// pub const Sprite = struct {
//     // hack for function override
//     // TODO: make more idiomatic, or reimplement with a 'property bag' approach using key, value pairs
//     const Update = *const fn (base: *Sprite) void;
//     const Draw = *const fn (base: Sprite, zg: *ZigGame) void;
//     __v_update: Update,
//     __v_draw: Draw,

//     // attributes
//     canvas: ziggame.Canvas,
//     bounds: sdl.Rectangle,
//     x: i32,
//     y: i32,

//     ext: ExtendedAttributes, // replace with k, v dict of types?

//     pub fn draw(self: Sprite, zg: *ZigGame) void {
//         self.__v_draw(self, zg);
//     }

//     pub fn update(self: *Sprite) void {
//         self.__v_update(self);
//     }

//     pub fn move_abs(self: *Sprite, x: i32, y: i32) void {
//         self.x = x;
//         self.y = y;
//     }
// };

// uses the visitor pattern to forward calls to implementing classes
pub fn Group(comptime Type: type) type {
    const Context = ZigGame;
    const CollisionResult = struct { collided: bool, index: usize, item: ?*Type };
    return struct {
        const Self = @This();

        pub const CollectionArrayList = std.ArrayList(Type);
        collection: CollectionArrayList = CollectionArrayList.init(std.heap.page_allocator),

        pub fn add(self: *Self, item: Type) !void {
            try self.collection.append(item);
        }

        pub fn remove(self: *Self, index: usize) Type {
            return self.collection.swapRemove(index);
        }

        pub fn update(self: Self) void {
            for (self.collection.items) |item| {
                item.update();
            }
        }

        pub fn draw(self: Self, context: *Context) void {
            for (self.collection.items) |item| {
                item.draw(context);
            }
        }

        pub fn rectangle(self: Self, context: *Context) void {
            for (self.collection.items) |item| {
                item.draw(context);
            }
        }

        pub fn collision_result(self: Group, s1: *Type) CollisionResult {
            var idx: usize = 0;
            while (idx != self.list.items.len) : (idx += 1) {
                var s2 = &self.list.items[idx];
                var collided = s1.rectangle().hasIntersection(s2.rectangle());
                if (collided) {
                    return .{ .collided = collided, .index = idx, .sprite = s2 };
                }
            }
            return .{ .collided = false, .index = 0, .sprite = null };
        }
    };
}
