const std = @import("std");
const dbg = std.log.debug;

const Context = @import("context.zig").Context;

pub const Circle = struct {
    pub const Data = struct {
        x: i32,
        y: i32,
        radius: i32,
    };
    data: *Data,

    pub const Factory = struct {
        const Mem = std.ArrayList(Circle.Data);
        mem: Mem,

        pub fn init() Factory {
            return .{ .mem = Mem.init(std.heap.page_allocator) };
        }

        pub fn new(self: *Factory, x: i32, y: i32, radius: i32) !Shape {
            try self.mem.append(.{ .x = x, .y = y, .radius = radius });
            var data = &self.mem.items[self.mem.items.len - 1];
            return .{ .circle = .{ .data = data } };
        }
    };

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
    };
    data: *Data,

    pub const Factory = struct {
        const Mem = std.ArrayList(Rectangle.Data);
        mem: Mem,

        pub fn init() Factory {
            return .{ .mem = Mem.init(std.heap.page_allocator) };
        }

        pub fn new(self: *Factory, x: i32, y: i32, width: i32, height: i32) !Shape {
            try self.mem.append(.{ .x = x, .y = y, .width = width, .height = height });
            var data = &self.mem.items[self.mem.items.len - 1];
            return .{ .rectangle = .{ .data = data } };
        }
    };

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
