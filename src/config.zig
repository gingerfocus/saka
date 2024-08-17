const Security = union(enum) {
    chroot: []const u8,
    chdir: []const u8,
    none,
};

const Rule = struct {
    uid: i32,
    gid: i32,
    cmd: []const u8,
    path: []const u8,
};

security: Security = blk: {
    // this is a code block that evaluates to data, you can write zig code in
    // here, try it! it's fun!
    break :blk .none;
},

rules: []const Rule = &.{
    Rule{
        .uid = 1000,
        .gid = -1,
        .cmd = "whoami",
        // .path = "/usr/bin/whoami",
        // .path = "/run/current-system/sw/bin/whoami",
        .path = "/nix/store/php4qidg2bxzmm79vpri025bqi0fa889-coreutils-9.5/bin/coreutils",
    },
    Rule{
        .uid = @as(c_int, 1000),
        .gid = -@as(c_int, 1),
        .cmd = "ifconfig",
        .path = "/sbin/ifconfig",
    },
    Rule{
        .uid = @as(c_int, 1000),
        .gid = -@as(c_int, 1),
        .cmd = "ls",
        .path = "/bin/ls",
    },
    Rule{
        .uid = @as(c_int, 1000),
        .gid = -@as(c_int, 1),
        .cmd = "wifi",
        .path = "/root/wifi.sh",
    },
    Rule{
        .uid = @as(c_int, 1000),
        .gid = -@as(c_int, 1),
        .cmd = "cp",
        .path = "*",
    },
    Rule{
        .uid = @as(c_int, 1000),
        .gid = -@as(c_int, 1),
        .cmd = "*",
        .path = "*",
    },
},
