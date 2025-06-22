const std = @import("std");

const Auth = enum { none, pam, shadow };
const Secu = enum { none, chroot, chdir };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const saka = b.addExecutable(.{
        .name = "saka",
        .root_source_file = b.path("src/saka.zig"),
        .target = target,
        .optimize = optimize,
    });

    var usepam = false;
    var useshadow = false;

    const auth = b.option(Auth, "auth", "Library to use for authentication") orelse .shadow;
    switch (auth) {
        .pam => {
            usepam = true;
            saka.linkSystemLibrary("pam");
            saka.linkLibC();
        },
        .shadow => {
            useshadow = true;
            saka.linkSystemLibrary("crypt");
            saka.linkLibC();
        },
        .none => {},
    }

    const secu = b.option(Secu, "security", "additional security method to use") orelse .chdir;
    const targetdir = b.option([]const u8, "targetdir", "directory to use chdir/chroot");

    const options = b.addOptions();
    options.addOption(bool, "useshadow", useshadow);
    options.addOption(bool, "usepam", usepam);
    options.addOption(bool, "usechroot", secu == .chroot);
    options.addOption(bool, "usechdir", secu == .chdir);
    if (targetdir) |dir|
        options.addOption([]const u8, "targetdir", dir);

    saka.root_module.addOptions("options", options);

    b.installArtifact(saka);

    // -----------------------------------------------------------------------
    // const sakaRun = b.addRunArtifact(saka);
    // if (b.args) |args| sakaRun.addArgs(args);
    // const run = b.step("run", "run the program");
    // run.dependOn(&sakaRun.step);
    // -----------------------------------------------------------------------

    const sakaTest = b.addTest(.{
        .root_source_file = b.path("src/saka.zig"),
        .target = target,
        .optimize = optimize,
    });
    const sakaRunTest = b.addRunArtifact(sakaTest);
    const tests = b.step("test", "Run unit tests");
    tests.dependOn(&sakaRunTest.step);
}
