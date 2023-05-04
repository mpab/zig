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

    var try_vckpg: bool = true;

    // NOTE: this is deliberate, to handle windows + git bash, as path concatenation is broken
    if (exe.target.isWindows()) {
        try_vckpg = false;
        const vcpkg_root = "./vcpkg_installed/x64-windows";
        exe.addIncludePath(vcpkg_root ++ "/include");
        exe.addLibraryPath(vcpkg_root ++ "/lib");
        var source_path = vcpkg_root ++ "/bin";
        var dest_path = "./bin";
        installFiles(b, source_path, dest_path, &.{
            "ogg.dll",
            "SDL2_mixer.dll",
            "SDL2_ttf.dll",
            "SDL2.dll",
            "vorbis.dll",
            "vorbisfile.dll",
        });
    }

    // ...and also here - brew installation of vckpg not detected
    // but ./bootstrap uses vckpg to pull down the files
    if (exe.target.isDarwin()) {
        try_vckpg = false;
        const vcpkg_root = "./vcpkg_installed/x64-osx";
        exe.addIncludePath(vcpkg_root ++ "/include");
        exe.addLibraryPath(vcpkg_root ++ "/lib");
    }

    if (exe.target.isLinux()) {
        try_vckpg = false;
        exe.addIncludePath("/usr/include");
        exe.addLibraryPath("/usr/lib");

        exe.linkSystemLibrary("freetype");
        exe.linkSystemLibrary("ogg");
        exe.linkSystemLibrary("png");
        exe.linkSystemLibrary("vorbis");
        exe.linkSystemLibrary("vorbisenc");
        exe.linkSystemLibrary("vorbisfile");
    }

    if (try_vckpg) {
        exe.addVcpkgPaths(.static) catch @panic("vcpkg not found");
    }

    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_mixer");
    exe.linkSystemLibrary("SDL2_ttf");

    // zig SDL wrapper
    const sdl_wrapper_module = b.createModule(.{
        .source_file = .{ .path = "./deps/SDL.zig/src/wrapper/sdl.zig" },
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

fn installFiles(b: *std.build.Builder, source_path: []const u8, dest_path: []const u8, files: []const []const u8) void {
    for (files) |file| {
        b.installFile(b.pathJoin(&.{ source_path, file }), b.pathJoin(&.{ dest_path, file }));
    }
}
