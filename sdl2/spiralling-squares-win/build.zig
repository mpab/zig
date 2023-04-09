const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "spiralling-squares",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const sdl_path = "C:/dev/sdl/SDL2-devel-2.26.4-VC";
    exe.addIncludePath(sdl_path ++ "/include");
    exe.addLibraryPath(sdl_path ++ "/lib/x64");
    b.installBinFile(sdl_path ++ "/lib/x64" ++ "/SDL2.dll", "SDL2.dll");
    exe.linkSystemLibrary("sdl2");
    exe.linkLibC();
    exe.install();
}
