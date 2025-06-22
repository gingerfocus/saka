const std = @import("std");
const mem = std.mem;

const conf = @import("conf.zig");

pub fn die(ret: u8, org: ?[]const u8, str: []const u8) u8 {
    if (org) |o| std.debug.print("{s}: ", .{o});

    std.debug.print("{s}\n", .{str});

    return ret;
}

// using a global buffer allows for no allocations
var buf: [std.fs.max_path_bytes]u8 = std.mem.zeroes([std.fs.max_path_bytes]u8);

// given a non relative command
pub fn getpath(path: [:0]const u8, name: []const u8) ?[]const u8 {
    std.debug.assert(name[0] != '.');
    std.debug.assert(name[0] != '/');

    var buffer: [std.fs.max_path_bytes]u8 = undefined;

    var start: u12 = 0;
    var end: u12 = 1;
    while (end <= path.len) : (end += 1) {
        const p = path[end];
        // if we have found a path seperator     OR its the end of the string
        if ((p == ':' and path[end - 1] != '\\') or end == path.len) {
            // var w = std.io.FixedBufferStream([4096]u8){ .buffer = buffer, .pos = 0 };
            const dir = path[start..end];

            @memcpy(buffer[0..dir.len], dir);
            buffer[dir.len] = '/';
            @memcpy(buffer[dir.len + 1 .. dir.len + 1 + name.len], name);
            buffer[dir.len + 1 + name.len] = 0;

            // std.fmt.format(w.writer(), "{s}/{s}", .{ path[start..end], str }) catch return null;
            // std.log.info("check: {s}", .{buffer});

            var st: std.posix.Stat = undefined;
            if (std.os.linux.lstat(@ptrCast(&buffer), &st) == 0) {
                return std.posix.realpathZ(@ptrCast(&buffer), &buf) catch return null;
            }

            start = end + 1;
        }
    }

    return null;
}

pub const HELP = "saka [-hlv] [cmd ..]";
pub const VERSION = "saka 0.1 gingerfocus <gingerfocus.dev> copyleft 2024";

pub fn main() !u8 {
    const argc = std.os.argv.len;
    const argv = std.os.argv;

    if (argc < 2) return die(1, null, HELP);

    const arg1 = mem.span(argv[1]);
    if (mem.eql(u8, arg1, "-h")) return die(0, null, HELP);
    if (mem.eql(u8, arg1, "-v")) return die(0, null, VERSION);
    if (mem.eql(u8, arg1, "-l")) {
        for (conf.rules) |rule| std.debug.print(
            "{} {} {s} {s}\n",
            .{ rule.uid, rule.gid, rule.cmd, rule.path },
        );
        return 0;
    }

    const path: [:0]const u8 = std.posix.getenv("PATH") orelse conf.safepath;

    const uid = std.os.linux.getuid();
    const gid = std.os.linux.getgid();

    for (conf.rules) |rule| {
        if (mem.eql(u8, rule.cmd, "*") or mem.eql(u8, arg1, rule.cmd)) {
            const cmd: []const u8 =
                // specific recipe
                if (rule.path[0] != '*') rule.path
            // relative or absolute path
            else if ((arg1[0] == '.') or arg1[0] == '/') arg1
            // unqualified file, fetch it from path
            else getpath(path, arg1) orelse return die(1, "execv", "cannot find program");

            // std.debug.print("path: {s}\n", .{cmd});

            var st = mem.zeroes(std.posix.Stat);
            if (std.os.linux.lstat(@ptrCast(cmd.ptr), &st) != 0)
                return die(1, "lstat", "cannot stat program");

            if ((st.mode & 0o222) != 0)
                return die(1, "stat", "cannot run writable binaries.");

            if (((uid != 0) and (rule.uid != -1)) and (rule.uid != uid)) return die(1, "urule", "user does not match");
            if (((gid != 0) and (rule.gid != -1)) and (rule.gid != gid)) return die(1, "grule", "group id does not match");

            // try std.posix.setuid(0); // On Error: install the program as root
            // try std.posix.setgid(0);
            // try std.posix.seteuid(0);
            // try std.posix.setegid(0);

            if (!conf.check("focus", true)) return 1;

            try @call(.always_inline, conf.preexec, .{});
            // try conf.preexec();

            return std.posix.execveZ(
                @ptrCast(cmd.ptr),
                @ptrCast(argv.ptr + 1),
                @ptrCast(std.os.environ.ptr),
            );
        }
    }
    return die(1, null, "Sorry");
}

test "find basic things" {
    const PATH: [:0]const u8 = "/bin:/usr/bin";

    const expect = struct {
        fn path(comptime inpath: []const u8, searchname: []const u8) !void {
            const a = std.testing.allocator;
            const output = try std.process.Child.run(.{
                .allocator = a,
                .argv = &.{ "realpath", inpath },
            });
            defer a.free(output.stdout);
            defer a.free(output.stderr);

            const opath = std.mem.trim(u8, output.stdout, "\n");
            const ipath = getpath(PATH, searchname);

            if (ipath) |iipath| {
                try std.testing.expectEqualSlices(u8, opath, iipath);
            } else {
                std.debug.print("expected output but path was null", .{});
                return error.TestExpectPath;
            }
        }
    };

    // This test assumes that /bin/sh and /usr/bin/env exists on every system
    try expect.path("/bin/sh", "sh");
    try expect.path("/usr/bin/env", "env");

    try std.testing.expectEqual(getpath(PATH, "not-a-real-thing"), null);
}
