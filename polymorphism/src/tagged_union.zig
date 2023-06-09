const std = @import("std");
const dbg = std.log.debug;

const Context = @import("context.zig").Context;

pub const Circle = struct {
    pub const Data = struct {
        x: i32,
        y: i32,
        radius: i32,
        pub fn init(x: i32, y: i32, radius: i32) Data {
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
        pub fn init(x: i32, y: i32, width: i32, height: i32) Data {
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
