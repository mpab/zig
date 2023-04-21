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

    const vcpkg_root = "./vcpkg_installed/x64-windows";
    exe.addIncludePath(vcpkg_root ++ "/include/SDL2");
    exe.addLibraryPath(vcpkg_root ++ "/lib");
    var bin_path = vcpkg_root ++ "/bin";
    installBinFiles(b, bin_path, &.{
        "SDL2.dll",
        "SDL2_mixer.dll",
        "ogg.dll",
        "vorbis.dll",
        "vorbisfile.dll",
    });
    exe.linkSystemLibrary("sdl2");
    exe.linkSystemLibrary("sdl2_mixer");

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    var sdlwrapperPkg: std.build.Pkg = .{
        .name = "sdl-wrapper",
        .source = .{ .path = "./deps/SDL.zig/src/wrapper/sdl.zig" },
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

fn installBinFiles(b: *std.build.Builder, path: []const u8, files: []const []const u8) void {
    for (files) |file| {
        b.installBinFile(b.pathJoin(&.{ path, file }), file);
    }
}
