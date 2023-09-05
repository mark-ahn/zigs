const std = @import("std");
const testing = std.testing;

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub var ally = gpa.allocator();

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

var init_st: InitState = .uninited;
pub fn init() !void {
    var st = @atomicRmw(InitState, &init_st, std.builtin.AtomicRmwOp.Xchg, .inited, std.builtin.AtomicOrder.Monotonic);
    switch (st) {
        .inited => return,
        .deinited => return Error.double_init,
        .uninited => {},
    }
}
pub fn deinit() !void {
    var st = @atomicRmw(InitState, &init_st, std.builtin.AtomicRmwOp.Xchg, .deinited, std.builtin.AtomicOrder.Monotonic);
    switch (st) {
        .inited => {},
        .deinited => return,
        .uninited => return Error.deinit_before_init,
    }

    if (gpa.deinit() == .leak) return Error.gpa_leak;

    return;
}

test "module" {
    testing.log_level = std.log.Level.info;
    try init();
    defer deinit() catch |err| std.debug.panic("error during deinit - {s}\n", .{@errorName(err)});

    var str = try ally.dupe(u8, "test string");
    defer ally.free(str);
    // std.log.info("{s}\n", .{str});
}
