const std = @import("std");

const allocator = std.heap.page_allocator;

pub const __u_int = c_uint;
pub const __uid_t = c_uint;
pub const __gid_t = c_uint;
pub const u_int = __u_int;

pub extern fn memcpy(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
pub extern fn strcmp(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strdup(__s: [*c]const u8) [*c]u8;
pub extern fn strchr(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strlen(__s: [*c]const u8) c_ulong;
pub const struct___va_list_tag = extern struct {
    gp_offset: c_uint,
    fp_offset: c_uint,
    overflow_arg_area: ?*anyopaque,
    reg_save_area: ?*anyopaque,
};
pub extern fn asprintf(noalias __ptr: [*c][*c]u8, noalias __fmt: [*c]const u8, ...) c_int;
pub extern fn free(__ptr: ?*anyopaque) void;
pub extern fn reallocarray(__ptr: ?*anyopaque, __nmemb: usize, __size: usize) ?*anyopaque;
pub extern fn getenv(__name: [*c]const u8) [*c]u8;
pub extern fn err(__status: c_int, __format: [*c]const u8, ...) noreturn;
pub extern fn verr(__status: c_int, __format: [*c]const u8, [*c]struct___va_list_tag) noreturn;
pub extern fn errx(__status: c_int, __format: [*c]const u8, ...) noreturn;
pub extern fn verrx(__status: c_int, [*c]const u8, [*c]struct___va_list_tag) noreturn;
pub extern var environ: [*c][*c]u8;
pub extern fn __errno_location() [*c]c_int;
pub extern var program_invocation_name: [*c]u8;
pub extern var program_invocation_short_name: [*c]u8;
// pub const error_t = c_int;

pub const passwd = extern struct {
    pw_name: [*c]u8,
    pw_passwd: [*c]u8,
    pw_uid: __uid_t,
    pw_gid: __gid_t,
    pw_gecos: [*c]u8,
    pw_dir: [*c]u8,
    pw_shell: [*c]u8,
};

pub extern fn verrc(eval: c_int, code: c_int, fmt: [*c]const u8, ap: [*c]struct___va_list_tag) noreturn;
pub extern fn errc(eval: c_int, code: c_int, fmt: [*c]const u8, ...) noreturn;
pub extern fn getprogname() [*c]const u8;
pub extern fn setprogname(progname: [*c]const u8) void;

pub const rule = extern struct {
    action: c_int,
    options: c_int,
    ident: [*c]const u8,
    target: [*c]const u8,
    cmd: [*c]const u8,
    cmdargs: [*c][*c]const u8,
    envlist: [*c][*c]const u8,
};

pub extern var rules: [*c][*c]rule;
pub extern var nrules: usize;
pub extern var parse_errors: c_int;

pub export var formerpath: [*c]const u8 = undefined;

const inner_node = extern struct {
    rbe_left: [*c]envnode,
    rbe_right: [*c]envnode,
    rbe_parent: [*c]envnode,
    rbe_color: c_int,
};

pub const envnode = extern struct {
    node: inner_node,
    key: [*c]const u8,
    value: [*c]const u8,
};

pub const envtree = extern struct {
    rbh_root: *envnode,
};

pub const env = extern struct {
    root: envtree,
    count: u_int,
};

pub export fn prepenv(rule_1: [*c]const rule, mypw: [*c]const passwd, targpw: [*c]const passwd) [*c][*c]u8 {
    var env_2: *env = createenv(rule_1, mypw, targpw);
    if (rule_1.*.envlist) |envlist| {
        fillenv(env_2, envlist);
    }
    return flattenenv(env_2);
}

pub fn fillenv(local_env: [*c]env, envlist: [*c][*c]const u8) void {
    var node: [*c]envnode = undefined;
    var key: envnode = undefined;
    var eq: [*c]const u8 = undefined;
    var val: [*c]const u8 = undefined;
    var name: [1024]u8 = undefined;
    var i: u_int = 0;
    var len: usize = undefined;
    while (envlist[i] != null) : (i +%= 1) {
        var e: [*c]const u8 = undefined;
        e = envlist[i];
        eq = strchr(e, '=');
        if (eq == null) {
            len = strlen(e);
        } else {
            len = @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(eq) -% @intFromPtr(e))), @sizeOf(u8))));
        }

        if (len > (@sizeOf([1024]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) continue;

        _ = memcpy(@as(?*anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(&name))))), @as(?*const anyopaque, @ptrCast(e)), len);
        name[len] = '\x00';
        key.key = @as([*c]u8, @ptrCast(@alignCast(&name)));
        if (@as(c_int, @bitCast(@as(c_uint, @as([*c]u8, @ptrCast(@alignCast(&name))).*))) == @as(c_int, '-')) {
            key.key = @as([*c]u8, @ptrCast(@alignCast(&name))) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1)))));
        }
        if ((blk: {
            const tmp = envtree_RB_FIND(&local_env.*.root, &key);
            node = tmp;
            break :blk tmp;
        }) != null) {
            _ = envtree_RB_REMOVE(&local_env.*.root, node);
            freenode(node);
            local_env.*.count -%= 1;
        }
        if (@as(c_int, @bitCast(@as(c_uint, @as([*c]u8, @ptrCast(@alignCast(&name))).*))) == @as(c_int, '-')) continue;
        if (eq != null) {
            val = eq + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1)))));
            if (@as(c_int, @bitCast(@as(c_uint, val.*))) == @as(c_int, '$')) {
                if (strcmp(val + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))), "PATH") == @as(c_int, 0)) {
                    val = formerpath;
                } else {
                    val = getenv(val + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))));
                }
            }
        } else {
            if (strcmp(@as([*c]u8, @ptrCast(@alignCast(&name))), "PATH") == @as(c_int, 0)) {
                val = formerpath;
            } else {
                val = getenv(@as([*c]u8, @ptrCast(@alignCast(&name))));
            }
        }
        if (val != null) {
            node = createnode(@as([*c]u8, @ptrCast(@alignCast(&name))), val);
            _ = envtree_RB_INSERT(&local_env.*.root, node);
            local_env.*.count +%= 1;
        }
    }
}

pub fn envcmp(a: *envnode, b: *envnode) c_int {
    return strcmp(a.key, b.key);
}

pub fn envtree_RB_INSERT_COLOR(arg_head: [*c]envtree, arg_elm: [*c]envnode) callconv(.C) void {
    var head = arg_head;
    var elm = arg_elm;
    var parent: [*c]envnode = undefined;
    var gparent: [*c]envnode = undefined;
    var tmp: [*c]envnode = undefined;
    while (((blk: {
        const tmp_1 = elm.*.node.rbe_parent;
        parent = tmp_1;
        break :blk tmp_1;
    }) != null) and (parent.*.node.rbe_color == @as(c_int, 1))) {
        gparent = parent.*.node.rbe_parent;
        if (parent == gparent.*.node.rbe_left) {
            tmp = gparent.*.node.rbe_right;
            if ((tmp != null) and (tmp.*.node.rbe_color == @as(c_int, 1))) {
                tmp.*.node.rbe_color = 0;
                while (true) {
                    parent.*.node.rbe_color = 0;
                    gparent.*.node.rbe_color = 1;
                    if (!false) break;
                }
                elm = gparent;
                continue;
            }
            if (parent.*.node.rbe_right == elm) {
                while (true) {
                    tmp = parent.*.node.rbe_right;
                    if ((blk: {
                        const tmp_1 = tmp.*.node.rbe_left;
                        parent.*.node.rbe_right = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        tmp.*.node.rbe_left.*.node.rbe_parent = parent;
                    }
                    while (true) {
                        if (!false) break;
                    }
                    if ((blk: {
                        const tmp_1 = parent.*.node.rbe_parent;
                        tmp.*.node.rbe_parent = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        if (parent == parent.*.node.rbe_parent.*.node.rbe_left) {
                            parent.*.node.rbe_parent.*.node.rbe_left = tmp;
                        } else {
                            parent.*.node.rbe_parent.*.node.rbe_right = tmp;
                        }
                    } else {
                        head.*.rbh_root = tmp;
                    }
                    tmp.*.node.rbe_left = parent;
                    parent.*.node.rbe_parent = tmp;
                    while (true) {
                        if (!false) break;
                    }
                    if (tmp.*.node.rbe_parent != null) while (true) {
                        if (!false) break;
                    };
                    if (!false) break;
                }
                tmp = parent;
                parent = elm;
                elm = tmp;
            }
            while (true) {
                parent.*.node.rbe_color = 0;
                gparent.*.node.rbe_color = 1;
                if (!false) break;
            }
            while (true) {
                tmp = gparent.*.node.rbe_left;
                if ((blk: {
                    const tmp_1 = tmp.*.node.rbe_right;
                    gparent.*.node.rbe_left = tmp_1;
                    break :blk tmp_1;
                }) != null) {
                    tmp.*.node.rbe_right.*.node.rbe_parent = gparent;
                }
                while (true) {
                    if (!false) break;
                }
                if ((blk: {
                    const tmp_1 = gparent.*.node.rbe_parent;
                    tmp.*.node.rbe_parent = tmp_1;
                    break :blk tmp_1;
                }) != null) {
                    if (gparent == gparent.*.node.rbe_parent.*.node.rbe_left) {
                        gparent.*.node.rbe_parent.*.node.rbe_left = tmp;
                    } else {
                        gparent.*.node.rbe_parent.*.node.rbe_right = tmp;
                    }
                } else {
                    head.*.rbh_root = tmp;
                }
                tmp.*.node.rbe_right = gparent;
                gparent.*.node.rbe_parent = tmp;
                while (true) {
                    if (!false) break;
                }
                if (tmp.*.node.rbe_parent != null) while (true) {
                    if (!false) break;
                };
                if (!false) break;
            }
        } else {
            tmp = gparent.*.node.rbe_left;
            if ((tmp != null) and (tmp.*.node.rbe_color == @as(c_int, 1))) {
                tmp.*.node.rbe_color = 0;
                while (true) {
                    parent.*.node.rbe_color = 0;
                    gparent.*.node.rbe_color = 1;
                    if (!false) break;
                }
                elm = gparent;
                continue;
            }
            if (parent.*.node.rbe_left == elm) {
                while (true) {
                    tmp = parent.*.node.rbe_left;
                    if ((blk: {
                        const tmp_1 = tmp.*.node.rbe_right;
                        parent.*.node.rbe_left = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        tmp.*.node.rbe_right.*.node.rbe_parent = parent;
                    }
                    while (true) {
                        if (!false) break;
                    }
                    if ((blk: {
                        const tmp_1 = parent.*.node.rbe_parent;
                        tmp.*.node.rbe_parent = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        if (parent == parent.*.node.rbe_parent.*.node.rbe_left) {
                            parent.*.node.rbe_parent.*.node.rbe_left = tmp;
                        } else {
                            parent.*.node.rbe_parent.*.node.rbe_right = tmp;
                        }
                    } else {
                        head.*.rbh_root = tmp;
                    }
                    tmp.*.node.rbe_right = parent;
                    parent.*.node.rbe_parent = tmp;
                    while (true) {
                        if (!false) break;
                    }
                    if (tmp.*.node.rbe_parent != null) while (true) {
                        if (!false) break;
                    };
                    if (!false) break;
                }
                tmp = parent;
                parent = elm;
                elm = tmp;
            }
            while (true) {
                parent.*.node.rbe_color = 0;
                gparent.*.node.rbe_color = 1;
                if (!false) break;
            }
            while (true) {
                tmp = gparent.*.node.rbe_right;
                if ((blk: {
                    const tmp_1 = tmp.*.node.rbe_left;
                    gparent.*.node.rbe_right = tmp_1;
                    break :blk tmp_1;
                }) != null) {
                    tmp.*.node.rbe_left.*.node.rbe_parent = gparent;
                }
                while (true) {
                    if (!false) break;
                }
                if ((blk: {
                    const tmp_1 = gparent.*.node.rbe_parent;
                    tmp.*.node.rbe_parent = tmp_1;
                    break :blk tmp_1;
                }) != null) {
                    if (gparent == gparent.*.node.rbe_parent.*.node.rbe_left) {
                        gparent.*.node.rbe_parent.*.node.rbe_left = tmp;
                    } else {
                        gparent.*.node.rbe_parent.*.node.rbe_right = tmp;
                    }
                } else {
                    head.*.rbh_root = tmp;
                }
                tmp.*.node.rbe_left = gparent;
                gparent.*.node.rbe_parent = tmp;
                while (true) {
                    if (!false) break;
                }
                if (tmp.*.node.rbe_parent != null) while (true) {
                    if (!false) break;
                };
                if (!false) break;
            }
        }
    }
    head.*.rbh_root.*.node.rbe_color = 0;
}
pub fn envtree_RB_REMOVE_COLOR(arg_head: [*c]envtree, arg_parent: [*c]envnode, arg_elm: [*c]envnode) callconv(.C) void {
    var head = arg_head;
    var parent = arg_parent;
    var elm = arg_elm;
    var tmp: [*c]envnode = undefined;
    while (((elm == @as([*c]envnode, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (elm.*.node.rbe_color == @as(c_int, 0))) and (elm != head.*.rbh_root)) {
        if (parent.*.node.rbe_left == elm) {
            tmp = parent.*.node.rbe_right;
            if (tmp.*.node.rbe_color == @as(c_int, 1)) {
                while (true) {
                    tmp.*.node.rbe_color = 0;
                    parent.*.node.rbe_color = 1;
                    if (!false) break;
                }
                while (true) {
                    tmp = parent.*.node.rbe_right;
                    if ((blk: {
                        const tmp_1 = tmp.*.node.rbe_left;
                        parent.*.node.rbe_right = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        tmp.*.node.rbe_left.*.node.rbe_parent = parent;
                    }
                    while (true) {
                        if (!false) break;
                    }
                    if ((blk: {
                        const tmp_1 = parent.*.node.rbe_parent;
                        tmp.*.node.rbe_parent = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        if (parent == parent.*.node.rbe_parent.*.node.rbe_left) {
                            parent.*.node.rbe_parent.*.node.rbe_left = tmp;
                        } else {
                            parent.*.node.rbe_parent.*.node.rbe_right = tmp;
                        }
                    } else {
                        head.*.rbh_root = tmp;
                    }
                    tmp.*.node.rbe_left = parent;
                    parent.*.node.rbe_parent = tmp;
                    while (true) {
                        if (!false) break;
                    }
                    if (tmp.*.node.rbe_parent != null) while (true) {
                        if (!false) break;
                    };
                    if (!false) break;
                }
                tmp = parent.*.node.rbe_right;
            }
            if (((tmp.*.node.rbe_left == @as([*c]envnode, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (tmp.*.node.rbe_left.*.node.rbe_color == @as(c_int, 0))) and ((tmp.*.node.rbe_right == @as([*c]envnode, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (tmp.*.node.rbe_right.*.node.rbe_color == @as(c_int, 0)))) {
                tmp.*.node.rbe_color = 1;
                elm = parent;
                parent = elm.*.node.rbe_parent;
            } else {
                if ((tmp.*.node.rbe_right == @as([*c]envnode, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (tmp.*.node.rbe_right.*.node.rbe_color == @as(c_int, 0))) {
                    var oleft: [*c]envnode = undefined;
                    if ((blk: {
                        const tmp_1 = tmp.*.node.rbe_left;
                        oleft = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        oleft.*.node.rbe_color = 0;
                    }
                    tmp.*.node.rbe_color = 1;
                    while (true) {
                        oleft = tmp.*.node.rbe_left;
                        if ((blk: {
                            const tmp_1 = oleft.*.node.rbe_right;
                            tmp.*.node.rbe_left = tmp_1;
                            break :blk tmp_1;
                        }) != null) {
                            oleft.*.node.rbe_right.*.node.rbe_parent = tmp;
                        }
                        while (true) {
                            if (!false) break;
                        }
                        if ((blk: {
                            const tmp_1 = tmp.*.node.rbe_parent;
                            oleft.*.node.rbe_parent = tmp_1;
                            break :blk tmp_1;
                        }) != null) {
                            if (tmp == tmp.*.node.rbe_parent.*.node.rbe_left) {
                                tmp.*.node.rbe_parent.*.node.rbe_left = oleft;
                            } else {
                                tmp.*.node.rbe_parent.*.node.rbe_right = oleft;
                            }
                        } else {
                            head.*.rbh_root = oleft;
                        }
                        oleft.*.node.rbe_right = tmp;
                        tmp.*.node.rbe_parent = oleft;
                        while (true) {
                            if (!false) break;
                        }
                        if (oleft.*.node.rbe_parent != null) while (true) {
                            if (!false) break;
                        };
                        if (!false) break;
                    }
                    tmp = parent.*.node.rbe_right;
                }
                tmp.*.node.rbe_color = parent.*.node.rbe_color;
                parent.*.node.rbe_color = 0;
                if (tmp.*.node.rbe_right != null) {
                    tmp.*.node.rbe_right.*.node.rbe_color = 0;
                }
                while (true) {
                    tmp = parent.*.node.rbe_right;
                    if ((blk: {
                        const tmp_1 = tmp.*.node.rbe_left;
                        parent.*.node.rbe_right = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        tmp.*.node.rbe_left.*.node.rbe_parent = parent;
                    }
                    while (true) {
                        if (!false) break;
                    }
                    if ((blk: {
                        const tmp_1 = parent.*.node.rbe_parent;
                        tmp.*.node.rbe_parent = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        if (parent == parent.*.node.rbe_parent.*.node.rbe_left) {
                            parent.*.node.rbe_parent.*.node.rbe_left = tmp;
                        } else {
                            parent.*.node.rbe_parent.*.node.rbe_right = tmp;
                        }
                    } else {
                        head.*.rbh_root = tmp;
                    }
                    tmp.*.node.rbe_left = parent;
                    parent.*.node.rbe_parent = tmp;
                    while (true) {
                        if (!false) break;
                    }
                    if (tmp.*.node.rbe_parent != null) while (true) {
                        if (!false) break;
                    };
                    if (!false) break;
                }
                elm = head.*.rbh_root;
                break;
            }
        } else {
            tmp = parent.*.node.rbe_left;
            if (tmp.*.node.rbe_color == @as(c_int, 1)) {
                while (true) {
                    tmp.*.node.rbe_color = 0;
                    parent.*.node.rbe_color = 1;
                    if (!false) break;
                }
                while (true) {
                    tmp = parent.*.node.rbe_left;
                    if ((blk: {
                        const tmp_1 = tmp.*.node.rbe_right;
                        parent.*.node.rbe_left = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        tmp.*.node.rbe_right.*.node.rbe_parent = parent;
                    }
                    while (true) {
                        if (!false) break;
                    }
                    if ((blk: {
                        const tmp_1 = parent.*.node.rbe_parent;
                        tmp.*.node.rbe_parent = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        if (parent == parent.*.node.rbe_parent.*.node.rbe_left) {
                            parent.*.node.rbe_parent.*.node.rbe_left = tmp;
                        } else {
                            parent.*.node.rbe_parent.*.node.rbe_right = tmp;
                        }
                    } else {
                        head.*.rbh_root = tmp;
                    }
                    tmp.*.node.rbe_right = parent;
                    parent.*.node.rbe_parent = tmp;
                    while (true) {
                        if (!false) break;
                    }
                    if (tmp.*.node.rbe_parent != null) while (true) {
                        if (!false) break;
                    };
                    if (!false) break;
                }
                tmp = parent.*.node.rbe_left;
            }
            if (((tmp.*.node.rbe_left == @as([*c]envnode, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (tmp.*.node.rbe_left.*.node.rbe_color == @as(c_int, 0))) and ((tmp.*.node.rbe_right == @as([*c]envnode, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (tmp.*.node.rbe_right.*.node.rbe_color == @as(c_int, 0)))) {
                tmp.*.node.rbe_color = 1;
                elm = parent;
                parent = elm.*.node.rbe_parent;
            } else {
                if ((tmp.*.node.rbe_left == @as([*c]envnode, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (tmp.*.node.rbe_left.*.node.rbe_color == @as(c_int, 0))) {
                    var oright: [*c]envnode = undefined;
                    if ((blk: {
                        const tmp_1 = tmp.*.node.rbe_right;
                        oright = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        oright.*.node.rbe_color = 0;
                    }
                    tmp.*.node.rbe_color = 1;
                    while (true) {
                        oright = tmp.*.node.rbe_right;
                        if ((blk: {
                            const tmp_1 = oright.*.node.rbe_left;
                            tmp.*.node.rbe_right = tmp_1;
                            break :blk tmp_1;
                        }) != null) {
                            oright.*.node.rbe_left.*.node.rbe_parent = tmp;
                        }
                        while (true) {
                            if (!false) break;
                        }
                        if ((blk: {
                            const tmp_1 = tmp.*.node.rbe_parent;
                            oright.*.node.rbe_parent = tmp_1;
                            break :blk tmp_1;
                        }) != null) {
                            if (tmp == tmp.*.node.rbe_parent.*.node.rbe_left) {
                                tmp.*.node.rbe_parent.*.node.rbe_left = oright;
                            } else {
                                tmp.*.node.rbe_parent.*.node.rbe_right = oright;
                            }
                        } else {
                            head.*.rbh_root = oright;
                        }
                        oright.*.node.rbe_left = tmp;
                        tmp.*.node.rbe_parent = oright;
                        while (true) {
                            if (!false) break;
                        }
                        if (oright.*.node.rbe_parent != null) while (true) {
                            if (!false) break;
                        };
                        if (!false) break;
                    }
                    tmp = parent.*.node.rbe_left;
                }
                tmp.*.node.rbe_color = parent.*.node.rbe_color;
                parent.*.node.rbe_color = 0;
                if (tmp.*.node.rbe_left != null) {
                    tmp.*.node.rbe_left.*.node.rbe_color = 0;
                }
                while (true) {
                    tmp = parent.*.node.rbe_left;
                    if ((blk: {
                        const tmp_1 = tmp.*.node.rbe_right;
                        parent.*.node.rbe_left = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        tmp.*.node.rbe_right.*.node.rbe_parent = parent;
                    }
                    while (true) {
                        if (!false) break;
                    }
                    if ((blk: {
                        const tmp_1 = parent.*.node.rbe_parent;
                        tmp.*.node.rbe_parent = tmp_1;
                        break :blk tmp_1;
                    }) != null) {
                        if (parent == parent.*.node.rbe_parent.*.node.rbe_left) {
                            parent.*.node.rbe_parent.*.node.rbe_left = tmp;
                        } else {
                            parent.*.node.rbe_parent.*.node.rbe_right = tmp;
                        }
                    } else {
                        head.*.rbh_root = tmp;
                    }
                    tmp.*.node.rbe_right = parent;
                    parent.*.node.rbe_parent = tmp;
                    while (true) {
                        if (!false) break;
                    }
                    if (tmp.*.node.rbe_parent != null) while (true) {
                        if (!false) break;
                    };
                    if (!false) break;
                }
                elm = head.*.rbh_root;
                break;
            }
        }
    }
    if (elm != null) {
        elm.*.node.rbe_color = 0;
    }
}

pub fn envtree_RB_REMOVE(head: *envtree, elm: *envnode) *envnode {
    _ = head;
    var child: *envnode = undefined;
    _ = child;
    var parent: *envnode = undefined;
    _ = parent;
    const old: *envnode = elm;
    _ = old;
    // const color: c_int = undefined;
    //
    // if (elm.node.rbe_left == null) {
    //     child = elm.node.rbe_right;
    // } else if (elm.node.rbe_right == null) {
    //     child = elm.node.rbe_left;
    // } else {
    //     var left: *envnode = undefined;
    //     elm = elm.node.rbe_right;
    //     while (true) {
    //         left = elm.node.rbe_left;
    //         if (left != null) {
    //             elm = left;
    //         }
    //     }
    //
    //     child = elm.node.rbe_right;
    //     parent = elm.node.rbe_parent;
    //     color = elm.node.rbe_color;
    //     if (child != null) {
    //         child.node.rbe_parent = parent;
    //     }
    //     if (parent != null) {
    //         if (parent.node.rbe_left == elm) {
    //             parent.node.rbe_left = child;
    //         } else {
    //             // 				RB_RIGHT(parent, field) = child;	\
    //         }
    //         // 			RB_AUGMENT(parent);				\
    //     }
    // 		} else							\
    // 			RB_ROOT(head) = child;				\
    // 		if (RB_PARENT(elm, field) == old)			\
    // 			parent = elm;					\
    // 		(elm)->field = (old)->field;				\
    // 		if (RB_PARENT(old, field)) {				\
    // 			if (RB_LEFT(RB_PARENT(old, field), field) == old)\
    // 				RB_LEFT(RB_PARENT(old, field), field) = elm;\
    // 			else						\
    // 				RB_RIGHT(RB_PARENT(old, field), field) = elm;\
    // 			RB_AUGMENT(RB_PARENT(old, field));		\
    // 		} else							\
    // 			RB_ROOT(head) = elm;				\
    // 		RB_PARENT(RB_LEFT(old, field), field) = elm;		\
    // 		if (RB_RIGHT(old, field))				\
    // 			RB_PARENT(RB_RIGHT(old, field), field) = elm;	\
    // 		if (parent) {						\
    // 			left = parent;					\
    // 			do {						\
    // 				RB_AUGMENT(left);			\
    // 			} while ((left = RB_PARENT(left, field)));	\
    // 		}							\
    // 		goto color;						\
    // }

    @panic("undefined");

    // 	parent = RB_PARENT(elm, field);					\
    // 	color = RB_COLOR(elm, field);					\
    // 	if (child)							\
    // 		RB_PARENT(child, field) = parent;			\
    // 	if (parent) {							\
    // 		if (RB_LEFT(parent, field) == elm)			\
    // 			RB_LEFT(parent, field) = child;			\
    // 		else							\
    // 			RB_RIGHT(parent, field) = child;		\
    // 		RB_AUGMENT(parent);					\
    // 	} else								\
    // 		RB_ROOT(head) = child;					\
    // color:									\
    // 	if (color == RB_BLACK)						\
    // 		name##_RB_REMOVE_COLOR(head, parent, child);		\
    // return old;
}

pub fn envtree_RB_INSERT(head: *envtree, elm: *envnode) [*c]envnode {
    var tmp: [*c]envnode = undefined;
    var parent: [*c]envnode = null;
    var comp: c_int = 0;
    tmp = head.*.rbh_root;
    while (tmp != null) {
        parent = tmp;
        comp = envcmp(elm, parent);
        if (comp < @as(c_int, 0)) {
            tmp = tmp.*.node.rbe_left;
        } else if (comp > @as(c_int, 0)) {
            tmp = tmp.*.node.rbe_right;
        } else return tmp;
    }
    while (true) {
        elm.*.node.rbe_parent = parent;
        elm.*.node.rbe_left = null;
        elm.*.node.rbe_right = null;
        elm.*.node.rbe_color = 1;
        if (!false) break;
    }
    if (parent != @as([*c]envnode, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
        if (comp < @as(c_int, 0)) {
            parent.*.node.rbe_left = elm;
        } else {
            parent.*.node.rbe_right = elm;
        }
    } else {
        head.rbh_root = elm;
    }
    envtree_RB_INSERT_COLOR(head, elm);
    return null;
}

pub fn envtree_RB_FIND(arg_head: [*c]envtree, arg_elm: [*c]envnode) callconv(.C) [*c]envnode {
    var head = arg_head;
    var elm = arg_elm;
    var tmp: [*c]envnode = head.*.rbh_root;
    var comp: c_int = undefined;
    while (tmp != null) {
        comp = envcmp(elm, tmp);
        if (comp < @as(c_int, 0)) {
            tmp = tmp.*.node.rbe_left;
        } else if (comp > @as(c_int, 0)) {
            tmp = tmp.*.node.rbe_right;
        } else return tmp;
    }
    return null;
}

pub fn envtree_RB_NFIND(arg_head: [*c]envtree, arg_elm: [*c]envnode) callconv(.C) [*c]envnode {
    var head = arg_head;
    var elm = arg_elm;
    var tmp: [*c]envnode = head.*.rbh_root;
    var res: [*c]envnode = null;
    var comp: c_int = undefined;
    while (tmp != null) {
        comp = envcmp(elm, tmp);
        if (comp < @as(c_int, 0)) {
            res = tmp;
            tmp = tmp.*.node.rbe_left;
        } else if (comp > @as(c_int, 0)) {
            tmp = tmp.*.node.rbe_right;
        } else return tmp;
    }
    return res;
}

pub fn envtree_RB_NEXT(a_elm: *envnode) *envnode {
    var elm = a_elm;
    if (elm.*.node.rbe_right != null) {
        elm = elm.*.node.rbe_right;
        while (elm.*.node.rbe_left != null) {
            elm = elm.*.node.rbe_left;
        }
    } else {
        if ((elm.*.node.rbe_parent != null) and (elm == elm.*.node.rbe_parent.*.node.rbe_left)) {
            elm = elm.*.node.rbe_parent;
        } else {
            while ((elm.*.node.rbe_parent != null) and (elm == elm.*.node.rbe_parent.*.node.rbe_right)) {
                elm = elm.*.node.rbe_parent;
            }
            elm = elm.*.node.rbe_parent;
        }
    }
    return elm;
}

pub fn envtree_RB_PREV(arg_elm: [*c]envnode) callconv(.C) [*c]envnode {
    var elm = arg_elm;
    if (elm.*.node.rbe_left != null) {
        elm = elm.*.node.rbe_left;
        while (elm.*.node.rbe_right != null) {
            elm = elm.*.node.rbe_right;
        }
    } else {
        if ((elm.*.node.rbe_parent != null) and (elm == elm.*.node.rbe_parent.*.node.rbe_right)) {
            elm = elm.*.node.rbe_parent;
        } else {
            while ((elm.*.node.rbe_parent != null) and (elm == elm.*.node.rbe_parent.*.node.rbe_left)) {
                elm = elm.*.node.rbe_parent;
            }
            elm = elm.*.node.rbe_parent;
        }
    }
    return elm;
}

pub fn envtree_RB_MINMAX(arg_head: [*c]envtree, arg_val: c_int) callconv(.C) [*c]envnode {
    var head = arg_head;
    var val = arg_val;
    var tmp: [*c]envnode = head.*.rbh_root;
    var parent: [*c]envnode = null;
    while (tmp != null) {
        parent = tmp;
        if (val < @as(c_int, 0)) {
            tmp = tmp.*.node.rbe_left;
        } else {
            tmp = tmp.*.node.rbe_right;
        }
    }
    return parent;
}

pub fn createnode(key: [*c]const u8, value: [*c]const u8) *envnode {
    const node = allocator.create(envnode) catch err(1, null);
    node.*.key = strdup(key);
    node.*.value = strdup(value);
    if (!(node.*.key != null) or !(node.*.value != null)) {
        err(@as(c_int, 1), null);
    }
    return node;
}

pub fn freenode(node: *envnode) void {
    free(@as(?*anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@volatileCast(@constCast(node.*.key)))))));
    free(@as(?*anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@volatileCast(@constCast(node.*.value)))))));
    allocator.destroy(node);
}

pub fn addnode(local_env: [*c]env, key: [*c]const u8, value: [*c]const u8) void {
    var node: *envnode = createnode(key, value);
    _ = envtree_RB_INSERT(&local_env.*.root, node);
    local_env.*.count += 1;
}

pub fn createenv(rule_1: *const rule, mypw: [*c]const passwd, targpw: [*c]const passwd) callconv(.C) *env {
    const copyset = struct {
        var static: [3][*c]const u8 = [3][*c]const u8{
            "DISPLAY",
            "TERM",
            null,
        };
    };

    var env_2: *env = allocator.create(env) catch err(1, null);

    env_2.root.rbh_root = undefined;

    env_2.count = 0;

    addnode(env_2, "DOAS_USER", mypw.*.pw_name);
    addnode(env_2, "HOME", targpw.*.pw_dir);
    addnode(env_2, "LOGNAME", targpw.*.pw_name);
    addnode(env_2, "PATH", getenv("PATH"));
    addnode(env_2, "SHELL", targpw.*.pw_shell);
    addnode(env_2, "USER", targpw.*.pw_name);
    fillenv(env_2, @as([*c][*c]const u8, @ptrCast(@alignCast(&copyset.static))));
    if ((rule_1.*.options & @as(c_int, 2)) != 0) {
        var i: u_int = 0;
        while (environ[i] != @as([*c]u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) : (i +%= 1) {
            var node: [*c]envnode = undefined;
            var e: [*c]const u8 = undefined;
            var eq: [*c]const u8 = undefined;
            var len: usize = undefined;
            var keybuf: [1024]u8 = undefined;
            e = environ[i];
            if (((blk: {
                const tmp = strchr(e, @as(c_int, '='));
                eq = tmp;
                break :blk tmp;
            }) == @as([*c]const u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (eq == e)) continue;
            len = @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(eq) -% @intFromPtr(e))), @sizeOf(u8))));
            if (len > (@sizeOf([1024]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) continue;
            _ = memcpy(@as(?*anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(&keybuf))))), @as(?*const anyopaque, @ptrCast(e)), len);
            keybuf[len] = '\x00';
            node = createnode(@as([*c]u8, @ptrCast(@alignCast(&keybuf))), eq + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))));
            if (envtree_RB_INSERT(&env_2.*.root, node) != null) {
                freenode(node);
            } else {
                env_2.*.count +%= 1;
            }
        }
    }
    return env_2;
}

pub fn flattenenv(local_env: *env) [*c][*c]u8 {
    // const alloc = std.heap.page_allocator;
    // alloc: std.mem.Allocator
    var envp: [*c][*c]u8 = @as([*c][*c]u8, @ptrCast(@alignCast(reallocarray(null, local_env.*.count + 1, @sizeOf([*c]u8)))));

    if (envp == null) {
        err(1, null);
    }

    var i: u_int = 0;

    var node: [*c]envnode = envtree_RB_MINMAX(&local_env.root, -1);

    while (node != null) : (node = envtree_RB_NEXT(node)) {
        if (asprintf(&envp[i], "%s=%s", node.*.key, node.*.value) == -1) {
            err(1, null);
        }
        i += 1;
    }
    envp[i] = null;
    return envp;
}
