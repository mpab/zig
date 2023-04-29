const std = @import("std");
const builtin = std.builtin;
const dbg = std.log.debug;

const build_impl = @import("./build-0.10.1.zig");

// in version 011, Builder is an alias for Build
pub fn build(b: *std.build.Builder) void {
    build_impl.build(b);
}
