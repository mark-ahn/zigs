const std = @import("std");
const testing = std.testing;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

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
    try init();
    defer deinit() catch |err| std.debug.panic("error during deinit - {s}\n", .{@errorName(err)});
}
