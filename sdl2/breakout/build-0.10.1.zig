const std = @import("std");

// zig version 0.10.1 build file

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("breakout", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const sdl_native_path = "./3rdparty/SDL2-devel-2.26.5-VC";
    const sdl_native_include_path = sdl_native_path ++ "/include";
    exe.addIncludePath(sdl_native_include_path);
    exe.addLibraryPath(sdl_native_path ++ "/lib/x64");
    b.installBinFile(sdl_native_path ++ "/lib/x64" ++ "/SDL2.dll", "SDL2.dll");
    exe.linkSystemLibrary("sdl2");

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    var sdlwrapperPkg: std.build.Pkg = .{
        .name = "sdl-wrapper",
        .source = .{ .path = "./3rdparty/SDL.zig/src/wrapper/sdl.zig" },
    };

    // zig SDL wrapper
    exe.addPackage(
        sdlwrapperPkg,
    );

    // zig-game library
    exe.addPackage(.{
        .name = "zig-game",
        .source = .{ .path = "./libs/zig_game/src/zig_game.zig" },
        .dependencies = &[_]std.build.Pkg{sdlwrapperPkg},
    });

    // tests
    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);

    exe.linkLibC();
    exe.install();
}
