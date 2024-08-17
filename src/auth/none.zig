pub const check = emptyauth;

fn emptyauth(name: []const u8, persist: bool) bool {
    _ = name;
    _ = persist;
    return true;
}
