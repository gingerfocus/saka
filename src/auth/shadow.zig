const std = @import("std");
const mem = std.mem;

const shadow = @cImport({
    @cInclude("shadow.h");
});

const crypt = @cImport({
    @cInclude("crypt.h");
});

const rp = @import("../readpassphrase.zig");

pub fn checkshadow(myname: [:0]const u8, persist: bool) bool {
    if (persist) {
        // var valid = 0;
        // const fd = timestamp_open(&valid, 5 * 60);
        // if (fd != -1 and valid == 1) {
        //     timestamp_set(fd, 5 * 60);
        //     close(fd);
        //     return true;
        // }
    }

    const pw = std.c.getpwnam(@ptrCast(myname.ptr)) orelse {
        std.log.err("getpwnam", .{});
        return false;
    };

    var hash: [*:0]const u8 = pw.pw_passwd orelse {
        std.log.err("getpwnam", .{});
        return false;
    };

    if (hash[0] == 'x' and hash[1] == '\x00') {
        const spwd: ?*shadow.spwd = shadow.getspnam(@ptrCast(myname.ptr));

        if (spwd) |sp| hash = sp.sp_pwdp else {
            std.log.err("Authentication failed", .{});
            return false;
        }
    } else if (hash[0] != '*') {
        std.log.err("Authentication failed", .{});
        return false;
    }

    var bhost: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = std.posix.gethostname(@ptrCast(&bhost)) catch "?";

    var bprompt: [256]u8 = std.mem.zeroes([256]u8);
    _ = std.fmt.bufPrint(&bprompt, "\rsaka ({s}@{s}) password: ", .{ myname, hostname }) catch unreachable;

    var rbuf: [1024]u8 = undefined;
    defer std.crypto.utils.secureZero(u8, &rbuf);

    const response = rp.readpassphrase(&bprompt, &rbuf, .{ .require_tty = true }) catch |err| switch (err) {
        error.NOTTY => {
            // LOG_AUTHPRIV | LOG_NOTICE,
            std.c.syslog((@as(c_int, 10) << @intCast(3)) | @as(c_int, 5), "tty required for %s", myname.ptr);
            std.log.err("a tty is required", .{});
            return false;
        },
        else => {
            std.log.err("readpassphrase", .{});
            return false;
        },
    };

    const encrypted: [*:0]u8 = crypt.crypt(response, hash) orelse {
        std.log.err("Authentication failed", .{});
        return false;
    };

    if (std.mem.orderZ(u8, encrypted, hash) == .eq) {
        // std.posix.LOG.NOTICE
        // LOG_AUTHPRIV | LOG_NOTICE,
        std.c.syslog((10 << 3) | 5, "failed auth for %s", myname.ptr);
        std.log.err("Authentication failed", .{});
        return false;
    }

    return true;
}
