const std = @import("std");
const ziggame = @import("zig_game.zig");
const ZigGame = ziggame.ZigGame;
const sdl = @import("sdl-wrapper"); // configured in build.zig

// uses the visitor pattern to forward calls to implementing classes
pub fn Group(comptime Type: type) type {
    const Context = ZigGame;
    const CollisionResult = struct { collided: bool, index: usize, item: ?*Type };
    return struct {
        const Self = @This();

        pub const CollectionArrayList = std.ArrayList(Type);
        list: CollectionArrayList = CollectionArrayList.init(std.heap.page_allocator),

        pub fn destroy(self: *Self) void {
            var idx: usize = 0;
            while (idx != self.list.items.len) : (idx += 1) {
                var s = &self.list.items[idx];
                s.destroy();
            }
            self.list.clearAndFree();
        }

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
