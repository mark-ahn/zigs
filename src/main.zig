const std = @import("std");
const testing = std.testing;

pub usingnamespace @import("ios.zig");

pub const heap = struct {
    pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    pub var ally = gpa.allocator();
};

pub const InitState = enum {
    uninited,
    inited,
    deinited,
};

pub const Error = error{
    double_init,
    deinit_before_init,
    gpa_leak,
};

const global = struct {
    var init_st: InitState = .uninited;
};
pub fn init() !void {
    var st = @atomicRmw(InitState, &global.init_st, std.builtin.AtomicRmwOp.Xchg, .inited, std.builtin.AtomicOrder.Monotonic);
    switch (st) {
        .inited => return,
        .deinited => return Error.double_init,
        .uninited => {},
    }
}
pub fn deinit() !void {
    var st = @atomicRmw(InitState, &global.init_st, std.builtin.AtomicRmwOp.Xchg, .deinited, std.builtin.AtomicOrder.Monotonic);
    switch (st) {
        .inited => {},
        .deinited => return,
        .uninited => return Error.deinit_before_init,
    }

    if (heap.gpa.deinit() == .leak) return Error.gpa_leak;

    return;
}

test "module" {
    testing.log_level = std.log.Level.info;
    try init();
    defer deinit() catch |err| std.debug.panic("error during deinit - {s}", .{@errorName(err)});

    var str = try heap.ally.dupe(u8, "test string");
    defer heap.ally.free(str);
    // std.log.info("{s}\n", .{str});
}

test {
    testing.refAllDecls(@import("ios.zig"));
}
