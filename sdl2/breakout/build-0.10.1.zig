const std = @import("std");
const info = std.log.info;

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
    exe.linkLibC();
    exe.install();

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

    // ...and also here - installation of vckpg not detected
    // bootstrap uses vckpg to pull down the files
    if (exe.target.isDarwin()) {
        try_vckpg = false;
        const vcpkg_root = "./vcpkg_installed/x64-osx";
        exe.addIncludePath(vcpkg_root ++ "/include");
        exe.addLibraryPath(vcpkg_root ++ "/lib");
    }

    // if (exe.target.isLinux()) {
    //     try_vckpg = false;
    //     exe.addIncludePath("/usr/include");
    //     exe.addLibraryPath("/usr/lib");

    //     exe.linkSystemLibrary("freetype");
    //     exe.linkSystemLibrary("ogg");
    //     exe.linkSystemLibrary("png");
    //     exe.linkSystemLibrary("vorbis");
    //     exe.linkSystemLibrary("vorbisenc");
    //     exe.linkSystemLibrary("vorbisfile");
    // }

    // ...and also here - installation of vckpg not detected
    // bootstrap uses vckpg to pull down the files
    if (exe.target.isLinux()) {
        try_vckpg = false;
        const vcpkg_root = "./vcpkg_installed/x64-linux";
        exe.addIncludePath(vcpkg_root ++ "/include");
        exe.addLibraryPath(vcpkg_root ++ "/lib");
        exe.linkSystemLibrary("brotlicommon-static");
        exe.linkSystemLibrary("brotlidec-static");
        exe.linkSystemLibrary("brotlienc-static");
        exe.linkSystemLibrary("bz2");
        exe.linkSystemLibrary("freetype");
        exe.linkSystemLibrary("ogg");
        exe.linkSystemLibrary("png");
        exe.linkSystemLibrary("vorbis");
        exe.linkSystemLibrary("vorbisenc");
        exe.linkSystemLibrary("vorbisfile");
        exe.linkSystemLibrary("z");
    }

    if (try_vckpg) {
        exe.addVcpkgPaths(.static) catch @panic("vcpkg not found");
    }

    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_mixer");
    exe.linkSystemLibrary("SDL2_ttf");

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
}

fn installFiles(b: *std.build.Builder, source_path: []const u8, dest_path: []const u8, files: []const []const u8) void {
    for (files) |file| {
        b.installFile(b.pathJoin(&.{ source_path, file }), b.pathJoin(&.{ dest_path, file }));
    }
}
