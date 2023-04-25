const std = @import("std");
const Context = @import("context.zig").Context;

// uses the visitor pattern to forward shape calls to implementing classes
pub fn Collection(comptime Type: type) type {
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
    };
}
