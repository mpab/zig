const std = @import("std");

// zig version 0.11.0 build file

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "breakout",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    exe.linkLibC();
    b.installArtifact(exe);

    const sdl_native_path = "./3rdparty/SDL2-devel-2.26.5-VC";
    const sdl_native_include_path = sdl_native_path ++ "/include";
    exe.addIncludePath(sdl_native_include_path);
    exe.addLibraryPath(sdl_native_path ++ "/lib/x64");
    b.installBinFile(sdl_native_path ++ "/lib/x64" ++ "/SDL2.dll", "SDL2.dll");
    exe.linkSystemLibrary("sdl2");

    const sdl_mixer_native_path = "./3rdparty/SDL2_mixer-devel-2.6.3-VC";
    const sdl_mixer_native_include_path = sdl_native_path ++ "/include";
    exe.addIncludePath(sdl_mixer_native_include_path);
    exe.addLibraryPath(sdl_mixer_native_path ++ "/lib/x64");
    b.installBinFile(sdl_mixer_native_path ++ "/lib/x64" ++ "/SDL2_mixer.dll", "SDL2_mixer.dll");
    exe.linkSystemLibrary("sdl2_mixer");

    // zig SDL wrapper
    const sdl_wrapper_module = b.createModule(.{
        .source_file = .{ .path = "./3rdparty/SDL.zig/src/wrapper/sdl.zig" },
        .dependencies = &.{},
    });
    exe.addModule("sdl-wrapper", sdl_wrapper_module);

    // zig-game library
    const zig_game_module = b.createModule(.{
        .source_file = .{ .path = "./libs/zig_game/src/zig_game.zig" },
        .dependencies = &.{
            .{ .name = "sdl-wrapper", .module = sdl_wrapper_module },
        },
    });
    exe.addModule("zig-game", zig_game_module);

    // tests
    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
