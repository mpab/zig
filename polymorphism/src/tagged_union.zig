const std = @import("std");
const dbg = std.log.debug;

pub const Context = struct {
    width: i32,
    height: i32,
    color: i32,
};

pub const Circle = struct {
    pub const Data = struct {
        x: i32,
        y: i32,
        radius: i32,
        pub fn new(x: i32, y: i32, radius: i32) Data {
            return .{ .x = x, .y = y, .radius = radius };
        }
    };
    data: *Data,

    pub fn new(data: *Data) Shape {
        return .{ .circle = .{ .data = data } };
    }

    pub fn update(self: Circle) void {
        self.data.x += 1;
        self.data.y += 1;
        self.data.radius += 1;
    }

    pub fn draw(self: Circle, context: *Context) void {
        std.debug.print("Circle.draw({}) {}, {}, {}\n", .{ context.color, self.data.x, self.data.y, self.data.radius });
    }
};

pub const Rectangle = struct {
    pub const Data = struct {
        x: i32,
        y: i32,
        width: i32,
        height: i32,
        pub fn new(x: i32, y: i32, width: i32, height: i32) Data {
            return .{ .x = x, .y = y, .width = width, .height = height };
        }
    };
    data: *Data,

    pub fn new(data: *Data) Shape {
        return .{ .rectangle = .{ .data = data } };
    }

    pub fn update(self: Rectangle) void {
        self.data.x -= 1;
        self.data.y -= 1;
        self.data.width -= 1;
        self.data.height -= 1;
    }

    pub fn draw(self: Rectangle, context: *Context) void {
        std.debug.print("Rectangle.draw({}) {}, {}, {}, {}\n", .{ context.color, self.data.x, self.data.y, self.data.width, self.data.height });
    }
};

pub const Shape = union(enum) {
    circle: Circle,
    rectangle: Rectangle,

    pub fn update(self: Shape) void {
        switch (self) {
            .circle => |circle| circle.update(),
            .rectangle => |rectangle| rectangle.update(),
        }
    }

    pub fn draw(self: Shape, context: *Context) void {
        switch (self) {
            .circle => |circle| circle.draw(context),
            .rectangle => |rectangle| rectangle.draw(context),
        }
    }
};

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
