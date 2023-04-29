const std = @import("std");
const builtin = @import("builtin");
const info = std.log.info;

const build_impl = @import("./build-0.10.1.zig");

// in version 011, Builder is an alias for Build
pub fn build(b: *std.build.Builder) void {
    if (builtin.zig_version.major < 1) {
        if (builtin.zig_version.minor <= 10) {
            info(
                "zig version {} detected\n - using build file: ./build-0.10.1.zig",
                .{builtin.zig_version},
            );
            const v10 = @import("./build-0.10.1.zig");
            v10.build(b);
            return;
        }

        if (builtin.zig_version.minor > 10) {
            info(
                "zig version {} detected\n - using build file: ./build-0.11.0.zig",
                .{builtin.zig_version},
            );
            const v11 = @import("./build-0.11.0.zig");
            v11.build(b);
            return;
        }
    }

    //const target = b.standardTargetOptions(.{});
    info("unhandled zig version: {}", .{builtin.zig_version});
}
