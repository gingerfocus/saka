const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const saka = b.addExecutable(.{
        .name = "saka",
        // .root_source_file = .{ .path = "src/doas.zig" },
        .target = target,
        .optimize = optimize,
    });

    saka.linkLibC();
    saka.linkSystemLibrary("crypt");
    // redis_server.addIncludeDir("deps/lua/src");
    saka.addCSourceFiles(&.{
        "src/doas.c",
        "include/libopenbsd/errc.c",
        "include/libopenbsd/verrc.c",
    }, &.{
        "-std=c11",
        "-pedantic",
        "-Wall",
        "-W",
        "-Wno-missing-field-initializers",
        "-fno-sanitize=undefined",
        "-Wextra",
        "-Isrc",
        "-Iinclude/libopenbsd",
        "-D__linux__",
        "-D_DEFAULT_SOURCE",
        "-D_GNU_SOURCE",
        //
    });

    const progname = b.addStaticLibrary(.{
        .name = "progname",
        .root_source_file = .{ .path = "src/include/progname.zig" },
        .target = target,
        .optimize = optimize,
    });
    progname.linkLibC();
    saka.linkLibrary(progname);

    const readpassphrase = b.addStaticLibrary(.{
        .name = "readpassphrase",
        .root_source_file = .{ .path = "src/include/readpassphrase.zig" },
        .target = target,
        .optimize = optimize,
    });
    readpassphrase.linkLibC();
    saka.linkLibrary(readpassphrase);

    const strtonum = b.addStaticLibrary(.{
        .name = "strtonum",
        .root_source_file = .{ .path = "src/include/strtonum.zig" },
        .target = target,
        .optimize = optimize,
    });
    strtonum.linkLibC();
    saka.linkLibrary(strtonum);

    const parse = b.addStaticLibrary(.{
        .name = "env",
        .root_source_file = .{ .path = "src/parse.zig" },
        .target = target,
        .optimize = optimize,
    });
    parse.linkLibC();

    const env = b.addStaticLibrary(.{
        .name = "env",
        .root_source_file = .{ .path = "src/env.zig" },
        .target = target,
        .optimize = optimize,
    });
    env.linkLibC();

    const timestamp = b.addStaticLibrary(.{
        .name = "timestamp",
        .root_source_file = .{ .path = "src/timestamp.zig" },
        .target = target,
        .optimize = optimize,
    });
    timestamp.linkLibC();

    const pam = b.addStaticLibrary(.{
        .name = "pam",
        .root_source_file = .{ .path = "src/pam.zig" },
        .target = target,
        .optimize = optimize,
    });
    pam.linkLibC();
    pam.linkSystemLibrary("pam");

    const shadow = b.addStaticLibrary(.{
        .name = "shadow",
        .root_source_file = .{ .path = "src/shadow.zig" },
        .target = target,
        .optimize = optimize,
    });
    shadow.linkLibC();

    saka.linkLibrary(env);
    saka.linkLibrary(parse);
    saka.linkLibrary(timestamp);
    saka.linkLibrary(pam);
    saka.linkLibrary(shadow);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(saka);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(saka);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

pub fn build2(b: *std.build.Builder) void {
    _ = b;
}
