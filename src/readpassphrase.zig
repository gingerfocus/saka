// $OpenBSD: readpassphrase.c,v 1.26 2016/10/18 12:47:18 millert Exp $
//
// Copyright (c) 2000-2002, 2007, 2010
//   Todd C. Miller <Todd.Miller@courtesan.com>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
// Sponsored in part by the Defense Advanced Research Projects
// Agency (DARPA) and Air Force Research Laboratory, Air Force
// Materiel Command, USAF, under agreement number F39502-99-1-0512.

const std = @import("std");

const posix = std.posix;
const SIG = posix.SIG;

const Flags = packed struct {
    // echo_on: bool = false,
    // echo_off: bool = false,
    /// also useful when not the foreground process on the terminal
    stdin: bool = false,
    require_tty: bool = false,
    echo_on: bool = false,
    sevenbit: bool = false,
    forcelower: bool = false,
    forceupper: bool = false,
};

pub fn readpassphrase(prompt: []const u8, buf: []u8, flags: Flags) ![:0]u8 {
    // catch any error and return it later after cleanup
    var err: ?anyerror = null;
    var p: usize = 0;

    // I suppose we could alloc on demand in this case (XXX).
    if (buf.len == 0)
        return error.EINVAL;

    // Read and write to /dev/tty if available.  If not, read from
    // stdin and write to stderr unless a tty is required.
    var hastty = false;
    const fd = blk: {
        if (!flags.stdin) if (posix.open("/dev/tty", .{ .ACCMODE = .RDWR }, 0)) |fd| {
            hastty = true;
            break :blk fd;
        } else |e| e catch {};

        if (flags.require_tty)
            return error.NOTTY;

        hastty = false;
        break :blk posix.STDIN_FILENO;
    };

    defer if (hastty) posix.close(fd);

    // undefined when hastty is false
    var oterm: posix.termios = undefined;

    // Turn off echo if possible.
    // If we are using a tty but are not the foreground pgrp this will
    // generate SIGTTOU, so do it *before* installing the signal handlers.
    if (hastty) {
        oterm = try posix.tcgetattr(fd);
        var term = oterm;
        if (!flags.echo_on) {
            term.lflag.ECHO = false;
            term.lflag.ECHONL = false;
        }
        // #ifdef VSTATUS
        // 		if (term.c_cc[VSTATUS] != _POSIX_VDISABLE)
        // 			term.c_cc[VSTATUS] = _POSIX_VDISABLE;
        // #endif
        try posix.tcsetattr(fd, posix.TCSA.FLUSH, term);
    }

    // Catch signals that would otherwise cause the user to end
    // up with echo turned off in the shell.  Don't worry about
    // things like SIGXCPU and SIGVTALRM for now.
    const sa = posix.Sigaction{
        .mask = std.posix.empty_sigset,
        .flags = 0, // don't restart system calls
        .handler = .{ .handler = handler },
    };
    var sigs = [_]struct { sig: u6, buf: posix.Sigaction = undefined }{
        .{ .sig = SIG.ALRM }, .{ .sig = SIG.HUP },  .{ .sig = SIG.INT },
        .{ .sig = SIG.PIPE }, .{ .sig = SIG.QUIT }, .{ .sig = SIG.TERM },
        .{ .sig = SIG.TSTP }, .{ .sig = SIG.TTIN }, .{ .sig = SIG.TTOU },
    };

    // install signals
    for (&sigs) |*sig|
        posix.sigaction(sig.sig, &sa, &sig.buf) catch unreachable;

    _ = posix.write(if (hastty) fd else 2, prompt) catch 0; // posix.STDERR_FILENO

    while (true) {
        var b: [1]u8 = undefined;
        const size = posix.read(fd, &b) catch |e| {
            err = e;
            break;
        };

        if (size == 0 or b[0] == '\n' or b[0] == '\r') break;
        if (b[0] == std.ascii.control_code.bs) {
            if (p > 0) p -= 1;
        } else if (p < buf.len) {
            var ch = b[0];
            if (flags.sevenbit) {
                ch &= 0x7f;
            }
            if (std.ascii.isAlphabetic(ch)) {
                if (flags.forcelower)
                    ch = std.ascii.toLower(ch);

                if (flags.forceupper)
                    ch = std.ascii.toUpper(ch);
            }
            buf[p] = ch;
            p += 1;
        }
    }
    buf[p] = 0;

    _ = posix.write(if (hastty) fd else 2, "\n") catch 0; // posix.STDERR_FILENO

    // Restore old terminal settings and signals
    if (hastty) {
        // Ignore SIGTTOU generated when we are not the fg pgrp.
        const sigttou = signo[SIG.TTOU];

        try posix.tcsetattr(fd, posix.TCSA.FLUSH, oterm);

        signo[SIG.TTOU] = sigttou;
    }

    // restore signals
    for (sigs) |sig|
        posix.sigaction(sig.sig, &sig.buf, null) catch unreachable;

    // If we were interrupted by a signal, resend it to ourselves
    // now that we have restored the signal handlers.
    var sig: u8 = 0;
    for (signo) |did| {
        if (did) {
            try posix.kill(std.os.linux.getpid(), sig);
            switch (sig) {
                // must be retried
                SIG.TSTP,
                SIG.TTIN,
                SIG.TTOU,
                => err = error.EAGIN,

                else => {},
            }
        }
        sig += 1;
    }

    // if we got an error return now
    if (err) |e| return e;

    return buf[0..p :0];
}

var signo: [std.os.linux.NSIG]bool = .{false} ** std.os.linux.NSIG;

fn handler(s: i32) callconv(.C) void {
    signo[@intCast(s)] = true;
}
