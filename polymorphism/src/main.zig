const std = @import("std");
const dbg = std.log.debug;

const Context = @import("context.zig").Context;
const Collection = @import("collection.zig").Collection;
const tu = @import("tagged_union.zig");
const stu = @import("storage_tagged_union.zig");

pub fn main() !void {
    var ctx: Context = .{ .width = 800, .height = 600, .color = 0 };

    var circle_data = tu.Circle.Data.init(1, 1, 1);
    var rectangle_data = tu.Rectangle.Data.init(-1, -1, -1, -1);

    var tu_shapes: Collection(tu.Shape) = .{};
    try tu_shapes.add(tu.Circle.new(&circle_data));
    try tu_shapes.add(tu.Rectangle.new(&rectangle_data));

    tu_shapes.draw(&ctx);
    tu_shapes.update();
    ctx.color = 1;
    tu_shapes.draw(&ctx);

    var circles = stu.Circle.Factory.init();
    var rectangles = stu.Rectangle.Factory.init();
    var shapes: Collection(stu.Shape) = .{};

    var c = try circles.new(10, 10, 10);
    try shapes.add(c);
    var r = try rectangles.new(-10, -10, -10, -10);
    try shapes.add(r);

    shapes.draw(&ctx);
    shapes.update();
    ctx.color = 0;
    shapes.draw(&ctx);

    _ = shapes.remove(1); // doesn't free object data storage...
    shapes.update();
    shapes.draw(&ctx);
}
