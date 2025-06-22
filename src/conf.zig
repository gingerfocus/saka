const std = @import("std");
const builtin = @import("builtin");

const opt = @import("options");

pub const check: (fn ([:0]const u8, bool) bool) = blk: {
    const checkfn = struct {
        const pam = @import("auth/pam.zig").checkpam;
        const shadow = @import("auth/shadow.zig").checkshadow;
        fn none(_: [:0]const u8, _: bool) bool {
            return true;
        }
    };

    if (opt.usepam)
        break :blk checkfn.pam;

    if (opt.useshadow)
        break :blk checkfn.shadow;

    break :blk checkfn.none;
};

pub const preexec = blk: {
    const preexecfn = struct {
        pub fn chroot() !void {
            try std.posix.chdir(dir);
            try std.os.linux.chroot(@ptrCast(dir.ptr));
        }

        pub fn chdir() !void {
            try std.posix.chdir(dir);
        }

        pub fn none() !void {}
    };

    if (opt.usechroot)
        break :blk preexecfn.chroot;

    if (opt.usechdir)
        break :blk preexecfn.chdir;

    break :blk preexecfn.none;
};

const dir: []const u8 =
    if (@hasField(opt, "targetdir")) @field(opt, "targetdir") else "/tmp";

const Rule = struct {
    uid: i32,
    gid: i32,
    cmd: []const u8,
    path: []const u8,
};

const config = @embedFile("saka.conf");

pub const RULES_COUNT: comptime_int = blk: {
    var count: usize = 0;
    var lines = std.mem.splitScalar(u8, config, '\n');
    while (lines.next()) |line| {
        if (line.len != 0) count += 1;
    }

    break :blk count;
};

pub const rules: [RULES_COUNT]Rule = blk: {
    @setEvalBranchQuota(10000);

    // const cerr = if (@inComptime()) @compileError else std.debug.print;
    const print = std.fmt.comptimePrint;

    var rulebuf: [RULES_COUNT]Rule = undefined;

    var lines = std.mem.splitScalar(u8, config, '\n');
    var i: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var items = std.mem.splitScalar(u8, line, ' ');
        const uidStr = items.next() orelse
            @compileError(print("line ({s}) should be non-empty", .{line}));

        const gidStr = items.next() orelse
            @compileError(print("line {} \"{s}\" is missing a 2nd argument", .{ i + 1, line }));

        const cmdStr = items.next() orelse @panic("");
        const pathStr = items.next() orelse @panic("");

        const uid = std.fmt.parseInt(i32, uidStr, 10) catch @panic("");
        const gid = std.fmt.parseInt(i32, gidStr, 10) catch @panic("");

        rulebuf[i] = .{
            .uid = uid,
            .gid = gid,
            .cmd = cmdStr,
            .path = pathStr,
        };
        i += 1;
    }
    break :blk rulebuf;
};

pub const safepath = if (@hasField(opt, "safepath")) @field(opt, "safepath") else "/bin:/usr/bin";
