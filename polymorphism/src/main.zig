const std = @import("std");
const dbg = std.log.debug;

const tu = @import("tagged_union.zig");

fn draw(shape: tu.Shape) void {
    shape.draw();
}

pub fn main() !void {
    var circle_data = tu.Circle.Data.new(1, 1, 1);
    var rectangle_data = tu.Rectangle.Data.new(-1, -1, -1, -1);

    var collection: tu.Collection(tu.Shape) = .{};
    try collection.add(tu.Circle.new(&circle_data));
    try collection.add(tu.Rectangle.new(&rectangle_data));

    var ctx: tu.Context = .{ .width = 800, .height = 600, .color = 0 };
    collection.draw(&ctx);
    collection.update();
    ctx.color = 1;
    collection.draw(&ctx);
}
