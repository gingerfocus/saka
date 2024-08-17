const std = @import("std");
const auth = @import("auth");

const mem = std.mem;

const conf = @import("config.zig"){};

pub fn die(ret: u8, org: ?[]const u8, str: []const u8) u8 {
    // if there is a thing
    if (org) |o| std.debug.print("{s}: {s}\n", .{ o, str })
    // not a thing
    else std.debug.print("{s}\n", .{str});

    return ret;
}

// using a global buffer allows for no allocations
var buf: [std.fs.max_path_bytes]u8 = std.mem.zeroes([std.fs.max_path_bytes]u8);

// given a non relative command
pub fn getpath(str: []const u8) ?[]const u8 {
    std.debug.assert(str[0] != '.');
    std.debug.assert(str[0] != '/');

    var buffer: [std.fs.max_path_bytes]u8 = undefined;

    if (std.posix.getenv("PATH")) |path| {
        var start: u12 = 0;
        var end: u12 = 1;
        // var p = path;
        while (end < path.len) : (end += 1) {
            const p = path[end];
            // if we have found a path seperator
            if (p == ':' and path[end - 1] != '\\') {
                // var w = std.io.FixedBufferStream([4096]u8){ .buffer = buffer, .pos = 0 };
                // _ = w; // autofix
                const dir = path[start..end];

                @memcpy(buffer[0..dir.len], dir);
                buffer[dir.len] = '/';
                @memcpy(buffer[dir.len + 1 .. dir.len + 1 + str.len], str);
                buffer[dir.len + 1 + str.len] = 0;

                // std.fmt.format(w.writer(), "{s}/{s}", .{ path[start..end], str }) catch return null;

                var st: std.posix.Stat = undefined;
                if (std.os.linux.lstat(@ptrCast(&buffer), &st) == 0) {
                    return std.posix.realpathZ(@ptrCast(&buffer), &buf) catch return null;
                }

                start = end + 1;
            }
        }
    }

    return null;
}

pub fn main() !u8 {
    const argc = std.os.argv.len;
    const argv = std.os.argv;

    if (argc < 2) return die(1, null, HELP);

    const arg1 = mem.span(argv[1]);
    if (mem.eql(u8, arg1, "-h")) return die(1, null, HELP);

    if (mem.eql(u8, arg1, "-v")) return die(1, null, VERSION);
    if (mem.eql(u8, arg1, "-l")) {
        for (conf.rules) |rule| std.debug.print(
            "{} {} {s} {s}\n",
            .{ rule.uid, rule.gid, rule.cmd, rule.path },
        );
        return 0;
    }

    const uid = std.os.linux.getuid();
    const gid = std.os.linux.getgid();

    inline for (conf.rules) |rule| {
        if (std.mem.eql(u8, rule.cmd, "*") or mem.eql(u8, arg1, rule.cmd)) {
            const cmd: []const u8 =
                // specific recipe
                if (rule.path[0] != '*') rule.path
            // relative or absolute path
            else if ((arg1[0] == '.') or arg1[0] == '/') arg1
            // unqualified file, fetch it from path
            else getpath(arg1) orelse return die(1, "execv", "cannot find program");

            var st = std.mem.zeroes(std.posix.Stat);
            if (std.os.linux.lstat(@ptrCast(cmd.ptr), &st) != 0) return die(1, "lstat", "cannot stat program");
            // if ((st.mode & 0o222) != 0) return die(1, "stat", "cannot run writable binaries.");

            if (((uid != 0) and (rule.uid != -1)) and (rule.uid != uid)) return die(1, "urule", "user does not match");
            if (((gid != 0) and (rule.gid != -1)) and (rule.gid != gid)) return die(1, "grule", "group id does not match");

            try std.posix.setuid(0); // this line fails if not installed properly
            try std.posix.setgid(0);
            try std.posix.seteuid(0);
            try std.posix.setegid(0);

            switch (comptime conf.security) {
                .chroot => |dir| {
                    try std.posix.chdir(dir);
                    try std.os.linux.chroot(@ptrCast(dir.ptr));
                },
                .chdir => |dir| try std.posix.chdir(dir),
                .none => {},
            }

            if (!auth.check("focus", true)) return 1;

            return std.posix.execveZ(
                @ptrCast(cmd.ptr),
                @ptrCast(argv.ptr + 1),
                @ptrCast(std.os.environ.ptr),
            );
        }
    }
    return die(1, null, "Sorry");
}

pub const HELP = "sup [-hlv] [cmd ..]";
pub const VERSION = "sup 0.1 pancake <nopcode.org> copyleft 2011";
pub const GROUP = -@as(c_int, 1);
pub const SETUID = @as(c_int, 0);
pub const SETGID = @as(c_int, 0);
// pub const CHROOT = "";
// pub const CHRDIR = "";
// pub const ENFORCE = @as(c_int, 1);
